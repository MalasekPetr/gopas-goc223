<#
    Unit testy k Get-UserAccess.

    Spusteni:  Invoke-Pester ./Get-UserAccess.Tests.ps1

    Nejdulezitejsi test tohoto souboru je 'najde pristup pres Entra skupinu':
    doklada presne ten kontrast, ktery je jadrem labu - naivni verze uzivatele
    NENAJDE, verze s transitiveMemberOf ano. V labu to student zazije jako
    rozdil mezi krokem 3 a krokem 6; tady je to zafixovane jako regresni test.

    Vyzaduje Pester 5 nebo novejsi.
#>

BeforeAll {
    . $PSScriptRoot/Get-UserAccess.ps1

    # Stuby cmdletu z PnP a Graph SDK - testy tim bezi i na stroji, kde ty moduly
    # nejsou nainstalovane.
    function Connect-PnPOnline          { param($Url, $ClientId) }
    function Get-PnPSiteCollectionAdmin { }
    function Get-PnPGroup               { }
    function Get-PnPGroupMember         { param($Identity) }
    function Get-MgUserTransitiveMemberOf { param($UserId, [switch]$All) }

    $script:Upn      = 'jan.novak@contoso.com'
    $script:SiteA    = 'https://contoso.sharepoint.com/sites/a'
    $script:SiteB    = 'https://contoso.sharepoint.com/sites/b'
    $script:GroupId  = '11111111-1111-1111-1111-111111111111'
}

Describe 'Get-UserAccess - prime cesty pristupu' {

    BeforeEach {
        Mock Connect-PnPOnline {}
        Mock Get-MgUserTransitiveMemberOf { @() }
        Mock Get-PnPSiteCollectionAdmin { @() }
        Mock Get-PnPGroup { @() }
        Mock Get-PnPGroupMember { @() }
    }

    It 'najde site collection admina' {
        Mock Get-PnPSiteCollectionAdmin {
            @( [pscustomobject]@{ LoginName = "i:0#.f|membership|$Upn"; Title = 'Jan Novak' } )
        }

        $result = @(Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA)

        $result.Count       | Should -Be 1
        $result[0].AccessVia | Should -Be 'SiteAdmin'
        $result[0].SiteUrl   | Should -Be $SiteA
    }

    It 'najde prime clenstvi v SharePoint skupine' {
        Mock Get-PnPGroup { @( [pscustomobject]@{ Id = 5; Title = 'Site Members' } ) }
        Mock Get-PnPGroupMember {
            @( [pscustomobject]@{ LoginName = "i:0#.f|membership|$Upn"; Title = 'Jan Novak' } )
        }

        $result = @(Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA)

        $result.Count        | Should -Be 1
        $result[0].AccessVia | Should -Be 'SharePointGroup:Site Members'
        $result[0].GroupName | Should -Be 'Site Members'
    }

    It 'web bez pristupu se ve vystupu neobjevi' {
        # Prazdny vystup je platna odpoved - ne chyba. Kdyby se web objevil
        # s prazdnym AccessVia, nesel by vystup filtrovat.
        $result = @(Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA)
        $result.Count | Should -Be 0
    }
}

Describe 'Get-UserAccess - cesta pres Entra skupinu (jadro labu)' {

    BeforeEach {
        Mock Connect-PnPOnline {}
        Mock Get-PnPSiteCollectionAdmin { @() }

        # Scenar z casti A labu: v SharePoint skupine Members NENI uzivatel,
        # ale Entra bezpecnostni skupina, jejimz je uzivatel clenem.
        Mock Get-PnPGroup { @( [pscustomobject]@{ Id = 5; Title = 'Site Members' } ) }
        Mock Get-PnPGroupMember {
            @(
                [pscustomobject]@{
                    LoginName     = "c:0t.c|tenant|$GroupId"
                    Title         = 'access-test'
                    PrincipalType = 'SecurityGroup'
                    AadObjectId   = $GroupId
                }
            )
        }
        Mock Get-MgUserTransitiveMemberOf {
            @( [pscustomobject]@{ Id = $GroupId } )
        }
    }

    It 'NAIVNI verze pristup NENAJDE (-SkipEntraGroups) - krok 3 labu' {
        $result = @(Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA -SkipEntraGroups)

        # Presne tohle hlasi vetsina skriptu na internetu: "zadny pristup",
        # ackoli uzivatel web vidi.
        $result.Count | Should -Be 0
        Should -Not -Invoke Get-MgUserTransitiveMemberOf
    }

    It 'verze s transitiveMemberOf pristup NAJDE - krok 6 labu' {
        $result = @(Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA)

        $result.Count        | Should -Be 1
        $result[0].AccessVia | Should -Be 'EntraGroup:access-test'
        $result[0].GroupName | Should -Be 'Site Members'
    }

    It 'pouziva transitiveMemberOf, ne memberOf' {
        Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA | Out-Null

        # Kdyby nekdo pri refaktoru sahl po memberOf, vnorene skupiny by zmizely
        # a report by zase zacal lhat. Proto je na to test.
        Should -Invoke Get-MgUserTransitiveMemberOf -Times 1 -Exactly -ParameterFilter {
            $UserId -eq $Upn -and $All.IsPresent
        }
    }

    It 'nenajde pristup, kdyz uzivatel v te Entra skupine NENI' {
        Mock Get-MgUserTransitiveMemberOf {
            @( [pscustomobject]@{ Id = '99999999-9999-9999-9999-999999999999' } )
        }

        $result = @(Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA)
        $result.Count | Should -Be 0
    }
}

Describe 'Get-UserAccess - odolnost' {

    BeforeEach {
        Mock Connect-PnPOnline {}
        Mock Get-MgUserTransitiveMemberOf { @() }
        Mock Get-PnPSiteCollectionAdmin { @() }
        Mock Get-PnPGroup { @() }
        Mock Get-PnPGroupMember { @() }
    }

    It 'nepristupny web zaznamena a pokracuje na dalsi' {
        Mock Connect-PnPOnline {
            param($Url, $ClientId)
            if ($Url -eq $SiteA) { throw 'Access denied' }
        }
        Mock Get-PnPSiteCollectionAdmin {
            @( [pscustomobject]@{ LoginName = "i:0#.f|membership|$Upn" } )
        }

        $result = @(Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA, $SiteB)

        # Prvni web selhal, druhy se presto zpracoval - to je pozadavek z labu.
        $result.Count | Should -Be 2
        ($result | Where-Object SiteUrl -eq $SiteA).Error     | Should -BeLike '*Access denied*'
        ($result | Where-Object SiteUrl -eq $SiteB).AccessVia | Should -Be 'SiteAdmin'
    }

    It 'necitelna skupina neshodi zpracovani zbytku webu' {
        Mock Get-PnPGroup {
            @(
                [pscustomobject]@{ Id = 1; Title = 'Nectitelna' }
                [pscustomobject]@{ Id = 2; Title = 'Site Owners' }
            )
        }
        Mock Get-PnPGroupMember {
            param($Identity)
            if ($Identity -eq 1) { throw 'Cannot read group' }
            @( [pscustomobject]@{ LoginName = "i:0#.f|membership|$Upn" } )
        }

        $result = @(Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA)

        $result.Count        | Should -Be 1
        $result[0].AccessVia | Should -Be 'SharePointGroup:Site Owners'
    }

    It 'kdyz selze Graph, varuje a pokracuje v naivnim rezimu' {
        Mock Get-MgUserTransitiveMemberOf { throw 'Insufficient privileges' }

        # Tichy prechod na naivni rezim by byl nejhorsi mozne chovani - report
        # by tvrdil "zadny pristup" a nikdo by nevedel, ze mu chybi cela cesta.
        $warnings = @()
        Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA -WarningVariable warnings | Out-Null

        $warnings | Should -Not -BeNullOrEmpty
        ($warnings -join ' ') | Should -BeLike '*prehlednout*'

        # Varovani musi obsahovat SKUTECNOU chybu, ne placeholder. Prvni verze
        # skriptu mela zavorky u -f spatne, takze do vystupu slo literalni "{0}"
        # a duvod selhani se ztratil.
        ($warnings -join ' ') | Should -BeLike '*Insufficient privileges*'
        ($warnings -join ' ') | Should -Not -BeLike '*{0}*'
    }

    It 'projde vsechny zadane weby, ne jen prvni' {
        Get-UserAccess -UserPrincipalName $Upn -SiteUrl $SiteA, $SiteB | Out-Null
        Should -Invoke Connect-PnPOnline -Times 2 -Exactly
    }
}
