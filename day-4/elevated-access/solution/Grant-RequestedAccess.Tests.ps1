<#
    Unit testy ke Grant-RequestedAccess.

    Spusteni:  Invoke-Pester ./Grant-RequestedAccess.Tests.ps1

    U elevovane operace se testuje neco jineho nez u bezneho skriptu. Nejde o to, jestli
    "to funguje" - jde o to, jestli to NEUDELA nic, co nemelo. Ctyri veci, ktere musi byt
    dokazane, protoze se nedaji vyzkouset na produkci:
      - zadost "za nekoho jineho" se zamitne (confused deputy),
      - zadost mimo povoleny rozsah se zamitne, i kdyz aplikace pravo ma,
      - eskalace role se neprideli ani kdyz si ji nekdo do radku napise,
      - s -WhatIf se nezapise ani jeden zapis,
      - zamitnuti se AUDITUJE, nezahodi.

    Vyzaduje Pester 5 nebo novejsi.
#>

BeforeAll {
    . $PSScriptRoot/Grant-RequestedAccess.ps1

    # PnP cmdlety v testech neexistuji, takze se deklaruji jako prazdne funkce a mockuji.
    function Get-PnPListItem { param($List, $Query, $Identity, $PageSize) }
    function Set-PnPListItemPermission { param($List, $Identity, $User, $AddRole, [switch] $SystemUpdate) }
    function Add-PnPListItem { param($List, $Values) }
    # Set-PnPListItem ma JEN -UpdateType (string). Switch -SystemUpdate neexistuje - kdyby
    # ho skript pouzil, na zivem PnP by spadl. Stub ho proto zamerne NEDEKLARUJE.
    function Set-PnPListItem { param($List, $Identity, $Values, [string] $UpdateType) }

    # Pomocnik: napodobi radek zadosti tak, jak ho vraci PnP (hodnoty ve FieldValues).
    function New-FakeRequest {
        param(
            [int]    $Id = 1,
            [string] $Requester = 'zadatel@contoso.com',
            [string] $Author = 'zadatel@contoso.com',
            [string] $Library = 'Dokumenty',
            [int]    $ItemId = 42,
            [string] $Role = 'Read',
            [string] $Status = 'Pending',
            [switch] $NoAuthor
        )
        $fields = @{
            RequestStatus  = $Status
            RequesterEmail = $Requester
            TargetLibrary  = $Library
            TargetItemId   = $ItemId
            RequestedRole  = $Role
        }
        if (-not $NoAuthor) {
            $fields['Author'] = [pscustomobject]@{ Email = $Author }
        }
        [pscustomobject]@{ Id = $Id; FieldValues = $fields }
    }

    $script:StdArgs = @{
        RequestListTitle    = 'Zadosti'
        AuditListTitle      = 'Audit'
        AllowedLibraryTitle = 'Dokumenty'
    }
}

Describe 'Test-RequestAllowed' {

    It 'povoli zadost, kterou zalozil sam zadatel na povolenou knihovnu' {
        $verdict = Test-RequestAllowed -Request (New-FakeRequest) -AllowedLibraryTitle 'Dokumenty'
        $verdict.Allowed | Should -BeTrue
    }

    It 'zamitne zadost za nekoho jineho' {
        # Confused deputy: radek zalozil utocnik, ale zadatel je nekdo jiny.
        $req = New-FakeRequest -Requester 'sef@contoso.com' -Author 'utocnik@contoso.com'
        $verdict = Test-RequestAllowed -Request $req -AllowedLibraryTitle 'Dokumenty'
        $verdict.Allowed | Should -BeFalse
        $verdict.Reason  | Should -BeLike '*neodpovida zakladateli*'
    }

    It 'zamitne zadost mimo povoleny rozsah, i kdyz aplikace pravo ma' {
        $req = New-FakeRequest -Library 'Mzdy'
        $verdict = Test-RequestAllowed -Request $req -AllowedLibraryTitle 'Dokumenty'
        $verdict.Allowed | Should -BeFalse
        $verdict.Reason  | Should -BeLike '*mimo povoleny rozsah*'
    }

    It 'neprideli eskalovanou roli, i kdyz si ji zadatel do radku napise' {
        $req = New-FakeRequest -Role 'Full Control'
        $verdict = Test-RequestAllowed -Request $req -AllowedLibraryTitle 'Dokumenty'
        $verdict.Allowed | Should -BeFalse
        $verdict.Reason  | Should -BeLike '*neni v povolene sade*'
    }

    It 'zamitne radek bez Author, protoze zadatele nelze overit' {
        $req = New-FakeRequest -NoAuthor
        $verdict = Test-RequestAllowed -Request $req -AllowedLibraryTitle 'Dokumenty'
        $verdict.Allowed | Should -BeFalse
        $verdict.Reason  | Should -BeLike '*nema Author*'
    }

    It 'zamitne radek bez zadatele' {
        $req = New-FakeRequest -Requester ''
        $verdict = Test-RequestAllowed -Request $req -AllowedLibraryTitle 'Dokumenty'
        $verdict.Allowed | Should -BeFalse
    }
}

Describe 'Get-PendingRequest' {

    It 'filtruje CAML dotazem, ne az na vysledku' {
        Mock Get-PnPListItem { @() }
        Get-PendingRequest -RequestListTitle 'Zadosti' | Out-Null
        Should -Invoke Get-PnPListItem -Times 1 -Exactly -ParameterFilter {
            $Query -like '*RequestStatus*' -and $Query -like '*Pending*'
        }
    }

    It 'null z cmdletu nevytvori fantomovou zadost' {
        Mock Get-PnPListItem { $null }
        $result = @(Get-PendingRequest -RequestListTitle 'Zadosti')
        $result.Count | Should -Be 0
    }

    It 'prazdny seznam vrati prazdne pole' {
        Mock Get-PnPListItem { @() }
        $result = @(Get-PendingRequest -RequestListTitle 'Zadosti')
        $result.Count | Should -Be 0
    }

    It 'jednu zadost vrati jako jednoprvkove pole' {
        Mock Get-PnPListItem { New-FakeRequest }
        $result = @(Get-PendingRequest -RequestListTitle 'Zadosti')
        $result.Count | Should -Be 1
    }
}

Describe 'Invoke-AccessRequestQueue' {

    BeforeEach {
        Mock Set-PnPListItemPermission {}
        Mock Add-PnPListItem {}
        Mock Set-PnPListItem {}
    }

    It 'schvalenou zadost elevuje, zauditovuje a oznaci jako Granted' {
        Mock Get-PnPListItem { New-FakeRequest }
        $result = Invoke-AccessRequestQueue @script:StdArgs

        $result.Count            | Should -Be 1
        $result[0].Outcome       | Should -Be 'Granted'
        Should -Invoke Set-PnPListItemPermission -Times 1 -Exactly -ParameterFilter {
            $User -eq 'zadatel@contoso.com' -and $AddRole -eq 'Read' -and $Identity -eq 42
        }
        Should -Invoke Add-PnPListItem -Times 1 -Exactly
    }

    It 'zamitnutou zadost NEelevuje, ale zauditovat MUSI' {
        Mock Get-PnPListItem { New-FakeRequest -Requester 'sef@contoso.com' -Author 'utocnik@contoso.com' }
        $result = Invoke-AccessRequestQueue @script:StdArgs -WarningAction SilentlyContinue

        $result[0].Outcome | Should -Be 'Rejected'
        Should -Not -Invoke Set-PnPListItemPermission
        # Zamitnuti, ktere nikde nezustane, je pro auditora totez jako kdyby neprislo.
        Should -Invoke Add-PnPListItem -Times 1 -Exactly
    }

    It 's -WhatIf neprovede ani jeden zapis' {
        Mock Get-PnPListItem { New-FakeRequest }
        Invoke-AccessRequestQueue @script:StdArgs -WhatIf | Out-Null

        Should -Not -Invoke Set-PnPListItemPermission
        Should -Not -Invoke Add-PnPListItem
        Should -Not -Invoke Set-PnPListItem
    }

    It 'stav zadosti zapisuje s -UpdateType SystemUpdate, aby nespoustel flow a neverzoval' {
        Mock Get-PnPListItem { New-FakeRequest }
        Invoke-AccessRequestQueue @script:StdArgs | Out-Null

        Should -Invoke Set-PnPListItem -Times 1 -Exactly -ParameterFilter { $UpdateType -eq 'SystemUpdate' }
    }

    It 'selhani jedne zadosti nezastavi frontu a oznaci ji jako Failed' {
        Mock Get-PnPListItem {
            @(
                (New-FakeRequest -Id 1 -ItemId 11)
                (New-FakeRequest -Id 2 -ItemId 22)
            )
        }
        # Prvni elevace spadne, druha projde.
        Mock Set-PnPListItemPermission { throw 'Access denied' } -ParameterFilter { $Identity -eq 11 }

        $result = Invoke-AccessRequestQueue @script:StdArgs -WarningAction SilentlyContinue

        $result.Count | Should -Be 2
        ($result | Where-Object { $_.RequestId -eq 1 }).Outcome | Should -Be 'Failed'
        ($result | Where-Object { $_.RequestId -eq 2 }).Outcome | Should -Be 'Granted'
    }

    It 'druhy beh nad prazdnou frontou neudela nic - idempotence' {
        # Po prvnim behu uz zadny radek neni Pending, takze CAML nic nevrati.
        Mock Get-PnPListItem { @() }
        $result = Invoke-AccessRequestQueue @script:StdArgs

        $result.Count | Should -Be 0
        Should -Not -Invoke Set-PnPListItemPermission
        Should -Not -Invoke Add-PnPListItem
    }

    It 'zpracuje vsechny zadosti ve fronte, ne jen prvni' {
        Mock Get-PnPListItem {
            @(
                (New-FakeRequest -Id 1 -ItemId 11)
                (New-FakeRequest -Id 2 -ItemId 22)
                (New-FakeRequest -Id 3 -ItemId 33)
            )
        }
        $result = Invoke-AccessRequestQueue @script:StdArgs
        $result.Count | Should -Be 3
        Should -Invoke Set-PnPListItemPermission -Times 3 -Exactly
    }
}
