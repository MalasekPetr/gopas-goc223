<#
    Unit testy ke Get-HostingCost.

    Spusteni:  Invoke-Pester ./Get-HostingCost.Tests.ps1

    Cenova kalkulace je presne ten druh kodu, ktery vypada spravne a tise pocita spatne.
    Testy proto miri na tri veci, na kterych se to lame:
      - free grant se odecita od MESICNI spotreby, ne od jednoho behu,
      - minimalni uctovana doba (Flex 1000 ms) se u kratkych behu projevi nasobne,
      - EUR meter zaokrouhleny na nulu se MUSI derivovat z USD, ne tise vratit nulu.

    Zadny test nejde na sit - cenik se do nich posila jako fixture.

    Vyzaduje Pester 5 nebo novejsi.
#>

BeforeAll {
    . $PSScriptRoot/Get-HostingCost.ps1

    # Pomocnik: radek ceniku v tom tvaru, v jakem ho vraci Retail Prices API.
    function New-FakeMeter {
        param(
            [string] $MeterName,
            [double] $RetailPrice,
            [double] $TierMinimumUnits = 0,
            [string] $Unit = '1 GB Second',
            [string] $SkuName = 'Standard',
            [string] $ProductName = 'Test Product'
        )
        [pscustomobject]@{
            meterName        = $MeterName
            retailPrice      = $RetailPrice
            tierMinimumUnits = $TierMinimumUnits
            unitOfMeasure    = $Unit
            skuName          = $SkuName
            productName      = $ProductName
            type             = 'Consumption'
        }
    }

    # Kompletni fixture ceniku pro -Offline. Musi mit vsechny vlastnosti, ktere
    # Get-HostingCost cte - pod StrictMode je chybejici vlastnost chyba.
    function New-FakeRates {
        [pscustomobject]@{
            FetchedAt      = '2026-09-08'
            Region         = 'westeurope'
            FxEurPerUsd    = 0.9
            DerivedFromUsd = @('flex.execGbSecond')
            Automation           = [pscustomobject]@{ PerMinute = 0.0017; GrantMinutes = 500 }
            FunctionsFlex        = [pscustomobject]@{ ExecGbSecond = 0.000014; GrantGbSeconds = 100000; PerExecution = 0.0000002; GrantExecutions = 250000; MinBillableMs = 1000 }
            FunctionsConsumption = [pscustomobject]@{ ExecGbSecond = 0.000014; GrantGbSeconds = 400000; PerExecution = 0.0000002; GrantExecutions = 1000000; MinBillableMs = 100 }
            ContainerApps        = [pscustomobject]@{ VcpuSecond = 0.0000306; MemoryGibSecond = 0.0000036 }
            LogAnalytics         = [pscustomobject]@{ IngestGb = 2.5674; GrantGb = 5; RetentionGbMonth = 0.1116 }
        }
    }

    function New-RatesFile {
        param($Rates)
        $path = Join-Path ([System.IO.Path]::GetTempPath()) "goc223-rates-$([guid]::NewGuid()).json"
        $Rates | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $path -Encoding utf8
        return $path
    }
}

Describe 'Get-BillableGbSecond' {

    It 'nasobi dobu behu pametovou velikosti' {
        Get-BillableGbSecond -DurationSeconds 10 -MemoryGb 2 -MinBillableMs 100 | Should -Be 20
    }

    It 'u dlouheho behu se minimalni uctovana doba neprojevi' {
        Get-BillableGbSecond -DurationSeconds 600 -MemoryGb 2 -MinBillableMs 1000 | Should -Be 1200
    }

    It 'kratky beh se na Flexu zaokrouhli nahoru na 1000 ms' {
        # 200 ms realneho behu se uctuje jako 1000 ms -> pateronasobek.
        $flex = Get-BillableGbSecond -DurationSeconds 0.2 -MemoryGb 1 -MinBillableMs 1000
        $cons = Get-BillableGbSecond -DurationSeconds 0.2 -MemoryGb 1 -MinBillableMs 100
        $flex | Should -Be 1
        $cons | Should -Be 0.2
        $flex | Should -BeGreaterThan $cons
    }
}

Describe 'Measure-GrantedCost' {

    It 'spotreba pod grantem nestoji nic' {
        Measure-GrantedCost -Usage 300 -Grant 500 -UnitPrice 0.0017 | Should -Be 0
    }

    It 'uctuje jen cast nad grantem, ne celou spotrebu' {
        # 600 - 500 = 100 minut * 0.0017. Zaokrouhleni v assertu neni kosmetika:
        # 100 * 0.0017 je v double 0.17000000000000002, takze rovnost na centy
        # se musi testovat po zaokrouhleni. Proto Get-HostingCost zaokrouhluje
        # az vysledny radek, ne mezivypocty.
        [math]::Round((Measure-GrantedCost -Usage 600 -Grant 500 -UnitPrice 0.0017), 4) | Should -Be 0.17
    }

    It 'presne na hranici grantu je jeste nula' {
        Measure-GrantedCost -Usage 500 -Grant 500 -UnitPrice 0.0017 | Should -Be 0
    }

    It 'chybejici sazba vrati nulu, ne chybu' {
        Measure-GrantedCost -Usage 1000 -Grant 0 -UnitPrice $null | Should -Be 0
    }
}

Describe 'Select-PriceMeter' {

    It 'vybere nejnizsi tarifni pasmo' {
        $items = @(
            (New-FakeMeter -MeterName 'Exec' -RetailPrice 0.5 -TierMinimumUnits 100)
            (New-FakeMeter -MeterName 'Exec' -RetailPrice 0.1 -TierMinimumUnits 0)
        )
        (Select-PriceMeter -Items $items -MeterName 'Exec').retailPrice | Should -Be 0.1
    }

    It '-Paid preskoci pasmo free grantu s nulovou cenou' {
        $items = @(
            (New-FakeMeter -MeterName 'Exec' -RetailPrice 0    -TierMinimumUnits 0)
            (New-FakeMeter -MeterName 'Exec' -RetailPrice 0.25 -TierMinimumUnits 400000)
        )
        $paid = Select-PriceMeter -Items $items -MeterName 'Exec' -Paid
        $paid.retailPrice | Should -Be 0.25
        # A hlavne: z toho placeneho pasma se cte velikost grantu.
        $paid.tierMinimumUnits | Should -Be 400000
    }

    It 'ignoruje mezery v nazvu SKU' {
        $items = @(New-FakeMeter -MeterName 'Plan' -RetailPrice 1 -SkuName 'P0 v3')
        Select-PriceMeter -Items $items -MeterName 'Plan' -SkuName 'P0v3' | Should -Not -BeNullOrEmpty
    }

    It 'vrati null, kdyz nic neodpovida' {
        $items = @(New-FakeMeter -MeterName 'Exec' -RetailPrice 1)
        Select-PriceMeter -Items $items -MeterName 'Neexistuje' | Should -BeNullOrEmpty
    }

    It 'zvlada prazdny cenik' {
        Select-PriceMeter -Items @() -MeterName 'Exec' | Should -BeNullOrEmpty
    }
}

Describe 'Resolve-MeterRate' {

    It 'nenulovou EUR cenu bere prime a neoznaci ji jako derivovanou' {
        $eur = @(New-FakeMeter -MeterName 'Exec' -RetailPrice 0.5)
        $usd = @(New-FakeMeter -MeterName 'Exec' -RetailPrice 0.6)
        $r = Resolve-MeterRate -EurItems $eur -UsdItems $usd -FxEurPerUsd 0.9 -Spec @{ MeterName = 'Exec' }
        $r.Price   | Should -Be 0.5
        $r.Derived | Should -BeFalse
    }

    It 'EUR zaokrouhlenou na nulu derivuje z USD a oznaci ji' {
        # Presne tenhle pripad ma cely Functions cenik v EUR.
        $eur = @(New-FakeMeter -MeterName 'Exec' -RetailPrice 0)
        $usd = @(New-FakeMeter -MeterName 'Exec' -RetailPrice 0.00002)
        $r = Resolve-MeterRate -EurItems $eur -UsdItems $usd -FxEurPerUsd 0.9 -Spec @{ MeterName = 'Exec' }
        $r.Price   | Should -Be 0.000018
        $r.Derived | Should -BeTrue
    }

    It 'grant cte z EUR meteru i kdyz je jeho cena nulova' {
        $eur = @(New-FakeMeter -MeterName 'Exec' -RetailPrice 0 -TierMinimumUnits 100000)
        $usd = @(New-FakeMeter -MeterName 'Exec' -RetailPrice 0.00002 -TierMinimumUnits 0)
        $r = Resolve-MeterRate -EurItems $eur -UsdItems $usd -FxEurPerUsd 0.9 -Spec @{ MeterName = 'Exec' }
        $r.Grant | Should -Be 100000
    }

    It 'vrati null, kdyz meter neni ani v jedne valute' {
        $r = Resolve-MeterRate -EurItems @() -UsdItems @() -FxEurPerUsd 0.9 -Spec @{ MeterName = 'Exec' }
        $r | Should -BeNullOrEmpty
    }
}

Describe 'Get-FxEurPerUsd' {

    It 'odvodi faktor jako podil obou valut' {
        $eur = @(New-FakeMeter -MeterName 'Standard Requests' -RetailPrice 0.45 -Unit '1M')
        $usd = @(New-FakeMeter -MeterName 'Standard Requests' -RetailPrice 0.50 -Unit '1M')
        Get-FxEurPerUsd -EurItems $eur -UsdItems $usd | Should -Be 0.9
    }

    It 'skonci chybou, kdyz je USD sazba nulova - misto tiseho odhadu kurzu' {
        $eur = @(New-FakeMeter -MeterName 'Standard Requests' -RetailPrice 0.45)
        $usd = @(New-FakeMeter -MeterName 'Standard Requests' -RetailPrice 0)
        { Get-FxEurPerUsd -EurItems $eur -UsdItems $usd } | Should -Throw -ExpectedMessage '*FX faktor*'
    }
}

Describe 'Get-HostingCost' {

    BeforeAll {
        $script:RatesFile = New-RatesFile -Rates (New-FakeRates)
    }

    AfterAll {
        if ($script:RatesFile -and (Test-Path -LiteralPath $script:RatesFile)) {
            Remove-Item -LiteralPath $script:RatesFile -Force
        }
    }

    It 'nocni skript se u vsech tri variant vejde do free grantu' {
        # 30 behu x 10 min: tohle je ta hlavni pointa celeho modulu.
        $rows = Get-HostingCost -Offline -PricesPath $script:RatesFile -WarningAction SilentlyContinue
        $compute = @($rows | Where-Object { $_.Varianta -ne 'Log Analytics (ingest)' })
        $compute.Count | Should -Be 4
        foreach ($row in $compute) { $row.EurZaMesic | Should -Be 0 }
    }

    It 'nocni skript s malym objemem logu nestoji nic ani v Log Analytics' {
        $rows = Get-HostingCost -Offline -PricesPath $script:RatesFile -WarningAction SilentlyContinue
        ($rows | Where-Object { $_.Varianta -eq 'Log Analytics (ingest)' }).EurZaMesic | Should -Be 0
    }

    It 'chybna DCR se projevi jako jediny nenulovy radek' {
        $rows = Get-HostingCost -Offline -PricesPath $script:RatesFile -LogGbPerMonth 100 -WarningAction SilentlyContinue
        $logs = @($rows | Where-Object { $_.Varianta -eq 'Log Analytics (ingest)' })[0]
        # (100 - 5) * 2.5674
        $logs.EurZaMesic | Should -Be 243.9
        $compute = @($rows | Where-Object { $_.Varianta -ne 'Log Analytics (ingest)' })
        foreach ($row in $compute) { $row.EurZaMesic | Should -Be 0 }
    }

    It 'castejsi beh uz z grantu vypadne' {
        # Kazdych pet minut po minute: 8640 behu, 2 GB -> 1 036 800 GB-s.
        $rows = Get-HostingCost -Offline -PricesPath $script:RatesFile `
            -RunsPerMonth 8640 -MinutesPerRun 1 -WarningAction SilentlyContinue
        ($rows | Where-Object { $_.Varianta -eq 'Functions Flex Consumption' }).EurZaMesic | Should -BeGreaterThan 0
        ($rows | Where-Object { $_.Varianta -eq 'Automation Runbook' }).EurZaMesic | Should -BeGreaterThan 0
    }

    It 'retence se pripocita az kdyz se o ni rekne' {
        $bez = Get-HostingCost -Offline -PricesPath $script:RatesFile -LogGbPerMonth 100 -WarningAction SilentlyContinue
        $s   = Get-HostingCost -Offline -PricesPath $script:RatesFile -LogGbPerMonth 100 -RetentionMonths 12 -WarningAction SilentlyContinue
        $bezLog = ($bez | Where-Object { $_.Varianta -eq 'Log Analytics (ingest)' }).EurZaMesic
        $sLog   = ($s   | Where-Object { $_.Varianta -eq 'Log Analytics (ingest)' }).EurZaMesic
        $sLog | Should -BeGreaterThan $bezLog
    }

    It 'nesmyslny vstup skonci chybou, ne nulou' {
        { Get-HostingCost -Offline -PricesPath $script:RatesFile -MinutesPerRun 0 } | Should -Throw -ExpectedMessage '*MinutesPerRun*'
    }

    It '-Offline bez snapshotu skonci srozumitelnou chybou' {
        { Get-HostingCost -Offline -PricesPath 'Z:\neexistuje.json' } | Should -Throw -ExpectedMessage '*PricesPath*'
    }
}
