<#
.SYNOPSIS
    Definuje Get-AppInventory - inventura nasazenych reseni napric weby, vcetne
    priznaku, ktere weby cekaji na upgrade.

.DESCRIPTION
    Referencni reseni labu 'lab-app-catalog-lifecycle.md', cast D.

    Pouziti:
        . ./Get-AppInventory.ps1
        Get-AppInventory -SiteUrl $sites -ClientId $clientId

.NOTES
    Kurz GOC223 - day-5/app-catalog-lifecycle
    Unit testy: Get-AppInventory.Tests.ps1
#>

Set-StrictMode -Version Latest

function Get-AppInventory {
    <#
    .SYNOPSIS
        Vrati pro kazdy web a kazde reseni verzi v katalogu, verzi na webu
        a spocitany priznak NeedsUpdate.

    .DESCRIPTION
        Nosne rozliseni celeho modulu: AppCatalogVersion se zmeni uploadem nove
        verze do katalogu, InstalledVersion az po Update-PnPApp NA DANEM WEBU.
        Rozdil mezi temi dvema cisly je seznam webu, ktere cekaji na upgrade -
        a bez skriptu se ten seznam poklika jen u malo webu.

        Skript zamerne NIC NEMENI. Je to inventura, ne remediace; upgrade je
        samostatne rozhodnuti, ktere ma videt cloveka. Kdo chce z vystupu udelat
        akci, propoji si ho s Update-PnPApp sam - a udela to s -WhatIf.

    .PARAMETER SiteUrl
        Weby k inventarizaci. Pole, bez vychozi hodnoty "vsechno" - stejny princip
        jako u Get-UserAccess: rozsah se vynucuje parametrem.

    .PARAMETER ClientId
        ClientId app registrace.

    .PARAMETER Scope
        Site (site collection app catalog) nebo Tenant. Vychozi Site, protoze
        v kurzu kazdy student pracuje s vlastnim site collection katalogem.

    .EXAMPLE
        Get-AppInventory -SiteUrl $sites -ClientId $id |
            Where-Object NeedsUpdate |
            Format-Table SiteUrl, Title, AppCatalogVersion, InstalledVersion

    .EXAMPLE
        Get-AppInventory -SiteUrl $sites -ClientId $id |
            Export-Csv .\app-inventory.csv -NoTypeInformation -Encoding utf8BOM -UseCulture

    .OUTPUTS
        PSCustomObject: SiteUrl, Title, AppId, AppCatalogVersion, InstalledVersion,
        Deployed, NeedsUpdate, Error.

    .NOTES
        NEOTESTOVANO PROTI ZIVEMU TENANTU. Overena je logika porovnani verzi,
        vypocet NeedsUpdate a odolnost proti nepristupnemu webu; skutecna volani
        zavisi na App Catalogu a opravnenich.

        Verze reseni NEJSOU vzdy platny [version] - v .sppkg muze byt cokoli, co
        vyvojar napsal do package-solution.json. Porovnani proto pada zpet na
        porovnani textem, misto aby skript spadl.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string[]] $SiteUrl,

        [string] $ClientId,

        [ValidateSet('Site', 'Tenant')]
        [string] $Scope = 'Site'
    )

    foreach ($url in $SiteUrl) {

        try {
            $connectArgs = @{ Url = $url; ErrorAction = 'Stop' }
            if ($ClientId) { $connectArgs['ClientId'] = $ClientId }
            Connect-PnPOnline @connectArgs

            foreach ($app in @(Get-PnPApp -Scope $Scope -ErrorAction Stop)) {

                [pscustomobject]@{
                    SiteUrl           = $url
                    Title             = $app.Title
                    AppId             = $app.Id
                    AppCatalogVersion = $app.AppCatalogVersion
                    InstalledVersion  = $app.InstalledVersion
                    Deployed          = $app.Deployed
                    NeedsUpdate       = Test-AppNeedsUpdate `
                                            -CatalogVersion $app.AppCatalogVersion `
                                            -InstalledVersion $app.InstalledVersion
                    Error             = $null
                }
            }
        }
        catch {
            # Nepristupny web se zaznamena a pokracuje se dal. Inventura nad 200 weby,
            # ktera spadne na 37. webu, je k nicemu - a chybejici radek by se navic
            # tvaril jako "tady nic nasazeno neni".
            [pscustomobject]@{
                SiteUrl           = $url
                Title             = $null
                AppId             = $null
                AppCatalogVersion = $null
                InstalledVersion  = $null
                Deployed          = $null
                NeedsUpdate       = $null
                Error             = $_.Exception.Message
            }
        }
    }
}

function Test-AppNeedsUpdate {
    <#
    .SYNOPSIS
        Rozhodne, zda web ceka na upgrade reseni.

    .DESCRIPTION
        Vlastni funkce, a ne jednordkovy vyraz uvnitr smycky, ze dvou duvodu:
        rozhodovani ma jedno misto, a da se na nej napsat test bez tenantu.

        Pravidla:
          - Neinstalovane reseni (prazdna InstalledVersion) NEPOTREBUJE upgrade -
            potrebuje instalaci. Jsou to dve rozdilne akce a michat je do jednoho
            priznaku by znamenalo, ze remediace omylem nainstaluje reseni tam,
            kde nikdy nebylo.
          - Kdyz jsou obe verze platne [version], porovnava se ciselne:
            1.10.0 je vyssi nez 1.9.0, coz textove porovnani nepozna.
          - Kdyz aspon jedna verze neni platny [version], pada se zpet na
            porovnani textem. Verze v .sppkg je to, co nekdo napsal do
            package-solution.json - nemusi to byt semver.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()][AllowEmptyString()][string] $CatalogVersion,
        [AllowNull()][AllowEmptyString()][string] $InstalledVersion
    )

    if ([string]::IsNullOrWhiteSpace($CatalogVersion))   { return $false }
    if ([string]::IsNullOrWhiteSpace($InstalledVersion)) { return $false }

    $catalog   = $null
    $installed = $null
    $parsed = [version]::TryParse($CatalogVersion,   [ref]$catalog) -and
              [version]::TryParse($InstalledVersion, [ref]$installed)

    if ($parsed) {
        return ($catalog -gt $installed)
    }

    return ($CatalogVersion -ne $InstalledVersion)
}
