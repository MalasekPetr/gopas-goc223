<#
    Unit testy ke Copy-ListContent.

    Spusteni:  Invoke-Pester ./Copy-ListContent.Tests.ps1

    U kopie s metadaty se testuje neco jineho nez "prosla". Testuje se, ze skript
    NELZE prehlednout tam, kde SharePoint tise nedodela, co jste chtel:

      - ve WriteMode Fidelity se skutecne pouzije UpdateOverwriteVersion, protoze zadny
        jiny update typ Modified/Editor nastavit neumi,
      - ve WriteMode Quiet se metadata NEPREDAVAJI vubec a rekne se to nahlas - kdyby
        se predala, SharePoint by je tise zahodil a kopie by vypadala verne,
      - cislo se do nedavkoveho zapisu dostane v americke notaci i na ceskem stroji,
      - druhy beh nezaklada druhou sadu kopii (idempotence pres business klic),
      - s -WhatIf se nezapise ani jeden zapis,
      - selhani metadat u jedne polozky neshodi celou davku.

    Vyzaduje Pester 5 nebo novejsi.
#>

BeforeAll {
    . $PSScriptRoot/Copy-ListContent.ps1

    # PnP cmdlety v testech neexistuji, takze se deklaruji jako prazdne funkce a mockuji.
    # -UpdateType je STRING, ne switch - na tom stoji polovina testu nize.
    function Get-PnPListItem { param($List, $PageSize, $Query, $Identity) }
    function Add-PnPListItem { param($List, $Values, $Folder, $Batch) }
    # Pozor: Set-PnPListItem ma JEN -UpdateType. Switch -SystemUpdate neexistuje.
    function Set-PnPListItem { param($List, $Identity, $Values, [string] $UpdateType) }

    # Pomocnik: napodobi radek tak, jak ho vraci PnP (hodnoty ve FieldValues).
    function New-FakeItem {
        param(
            [int]      $Id = 1,
            [string]   $Key = 'EV-001',
            [string]   $Title = 'Polozka',
            [double]   $Amount = 1234.56,
            [string]   $Author = 'puvodni.autor@contoso.com',
            [string]   $Editor = 'puvodni.editor@contoso.com',
            [datetime] $Created = '2019-03-14T08:30:00Z',
            [switch]   $NoKey
        )
        $fields = @{
            Title    = $Title
            Castka   = $Amount
            Created  = $Created
            Modified = $Created.AddDays(10)
            Author   = [pscustomobject]@{ Email = $Author; LookupValue = 'Puvodni Autor' }
            Editor   = [pscustomobject]@{ Email = $Editor; LookupValue = 'Puvodni Editor' }
        }
        if (-not $NoKey) { $fields['EvidencniCislo'] = $Key }
        [pscustomobject]@{ Id = $Id; FieldValues = $fields }
    }

    $script:StdArgs = @{
        SourceListTitle = 'Evidence'
        TargetListTitle = 'Evidence archiv'
        KeyField        = 'EvidencniCislo'
        DataField       = @('Title', 'Castka')
    }
}

Describe 'Format-FieldValue' {

    It 'prevede desetinne cislo do americke notace i na ceskem stroji' {
        # Tohle je ta past. Nedavkovy zapis vyzaduje tecku jako desetinny separator,
        # ale "$hodnota" na cs-CZ stroji vyrobi carku. Test proto kulturu skutecne
        # prepne - jinak by na anglickem stroji prosel i rozbity kod.
        $original = [System.Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = [cultureinfo]::GetCultureInfo('cs-CZ')
            Format-FieldValue -Value ([double] 1234.56) | Should -Be '1234.56'
        }
        finally {
            [System.Threading.Thread]::CurrentThread.CurrentCulture = $original
        }
    }

    It 'DateTime propusti jako objekt, neprevadi ho na string' {
        $value = Format-FieldValue -Value ([datetime] '2019-03-14T08:30:00Z')
        $value | Should -BeOfType [datetime]
    }

    It 'null propusti jako null' {
        Format-FieldValue -Value $null | Should -BeNullOrEmpty
    }
}

Describe 'Get-PrincipalLogin' {

    It 'preferuje Email' {
        $value = [pscustomobject]@{ Email = 'a@contoso.com'; LookupValue = 'Alfa' }
        Get-PrincipalLogin -FieldValue $value | Should -Be 'a@contoso.com'
    }

    It 'kdyz Email chybi, vezme LookupValue' {
        $value = [pscustomobject]@{ Email = ''; LookupValue = 'Alfa' }
        Get-PrincipalLogin -FieldValue $value | Should -Be 'Alfa'
    }

    It 'smazany ucet (null) neni chyba, vrati null' {
        Get-PrincipalLogin -FieldValue $null | Should -BeNullOrEmpty
    }
}

Describe 'Get-SourceItem' {

    It 'null z cmdletu nevytvori fantomovou polozku' {
        Mock Get-PnPListItem { $null }
        @(Get-SourceItem -ListTitle 'Evidence').Count | Should -Be 0
    }

    It 'prazdny seznam vrati prazdne pole' {
        Mock Get-PnPListItem { @() }
        @(Get-SourceItem -ListTitle 'Evidence').Count | Should -Be 0
    }

    It 'jednu polozku vrati jako jednoprvkove pole' {
        Mock Get-PnPListItem { New-FakeItem }
        @(Get-SourceItem -ListTitle 'Evidence').Count | Should -Be 1
    }

    It 'strankuje, nespoleha na default' {
        Mock Get-PnPListItem { @() }
        Get-SourceItem -ListTitle 'Evidence' | Out-Null
        Should -Invoke Get-PnPListItem -Times 1 -Exactly -ParameterFilter { $PageSize -eq 500 }
    }
}

Describe 'Get-TargetIndex' {

    It 'indexuje podle business klice, ne podle ID' {
        Mock Get-PnPListItem { @((New-FakeItem -Id 7 -Key 'EV-042')) }
        $index = Get-TargetIndex -ListTitle 'Evidence archiv' -KeyField 'EvidencniCislo'
        $index.ContainsKey('EV-042') | Should -BeTrue
        $index['EV-042'] | Should -Be 7
    }

    It 'polozku bez klice do indexu nedava' {
        Mock Get-PnPListItem { @((New-FakeItem -NoKey)) }
        $index = Get-TargetIndex -ListTitle 'Evidence archiv' -KeyField 'EvidencniCislo'
        $index.Count | Should -Be 0
    }
}

Describe 'Copy-ItemMetadata' {

    BeforeEach { Mock Set-PnPListItem {} }

    It 've WriteMode Fidelity pouzije UpdateOverwriteVersion - jediny typ, ktery Modified/Editor nastavit umi' {
        $item = New-FakeItem
        Copy-ItemMetadata -TargetListTitle 'Archiv' -TargetItemId 9 `
            -SourceFieldValues $item.FieldValues -WriteMode Fidelity | Should -BeTrue

        Should -Invoke Set-PnPListItem -Times 1 -Exactly -ParameterFilter {
            $UpdateType -eq 'UpdateOverwriteVersion'
        }
    }

    It 've WriteMode Fidelity preda vsechna ctyri systemova pole' {
        $item = New-FakeItem
        Copy-ItemMetadata -TargetListTitle 'Archiv' -TargetItemId 9 `
            -SourceFieldValues $item.FieldValues -WriteMode Fidelity | Out-Null

        Should -Invoke Set-PnPListItem -Times 1 -Exactly -ParameterFilter {
            $Values.ContainsKey('Created') -and $Values.ContainsKey('Modified') -and
            $Values.ContainsKey('Author') -and $Values.ContainsKey('Editor')
        }
    }

    It 'Author/Editor preda jako prihlasovaci jmeno, ne jako objekt' {
        $item = New-FakeItem -Author 'puvodni.autor@contoso.com'
        Copy-ItemMetadata -TargetListTitle 'Archiv' -TargetItemId 9 `
            -SourceFieldValues $item.FieldValues -WriteMode Fidelity | Out-Null

        Should -Invoke Set-PnPListItem -Times 1 -Exactly -ParameterFilter {
            $Values['Author'] -eq 'puvodni.autor@contoso.com'
        }
    }

    It 've WriteMode Quiet metadata NEPREDA a nahlasi to' {
        # Klicovy test celeho materialu. SystemUpdate Modified/Editor nastavit NEUMI
        # ("can not be set"). Kdyby je skript presto poslal, SharePoint by je tise
        # zahodil a kopie by vypadala verne, aniz by byla.
        $item = New-FakeItem
        $result = Copy-ItemMetadata -TargetListTitle 'Archiv' -TargetItemId 9 `
            -SourceFieldValues $item.FieldValues -WriteMode Quiet -WarningAction SilentlyContinue

        $result | Should -BeFalse
        Should -Not -Invoke Set-PnPListItem
    }

    It 've WriteMode Quiet vyda varovani, netvari se, ze je vse v poradku' {
        $item = New-FakeItem
        $warnings = @()
        Copy-ItemMetadata -TargetListTitle 'Archiv' -TargetItemId 9 `
            -SourceFieldValues $item.FieldValues -WriteMode Quiet -WarningVariable warnings `
            -WarningAction SilentlyContinue | Out-Null

        $warnings.Count | Should -BeGreaterThan 0
    }

    It 's -WhatIf nezapise nic' {
        $item = New-FakeItem
        Copy-ItemMetadata -TargetListTitle 'Archiv' -TargetItemId 9 `
            -SourceFieldValues $item.FieldValues -WriteMode Fidelity -WhatIf | Out-Null
        Should -Not -Invoke Set-PnPListItem
    }
}

Describe 'Copy-ListContent' {

    BeforeEach {
        Mock Add-PnPListItem { [pscustomobject]@{ Id = 99 } }
        Mock Set-PnPListItem {}
        # Cil je prazdny, pokud si test nerekne jinak.
        Mock Get-PnPListItem { @() } -ParameterFilter { $List -eq 'Evidence archiv' }
        Mock Get-PnPListItem { @((New-FakeItem)) } -ParameterFilter { $List -eq 'Evidence' }
    }

    It 'zkopiruje polozku a vrati vysledek s vernou metadatovou stopou' {
        $result = Copy-ListContent @script:StdArgs

        $result.Count              | Should -Be 1
        $result[0].Outcome         | Should -Be 'Copied'
        $result[0].MetadataCopied  | Should -BeTrue
        Should -Invoke Add-PnPListItem -Times 1 -Exactly
    }

    It 'cislo posle do nedavkoveho zapisu v americke notaci' {
        Copy-ListContent @script:StdArgs | Out-Null
        Should -Invoke Add-PnPListItem -Times 1 -Exactly -ParameterFilter {
            $Values['Castka'] -eq '1234.56'
        }
    }

    It 'druhy beh nezaklada druhou sadu kopii - idempotence pres business klic' {
        # Cil uz tentyz klic obsahuje.
        Mock Get-PnPListItem { @((New-FakeItem -Id 7 -Key 'EV-001')) } -ParameterFilter { $List -eq 'Evidence archiv' }

        $result = Copy-ListContent @script:StdArgs

        $result[0].Outcome | Should -Be 'Exists'
        Should -Not -Invoke Add-PnPListItem
        Should -Not -Invoke Set-PnPListItem
    }

    It 's -WhatIf neprovede ani jeden zapis' {
        $result = Copy-ListContent @script:StdArgs -WhatIf

        $result[0].Outcome | Should -Be 'WhatIf'
        Should -Not -Invoke Add-PnPListItem
        Should -Not -Invoke Set-PnPListItem
    }

    It 'polozku bez business klice preskoci a nezapise ji' {
        Mock Get-PnPListItem { @((New-FakeItem -NoKey)) } -ParameterFilter { $List -eq 'Evidence' }

        $result = Copy-ListContent @script:StdArgs -WarningAction SilentlyContinue

        $result[0].Outcome | Should -Be 'Skipped'
        Should -Not -Invoke Add-PnPListItem
    }

    It 'selhani metadat neshodi kopii - polozka zustane, jen bez verne stopy' {
        # Nejcastejsi pricina v praxi: puvodni autor neni v site user information listu cile.
        Mock Set-PnPListItem { throw 'The specified user could not be found.' }

        $result = Copy-ListContent @script:StdArgs -WarningAction SilentlyContinue

        $result[0].Outcome        | Should -Be 'Copied'
        $result[0].MetadataCopied | Should -BeFalse
    }

    It 've WriteMode Quiet polozku zkopiruje, ale bez verne stopy' {
        $result = Copy-ListContent @script:StdArgs -WriteMode Quiet -WarningAction SilentlyContinue

        $result[0].Outcome        | Should -Be 'Copied'
        $result[0].MetadataCopied | Should -BeFalse
        Should -Invoke Add-PnPListItem -Times 1 -Exactly
        Should -Not -Invoke Set-PnPListItem
    }

    It 'selhani jedne polozky nezastavi zbytek davky' {
        Mock Get-PnPListItem {
            @(
                (New-FakeItem -Id 1 -Key 'EV-001')
                (New-FakeItem -Id 2 -Key 'EV-002')
            )
        } -ParameterFilter { $List -eq 'Evidence' }

        # Prvni zapis spadne, druhy projde. Klic se do Add-PnPListItem neposila
        # (neni v DataField), takze se rozlisuje poradim, ne parametrem.
        $script:addAttempt = 0
        Mock Add-PnPListItem {
            $script:addAttempt++
            if ($script:addAttempt -eq 1) { throw 'Access denied' }
            [pscustomobject]@{ Id = 99 }
        }

        $result = Copy-ListContent @script:StdArgs -WarningAction SilentlyContinue

        $result.Count | Should -Be 2
        @($result | Where-Object { $_.Outcome -eq 'Failed' }).Count | Should -Be 1
        @($result | Where-Object { $_.Outcome -eq 'Copied' }).Count | Should -Be 1
    }

    It 'jednoprvkovy vysledek dorazi k volajicimu jako pole, ne jako skalar' {
        # Pole se pri return z funkce rozbaluje. Bez -NoEnumerate by tady .Count spadl.
        $result = Copy-ListContent @script:StdArgs
        $result.GetType().IsArray | Should -BeTrue
    }
}
