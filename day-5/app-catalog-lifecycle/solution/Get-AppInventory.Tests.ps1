<#
    Unit testy k Get-AppInventory.

    Spusteni:  Invoke-Pester ./Get-AppInventory.Tests.ps1

    Vetsina testu miri na Test-AppNeedsUpdate. Je to jedina funkce v celem
    referencnim reseni, ktera neco ROZHODUJE - a rozhodnuti "tenhle web ceka
    na upgrade" je to, podle ceho nekdo bude jednat. Presne to se testuje.

    Vyzaduje Pester 5 nebo novejsi.
#>

BeforeAll {
    . $PSScriptRoot/Get-AppInventory.ps1

    function Connect-PnPOnline { param($Url, $ClientId) }
    function Get-PnPApp        { param($Scope) }

    $script:SiteA = 'https://contoso.sharepoint.com/sites/a'
    $script:SiteB = 'https://contoso.sharepoint.com/sites/b'
}

Describe 'Test-AppNeedsUpdate' {

    It 'novejsi verze v katalogu znamena, ze web ceka na upgrade' {
        Test-AppNeedsUpdate -CatalogVersion '1.1.0' -InstalledVersion '1.0.0' | Should -BeTrue
    }

    It 'shodne verze znamenaji, ze je hotovo' {
        Test-AppNeedsUpdate -CatalogVersion '1.1.0' -InstalledVersion '1.1.0' | Should -BeFalse
    }

    It 'porovnava CISELNE, ne textove - 1.10.0 je vyssi nez 1.9.0' {
        # Textove porovnani by reklo, ze "1.10.0" < "1.9.0", protoze '1' < '9'.
        # Tohle je nejcastejsi chyba v podobnych skriptech a v praxi znamena,
        # ze upgrade na verzi 1.10 nikdo neuvidi.
        Test-AppNeedsUpdate -CatalogVersion '1.10.0' -InstalledVersion '1.9.0' | Should -BeTrue
        Test-AppNeedsUpdate -CatalogVersion '1.9.0'  -InstalledVersion '1.10.0' | Should -BeFalse
    }

    It 'NEinstalovane reseni upgrade nepotrebuje - potrebuje instalaci' {
        # Michat "chybi instalace" a "ceka na upgrade" do jednoho priznaku by
        # znamenalo, ze automatizovana remediace nainstaluje reseni na weby,
        # kde nikdy nebylo. Jsou to dve rozdilne akce.
        Test-AppNeedsUpdate -CatalogVersion '1.0.0' -InstalledVersion ''    | Should -BeFalse
        Test-AppNeedsUpdate -CatalogVersion '1.0.0' -InstalledVersion $null | Should -BeFalse
    }

    It 'chybejici verze v katalogu nevede k zadnemu tvrzeni' {
        Test-AppNeedsUpdate -CatalogVersion ''    -InstalledVersion '1.0.0' | Should -BeFalse
        Test-AppNeedsUpdate -CatalogVersion $null -InstalledVersion '1.0.0' | Should -BeFalse
    }

    It 'neparsovatelnou verzi porovna textem, misto aby spadl' {
        # Verze v .sppkg je to, co nekdo napsal do package-solution.json.
        # Nemusi to byt semver a skript kvuli tomu nesmi skoncit chybou.
        Test-AppNeedsUpdate -CatalogVersion '2.0-beta' -InstalledVersion '1.0-beta' | Should -BeTrue
        Test-AppNeedsUpdate -CatalogVersion '2.0-beta' -InstalledVersion '2.0-beta' | Should -BeFalse
    }
}

Describe 'Get-AppInventory' {

    BeforeEach {
        Mock Connect-PnPOnline {}
        Mock Get-PnPApp {
            @(
                [pscustomobject]@{
                    Title = 'Reseni A'; Id = 'aaa'
                    AppCatalogVersion = '1.1.0'; InstalledVersion = '1.0.0'; Deployed = $true
                }
                [pscustomobject]@{
                    Title = 'Reseni B'; Id = 'bbb'
                    AppCatalogVersion = '2.0.0'; InstalledVersion = '2.0.0'; Deployed = $true
                }
            )
        }
    }

    It 'vrati radek za kazde reseni na kazdem webu' {
        $result = @(Get-AppInventory -SiteUrl $SiteA, $SiteB)
        $result.Count | Should -Be 4
    }

    It 'spocita NeedsUpdate za kazdy radek' {
        $result = @(Get-AppInventory -SiteUrl $SiteA)

        ($result | Where-Object Title -eq 'Reseni A').NeedsUpdate | Should -BeTrue
        ($result | Where-Object Title -eq 'Reseni B').NeedsUpdate | Should -BeFalse
    }

    It 'NIC nemeni - inventura, ne remediace' {
        # Kdyby nekdo pri "vylepseni" doplnil automaticky upgrade, tenhle test spadne.
        # Skript, ktery se jmenuje Get-*, nesmi nic menit - a u nastroje nad App
        # Catalogem to plati dvojnasob.
        Mock Update-PnPApp {}
        Mock Install-PnPApp {}
        Mock Add-PnPApp {}

        Get-AppInventory -SiteUrl $SiteA | Out-Null

        Should -Not -Invoke Update-PnPApp
        Should -Not -Invoke Install-PnPApp
        Should -Not -Invoke Add-PnPApp
    }

    It 'nepristupny web zaznamena a pokracuje na dalsi' {
        Mock Connect-PnPOnline {
            param($Url, $ClientId)
            if ($Url -eq $SiteA) { throw 'Access denied' }
        }

        $result = @(Get-AppInventory -SiteUrl $SiteA, $SiteB)

        # Jeden chybovy radek za SiteA + dva radky za SiteB.
        $result.Count | Should -Be 3
        ($result | Where-Object SiteUrl -eq $SiteA).Error | Should -BeLike '*Access denied*'
        @($result | Where-Object SiteUrl -eq $SiteB).Count | Should -Be 2
    }

    It 'vychozi Scope je Site, ne Tenant' {
        # Vychozi hodnota miri na site collection katalog. Kdyby byla Tenant,
        # student by pri prvnim spusteni cetl cely tenant misto vlastniho webu.
        Get-AppInventory -SiteUrl $SiteA | Out-Null
        Should -Invoke Get-PnPApp -ParameterFilter { $Scope -eq 'Site' }
    }

    It 'predava zadany Scope dal' {
        Get-AppInventory -SiteUrl $SiteA -Scope Tenant | Out-Null
        Should -Invoke Get-PnPApp -ParameterFilter { $Scope -eq 'Tenant' }
    }
}
