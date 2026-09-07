<#
.SYNOPSIS
    Definuje funkci Connect-CourseTarget - jedno misto pro pripojeni k M365.

.DESCRIPTION
    Referencni reseni labu 'lab-cert-auth-sites.md', krok 6.

    Soubor funkci jen DEFINUJE, nespousti ji. Pouziti:

        . ./Connect-CourseTarget.ps1        # dot-source, nacte funkci do session
        Connect-CourseTarget -Module PnP -AuthMode Certificate ...

    Dot-source (tecka mezera cesta) je zamerny: funkce se tim da testovat
    Pesterem a pouzit z jineho skriptu. Kdyby to byl obycejny skript s param(),
    nesla by zamockovat a nesla by volat vickrat v jednom behu.

.NOTES
    Kurz GOC223 - day-2/powershell-deep-dive
    Unit testy: Connect-CourseTarget.Tests.ps1
#>

Set-StrictMode -Version Latest

function Connect-CourseTarget {
    <#
    .SYNOPSIS
        Pripoji se k M365 vybranym modulem a autentizacnim modem a vrati zaznam o pripojeni.

    .DESCRIPTION
        Proc wrapper vubec: kazdy z trech modulu ma jiny Connect-* cmdlet s jinymi
        nazvy parametru pro tutez vec. PnP chce -Thumbprint, SPO i Graph chteji
        -CertificateThumbprint, PnP chce -Tenant, Graph chce -TenantId. Kdo si to
        pamatuje z hlavy, plete se; kdo to ma na jednom miste, nepamatuje si to vubec.

        Druhy duvod je log. Pripojeni je nejcastejsi misto, kde automatizace selze,
        a "nefunguje mi to" bez zaznamu, KAM a JAK se pripojovalo, se ladi spatne.
        Funkce proto vraci objekt (ne text), ktery lze poslat do Export-Csv,
        ConvertTo-Json nebo do Log Analytics (viz day-4/siem-blob-integration).

    .PARAMETER Module
        PnP | Graph | SPO.

    .PARAMETER AuthMode
        Interactive | DeviceCode | Certificate.
        Interactive a DeviceCode jsou delegated (prokazuje se clovek),
        Certificate je app-only (prokazuje se aplikace) - viz GLOSSARY,
        public vs confidential client.

    .PARAMETER Url
        Cilova URL. PnP chce URL webu, SPO chce URL admin centra.
        Graph URL nepouziva - je tady kvuli jednotnemu rozhrani a zaznamu v logu.

    .PARAMETER ClientId
        Application (client) ID vlastni app registrace. PnP.PowerShell ho vyzaduje
        VZDY, i pro interaktivni prihlaseni (od zari 2024 nema vychozi ClientId).

    .PARAMETER Tenant
        Tenant, typicky <tenant>.onmicrosoft.com. Povinny pro app-only rezim.

    .PARAMETER Thumbprint
        Otisk certifikatu v Cert:\CurrentUser\My. Povinny pro AuthMode Certificate.
        Nikdy nedavejte hodnotu natvrdo - berte ji z konfigurace nebo parametru.

    .PARAMETER RequiredVersion
        Pin verze modulu (pozadavek z Overeni labu). Bez nej se importuje nejvyssi
        dostupna verze - na stanici v poradku, v produkci ne.

    .EXAMPLE
        Connect-CourseTarget -Module PnP -AuthMode Certificate `
            -Url https://contoso.sharepoint.com/sites/jan-novak-dev `
            -ClientId $clientId -Tenant contoso.onmicrosoft.com -Thumbprint $thumb

        App-only pripojeni bez jakehokoli promptu - varianta z kroku 4 labu.

    .EXAMPLE
        'PnP','Graph' | ForEach-Object {
            Connect-CourseTarget -Module $_ -AuthMode Certificate -Url $url `
                -ClientId $id -Tenant $tenant -Thumbprint $thumb
        } | Export-Csv .\connection-log.csv -NoTypeInformation -Encoding utf8BOM -UseCulture

        Log pripojeni jako data, ne jako text na obrazovce.

    .OUTPUTS
        PSCustomObject: Timestamp, Module, AuthMode, Url, ClientId, Success, Error, DurationMs.

        Objekt se vraci VZDY, i kdyz pripojeni selze - zaznam o neuspechu je
        cennejsi nez o uspechu. Selhani se hlasi pres Write-Error (non-terminating),
        takze kdo chce tvrde zastaveni, prida -ErrorAction Stop.

    .NOTES
        NEOTESTOVANO PROTI ZIVEMU TENANTU. Logika vyberu cmdletu, validace vstupu
        a podoba logu jsou overene unit testy s mockem; skutecne prihlaseni zavisi
        na app registraci, certifikatu a tenant policy. Pred prvnim behem kurzu
        projet vsechny tri auth mody na kurzovnim tenantu - je to soucast go/no-go.

        Nazvy parametru Connect-* cmdletu se mezi verzemi modulu MENI. Kdyz wrapper
        prestane fungovat, prvni krok je overit parametry proti dokumentaci modulu,
        ne hledat chybu ve wrapperu.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('PnP', 'Graph', 'SPO')]
        [string] $Module,

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceCode', 'Certificate')]
        [string] $AuthMode,

        [string]  $Url,
        [string]  $ClientId,
        [string]  $Tenant,
        [string]  $Thumbprint,
        [version] $RequiredVersion
    )

    # --- Validace vstupu ----------------------------------------------------
    # Validace patri PRED import modulu a pred jakykoli pokus o pripojeni.
    # Chyba "chybi Thumbprint" ma prijit okamzite a citelne, ne az jako obskurni
    # chyba z Connect-* cmdletu po deseti sekundach.

    $moduleName = switch ($Module) {
        'PnP'   { 'PnP.PowerShell' }
        'Graph' { 'Microsoft.Graph.Authentication' }   # Connect-MgGraph zije tady
        'SPO'   { 'Microsoft.Online.SharePoint.PowerShell' }
    }

    if ($AuthMode -eq 'Certificate') {
        if (-not $Thumbprint) { throw "AuthMode 'Certificate' vyzaduje -Thumbprint." }
        if (-not $Tenant)     { throw "AuthMode 'Certificate' vyzaduje -Tenant (napr. contoso.onmicrosoft.com)." }
    }

    # PnP.PowerShell vyzaduje ClientId u KAZDEHO pripojeni, i interaktivniho.
    # Bez nej skonci prihlaseni na AADSTS700016 - viz troubleshooting-auth.md.
    if ($Module -eq 'PnP' -and -not $ClientId) {
        throw 'Modul PnP vyzaduje -ClientId u kazdeho pripojeni, vcetne interaktivniho.'
    }

    if ($Module -in @('PnP', 'SPO') -and -not $Url) {
        throw "Modul $Module vyzaduje -Url (PnP: URL webu, SPO: URL admin centra)."
    }

    # Mapovani modul+mod na konkretni Connect-* cmdlet. Tabulka, ne rada if/else:
    # kdyz se pridava ctvrty modul nebo ctvrty auth mod, pridava se JEDEN zaznam.
    # Hodnoty jsou scriptblocky, aby se parametry vyhodnotily az pri volani.
    #
    # SPO|DeviceCode v tabulce zamerne NENI - SPO Management Shell takovy flow nema.
    $connectors = @{
        'PnP|Interactive'   = { Connect-PnPOnline -Url $Url -ClientId $ClientId -Interactive }
        'PnP|DeviceCode'    = { Connect-PnPOnline -Url $Url -ClientId $ClientId -DeviceLogin }
        'PnP|Certificate'   = { Connect-PnPOnline -Url $Url -ClientId $ClientId -Tenant $Tenant -Thumbprint $Thumbprint }

        'Graph|Interactive' = { Connect-MgGraph -ClientId $ClientId -TenantId $Tenant }
        'Graph|DeviceCode'  = { Connect-MgGraph -ClientId $ClientId -TenantId $Tenant -UseDeviceCode }
        'Graph|Certificate' = { Connect-MgGraph -ClientId $ClientId -TenantId $Tenant -CertificateThumbprint $Thumbprint }

        'SPO|Interactive'   = { Connect-SPOService -Url $Url }
        'SPO|Certificate'   = { Connect-SPOService -Url $Url -ClientId $ClientId -TenantId $Tenant -CertificateThumbprint $Thumbprint }
    }

    $key = "$Module|$AuthMode"

    # Nepodporovana kombinace je chyba ZADANI, ne selhani pripojeni - proto throw
    # tady, mezi ostatnimi validacemi, a ne az v chybove vetvi nize. Rozdil je
    # prakticky: nema smysl importovat modul pro kombinaci, ktera nemuze fungovat.
    if (-not $connectors.ContainsKey($key)) {
        if ($Module -eq 'SPO' -and $AuthMode -eq 'DeviceCode') {
            throw 'SPO Management Shell nema device code flow. Pouzijte Interactive nebo Certificate.'
        }
        throw "Kombinace '$key' neni podporovana."
    }

    # --- Import modulu ------------------------------------------------------

    $importArgs = @{ Name = $moduleName; ErrorAction = 'Stop' }
    if ($RequiredVersion) { $importArgs['RequiredVersion'] = $RequiredVersion }

    # SPO Management Shell muze v PowerShell 7 vyzadovat kompatibilitni shim.
    # Poradi je zamerne: nejdriv normalni import, shim teprve pri selhani -
    # aby se nepouzival tam, kde neni potreba.
    try {
        Import-Module @importArgs
    }
    catch {
        if ($Module -eq 'SPO') {
            Write-Verbose "Import $moduleName selhal, zkousim -UseWindowsPowerShell: $($_.Exception.Message)"
            Import-Module @importArgs -UseWindowsPowerShell
        }
        else {
            throw
        }
    }

    # --- Pripojeni ----------------------------------------------------------

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $success = $false
    $errorText = $null

    try {
        & $connectors[$key]
        $success = $true
    }
    catch {
        # Chyba se NEPOLYKA (pravidlo AvoidUsingEmptyCatchBlock) - zaznamena se
        # do logu a nize se znovu vyhodi.
        $errorText = $_.Exception.Message
    }
    finally {
        $stopwatch.Stop()
    }

    # --- Strukturovany log --------------------------------------------------
    # Objekt, ne Write-Host. ClientId je v logu zamerne - je to identifikator
    # aplikace, ne tajemstvi. Thumbprint ani tenant GUID v logu nejsou.

    [pscustomobject]@{
        Timestamp  = (Get-Date).ToString('o')   # ISO 8601, aby slo radit i mimo PowerShell
        Module     = $Module
        AuthMode   = $AuthMode
        Url        = $Url
        ClientId   = $ClientId
        Success    = $success
        Error      = $errorText
        DurationMs = $stopwatch.ElapsedMilliseconds
    }

    # Selhani se hlasi pres Write-Error, NE pres throw - a je to zamerne.
    #
    # throw je terminating error: ukonci cely prikaz vcetne prirazeni, takze
    # `$log = Connect-CourseTarget ...` by pri selhani NIC nepriradilo a zaznam
    # o nejzajimavejsim pripade (neuspesne pripojeni) by se ztratil.
    #
    # Write-Error je non-terminating: objekt vyse projde do pipeline, chyba jde
    # do error streamu a volajici si vybere. Kdo chce tvrde zastaveni, zavola
    #     Connect-CourseTarget ... -ErrorAction Stop
    # protoze [CmdletBinding()] respektuje ErrorActionPreference volajiciho.
    #
    # Pravidlo: funkce, jejimz vystupem je zaznam o tom, co se stalo, nesmi
    # ten zaznam zahodit prave v okamziku, kdy je nejpotrebnejsi.
    if (-not $success) {
        Write-Error "Pripojeni '$key' selhalo: $errorText"
    }
}
