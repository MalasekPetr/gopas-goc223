<#
    Get-HostingCost - kalkulator nakladu na hostovani PLANOVANEHO SKRIPTU v Azure.

    Kvantitativni protejsek ke kvalitativnimu srovnani v
    day-4/azure-integration-patterns/comparison-scheduled-runtimes.md. Tam se rozhoduje
    podle toho, co plan udela se skriptem (moduly, strop behu, runtime). Tady se pocita,
    co to bude stat.

    Pointa NENI "kolik stoji jeden beh". Pointa je, ze u planovaneho administratorskeho
    skriptu se vypocet skoro vzdy vejde do FREE GRANTU vsech tri variant, a jediny
    naklad, ktery realne roste, je INGEST TELEMETRIE do Log Analytics. Tabulka je proto
    vodorovna a posledni radek trci - a to je ten teaching point.

    Sazby se tahaji z Azure Retail Prices API. To je ANONYMNI endpoint: nepotrebuje
    prihlaseni, subscription ani token, takze skript jde spustit i na kurzu, kde student
    Azure subscription nema.

    Spusteni (po dot-sourcovani):
        . ./Get-HostingCost.ps1
        Get-HostingCost                                   # nocni skript, 30x10 min
        Get-HostingCost -RunsPerMonth 8640 -MinutesPerRun 1
        Get-HostingCost -LogGbPerMonth 100                # co udela chybna DCR
        Get-HostingCost -PricesPath ./prices-snapshot.json -Offline

    POZOR na jednu vlastnost ceniku: Azure Retail Prices API zaokrouhluje sub-centove
    EUR metery na NULU. U Functions jsou v EUR nulove VSECHNY vykonove metery, u Container
    Apps taky. Tyhle sazby se proto tahaji v USD a prepocitavaji faktorem, ktery si skript
    odvodi ZIVE z meteru, ktery ma obe valuty nenulove. Kazda takova sazba je ve vystupu
    oznacena jako derivovana - cislo bez dolozitelneho puvodu do kurzovniho materialu
    nepatri.

    Vyzaduje PowerShell 7.4+.
#>

#Requires -Version 7.4

Set-StrictMode -Version Latest

# Hodin v mesici. Stejna konstanta, jakou pouziva Azure kalkulacka.
$script:HoursPerMonth = 730

# Free granty Container Apps NEJSOU v API jako cena - jsou dokumentovane:
# https://learn.microsoft.com/en-us/azure/container-apps/billing
$script:ContainerAppsGrants = @{
    VcpuSeconds      = 180000
    MemoryGibSeconds = 360000
    Requests         = 2000000
}


function Get-AzureRetailPrice {
    <#
    .SYNOPSIS
        Stahne metery z Azure Retail Prices API pro danou valutu a OData filtr.
    .DESCRIPTION
        API strankuje pres NextPageLink. Strop na osm stranek je zamerny: kdyby filtr
        byl prilis siroky, at skript spadne na necem srozumitelnem misto aby tahal
        desetitisice radku.

        Filtruje jen `type -eq 'Consumption'` - reservation a savings-plan radky maji
        jinou jednotku a smichane by tise zkreslily vysledek.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] [ValidateSet('EUR', 'USD')] [string] $Currency,
        [Parameter(Mandatory)] [string] $Filter,
        [int] $MaxPages = 8
    )

    $url = "https://prices.azure.com/api/retail/prices?currencyCode='$Currency'" +
           "&`$filter=$([uri]::EscapeDataString($Filter))&`$top=1000"

    $items = [System.Collections.Generic.List[object]]::new()
    for ($page = 0; $page -lt $MaxPages -and $url; $page++) {
        Write-Verbose "Cenik: $Currency, stranka $($page + 1)"
        $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 60
        foreach ($item in @($response.Items)) { $items.Add($item) }
        $url = if ($response.PSObject.Properties.Name -contains 'NextPageLink') { $response.NextPageLink } else { $null }
    }

    # Zavorky @() jsou nutne: filtr, ktery nic nenajde, vrati $null, a jednoprvkovy
    # vysledek se rozbali na ten jediny prvek - viz day-2/opt-powershell-basics.
    return @($items | Where-Object { $_.type -eq 'Consumption' })
}


function Select-PriceMeter {
    <#
    .SYNOPSIS
        Vybere jeden meter z vysledku ceniku.
    .PARAMETER Paid
        Vezme prvni tarifni pasmo s NENULOVOU cenou. Tim se preskoci pasmo free grantu,
        ktere ma cenu 0 - a soucasne se z nej da precist velikost toho grantu.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $Items,
        [string] $MeterName,
        [string] $ProductName,
        [string] $SkuName,
        [string] $Unit,
        [switch] $Paid
    )

    $found = @($Items | Where-Object {
        (-not $MeterName   -or $_.meterName   -eq $MeterName) -and
        (-not $ProductName -or $_.productName -eq $ProductName) -and
        (-not $SkuName     -or ($_.skuName -replace '\s', '') -eq ($SkuName -replace '\s', '')) -and
        (-not $Unit        -or $_.unitOfMeasure -eq $Unit)
    })

    if ($Paid) { $found = @($found | Where-Object { $_.retailPrice -gt 0 }) }
    if ($found.Count -eq 0) { return $null }

    # Nejnizsi odpovidajici tarifni pasmo; u -Paid je to prvni placene.
    return @($found | Sort-Object tierMinimumUnits)[0]
}


function Resolve-MeterRate {
    <#
    .SYNOPSIS
        Vrati sazbu v EUR, i kdyz ji API zaokrouhlilo na nulu.
    .DESCRIPTION
        Kdyz je EUR cena nenulova, bere se prima. Kdyz je nulova (sub-centovy meter),
        derivuje se z USD * FX a vysledek nese Derived = $true.

        Vraci: Price, Derived, Grant (velikost free grantu z tierMinimumUnits).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $EurItems,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $UsdItems,
        [Parameter(Mandatory)] [hashtable] $Spec,
        [Parameter(Mandatory)] [double] $FxEurPerUsd
    )

    $eur = Select-PriceMeter -Items $EurItems @Spec
    if ($eur -and $eur.retailPrice -gt 0) {
        return [pscustomobject]@{ Price = [double] $eur.retailPrice; Derived = $false; Grant = [double] $eur.tierMinimumUnits }
    }

    $usd = Select-PriceMeter -Items $UsdItems @Spec
    if (-not $usd) { return $null }

    # Grant se cte z EUR meteru, kdyz existuje - tarifni pasma jsou citelna i pri nulove cene.
    $grant = if ($eur) { [double] $eur.tierMinimumUnits } else { [double] $usd.tierMinimumUnits }
    return [pscustomobject]@{ Price = [double] $usd.retailPrice * $FxEurPerUsd; Derived = $true; Grant = $grant }
}


function Get-FxEurPerUsd {
    <#
    .SYNOPSIS
        Odvodi prepocetni faktor EUR/USD ZIVE z meteru, ktery ma obe valuty nenulove.
    .DESCRIPTION
        Zadna konstanta v kodu. Pouziva se Container Apps "Standard Requests" - meter
        za milion pozadavku, ktery je dost velky, aby ho zaokrouhleni nezerodovalo.

        Kdyz se faktor odvodit neda, skript SKONCI. Tise dopocitat kurz odhadem by
        znamenalo vyrobit cislo bez puvodu.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $EurItems,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]] $UsdItems
    )

    $eur = Select-PriceMeter -Items $EurItems -MeterName 'Standard Requests'
    $usd = Select-PriceMeter -Items $UsdItems -MeterName 'Standard Requests'

    if (-not $eur -or -not $usd -or $usd.retailPrice -le 0) {
        throw "Nelze odvodit FX faktor z meteru 'Standard Requests' - cenik ma jiny tvar, nez skript ocekava."
    }
    return [double] $eur.retailPrice / [double] $usd.retailPrice
}


function Get-HostingRate {
    <#
    .SYNOPSIS
        Stahne vsechny sazby, ktere kalkulace potrebuje, do jednoho objektu.
    #>
    [CmdletBinding()]
    param(
        [string] $Region = 'westeurope'
    )

    $caEur = Get-AzureRetailPrice -Currency EUR -Filter "serviceName eq 'Azure Container Apps' and armRegionName eq '$Region'"
    $caUsd = Get-AzureRetailPrice -Currency USD -Filter "serviceName eq 'Azure Container Apps' and armRegionName eq '$Region'"
    $fx = Get-FxEurPerUsd -EurItems $caEur -UsdItems $caUsd

    $fnEur = Get-AzureRetailPrice -Currency EUR -Filter "serviceName eq 'Functions' and armRegionName eq '$Region'"
    $fnUsd = Get-AzureRetailPrice -Currency USD -Filter "serviceName eq 'Functions' and armRegionName eq '$Region'"
    $auEur = Get-AzureRetailPrice -Currency EUR -Filter "serviceName eq 'Automation' and armRegionName eq '$Region'"
    $laEur = Get-AzureRetailPrice -Currency EUR -Filter "serviceName eq 'Log Analytics' and armRegionName eq '$Region'"

    $derived = [System.Collections.Generic.List[string]]::new()
    $take = {
        param($Key, $Rate)
        if ($null -eq $Rate) { return $null }
        if ($Rate.Derived) { $derived.Add($Key) }
        return $Rate
    }

    # Automation: meter je za MINUTU behu, free grant je tarifni pasmo.
    $auPaid = Select-PriceMeter -Items $auEur -MeterName 'Basic Runtime' -Unit '1 Minute' -Paid
    $auFree = Select-PriceMeter -Items $auEur -MeterName 'Basic Runtime' -Unit '1 Minute'

    # Functions: Flex ma minimalni uctovanou dobu 1000 ms, Consumption 100 ms.
    $flexExec = & $take 'flex.execGbSecond'  (Resolve-MeterRate -EurItems $fnEur -UsdItems $fnUsd -FxEurPerUsd $fx -Spec @{ MeterName = 'On Demand Execution Time'; Unit = '1 GB Second'; Paid = $true })
    $flexCall = & $take 'flex.perExecution'  (Resolve-MeterRate -EurItems $fnEur -UsdItems $fnUsd -FxEurPerUsd $fx -Spec @{ MeterName = 'On Demand Total Executions'; Unit = '10'; Paid = $true })
    $consExec = & $take 'cons.execGbSecond'  (Resolve-MeterRate -EurItems $fnEur -UsdItems $fnUsd -FxEurPerUsd $fx -Spec @{ MeterName = 'Standard Execution Time'; Unit = '1 GB Second'; Paid = $true })
    $consCall = & $take 'cons.perExecution'  (Resolve-MeterRate -EurItems $fnEur -UsdItems $fnUsd -FxEurPerUsd $fx -Spec @{ MeterName = 'Standard Total Executions'; Unit = '10'; Paid = $true })
    $caVcpu   = & $take 'containerApps.vcpuSecond'   (Resolve-MeterRate -EurItems $caEur -UsdItems $caUsd -FxEurPerUsd $fx -Spec @{ MeterName = 'Standard vCPU Active Usage' })
    $caMem    = & $take 'containerApps.memoryGibSecond' (Resolve-MeterRate -EurItems $caEur -UsdItems $caUsd -FxEurPerUsd $fx -Spec @{ MeterName = 'Standard Memory Active Usage' })

    $laIngest    = Select-PriceMeter -Items $laEur -MeterName 'Analytics Logs Data Ingestion' -Paid
    $laIngestAny = Select-PriceMeter -Items $laEur -MeterName 'Analytics Logs Data Ingestion'
    $laRetention = Select-PriceMeter -Items $laEur -MeterName 'Analytics Logs Data Retention'

    return [pscustomobject]@{
        FetchedAt      = (Get-Date).ToString('yyyy-MM-dd')
        Region         = $Region
        FxEurPerUsd    = $fx
        DerivedFromUsd = @($derived)

        Automation = [pscustomobject]@{
            PerMinute  = if ($auPaid) { [double] $auPaid.retailPrice } else { $null }
            GrantMinutes = if ($auPaid) { [double] $auPaid.tierMinimumUnits } elseif ($auFree) { 0 } else { 0 }
        }
        FunctionsFlex = [pscustomobject]@{
            ExecGbSecond   = if ($flexExec) { $flexExec.Price } else { $null }
            GrantGbSeconds = if ($flexExec) { $flexExec.Grant } else { 0 }
            # Meter je za 10 spusteni, proto deleni desitkou.
            PerExecution   = if ($flexCall) { $flexCall.Price / 10 } else { $null }
            GrantExecutions = if ($flexCall) { $flexCall.Grant * 10 } else { 0 }
            MinBillableMs  = 1000
        }
        FunctionsConsumption = [pscustomobject]@{
            ExecGbSecond   = if ($consExec) { $consExec.Price } else { $null }
            GrantGbSeconds = if ($consExec) { $consExec.Grant } else { 0 }
            PerExecution   = if ($consCall) { $consCall.Price / 10 } else { $null }
            GrantExecutions = if ($consCall) { $consCall.Grant * 10 } else { 0 }
            MinBillableMs  = 100
        }
        ContainerApps = [pscustomobject]@{
            VcpuSecond       = if ($caVcpu) { $caVcpu.Price } else { $null }
            MemoryGibSecond  = if ($caMem) { $caMem.Price } else { $null }
        }
        LogAnalytics = [pscustomobject]@{
            IngestGb        = if ($laIngest) { [double] $laIngest.retailPrice } else { $null }
            GrantGb         = if ($laIngest) { [double] $laIngest.tierMinimumUnits } elseif ($laIngestAny) { 0 } else { 0 }
            RetentionGbMonth = if ($laRetention) { [double] $laRetention.retailPrice } else { $null }
        }
    }
}


function Get-BillableGbSecond {
    <#
    .SYNOPSIS
        Uctovane GB-sekundy pro jeden beh, se zaokrouhlenim na minimalni uctovanou dobu.
    .DESCRIPTION
        Flex Consumption uctuje minimalne 1000 ms na spusteni, Consumption 100 ms.
        U minutovych behu je to jedno; u skriptu, ktery bezi 200 ms a spousti se kazdou
        minutu, to je pateronasobek. Proto se to pocita, ne odhaduje.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)] [double] $DurationSeconds,
        [Parameter(Mandatory)] [double] $MemoryGb,
        [Parameter(Mandatory)] [int] $MinBillableMs
    )

    $ms = [math]::Max($DurationSeconds * 1000, $MinBillableMs)
    return ($ms / 1000) * $MemoryGb
}


function Measure-GrantedCost {
    <#
    .SYNOPSIS
        Naklad za spotrebu, ze ktere se odecte free grant.
    .DESCRIPTION
        Jedina netrivialni vec na cele kalkulaci: grant se odecita od MESICNI spotreby,
        ne od jednoho behu. Proto se sem posila mesicni soucet.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param(
        [Parameter(Mandatory)] [double] $Usage,
        [Parameter(Mandatory)] [double] $Grant,
        [Parameter(Mandatory)] [AllowNull()] $UnitPrice
    )

    if ($null -eq $UnitPrice) { return 0 }
    $billable = [math]::Max(0, $Usage - $Grant)
    return $billable * [double] $UnitPrice
}


function Get-HostingCost {
    <#
    .SYNOPSIS
        Spocita mesicni naklad na hostovani planovaneho skriptu ve ctyrech variantach.
    .PARAMETER RunsPerMonth
        Kolikrat za mesic skript bezi. 30 = nocni davka, 720 = kazdou hodinu,
        8640 = kazdych pet minut.
    .PARAMETER MinutesPerRun
        Doba jednoho behu. U davky nad tenantem merte, nehadejte.
    .PARAMETER LogGbPerMonth
        Objem telemetrie do Log Analytics za mesic. Vychozich 0.3 GB je nocni skript,
        ktery loguje ~10 MB na beh. Zkuste 100 - to je chybne nastavena DCR.
    .EXAMPLE
        Get-HostingCost -RunsPerMonth 8640 -MinutesPerRun 1 -LogGbPerMonth 50
    #>
    [CmdletBinding()]
    param(
        [int] $RunsPerMonth = 30,
        [double] $MinutesPerRun = 10,
        [double] $FunctionMemoryGb = 2,      # Flex default pro vetsinu scenaru
        [double] $JobVcpu = 0.5,
        [double] $JobMemoryGib = 1,
        [double] $LogGbPerMonth = 0.3,
        [int] $RetentionMonths = 0,          # nad zdarma zahrnutych 31 dni
        [string] $Region = 'westeurope',
        [string] $PricesPath,
        [switch] $Offline
    )

    if ($MinutesPerRun -le 0) { throw "MinutesPerRun musi byt vetsi nez nula." }
    if ($RunsPerMonth -lt 0) { throw "RunsPerMonth nemuze byt negativni." }

    $rates = if ($Offline) {
        if (-not $PricesPath -or -not (Test-Path -LiteralPath $PricesPath)) {
            throw "S -Offline je potreba -PricesPath na existujici snapshot ceniku."
        }
        Get-Content -LiteralPath $PricesPath -Raw | ConvertFrom-Json
    }
    else {
        Get-HostingRate -Region $Region
    }

    $secondsPerRun = $MinutesPerRun * 60
    $totalMinutes  = $RunsPerMonth * $MinutesPerRun
    $totalSeconds  = $RunsPerMonth * $secondsPerRun

    # --- Automation Runbook: uctuje se za minutu behu -----------------------
    $automation = Measure-GrantedCost -Usage $totalMinutes `
        -Grant $rates.Automation.GrantMinutes -UnitPrice $rates.Automation.PerMinute

    # --- Functions: GB-sekundy + pocet spusteni ----------------------------
    $flexGbs = $RunsPerMonth * (Get-BillableGbSecond -DurationSeconds $secondsPerRun `
        -MemoryGb $FunctionMemoryGb -MinBillableMs $rates.FunctionsFlex.MinBillableMs)
    $flex = (Measure-GrantedCost -Usage $flexGbs -Grant $rates.FunctionsFlex.GrantGbSeconds -UnitPrice $rates.FunctionsFlex.ExecGbSecond) +
            (Measure-GrantedCost -Usage $RunsPerMonth -Grant $rates.FunctionsFlex.GrantExecutions -UnitPrice $rates.FunctionsFlex.PerExecution)

    $consGbs = $RunsPerMonth * (Get-BillableGbSecond -DurationSeconds $secondsPerRun `
        -MemoryGb $FunctionMemoryGb -MinBillableMs $rates.FunctionsConsumption.MinBillableMs)
    $consumption = (Measure-GrantedCost -Usage $consGbs -Grant $rates.FunctionsConsumption.GrantGbSeconds -UnitPrice $rates.FunctionsConsumption.ExecGbSecond) +
                   (Measure-GrantedCost -Usage $RunsPerMonth -Grant $rates.FunctionsConsumption.GrantExecutions -UnitPrice $rates.FunctionsConsumption.PerExecution)

    # --- Container Apps Job: jen ACTIVE sazba, job neplati idle ------------
    $job = (Measure-GrantedCost -Usage ($totalSeconds * $JobVcpu) `
                -Grant $script:ContainerAppsGrants.VcpuSeconds -UnitPrice $rates.ContainerApps.VcpuSecond) +
           (Measure-GrantedCost -Usage ($totalSeconds * $JobMemoryGib) `
                -Grant $script:ContainerAppsGrants.MemoryGibSeconds -UnitPrice $rates.ContainerApps.MemoryGibSecond)

    # --- Log Analytics: ingest + pripadna retence nad ramec zdarma ---------
    $logs = Measure-GrantedCost -Usage $LogGbPerMonth -Grant $rates.LogAnalytics.GrantGb -UnitPrice $rates.LogAnalytics.IngestGb
    if ($RetentionMonths -gt 0 -and $rates.LogAnalytics.RetentionGbMonth) {
        $logs += $LogGbPerMonth * $RetentionMonths * $rates.LogAnalytics.RetentionGbMonth
    }

    $rows = @(
        [pscustomobject]@{ Varianta = 'Automation Runbook';        EurZaMesic = [math]::Round($automation, 2);  Poznamka = "$totalMinutes min behu, grant $($rates.Automation.GrantMinutes) min" }
        [pscustomobject]@{ Varianta = 'Functions Flex Consumption'; EurZaMesic = [math]::Round($flex, 2);        Poznamka = "$([math]::Round($flexGbs)) GB-s, grant $($rates.FunctionsFlex.GrantGbSeconds) GB-s" }
        [pscustomobject]@{ Varianta = 'Functions Consumption (legacy)'; EurZaMesic = [math]::Round($consumption, 2); Poznamka = "$([math]::Round($consGbs)) GB-s, grant $($rates.FunctionsConsumption.GrantGbSeconds) GB-s" }
        [pscustomobject]@{ Varianta = 'Container Apps Job';        EurZaMesic = [math]::Round($job, 2);          Poznamka = "$([math]::Round($totalSeconds * $JobVcpu)) vCPU-s, grant $($script:ContainerAppsGrants.VcpuSeconds) vCPU-s" }
        [pscustomobject]@{ Varianta = 'Log Analytics (ingest)';    EurZaMesic = [math]::Round($logs, 2);         Poznamka = "$LogGbPerMonth GB, grant $($rates.LogAnalytics.GrantGb) GB" }
    )

    # Test na existenci vlastnosti je nutny, ne defenzivni zdobeni: pod
    # Set-StrictMode -Version Latest je cteni neexistujici vlastnosti CHYBA, a offline
    # snapshot ceniku klidne muze byt starsi a tuhle sekci neobsahovat.
    $derivedList = @()
    if ($rates.PSObject.Properties.Name -contains 'DerivedFromUsd') {
        $derivedList = @($rates.DerivedFromUsd)
    }
    if ($derivedList.Count -gt 0) {
        Write-Warning "Sazby derivovane z USD (EUR meter zaokrouhlen na nulu): $($derivedList -join ', ')"
    }

    return $rows
}
