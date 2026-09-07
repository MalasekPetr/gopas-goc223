<#
    Unit testy k Connect-CourseTarget.

    Spusteni:  Invoke-Pester ./Connect-CourseTarget.Tests.ps1

    Proc tyhle testy existuji: wrapper se pripojuje k zivemu tenantu, takze ho
    nelze "vyzkouset" jako soucast CI ani na stroji bez certifikatu. Testovat se
    ale da vsechno, co se rozhoduje PRED pripojenim - validace vstupu, vyber
    spravneho cmdletu a podoba logu. Presne to je pointa mockovani z
    day-1/vscode-copilot-env/explainer-quality-gates.md: netestuje se Microsoft,
    testuje se vlastni logika.

    Vyzaduje Pester 5 nebo novejsi (syntaxe Should -Invoke).
#>

BeforeAll {
    . $PSScriptRoot/Connect-CourseTarget.ps1

    # Stuby Connect-* cmdletu. Definuji se jako funkce, protoze funkce maji
    # v PowerShellu prednost pred cmdlety - testy tim bezi stejne na stroji,
    # kde prislusny modul je, jako na tom, kde neni. Bez toho by test selhal
    # na "Could not find Command ..." misto na skutecne chybe.
    function Connect-PnPOnline  { param($Url, $ClientId, $Tenant, $Thumbprint, [switch]$Interactive, [switch]$DeviceLogin) }
    function Connect-MgGraph    { param($ClientId, $TenantId, $CertificateThumbprint, [switch]$UseDeviceCode) }
    function Connect-SPOService { param($Url, $ClientId, $TenantId, $CertificateThumbprint) }

    # Spolecne testovaci hodnoty. Zadne realne identifikatory - stejne pravidlo
    # jako v kurzovnich materialech.
    $script:TestUrl   = 'https://contoso.sharepoint.com/sites/test-dev'
    $script:TestAppId = '00000000-0000-0000-0000-000000000000'
    $script:TestThumb = '0000000000000000000000000000000000000000'
    $script:TestTenant = 'contoso.onmicrosoft.com'
}

Describe 'Connect-CourseTarget - validace vstupu' {

    # Tyhle testy nepotrebuji mock vubec: validace probiha PRED importem modulu
    # i pred pripojenim, takze se k zadnemu cizimu kodu nedostane.

    It 'odmitne Certificate bez -Thumbprint' {
        { Connect-CourseTarget -Module PnP -AuthMode Certificate `
            -Url $TestUrl -ClientId $TestAppId -Tenant $TestTenant } |
            Should -Throw -ExpectedMessage '*vyzaduje -Thumbprint*'
    }

    It 'odmitne Certificate bez -Tenant' {
        { Connect-CourseTarget -Module PnP -AuthMode Certificate `
            -Url $TestUrl -ClientId $TestAppId -Thumbprint $TestThumb } |
            Should -Throw -ExpectedMessage '*vyzaduje -Tenant*'
    }

    It 'odmitne PnP bez -ClientId, i pro interaktivni prihlaseni' {
        # Nejcastejsi realna chyba: PnP od zari 2024 nema vychozi ClientId,
        # takze i -Interactive ho vyzaduje. Bez teto validace by clovek dostal
        # az AADSTS700016 z Entra.
        { Connect-CourseTarget -Module PnP -AuthMode Interactive -Url $TestUrl } |
            Should -Throw -ExpectedMessage '*vyzaduje -ClientId*'
    }

    It 'odmitne PnP bez -Url' {
        { Connect-CourseTarget -Module PnP -AuthMode Interactive -ClientId $TestAppId } |
            Should -Throw -ExpectedMessage '*vyzaduje -Url*'
    }

    It 'Graph bez -Url projde validaci - Graph URL nepouziva' {
        Mock Import-Module {}
        Mock Connect-MgGraph {}

        { Connect-CourseTarget -Module Graph -AuthMode Interactive `
            -ClientId $TestAppId -Tenant $TestTenant } | Should -Not -Throw
    }

    It 'odmitne neplatnou hodnotu -Module jiz na urovni ValidateSet' {
        { Connect-CourseTarget -Module Sharepoint -AuthMode Interactive } | Should -Throw
    }
}

Describe 'Connect-CourseTarget - vyber spravneho cmdletu' {

    BeforeEach {
        Mock Import-Module {}
        Mock Connect-PnPOnline {}
        Mock Connect-MgGraph {}
        Mock Connect-SPOService {}
    }

    It 'PnP + Certificate vola Connect-PnPOnline s -Thumbprint a -Tenant' {
        Connect-CourseTarget -Module PnP -AuthMode Certificate `
            -Url $TestUrl -ClientId $TestAppId -Tenant $TestTenant -Thumbprint $TestThumb | Out-Null

        Should -Invoke Connect-PnPOnline -Times 1 -Exactly -ParameterFilter {
            $Thumbprint -eq $TestThumb -and $Tenant -eq $TestTenant -and $ClientId -eq $TestAppId
        }
    }

    It 'PnP + Interactive nepredava zadny Thumbprint' {
        Connect-CourseTarget -Module PnP -AuthMode Interactive `
            -Url $TestUrl -ClientId $TestAppId | Out-Null

        Should -Invoke Connect-PnPOnline -Times 1 -Exactly -ParameterFilter {
            $Interactive.IsPresent -and -not $Thumbprint
        }
    }

    It 'PnP + DeviceCode pouzije -DeviceLogin, ne -Interactive' {
        Connect-CourseTarget -Module PnP -AuthMode DeviceCode `
            -Url $TestUrl -ClientId $TestAppId | Out-Null

        Should -Invoke Connect-PnPOnline -Times 1 -Exactly -ParameterFilter {
            $DeviceLogin.IsPresent -and -not $Interactive.IsPresent
        }
    }

    It 'Graph pouziva -TenantId, ne -Tenant' {
        # Rozdil v nazvu parametru mezi moduly je presne to, co wrapper skryva.
        Connect-CourseTarget -Module Graph -AuthMode Certificate `
            -ClientId $TestAppId -Tenant $TestTenant -Thumbprint $TestThumb | Out-Null

        Should -Invoke Connect-MgGraph -Times 1 -Exactly -ParameterFilter {
            $TenantId -eq $TestTenant -and $CertificateThumbprint -eq $TestThumb
        }
    }

    It 'nezavola cizi modul - PnP volani se nesmi dostat do Graphu ani SPO' {
        Connect-CourseTarget -Module PnP -AuthMode Interactive `
            -Url $TestUrl -ClientId $TestAppId | Out-Null

        Should -Not -Invoke Connect-MgGraph
        Should -Not -Invoke Connect-SPOService
    }

    It 'SPO + DeviceCode selze - takovy flow SPO modul nema' {
        { Connect-CourseTarget -Module SPO -AuthMode DeviceCode -Url $TestUrl } |
            Should -Throw -ExpectedMessage '*device code*'

        Should -Not -Invoke Connect-SPOService
    }
}

Describe 'Connect-CourseTarget - strukturovany log' {

    BeforeEach {
        Mock Import-Module {}
        Mock Connect-PnPOnline {}
    }

    It 'vraci objekt se vsemi ocekavanymi vlastnostmi' {
        $log = Connect-CourseTarget -Module PnP -AuthMode Interactive `
            -Url $TestUrl -ClientId $TestAppId

        foreach ($property in 'Timestamp','Module','AuthMode','Url','ClientId','Success','Error','DurationMs') {
            $log.PSObject.Properties.Name | Should -Contain $property
        }
    }

    It 'pri uspechu ma Success = true a prazdny Error' {
        $log = Connect-CourseTarget -Module PnP -AuthMode Interactive `
            -Url $TestUrl -ClientId $TestAppId

        $log.Success | Should -BeTrue
        $log.Error   | Should -BeNullOrEmpty
    }

    It 'Timestamp je v ISO 8601, aby slo radit i mimo PowerShell' {
        $log = Connect-CourseTarget -Module PnP -AuthMode Interactive `
            -Url $TestUrl -ClientId $TestAppId

        # Kdyz format prestane byt ISO, prestanou fungovat KQL dotazy nad logem
        # v day-4/siem-blob-integration - proto je na to test.
        { [datetime]::Parse($log.Timestamp) } | Should -Not -Throw
        $log.Timestamp | Should -Match '^\d{4}-\d{2}-\d{2}T'
    }

    It 'NEOBSAHUJE thumbprint - v logu nesmi byt credential material' {
        $log = Connect-CourseTarget -Module PnP -AuthMode Certificate `
            -Url $TestUrl -ClientId $TestAppId -Tenant $TestTenant -Thumbprint $TestThumb

        # Nejdulezitejsi test tohoto souboru. Log konci v CSV nebo v Log Analytics,
        # takze cokoli citliveho v nem se rozsiri dal, nez cekate.
        ($log | ConvertTo-Json -Compress) | Should -Not -Match $TestThumb
    }

    It 'pri selhani vrati zaznam se Success = false a chybou v Error' {
        Mock Connect-PnPOnline { throw 'AADSTS700016: aplikace nenalezena' }

        # Tenhle test odhalil realnou chybu v prvni verzi wrapperu. Puvodne
        # koncil pres throw - a protoze throw je terminating, prirazeni
        # `$log = ...` se vubec neprovedlo a zaznam o selhani se ztratil.
        # Proto je tam dnes Write-Error, ne throw.
        $log = Connect-CourseTarget -Module PnP -AuthMode Interactive `
            -Url $TestUrl -ClientId $TestAppId -ErrorAction SilentlyContinue

        $log         | Should -Not -BeNullOrEmpty
        $log.Success | Should -BeFalse
        $log.Error   | Should -BeLike '*AADSTS700016*'
    }

    It 's -ErrorAction Stop selhani zastavi volajiciho' {
        Mock Connect-PnPOnline { throw 'AADSTS700016: aplikace nenalezena' }

        # Volajici, ktery nesmi pokracovat s nefunkcnim pripojenim, si tvrde
        # zastaveni vyzada sam - to je rozdil mezi "funkce rozhodla za tebe"
        # a "funkce ti dala na vyber".
        { Connect-CourseTarget -Module PnP -AuthMode Interactive `
            -Url $TestUrl -ClientId $TestAppId -ErrorAction Stop } |
            Should -Throw -ExpectedMessage '*selhalo*'
    }
}
