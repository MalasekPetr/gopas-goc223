<#
    Unit testy k Sync-CourseList.

    Spusteni:  Invoke-Pester ./Sync-CourseList.Tests.ps1

    Tri veci, ktere davkovy skript nad produkcnim tenantem MUSI mit dokazane,
    protoze se nedaji "vyzkouset":
      - druhy beh nad stejnymi daty neudela nic (idempotence),
      - s -WhatIf se nezapise ani jeden zapis,
      - retry se opakuje jen na 429/5xx, ne na 403.

    Vyzaduje Pester 5 nebo novejsi.
#>

BeforeAll {
    . $PSScriptRoot/Sync-CourseList.ps1

    function Get-PnPListItem { param($List, $PageSize, $Identity) }
    function Add-PnPListItem { param($List, $Values) }
    function Set-PnPListItem { param($List, $Identity, $Values) }

    # Pomocnik: napodobi PnP polozku, ktera ma hodnoty ve FieldValues.
    function New-FakeItem {
        param([int]$Id, [hashtable]$Fields)
        [pscustomobject]@{ Id = $Id; FieldValues = $Fields }
    }
}

Describe 'Get-ChangedField' {

    It 'najde zmenene pole' {
        $existing = New-FakeItem -Id 1 -Fields @{ ExternalId = 'A'; Title = 'Stary' }
        Get-ChangedField -Existing $existing -Values @{ Title = 'Novy' } | Should -Be @('Title')
    }

    It 'shodna hodnota neni zmena' {
        $existing = New-FakeItem -Id 1 -Fields @{ Title = 'Stejny' }
        @(Get-ChangedField -Existing $existing -Values @{ Title = 'Stejny' }).Count | Should -Be 0
    }

    It 'null v cili a prazdny retezec ve zdroji NENI zmena' {
        # Bez tohoto pravidla by skript nikdy nebyl idempotentni: SharePoint vraci
        # nevyplnene textove pole jako $null, ze zdroje casto prijde ''.
        $existing = New-FakeItem -Id 1 -Fields @{ Note = $null }
        @(Get-ChangedField -Existing $existing -Values @{ Note = '' }).Count | Should -Be 0
    }

    It 'porovnava jen pole, ktera zdroj posila' {
        # Pole, ktera ve zdroji nejsou, se nesmi hlasit jako zmena - jinak by
        # sync prepisoval data, ktera nema na starosti.
        $existing = New-FakeItem -Id 1 -Fields @{ Title = 'X'; JinePole = 'nedotykat' }
        @(Get-ChangedField -Existing $existing -Values @{ Title = 'X' }).Count | Should -Be 0
    }
}

Describe 'Sync-CourseList - parovani a idempotence' {

    BeforeEach {
        Mock Add-PnPListItem {}
        Mock Set-PnPListItem {}
    }

    It 'novou polozku vytvori' {
        Mock Get-PnPListItem { @() }

        $result = @(Sync-CourseList -SourceItem @([pscustomobject]@{ ExternalId = 'A'; Title = 'Prvni' }) `
            -ListName 'Zakazky' -KeyField 'ExternalId')

        $result[0].Action | Should -Be 'Created'
        Should -Invoke Add-PnPListItem -Times 1 -Exactly
    }

    It 'zmenenou polozku aktualizuje a rekne, ktere pole' {
        Mock Get-PnPListItem { @( New-FakeItem -Id 7 -Fields @{ ExternalId = 'A'; Title = 'Stary' } ) }

        $result = @(Sync-CourseList -SourceItem @([pscustomobject]@{ ExternalId = 'A'; Title = 'Novy' }) `
            -ListName 'Zakazky' -KeyField 'ExternalId')

        $result[0].Action  | Should -Be 'Updated'
        $result[0].Changed | Should -Contain 'Title'
        Should -Invoke Set-PnPListItem -Times 1 -Exactly
    }

    It 'IDEMPOTENCE: druhy beh nad stejnymi daty nezapise nic' {
        Mock Get-PnPListItem { @( New-FakeItem -Id 7 -Fields @{ ExternalId = 'A'; Title = 'Stejny' } ) }

        $result = @(Sync-CourseList -SourceItem @([pscustomobject]@{ ExternalId = 'A'; Title = 'Stejny' }) `
            -ListName 'Zakazky' -KeyField 'ExternalId')

        $result[0].Action | Should -Be 'Unchanged'
        Should -Not -Invoke Add-PnPListItem
        Should -Not -Invoke Set-PnPListItem
    }

    It 'paruje podle klice, ne podle poradi' {
        # Kdyby se parovalo podle poradi nebo indexu, obracene poradi zdroje
        # by zpusobilo dva zbytecne updaty. Test to zafixuje.
        Mock Get-PnPListItem {
            @(
                New-FakeItem -Id 1 -Fields @{ ExternalId = 'A'; Title = 'Aaa' }
                New-FakeItem -Id 2 -Fields @{ ExternalId = 'B'; Title = 'Bbb' }
            )
        }

        $result = @(Sync-CourseList -ListName 'Zakazky' -KeyField 'ExternalId' -SourceItem @(
            [pscustomobject]@{ ExternalId = 'B'; Title = 'Bbb' }
            [pscustomobject]@{ ExternalId = 'A'; Title = 'Aaa' }
        ))

        @($result | Where-Object Action -eq 'Unchanged').Count | Should -Be 2
        Should -Not -Invoke Set-PnPListItem
    }

    It 'polozku v cili, kterou zdroj nezna, hlasi jako Orphan a NEMAZE' {
        Mock Get-PnPListItem { @( New-FakeItem -Id 9 -Fields @{ ExternalId = 'Z'; Title = 'Osirela' } ) }
        Mock Remove-PnPListItem {}

        $result = @(Sync-CourseList -SourceItem @() -ListName 'Zakazky' -KeyField 'ExternalId')

        $result[0].Action | Should -Be 'Orphan'
        Should -Not -Invoke Remove-PnPListItem
    }

    It 'zdrojovou polozku bez klice hlasi jako Failed, nepreskoci ji tise' {
        Mock Get-PnPListItem { @() }

        $result = @(Sync-CourseList -SourceItem @([pscustomobject]@{ ExternalId = ''; Title = 'Bezklice' }) `
            -ListName 'Zakazky' -KeyField 'ExternalId')

        $result[0].Action | Should -Be 'Failed'
        $result[0].Error  | Should -BeLike '*ExternalId*'
        Should -Not -Invoke Add-PnPListItem
    }

    It 'selhani jedne polozky nezastavi davku' {
        Mock Get-PnPListItem { @() }
        Mock Add-PnPListItem {
            param($List, $Values)
            if ($Values['ExternalId'] -eq 'B') { throw 'Neco se pokazilo' }
        }

        $result = @(Sync-CourseList -ListName 'Zakazky' -KeyField 'ExternalId' -SourceItem @(
            [pscustomobject]@{ ExternalId = 'A' }
            [pscustomobject]@{ ExternalId = 'B' }
            [pscustomobject]@{ ExternalId = 'C' }
        ))

        $result.Count | Should -Be 3
        ($result | Where-Object Key -eq 'B').Action | Should -Be 'Failed'
        @($result | Where-Object Action -eq 'Created').Count | Should -Be 2
    }
}

Describe 'Sync-CourseList - dry-run' {

    BeforeEach {
        Mock Add-PnPListItem {}
        Mock Set-PnPListItem {}
    }

    It 'S -WHATIF NEZAPISE ANI JEDEN ZAPIS' {
        # Nejcennejsi test celeho souboru: kontroluje samotny bezpecnostni
        # mechanismus. Odpovida na otazku "a jak vite, ze vam -WhatIf funguje?".
        Mock Get-PnPListItem { @( New-FakeItem -Id 1 -Fields @{ ExternalId = 'A'; Title = 'Stary' } ) }

        Sync-CourseList -ListName 'Zakazky' -KeyField 'ExternalId' -WhatIf -SourceItem @(
            [pscustomobject]@{ ExternalId = 'A'; Title = 'Novy' }
            [pscustomobject]@{ ExternalId = 'B'; Title = 'Uplne novy' }
        ) | Out-Null

        Should -Not -Invoke Add-PnPListItem
        Should -Not -Invoke Set-PnPListItem
    }

    It 's -WhatIf presto rekne, co by se stalo' {
        # Dry-run, ktery nic nevypise, je k nicemu - clovek potrebuje videt plan.
        Mock Get-PnPListItem { @() }

        $result = @(Sync-CourseList -SourceItem @([pscustomobject]@{ ExternalId = 'A' }) `
            -ListName 'Zakazky' -KeyField 'ExternalId' -WhatIf)

        $result[0].Action | Should -Be 'Created'
    }
}

Describe 'Invoke-WithRetry - klasifikace chyb' {

    BeforeEach {
        # Bez tohoto mocku by testy retry cekaly realne sekundy. Cas je jedina
        # vec, kterou v unit testu mockovat MUSITE - jinak nikdo testy nepousti.
        Mock Start-Sleep {}
    }

    It 'opakuje 429' {
        $script:calls = 0
        $result = Invoke-WithRetry -MaxRetry 3 -Action {
            $script:calls++
            if ($script:calls -lt 3) { throw 'Request failed with 429 Too Many Requests' }
            'hotovo'
        }

        $result       | Should -Be 'hotovo'
        $script:calls | Should -Be 3
    }

    It 'opakuje 503' {
        $script:calls = 0
        Invoke-WithRetry -MaxRetry 3 -Action {
            $script:calls++
            if ($script:calls -lt 2) { throw 'Service returned 503' }
            'ok'
        } | Out-Null

        $script:calls | Should -Be 2
    }

    It 'NEOPAKUJE 403 - opakovat "nemas pravo" nema smysl' {
        $script:calls = 0
        { Invoke-WithRetry -MaxRetry 3 -Action {
            $script:calls++
            throw 'Request failed with 403 Forbidden'
        } } | Should -Throw

        $script:calls | Should -Be 1
    }

    It 'NEOPAKUJE 404' {
        $script:calls = 0
        { Invoke-WithRetry -MaxRetry 3 -Action { $script:calls++; throw '404 Not Found' } } |
            Should -Throw

        $script:calls | Should -Be 1
    }

    It 'po vycerpani pokusu chybu vyhodi' {
        $script:calls = 0
        { Invoke-WithRetry -MaxRetry 2 -Action { $script:calls++; throw '429 Too Many Requests' } } |
            Should -Throw

        # Prvni pokus + 2 opakovani.
        $script:calls | Should -Be 3
    }
}
