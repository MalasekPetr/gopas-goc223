<#
    Get-SelectedPermissionGrant - inventura per-site grantu (Sites.Selected) v tenantu.

    PROC TENHLE REPORT EXISTUJE
    Grant, ktery jste v dni 4 udelili aplikaci, je z pohledu spravce NEVIDITELNY:
      - neni stranka v admin centru, ktera by granty vypsala,
      - neni inventurni cmdlet pro cely tenant,
      - grant PREZIJE toho, kdo o nej pozadal, i projekt, kvuli kteremu vznikl.
    Jedina cesta je ptat se web po webu. Index neexistuje - stejne jako u reverzniho
    dotazu "k cemu ma uzivatel pristup".

    CO TENHLE REPORT NEVIDI (a musi to rict nahlas)
    Dokumentace: "Applications can have multiple Selected consents and those consents
    can apply at various levels across the tenant." Tenhle skript se pta jen na
    /sites/{id}/permissions, takze granty na urovni SEZNAMU, POLOZEK a SOUBORU
    (Lists./ListItems./Files.SelectedOperations.Selected) NEVIDI. Kdo je chce, musi
    stejnou logiku pustit i na /lists/{id}/permissions a nize.

    CENA ZA CTENI
    GET /sites/{id}/permissions vyzaduje Sites.FullControl.All (application).
    Dokumentace to zduvodnuje: "Because you can grant full control permissions to
    a site collection by using Sites.Selected, this requirement is necessarily high."
    Least-privileged alternativa NENI.

    DVE PRAVIDLA, KTERA TENHLE SKRIPT DRZI A BEZ KTERYCH JE REPORT NEBEZPECNY
      1. "Nedivali jsme se" != "nic tam neni". Web, ktery nesla precist, je ve vystupu
         jako Unreadable - nikdy se nesmi slit s webem, ktery granty opravdu nema.
      2. Selhany PREDPOKLAD se nesmi tvarit jako nalez. Kdyz se nepodari nacist adresar
         service principalu, skript NEoznaci vsechny granty za osirele - rekne, ze
         kontrola nebezela.

    Spusteni (po dot-sourcovani):
        . ./Get-SelectedPermissionGrant.ps1
        $r = Get-SelectedPermissionGrant -AccessToken $token -MaxSites 50
        $r.Grants     | Export-Csv .\grants.csv -NoTypeInformation -Encoding utf8BOM -UseCulture
        $r.Unreadable | Export-Csv .\unreadable.csv -NoTypeInformation -Encoding utf8BOM -UseCulture

    Vyzaduje PowerShell 7.4+.
#>

#Requires -Version 7.4

Set-StrictMode -Version Latest

# Poradi roli, aby "nejvyssi role, kterou ta aplikace ma" bylo definovane.
# NEZNAMA role se radi k 'write', ne k 'read': role, kterou neznam, je spis
# schopnost, kterou Microsoft pridal, nez neco mensiho - a PODCENIT opravneni
# je horsi chyba nez ho nadcenit.
$script:RoleRank = @{
    'read'        = 1
    'write'       = 2
    'owner'       = 3
    'manage'      = 3
    'fullcontrol' = 4
}


function Get-GrantRoleRank {
    <#
    .SYNOPSIS
        Vrati ciselne poradi role. Neznama role = 2 (uroven write).
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [AllowNull()] [string] $Role
    )

    if ([string]::IsNullOrWhiteSpace($Role)) { return 0 }

    $key = $Role.ToLowerInvariant()
    if ($script:RoleRank.ContainsKey($key)) { return $script:RoleRank[$key] }

    return 2
}


function Get-SelectedPermissionGrant {
    <#
    .SYNOPSIS
        Projde weby tenantu a vrati, ktera aplikace ma na kterem webu jaky grant.
    .DESCRIPTION
        Vraci hashtable: Grants, Unreadable, SitesRead, TotalSites, Capped,
        DirectoryKnown.

        -MaxSites je tu zamerne s NIZKYM defaultem. Reverzni inventura je O(pocet webu)
        a nad velkym tenantem bezi dlouho; "projdi vsechno" nesmi byt vychozi chovani.
        Kdyz se strop uplatni, vystup to rekne priznakem Capped - report, ktery je
        useknuty a netvari se tak, je horsi nez zadny.
    .PARAMETER GetSitesFunc
        Testovatelnost: funkce vracejici weby. V provozu se nepredava.
    .PARAMETER GetPermissionsFunc
        Testovatelnost: funkce vracejici pro jeden web ODPOVED GRAPHU - tedy objekt
        s vlastnosti .value - nebo $null, kdyz se web precist nepodarilo (401/403/404).

        POZOR, TENHLE KONTRAKT NENI NAHODNY. Kdyby funkce vracela rovnou POLE grantu,
        prazdne pole by se pri navratu ROZBALILO NA $null (past z
        day-2/opt-powershell-basics) a web bez grantu by se stal webem neprectenym -
        tedy presne to sliti, ktere ma tenhle report zakazane. Objekt se nerozbaluje,
        takze rozdil prezije. Graph tak mimochodem odpovida i ve skutecnosti.
    #>
    [CmdletBinding()]
    param(
        [string] $AccessToken,
        [int] $MaxSites = 50,
        [scriptblock] $GetSitesFunc,
        [scriptblock] $GetPermissionsFunc,
        [scriptblock] $GetServicePrincipalsFunc
    )

    # --- Adresar aplikaci ----------------------------------------------------
    # Slouzi k rozliseni grantu ZIVE aplikace od grantu po aplikaci, ktera uz byla
    # smazana. V objektu grantu jsou oba identicke; rozdil zna jen adresar.
    $principals = @{}
    $spList = @()
    if ($GetServicePrincipalsFunc) {
        $spList = @(& $GetServicePrincipalsFunc)
    }
    foreach ($sp in $spList) {
        if ($sp -and $sp.appId) { $principals["$($sp.appId)"] = $sp }
    }

    # Prazdny adresar NEZNAMENA prazdny tenant - znamena, ze se cteni nepodarilo.
    # Kdybychom to nerozlisili, oznacili bychom KAZDY grant za osirely a vytiskli
    # tabulku alarmujicich nalezu, ktere jsou vsechny falesne.
    $directoryKnown = $principals.Count -gt 0
    if (-not $directoryKnown) {
        Write-Warning ('Adresar service principalu se nepodarilo nacist. Granty proto NEJSOU ' +
            'kontrolovany proti existujicim aplikacim - kontrola NEBEZELA, nenasla nulu.')
    }

    # --- Weby ----------------------------------------------------------------
    $allSites = @()
    if ($GetSitesFunc) { $allSites = @(& $GetSitesFunc) }
    $allSites = @($allSites | Where-Object { $_ -and $_.isPersonalSite -ne $true })

    $totalSites = $allSites.Count
    $capped = $false
    if ($MaxSites -gt 0 -and $totalSites -gt $MaxSites) {
        Write-Warning "Omezuji se na prvnich $MaxSites z $totalSites webu - report je USEKNUTY."
        $allSites = @($allSites | Select-Object -First $MaxSites)
        $capped = $true
    }

    $grants     = [System.Collections.Generic.List[object]]::new()
    $unreadable = [System.Collections.Generic.List[object]]::new()

    foreach ($site in $allSites) {
        $response = $null
        if ($GetPermissionsFunc) { $response = & $GetPermissionsFunc $site }

        # TOHLE ROZLISENI JE CELY REPORT. $null = web jsme nesmeli precist,
        # prazdne pole = web granty opravdu nema. Slitim obojiho by "zadna aplikace
        # sem nema pristup" a "nepodivali jsme se" vypadaly stejne. Prvni je
        # ujisteni, druhe je mezera - a report nesmi nabidnout prvni, kdyz mysli druhe.
        if ($null -eq $response) {
            $unreadable.Add([pscustomobject]@{
                Site = $site.displayName
                Url  = $site.webUrl
                Note = 'Graph vratil 401, 403 nebo 404 - konkretni kod je v logu behu'
            })
            continue
        }

        foreach ($permission in @($response.value)) {
            if ($null -eq $permission) { continue }

            $appId = $null
            $appName = $null
            if ($permission.PSObject.Properties.Name -contains 'grantedToIdentitiesV2') {
                foreach ($identity in @($permission.grantedToIdentitiesV2)) {
                    if ($identity -and $identity.application) {
                        $appId = "$($identity.application.id)"
                        $appName = "$($identity.application.displayName)"
                    }
                }
            }

            $roles = @($permission.roles)
            $topRole = ''
            $topRank = 0
            foreach ($role in $roles) {
                $rank = Get-GrantRoleRank -Role $role
                if ($rank -gt $topRank) { $topRank = $rank; $topRole = "$role" }
            }

            # Osirely grant = aplikace uz v adresari neni. Hlasi se JEN kdyz adresar
            # skutecne cteme; jinak zustava $null a report to prizna.
            $orphan = $null
            if ($directoryKnown -and $appId) {
                $orphan = -not $principals.ContainsKey($appId)
            }

            $grants.Add([pscustomobject]@{
                Site          = $site.displayName
                Url           = $site.webUrl
                ApplicationId = $appId
                Application   = $appName
                Roles         = ($roles -join ',')
                HighestRole   = $topRole
                WriteOrAbove  = ($topRank -ge 2)
                Orphaned      = $orphan
            })
        }
    }

    return @{
        Grants         = @($grants.ToArray())
        Unreadable     = @($unreadable.ToArray())
        SitesRead      = $allSites.Count
        TotalSites     = $totalSites
        Capped         = $capped
        DirectoryKnown = $directoryKnown
    }
}
