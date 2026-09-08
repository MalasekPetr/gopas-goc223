<#
    Grant-RequestedAccess - elevovana operace nad SharePointem pod aplikacni identitou.

    Nahrazuje ten nejcasteji stavany Power Automate flow: uzivatel pozada o pristup
    k dokumentu, automatizace mu ho prideli. V Power Automate se to dela sdilenim flow
    s run-only uzivateli, kde konektor zustane na vlastnikovi - operace se pak provede
    pod OPRAVNENIM VLASTNIKA. Srovnani a dusledky: comparison-power-automate.md.

    Tady to bezi pod app registraci se Sites.Selected na jeden web. Rozdil neni v tom,
    ze by to bylo "lepsi" - rozdil je, ze identita neni cloveka, autorizace je explicitni
    v kodu a audit lezi v seznamu, ktery vidi i zadavatel.

    ARCHITEKTURA
        Seznam zadosti (uzivatel zaklada radky)
            -> timer trigger probudi funkci podle rozvrhu
            -> pro kazdou Pending zadost: autorizacni brana, pak elevace, pak audit
            -> radek zadosti se oznaci jako zpracovany

    AUTORIZACNI BRANA JE TU PODSTATNA VEC. Aplikace ma pravo zapisovat na cely web,
    takze kdyby brala zadosti bez kontroly, je to ucebnicovy confused deputy: kdokoli,
    kdo umi zalozit radek, si necha pridelit cokoli. Brana proto kontroluje dve veci:
      1. zadatel je tentyz clovek, ktery radek zalozil (Author), ne kdokoli uvedeny v poli,
      2. cilova knihovna je v povolenem rozsahu, ktery se predava parametrem.
    Zamitnuta zadost se AUDITUJE, nezahodi.

    Spusteni (po dot-sourcovani; pripojeni resi Connect-CourseTarget z day-2):
        . ./Grant-RequestedAccess.ps1
        Invoke-AccessRequestQueue -RequestListTitle 'Zadosti o pristup' `
            -AuditListTitle 'Audit pristupu' -AllowedLibraryTitle 'Dokumenty' -WhatIf

    Vyzaduje PowerShell 7.4+ a PnP.PowerShell.
#>

#Requires -Version 7.4

Set-StrictMode -Version Latest

# Nazvy poli v seznamu zadosti. Interni nazvy, ne zobrazovane - viz guide-elevated-op.md.
$script:RequestFields = @{
    Status      = 'RequestStatus'
    Requester   = 'RequesterEmail'
    Library     = 'TargetLibrary'
    ItemId      = 'TargetItemId'
    Role        = 'RequestedRole'
    Decision    = 'DecisionNote'
}


function Get-PendingRequest {
    <#
    .SYNOPSIS
        Vrati zadosti ve stavu Pending.
    .DESCRIPTION
        Filtruje se CAML dotazem, ne az Where-Object na vysledku. U seznamu, ktery za rok
        naroste na desetitisice radku, je to rozdil mezi dotazem a stahovanim cele historie
        - tentyz princip "filtruj vlevo" jako v day-2/opt-powershell-basics.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] [string] $RequestListTitle
    )

    $caml = @"
<View>
  <Query>
    <Where>
      <Eq>
        <FieldRef Name='$($script:RequestFields.Status)' />
        <Value Type='Text'>Pending</Value>
      </Eq>
    </Where>
  </Query>
  <RowLimit>500</RowLimit>
</View>
"@

    # Vraci se prirozene, tedy s rozbalenim - a volajici to MUSI obalit @(). Je to ta
    # past z day-2/opt-powershell-basics: prazdny vysledek dorazi jako $null
    # a jednoprvkovy jako ta jedina polozka.
    #
    # Proc se to tady neresi pres Write-Output -NoEnumerate: kdyby funkce pole
    # garantovala A volajici ho jeste obalil, zabali se DVAKRAT a foreach pak iteruje
    # jednou nad celym polem. Jeden mechanismus, ne oba. U interniho helperu obaluje
    # volajici; u verejneho Invoke-AccessRequestQueue garantuje pole funkce.
    # Where-Object neni zdobeni: @($null) ma Count 1, ne 0. Kdyby cmdlet vratil $null,
    # do fronty by se dostala FANTOMOVA zadost a foreach by spadl az na .FieldValues -
    # tedy hlaskou, ktera o pricine nic nerekne. U kodu, ktery bezi bez dozoru nad
    # produkcnim tenantem, se tohle filtruje na vstupu.
    return @(Get-PnPListItem -List $RequestListTitle -Query $caml | Where-Object { $null -ne $_ })
}


function Test-RequestAllowed {
    <#
    .SYNOPSIS
        Autorizacni brana. Vraci objekt s Allowed a Reason.
    .DESCRIPTION
        Bez teto funkce je cely skript confused deputy. Kontroluje se:
          - zadatel se rovna zakladateli radku (Author), aby nikdo nezadal o pristup
            "za nekoho jineho",
          - cilova knihovna je v povolenem rozsahu,
          - pozadovana role je z povolene sady - eskalace na Full Control se neprideli
            ani kdyz si ji nekdo do radku napise.

        Vraci objekt, ne boolean, protoze duvod zamitnuti se musi dostat do auditu.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Request,
        [Parameter(Mandatory)] [string] $AllowedLibraryTitle,
        [string[]] $AllowedRoles = @('Read', 'Contribute')
    )

    $fields    = $Request.FieldValues
    $requester = $fields[$script:RequestFields.Requester]
    $library   = $fields[$script:RequestFields.Library]
    $role      = $fields[$script:RequestFields.Role]

    # Author je systemove pole, ktere uzivatel nezmeni - proto se overuje proti nemu.
    $authorEmail = if ($fields.ContainsKey('Author') -and $fields['Author']) {
        $fields['Author'].Email
    } else {
        $null
    }

    if ([string]::IsNullOrWhiteSpace($requester)) {
        return [pscustomobject]@{ Allowed = $false; Reason = 'Zadost neuvadi zadatele.' }
    }
    if ([string]::IsNullOrWhiteSpace($authorEmail)) {
        return [pscustomobject]@{ Allowed = $false; Reason = 'Radek nema Author, nelze overit zadatele.' }
    }
    if ($requester -ne $authorEmail) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = ("Zadatel '{0}' neodpovida zakladateli radku '{1}'." -f $requester, $authorEmail)
        }
    }
    if ($library -ne $AllowedLibraryTitle) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = ("Knihovna '{0}' je mimo povoleny rozsah '{1}'." -f $library, $AllowedLibraryTitle)
        }
    }
    if ($role -notin $AllowedRoles) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = ("Role '{0}' neni v povolene sade: {1}." -f $role, ($AllowedRoles -join ', '))
        }
    }

    return [pscustomobject]@{ Allowed = $true; Reason = 'OK' }
}


function Write-AuditEntry {
    <#
    .SYNOPSIS
        Zapise radek do audit seznamu.
    .DESCRIPTION
        Audit se zapisuje u schvalene I zamitnute zadosti. Zamitnuti, ktere nikde nezustane,
        je z pohledu auditora totez jako kdyby zadost nikdy neprisla.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $AuditListTitle,
        [Parameter(Mandatory)] [int] $RequestId,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Requester,
        [Parameter(Mandatory)] [ValidateSet('Granted', 'Rejected', 'Failed')] [string] $Outcome,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Detail
    )

    $values = @{
        Title      = "Request $RequestId"
        Requester  = $Requester
        Outcome    = $Outcome
        Detail     = $Detail
        ProcessedU = (Get-Date).ToUniversalTime().ToString('o')
    }

    if ($PSCmdlet.ShouldProcess("$AuditListTitle / $RequestId", "Zapsat audit ($Outcome)")) {
        Add-PnPListItem -List $AuditListTitle -Values $values | Out-Null
    }
}


function Grant-ItemAccess {
    <#
    .SYNOPSIS
        Samotna elevovana operace - prideli uzivateli roli na jedne polozce.
    .DESCRIPTION
        Set-PnPListItemPermission s -AddRole rozbije dedeni opravneni na te polozce
        a prida zadanou roli. Je to presne ta operace, kterou by beznemu uzivateli
        SharePoint nedovolil - proto ji dela aplikacni identita.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $LibraryTitle,
        [Parameter(Mandatory)] [int] $ItemId,
        [Parameter(Mandatory)] [string] $UserEmail,
        [Parameter(Mandatory)] [string] $Role
    )

    if ($PSCmdlet.ShouldProcess("$LibraryTitle / item $ItemId", "Pridelit '$Role' uzivateli $UserEmail")) {
        Set-PnPListItemPermission -List $LibraryTitle -Identity $ItemId `
            -User $UserEmail -AddRole $Role
    }
}


function Set-RequestProcessed {
    <#
    .SYNOPSIS
        Oznaci radek zadosti jako zpracovany.
    .DESCRIPTION
        -SystemUpdate je tu zamerne: podle dokumentace PnP meni polozku BEZ verzovani
        a BEZ spousteni flow. U zapisu zpatky do seznamu, ktery cely proces spustil, to
        zabranuje dvema vecem - zaplaveni verzi a zacykleni, kdyby nad tim seznamem visel
        jeste nejaky flow.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $RequestListTitle,
        [Parameter(Mandatory)] [int] $RequestId,
        [Parameter(Mandatory)] [ValidateSet('Granted', 'Rejected', 'Failed')] [string] $Status,
        [Parameter(Mandatory)] [AllowEmptyString()] [string] $Note
    )

    $values = @{
        $script:RequestFields.Status   = $Status
        $script:RequestFields.Decision = $Note
    }

    if ($PSCmdlet.ShouldProcess("$RequestListTitle / $RequestId", "Nastavit stav $Status")) {
        Set-PnPListItem -List $RequestListTitle -Identity $RequestId -Values $values -SystemUpdate | Out-Null
    }
}


function Invoke-AccessRequestQueue {
    <#
    .SYNOPSIS
        Zpracuje frontu zadosti o pristup. Vstupni bod celeho skriptu.
    .DESCRIPTION
        Idempotence je tu podminka, ne ozdoba: kdyz se hostitel restartuje, Azure Automation
        spusti job OD ZACATKU (viz comparison-scheduled-runtimes.md). Skript proto bere jen
        radky ve stavu Pending a kazdy zpracovany radek prepne na koncovy stav - druhy beh
        nad stejnymi daty tedy neudela nic.

        Selhani jedne zadosti nesmi shodit celou frontu. Chyba se proto chyta per zadost,
        zapise se do auditu a radek dostane stav Failed.
    .PARAMETER AllowedLibraryTitle
        Povoleny rozsah. Zadost na jinou knihovnu se zamitne, i kdyz aplikace technicky
        pravo ma - least privilege se vynucuje i v kodu, ne jen v Entra.
    .EXAMPLE
        Invoke-AccessRequestQueue -RequestListTitle 'Zadosti o pristup' `
            -AuditListTitle 'Audit pristupu' -AllowedLibraryTitle 'Dokumenty' -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] [string] $RequestListTitle,
        [Parameter(Mandatory)] [string] $AuditListTitle,
        [Parameter(Mandatory)] [string] $AllowedLibraryTitle,
        [string[]] $AllowedRoles = @('Read', 'Contribute')
    )

    # Zavorky @() jsou i tak na miste: producent garantuje pole, konzument se na to
    # nespoleha. U kodu, ktery bezi bez dozoru nad produkcnim tenantem, se tahle
    # dvojita opatrnost vyplati.
    $requests = @(Get-PendingRequest -RequestListTitle $RequestListTitle)
    Write-Verbose "Zadosti ke zpracovani: $($requests.Count)"

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($request in $requests) {
        $fields    = $request.FieldValues
        $requestId = [int] $request.Id
        $requester = [string] $fields[$script:RequestFields.Requester]

        $verdict = Test-RequestAllowed -Request $request `
            -AllowedLibraryTitle $AllowedLibraryTitle -AllowedRoles $AllowedRoles

        if (-not $verdict.Allowed) {
            Write-Warning "Zadost $requestId zamitnuta: $($verdict.Reason)"
            Write-AuditEntry -AuditListTitle $AuditListTitle -RequestId $requestId `
                -Requester $requester -Outcome 'Rejected' -Detail $verdict.Reason
            Set-RequestProcessed -RequestListTitle $RequestListTitle -RequestId $requestId `
                -Status 'Rejected' -Note $verdict.Reason
            $results.Add([pscustomobject]@{ RequestId = $requestId; Outcome = 'Rejected'; Detail = $verdict.Reason })
            continue
        }

        $library = [string] $fields[$script:RequestFields.Library]
        $itemId  = [int] $fields[$script:RequestFields.ItemId]
        $role    = [string] $fields[$script:RequestFields.Role]

        try {
            Grant-ItemAccess -LibraryTitle $library -ItemId $itemId -UserEmail $requester -Role $role
            $detail = "Pridelena role '$role' na polozku $itemId v '$library'."

            Write-AuditEntry -AuditListTitle $AuditListTitle -RequestId $requestId `
                -Requester $requester -Outcome 'Granted' -Detail $detail
            Set-RequestProcessed -RequestListTitle $RequestListTitle -RequestId $requestId `
                -Status 'Granted' -Note $detail
            $results.Add([pscustomobject]@{ RequestId = $requestId; Outcome = 'Granted'; Detail = $detail })
        }
        catch {
            # Jedna spadla zadost nesmi zastavit frontu. Zapisujeme ji a jdeme dal.
            $detail = "Elevace selhala: $($_.Exception.Message)"
            Write-Warning "Zadost $requestId - $detail"
            Write-AuditEntry -AuditListTitle $AuditListTitle -RequestId $requestId `
                -Requester $requester -Outcome 'Failed' -Detail $detail
            Set-RequestProcessed -RequestListTitle $RequestListTitle -RequestId $requestId `
                -Status 'Failed' -Note $detail
            $results.Add([pscustomobject]@{ RequestId = $requestId; Outcome = 'Failed'; Detail = $detail })
        }
    }

    # Totez jako u Get-PendingRequest: bez -NoEnumerate by prazdna fronta dorazila
    # volajicimu jako $null a jedna zadost jako samotny objekt.
    Write-Output -NoEnumerate $results.ToArray()
}
