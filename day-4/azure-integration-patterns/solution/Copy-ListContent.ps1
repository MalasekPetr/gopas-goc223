<#
    Copy-ListContent - kopie polozek mezi seznamy se zachovanim puvodnich metadat.

    Nahrazuje druhy nejcasteji stavany Power Automate flow: "kdyz vznikne polozka tady,
    vytvor ji i tam". Flow to zvladne, ale kopii oznaci svym vlastnim casem a svou
    identitou - a u migrace nebo archivace je puvodni Created/Modified/Author/Editor
    presne to, co nesmite ztratit. Auditor se pta "kdo to zalozil a kdy", ne "kdy to
    prekopiroval skript".

    JADRO CELEHO MATERIALU JE JEDEN FORK, ZE KTEREHO NENI VOLNE VYCHODISKO.
    PnP ma tri update typy a dokumentace o nich rika (verbatim, Set-PnPListItem):

      Update
        "Sets field values and creates a new version if versioning is enabled for the
         list. The 'Modified By' and 'Modified' fields will be updated to reflect the
         time of the update and the user who made the change."

      SystemUpdate
        "Sets field values and does not create a new version. Changes are appended to
         the last version. Any events on the list will trigger. The 'Modified By' and
         'Modified' fields are not updated and CAN NOT BE SET."
        Note: Power Automate Flows are not triggered

      UpdateOverwriteVersion
        "Sets field values and does not create a new version. The last version's modified
         date is updated and the changes are appended. The 'Modified By' and 'Modified'
         fields are not updated BUT CAN BE SET by passing the field values in the update.
         HINT: use 'Editor' to set the 'Modified By' field."
        Note: Power Automate Flows ARE triggered

    Cili:
      chcete zachovat puvodni casy a autory -> UpdateOverwriteVersion -> FLOW SE SPUSTI.
        Na migraci 10 000 polozek to je 10 000 behu flow.
      nechcete zaplavit flow -> SystemUpdate -> METADATA NASTAVIT NELZE.
    V jednom volani to obe veci mit nejde. Skript proto ma parametr -WriteMode a nuti vas
    ten fork rozhodnout vedome, misto aby jednu stranu tise schoval.

    DRUHA VEC, KTERA PRICHAZI ZDARMA A JE HORSI, NEZ SE ZDA.
    Zapis pres SystemUpdate necha Modified nedotcene. Detekce driftu postavena na
    "co se zmenilo od vcerejska podle Modified" takovy zapis NEUVIDI. To je presne
    detekce, kterou stavi day-4/lifecycle-compliance. Neni to chyba PnP - je to vlastnost,
    kterou musi znat ten, kdo governance navrhuje. Viz guide-copy-metadata.md.

    ARCHITEKTURA (kopie je vzdy DVOUFAZOVA, protoze jinak to nejde)
        faze 1: Add-PnPListItem  -> vytvori polozku; Author je VZDY volajici identita
                                    ("The author is set to the current authenticated
                                     user executing the cmdlet.") a nastavit ho tu nelze
        faze 2: Set-PnPListItem  -> az tady se vrati puvodni Created/Modified/Author/Editor
                                    (jen ve WriteMode Fidelity - viz fork vyse)

    Spusteni (po dot-sourcovani; pripojeni resi Connect-CourseTarget z day-2):
        . ./Copy-ListContent.ps1
        Copy-ListContent -SourceListTitle 'Evidence' -TargetListTitle 'Evidence archiv' `
            -KeyField 'EvidencniCislo' -DataField @('Title', 'Popis', 'Castka') -WhatIf

    Vyzaduje PowerShell 7.4+ a PnP.PowerShell.
#>

#Requires -Version 7.4

Set-StrictMode -Version Latest

# Systemova pole, ktera kopii delaji kopii a ne novym zapisem. Interni nazvy.
# Author = "Created By", Editor = "Modified By" - zobrazovane nazvy jsou jine, viz
# day-2/opt-powershell-basics (Get-Member ukaze skutecna jmena, ne ta z tabulky).
$script:FidelityFields = @('Created', 'Modified', 'Author', 'Editor')


function Format-FieldValue {
    <#
    .SYNOPSIS
        Prevede hodnotu do podoby, kterou nedavkovy zapis prijme.
    .DESCRIPTION
        Tady je past, na kterou se v ceskem prostredi narazi tvrde. Add-PnPListItem
        dokumentuje (verbatim):

          "For numeric and currency fields, when using -Batch, provide the value using
           the comma and dots matching the regional setting of the site you're adding
           the listitem to. When not using batch, you must always provide the value in
           the American notation, so dot for decimals and comma for thousands separators."

        Na cs-CZ webu tedy davkovy zapis chce 1234,56 a nedavkovy 1234.56. A protoze
        "$hodnota" na ceskem stroji vyrobi 1234,56, nedavkovy zapis cisla pres bezne
        prevedeni na string je ROZBITY - mlcky, protoze SharePoint hodnotu bud odmitne,
        nebo si ji prelozi jinak, nez jste myslel.

        Reseni je InvariantCulture. Nikoli ToString() bez parametru.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [AllowNull()] $Value
    )

    if ($null -eq $Value) { return $null }

    # DateTime posilame jako objekt - PnP si ho prevede sam a zadna kulturni
    # dvojznacnost nevznika. Prevadet ho na string by past jen presunulo.
    if ($Value -is [datetime]) { return $Value }

    if ($Value -is [double] -or $Value -is [decimal] -or $Value -is [single]) {
        return $Value.ToString([cultureinfo]::InvariantCulture)
    }

    return $Value
}


function Get-PrincipalLogin {
    <#
    .SYNOPSIS
        Vytahne prihlasovaci jmeno z hodnoty Person pole.
    .DESCRIPTION
        Person pole nevraci string, ale objekt (FieldUserValue) s vlastnostmi Email
        a LookupValue. Ktera z nich je pouzitelna, zavisi na tom, jak je uzivatel
        v site user information listu - proto se bere Email a teprve kdyz chybi,
        LookupValue. Prazdno neni chyba: puvodni autor mohl byt smazany ucet.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [AllowNull()] $FieldValue
    )

    if ($null -eq $FieldValue) { return $null }
    if ($FieldValue -is [string]) { return $FieldValue }

    $names = $FieldValue.PSObject.Properties.Name
    if ($names -contains 'Email' -and $FieldValue.Email) { return $FieldValue.Email }
    if ($names -contains 'LookupValue' -and $FieldValue.LookupValue) { return $FieldValue.LookupValue }

    return $null
}


function Get-SourceItem {
    <#
    .SYNOPSIS
        Precte polozky zdrojoveho seznamu.
    .DESCRIPTION
        -PageSize neni ozdoba: bez nej PnP tahne vsechno najednou a nad velkym seznamem
        to skonci na list view threshold. Vazba na day-3/graph-fundamentals.

        @(...) na vysledku je tu proto, ze @($null).Count je 1, ne 0. Kdyby cmdlet vratil
        $null, dostala by se do zpracovani FANTOMOVA polozka a spadlo by to az na
        .FieldValues - tedy hlaskou, ktera o pricine nerekne nic.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] [string] $ListTitle,
        [int] $PageSize = 500
    )

    return @(Get-PnPListItem -List $ListTitle -PageSize $PageSize | Where-Object { $null -ne $_ })
}


function Get-TargetIndex {
    <#
    .SYNOPSIS
        Postavi index cilovych polozek podle business klice.
    .DESCRIPTION
        Idempotence stoji na tom, ze kopie pozna, co uz v cili je. Klicem NENI ID
        polozky - to si cil generuje sam a se zdrojem nijak nesouvisi. Klicem je pole,
        ktere ma vecny vyznam (evidencni cislo, UPN, cislo smlouvy).

        Bez toho vznikne pri druhem behu druha sada kopii. To je nejcastejsi chyba
        v kopirovacich skriptech vubec.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $ListTitle,
        [Parameter(Mandatory)] [string] $KeyField,
        [int] $PageSize = 500
    )

    $index = @{}
    foreach ($item in (Get-SourceItem -ListTitle $ListTitle -PageSize $PageSize)) {
        $key = $item.FieldValues[$KeyField]
        if ($null -ne $key -and "$key".Length -gt 0) {
            $index["$key"] = $item.Id
        }
    }

    return $index
}


function Copy-ItemMetadata {
    <#
    .SYNOPSIS
        Faze 2 - vrati na zkopirovanou polozku puvodni Created/Modified/Author/Editor.
    .DESCRIPTION
        Ve WriteMode Fidelity se pouzije UpdateOverwriteVersion, protoze podle
        dokumentace je to JEDINY update typ, u ktereho lze Modified a Editor nastavit.
        Cenou je, ze se spusti flow.

        Ve WriteMode Quiet se metadata nepredavaji VUBEC a funkce to nahlasi. Neni to
        opomenuti - SystemUpdate je nastavit neumi ("can not be set"). Kdybychom je
        do -Values pridali, SharePoint by je tise zahodil a vy byste si myslel, ze
        kopie ma verna metadata. Tise selhat je horsi nez selhat nahlas.

        Author/Editor navic vyzaduji, aby ten uzivatel byl v site user information listu
        ciloveho webu. Kdyz neni, zapis spadne - viz New-PnPUser v poznamce
        u Add-PnPListItem. Selhani jedne polozky proto neshodi celou davku; degraduje
        se na kopii bez verne metadatove stopy a nahlasi se.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $TargetListTitle,
        [Parameter(Mandatory)] [int] $TargetItemId,
        [Parameter(Mandatory)] $SourceFieldValues,
        [Parameter(Mandatory)] [ValidateSet('Fidelity', 'Quiet')] [string] $WriteMode
    )

    if ($WriteMode -eq 'Quiet') {
        Write-Warning ("Polozka $TargetItemId - WriteMode Quiet: SystemUpdate neumi nastavit " +
            'Modified/Editor, kopie proto nese identitu a cas aplikace. Verna metadata ' +
            'vyzaduji WriteMode Fidelity (a spusti flow).')
        return $false
    }

    $values = @{}
    foreach ($field in $script:FidelityFields) {
        if (-not $SourceFieldValues.ContainsKey($field)) { continue }

        $raw = $SourceFieldValues[$field]
        if ($field -in @('Author', 'Editor')) {
            $login = Get-PrincipalLogin -FieldValue $raw
            if ($login) { $values[$field] = $login }
        }
        else {
            $formatted = Format-FieldValue -Value $raw
            if ($null -ne $formatted) { $values[$field] = $formatted }
        }
    }

    if ($values.Count -eq 0) { return $false }

    if (-not $PSCmdlet.ShouldProcess("$TargetListTitle / item $TargetItemId", 'Vratit puvodni metadata')) {
        return $false
    }

    Set-PnPListItem -List $TargetListTitle -Identity $TargetItemId `
        -Values $values -UpdateType UpdateOverwriteVersion | Out-Null

    return $true
}


function Copy-ListContent {
    <#
    .SYNOPSIS
        Zkopiruje polozky mezi seznamy. Vstupni bod celeho skriptu.
    .DESCRIPTION
        Idempotentni: co uz v cili podle business klice je, se znovu nezaklada. Druhy beh
        nad stejnymi daty proto nezapise nic - stejna podminka jako u batch sync labu.

        Vraci jeden zaznam na polozku s vysledkem, aby slo po behu rict, kolik kopii ma
        vernou metadatovou stopu a kolik ne. U migrace je to cislo, ktere chce videt
        zadavatel.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] [string] $SourceListTitle,
        [Parameter(Mandatory)] [string] $TargetListTitle,
        [Parameter(Mandatory)] [string] $KeyField,
        [Parameter(Mandatory)] [string[]] $DataField,
        [ValidateSet('Fidelity', 'Quiet')] [string] $WriteMode = 'Fidelity',
        [int] $PageSize = 500
    )

    $existing = Get-TargetIndex -ListTitle $TargetListTitle -KeyField $KeyField -PageSize $PageSize
    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($item in (Get-SourceItem -ListTitle $SourceListTitle -PageSize $PageSize)) {
        $fields = $item.FieldValues
        $key = "$($fields[$KeyField])"

        if ($key.Length -eq 0) {
            Write-Warning "Zdrojova polozka $($item.Id) nema $KeyField - preskakuji, bez klice nelze zajistit idempotenci."
            $results.Add([pscustomobject]@{ SourceId = $item.Id; Key = ''; Outcome = 'Skipped'; MetadataCopied = $false })
            continue
        }

        if ($existing.ContainsKey($key)) {
            # Uz je v cili. Tady by v produkcnim skriptu byla delta - viz Sync-CourseList.ps1.
            $results.Add([pscustomobject]@{ SourceId = $item.Id; Key = $key; Outcome = 'Exists'; MetadataCopied = $false })
            continue
        }

        $values = @{}
        foreach ($field in $DataField) {
            if ($fields.ContainsKey($field)) {
                $values[$field] = Format-FieldValue -Value $fields[$field]
            }
        }

        try {
            if (-not $PSCmdlet.ShouldProcess("$TargetListTitle / $key", 'Zalozit kopii')) {
                $results.Add([pscustomobject]@{ SourceId = $item.Id; Key = $key; Outcome = 'WhatIf'; MetadataCopied = $false })
                continue
            }

            # Faze 1. Author bude aplikacni identita a nastavit ho tu nelze.
            $created = Add-PnPListItem -List $TargetListTitle -Values $values -ErrorAction Stop

            # Faze 2. Az tady se vraci puvodni metadata - a jen ve WriteMode Fidelity.
            $copied = $false
            try {
                $copied = Copy-ItemMetadata -TargetListTitle $TargetListTitle -TargetItemId $created.Id `
                    -SourceFieldValues $fields -WriteMode $WriteMode
            }
            catch {
                # Nejcastejsi pricina: puvodni autor neni v site user information listu cile.
                # Kopie existuje, jen nema vernou stopu. Zahodit celou davku by bylo horsi.
                Write-Warning "Polozka $key zkopirovana, ale metadata se nepodarilo vratit: $($_.Exception.Message)"
            }

            $results.Add([pscustomobject]@{
                SourceId = $item.Id; Key = $key; Outcome = 'Copied'; MetadataCopied = $copied
            })
        }
        catch {
            Write-Warning "Polozka $key se nezkopirovala: $($_.Exception.Message)"
            $results.Add([pscustomobject]@{ SourceId = $item.Id; Key = $key; Outcome = 'Failed'; MetadataCopied = $false })
        }
    }

    # -NoEnumerate: pole se pri return z funkce rozbaluje a jednoprvkovy vysledek by
    # u volajiciho dorazil jako skalar. Volajici pak spadne na .Count.
    Write-Output -NoEnumerate $results.ToArray()
}
