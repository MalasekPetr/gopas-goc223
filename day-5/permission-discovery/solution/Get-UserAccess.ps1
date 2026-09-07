<#
.SYNOPSIS
    Definuje Get-UserAccess - reverzni report "ke kterym webum ma uzivatel pristup
    a kudy ten pristup vede".

.DESCRIPTION
    Referencni reseni labu 'lab-user-access-report.md'.

    Pouziti:
        . ./Get-UserAccess.ps1
        Get-UserAccess -UserPrincipalName jan.novak@contoso.com -SiteUrl $sites

    Portal umi jen dotaz "kdo ma pristup k tomuhle webu". Otazka od HR nebo od
    pravniku je ale obracena: "k cemu ma pristup tenhle clovek". Neexistuje index
    uzivatel -> weby, takze se musi projit weby a v kazdem se zeptat.

.NOTES
    Kurz GOC223 - day-5/permission-discovery
    Unit testy: Get-UserAccess.Tests.ps1
#>

Set-StrictMode -Version Latest

function Get-UserAccess {
    <#
    .SYNOPSIS
        Vrati weby, ke kterym ma zadany uzivatel pristup, vcetne cesty pristupu.

    .DESCRIPTION
        Pro kazdy web zjistuje tri cesty pristupu:
          1. site collection admin
          2. PRIME clenstvi v SharePoint skupine
          3. clenstvi v Entra skupine, ktera je clenem SharePoint skupiny

        Cesta 3 je ta, kterou naivni reporty MIJI - a v realnem tenantu je
        nejbeznejsi. Get-PnPGroupMember vraci i principaly typu skupina, ne jen
        uzivatele; kdo filtruje na LoginName -like "*upn*", skupinu zahodi a report
        pak tvrdi "zadny pristup". Falesne negativni odpoved na otazku od pravniku
        je horsi nez zadna odpoved.

    .PARAMETER UserPrincipalName
        UPN zkoumaneho uzivatele.

    .PARAMETER SiteUrl
        Weby k prohledani. Pole, ne jeden web, a bez vychozi hodnoty "vsechno" -
        reverzni dotaz je O(pocet webu) na jednoho uzivatele, takze rozsah
        se vynucuje parametrem, ne odhadem.

    .PARAMETER ClientId
        ClientId app registrace pro pripojeni k webum.

    .PARAMETER SkipEntraGroups
        Vynecha rozbaleni Entra skupin (cesta 3). Slouzi K DEMONSTRACI toho, co
        naivni report mine - ne k beznemu pouziti. V labu je to krok 3 vs krok 6.

    .EXAMPLE
        Get-UserAccess -UserPrincipalName jan.novak@contoso.com `
            -SiteUrl 'https://c.sharepoint.com/sites/a','https://c.sharepoint.com/sites/b' `
            -ClientId $clientId |
            Export-Csv .\user-access.csv -NoTypeInformation -Encoding utf8BOM -UseCulture

    .EXAMPLE
        # Kontrast z labu: nejdriv bez Entra skupin, potom s nimi.
        Get-UserAccess -UserPrincipalName $upn -SiteUrl $sites -ClientId $id -SkipEntraGroups
        Get-UserAccess -UserPrincipalName $upn -SiteUrl $sites -ClientId $id

    .OUTPUTS
        PSCustomObject: UserPrincipalName, SiteUrl, AccessVia, GroupName, Error.
        Kdyz uzivatel na webu pristup nema, web se ve vystupu NEOBJEVI - kdyz web
        nelze precist, objevi se s vyplnenym Error.

    .NOTES
        SLEPA MISTA TOHOTO REPORTU - vedoma, ne opomenuta:
          - PRIMA opravneni na knihovne nebo polozce pri porusene dedicnosti.
            Report se diva na uroven webu, ne na jednotlive polozky.
          - SHARING LINKS. Samostatna soustava, v clenstvich skupin neni videt vubec.
          - Pristup pres site collection admin na urovni tenantu (SharePoint admin
            role) - ten neni clenstvim, ale roli v Entra.
        Kdo potrebuje i tyhle cesty, potrebuje SAM DAG report "Site permissions for
        users" - viz README modulu, vcetne jeho limitu (5 reportu, 1x za 30 dni).

        NEOTESTOVANO PROTI ZIVEMU TENANTU. Rozhodovaci logika je overena unit testy
        s mockem; skutecne volani zavisi na opravnenich app registrace
        (GroupMember.Read.All nebo Directory.Read.All pro tranzitivni clenstvi).
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string] $UserPrincipalName,

        [Parameter(Mandatory)]
        [string[]] $SiteUrl,

        [string] $ClientId,

        [switch] $SkipEntraGroups
    )

    # --- Tranzitivni clenstvi uzivatele -------------------------------------
    # memberOf vraci jen PRIMA clenstvi. transitiveMemberOf vraci i vnorena -
    # a rozdil mezi temi dvema cmdlety je rozdil mezi reportem, ktery plati,
    # a reportem, ktery jen uklidni.

    $userGroupIds = @()

    if (-not $SkipEntraGroups) {
        try {
            $userGroupIds = @(
                Get-MgUserTransitiveMemberOf -UserId $UserPrincipalName -All -ErrorAction Stop |
                    Select-Object -ExpandProperty Id
            )
            Write-Verbose "Uzivatel je clenem $($userGroupIds.Count) skupin (vcetne vnorenych)."
        }
        catch {
            # Bez tranzitivnich skupin report POKRACUJE, ale je nutne to hlasit -
            # tichy prechod na naivni rezim je presne ta falesne negativni odpoved,
            # kvuli ktere tenhle skript existuje.
            # Zavorky kolem cele konkatenace jsou nutne: bez nich se -f navaze jen
            # na posledni retezec a {0} v prvnim zustane jako literal - chybova
            # zprava by se ztratila prave tam, kde je nejpotrebnejsi.
            Write-Warning (("Nepodarilo se ziskat clenstvi ve skupinach ({0}). " +
                'Report pokracuje BEZ cesty pres Entra skupiny a muze prehlednout pristupy.') -f $_.Exception.Message)
        }
    }

    # --- Prochazeni webu ----------------------------------------------------

    foreach ($url in $SiteUrl) {

        try {
            $connectArgs = @{ Url = $url; ErrorAction = 'Stop' }
            if ($ClientId) { $connectArgs['ClientId'] = $ClientId }
            Connect-PnPOnline @connectArgs

            # 1. Site collection admin
            foreach ($admin in @(Get-PnPSiteCollectionAdmin -ErrorAction Stop)) {
                if ($admin.LoginName -like "*$UserPrincipalName*") {
                    [pscustomobject]@{
                        UserPrincipalName = $UserPrincipalName
                        SiteUrl           = $url
                        AccessVia         = 'SiteAdmin'
                        GroupName         = ''
                        Error             = $null
                    }
                }
            }

            # 2. a 3. Clenstvi v SharePoint skupinach
            foreach ($group in @(Get-PnPGroup -ErrorAction Stop)) {

                # Chyba u jedne skupiny nesmi shodit cely web - typicky se
                # nepodari precist clenstvi skupiny, na kterou nemame pravo.
                $members = @()
                try {
                    $members = @(Get-PnPGroupMember -Identity $group.Id -ErrorAction Stop)
                }
                catch {
                    Write-Verbose "Skupinu '$($group.Title)' na $url nelze precist: $($_.Exception.Message)"
                    continue
                }

                foreach ($member in $members) {

                    # Prime clenstvi uzivatele
                    if ($member.LoginName -like "*$UserPrincipalName*") {
                        [pscustomobject]@{
                            UserPrincipalName = $UserPrincipalName
                            SiteUrl           = $url
                            AccessVia         = "SharePointGroup:$($group.Title)"
                            GroupName         = $group.Title
                            Error             = $null
                        }
                        continue
                    }

                    # Clenstvi pres Entra skupinu. Principal typu skupina ma v PnP
                    # PrincipalType 'SecurityGroup', a jeho AadObjectId se porovnava
                    # proti tranzitivnimu clenstvi uzivatele.
                    if (-not $SkipEntraGroups -and $userGroupIds.Count -gt 0) {
                        $memberAadId = $null
                        if ($member.PSObject.Properties.Name -contains 'AadObjectId') {
                            $memberAadId = $member.AadObjectId
                        }

                        if ($memberAadId -and $userGroupIds -contains $memberAadId) {
                            [pscustomobject]@{
                                UserPrincipalName = $UserPrincipalName
                                SiteUrl           = $url
                                AccessVia         = "EntraGroup:$($member.Title)"
                                GroupName         = $group.Title
                                Error             = $null
                            }
                        }
                    }
                }
            }
        }
        catch {
            # Nepristupny web se ZAZNAMENA a pokracuje se dal. Report nad 200 weby,
            # ktery spadne na 37. webu, je k nicemu - a chybejici zaznam by se navic
            # tvaril jako "zadny pristup".
            [pscustomobject]@{
                UserPrincipalName = $UserPrincipalName
                SiteUrl           = $url
                AccessVia         = $null
                GroupName         = ''
                Error             = $_.Exception.Message
            }
        }
    }
}
