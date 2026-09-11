<#
    Unit testy ke Get-SelectedPermissionGrant.

    Spusteni:  Invoke-Pester ./Get-SelectedPermissionGrant.Tests.ps1

    U inventurniho reportu se netestuje "naslo to granty". Testuje se, ze report
    NEPRELHAVA tam, kde se nepodarilo se podivat:

      - web, ktery nesel precist ($null), skonci v Unreadable, NE mezi weby bez grantu,
      - web s prazdnym seznamem grantu je neco JINEHO nez web neprecteny,
      - kdyz se nepodari nacist adresar, granty se NEoznaci za osirele,
      - useknuty report to prizna priznakem Capped,
      - neznama role se radi k write, ne k read (podcenit opravneni je horsi chyba).

    Vyzaduje Pester 5 nebo novejsi.
#>

BeforeAll {
    . $PSScriptRoot/Get-SelectedPermissionGrant.ps1

    function New-FakeSite {
        param([string] $Name = 'Projekty', [string] $Url = 'https://c.sharepoint.com/sites/projekty')
        [pscustomobject]@{ id = "id-$Name"; displayName = $Name; webUrl = $Url; isPersonalSite = $false }
    }

    function New-FakeGrant {
        param(
            [string] $AppId = 'app-1',
            [string] $AppName = 'Course App',
            [string[]] $Roles = @('write')
        )
        [pscustomobject]@{
            roles = $Roles
            grantedToIdentitiesV2 = @(
                [pscustomobject]@{ application = [pscustomobject]@{ id = $AppId; displayName = $AppName } }
            )
        }
    }
}

Describe 'Get-GrantRoleRank' {

    It 'radi ctyri znama jmena vzestupne' {
        (Get-GrantRoleRank -Role 'read')        | Should -BeLessThan (Get-GrantRoleRank -Role 'write')
        (Get-GrantRoleRank -Role 'write')       | Should -BeLessThan (Get-GrantRoleRank -Role 'owner')
        (Get-GrantRoleRank -Role 'owner')       | Should -BeLessThan (Get-GrantRoleRank -Role 'fullcontrol')
    }

    It 'NEZNAMOU roli radi k write, ne k read' {
        # Podcenit opravneni je horsi chyba nez ho nadcenit.
        (Get-GrantRoleRank -Role 'neco-co-microsoft-pridal') | Should -Be (Get-GrantRoleRank -Role 'write')
    }

    It 'prazdna role je nula' {
        (Get-GrantRoleRank -Role '') | Should -Be 0
    }
}

Describe 'Get-SelectedPermissionGrant' {

    It 'web, ktery nesel precist, skonci v Unreadable a NE mezi granty' {
        $r = Get-SelectedPermissionGrant -MaxSites 0 `
            -GetSitesFunc { @(New-FakeSite) } `
            -GetPermissionsFunc { $null } `
            -GetServicePrincipalsFunc { @([pscustomobject]@{ appId = 'app-1' }) }

        $r.Unreadable.Count | Should -Be 1
        $r.Grants.Count     | Should -Be 0
    }

    It 'web BEZ grantu je neco jineho nez web neprecteny' {
        # Klicovy test celeho reportu: prazdne pole != $null.
        $r = Get-SelectedPermissionGrant -MaxSites 0 `
            -GetSitesFunc { @(New-FakeSite) } `
            -GetPermissionsFunc { [pscustomobject]@{ value = @() } } `
            -GetServicePrincipalsFunc { @([pscustomobject]@{ appId = 'app-1' }) }

        $r.Unreadable.Count | Should -Be 0
        $r.Grants.Count     | Should -Be 0
    }

    It 'grant zive aplikace neni osirely' {
        $r = Get-SelectedPermissionGrant -MaxSites 0 `
            -GetSitesFunc { @(New-FakeSite) } `
            -GetPermissionsFunc { [pscustomobject]@{ value = @(New-FakeGrant -AppId 'app-1') } } `
            -GetServicePrincipalsFunc { @([pscustomobject]@{ appId = 'app-1' }) }

        $r.Grants[0].Orphaned | Should -BeFalse
    }

    It 'grant po smazane aplikaci se oznaci jako osirely' {
        $r = Get-SelectedPermissionGrant -MaxSites 0 `
            -GetSitesFunc { @(New-FakeSite) } `
            -GetPermissionsFunc { [pscustomobject]@{ value = @(New-FakeGrant -AppId 'app-smazana') } } `
            -GetServicePrincipalsFunc { @([pscustomobject]@{ appId = 'app-1' }) }

        $r.Grants[0].Orphaned | Should -BeTrue
    }

    It 'kdyz se NEPODARI nacist adresar, granty se NEoznaci za osirele' {
        # Selhany predpoklad se nesmi tvarit jako nalez. Prazdny adresar by jinak
        # vyrobil tabulku alarmujicich nalezu, ktere jsou vsechny falesne.
        $r = Get-SelectedPermissionGrant -MaxSites 0 -WarningAction SilentlyContinue `
            -GetSitesFunc { @(New-FakeSite) } `
            -GetPermissionsFunc { [pscustomobject]@{ value = @(New-FakeGrant -AppId 'app-1') } } `
            -GetServicePrincipalsFunc { @() }

        $r.DirectoryKnown     | Should -BeFalse
        $r.Grants[0].Orphaned | Should -BeNullOrEmpty
    }

    It 'useknuty report to prizna' {
        $sites = 1..5 | ForEach-Object { New-FakeSite -Name "Web$_" -Url "https://c.sharepoint.com/sites/w$_" }
        $r = Get-SelectedPermissionGrant -MaxSites 2 -WarningAction SilentlyContinue `
            -GetSitesFunc { $sites } `
            -GetPermissionsFunc { [pscustomobject]@{ value = @() } } `
            -GetServicePrincipalsFunc { @([pscustomobject]@{ appId = 'app-1' }) }

        $r.Capped     | Should -BeTrue
        $r.TotalSites | Should -Be 5
        $r.SitesRead  | Should -Be 2
    }

    It 'osobni weby se do inventury nepocitaji' {
        $personal = [pscustomobject]@{ id = 'p'; displayName = 'OneDrive'; webUrl = 'https://c-my.sharepoint.com/personal/x'; isPersonalSite = $true }
        $r = Get-SelectedPermissionGrant -MaxSites 0 `
            -GetSitesFunc { @($personal, (New-FakeSite)) } `
            -GetPermissionsFunc { [pscustomobject]@{ value = @() } } `
            -GetServicePrincipalsFunc { @([pscustomobject]@{ appId = 'app-1' }) }

        $r.SitesRead | Should -Be 1
    }

    It 'z vic roli vybere tu nejvyssi a oznaci write a vys' {
        $r = Get-SelectedPermissionGrant -MaxSites 0 `
            -GetSitesFunc { @(New-FakeSite) } `
            -GetPermissionsFunc { [pscustomobject]@{ value = @(New-FakeGrant -Roles @('read', 'fullcontrol')) } } `
            -GetServicePrincipalsFunc { @([pscustomobject]@{ appId = 'app-1' }) }

        $r.Grants[0].HighestRole  | Should -Be 'fullcontrol'
        $r.Grants[0].WriteOrAbove | Should -BeTrue
    }

    It 'grant jen pro cteni se jako write a vys neoznaci' {
        $r = Get-SelectedPermissionGrant -MaxSites 0 `
            -GetSitesFunc { @(New-FakeSite) } `
            -GetPermissionsFunc { [pscustomobject]@{ value = @(New-FakeGrant -Roles @('read')) } } `
            -GetServicePrincipalsFunc { @([pscustomobject]@{ appId = 'app-1' }) }

        $r.Grants[0].WriteOrAbove | Should -BeFalse
    }
}
