<#
.SYNOPSIS
    Definuje Sync-CourseList - idempotentni davkovy sync seznamu ze zdrojovych dat,
    s podporou -WhatIf.

.DESCRIPTION
    Referencni reseni labu 'lab-batch-sync-task.md' (Lab 3).

    Pouziti:
        . ./Sync-CourseList.ps1
        Sync-CourseList -SourceItem $data -ListName 'Zakazky' -KeyField 'ExternalId' -WhatIf

.NOTES
    Kurz GOC223 - day-4/azure-integration-patterns
    Unit testy: Sync-CourseList.Tests.ps1
#>

Set-StrictMode -Version Latest

function Sync-CourseList {
    <#
    .SYNOPSIS
        Sesynchronizuje seznam v SharePointu se zdrojovymi daty. Idempotentne.

    .DESCRIPTION
        Tri vlastnosti, ktere z davkoveho skriptu delaji neco, co se smi pustit
        na plan:

        1. IDEMPOTENCE. Druhy beh nad stejnymi daty neudela nic. Dosahuje se toho
           tim, ze se polozky paruji podle KLICE, ne podle poradi nebo poctu, a
           update se posila jen kdyz se nejake pole skutecne lisi.

        2. DRY-RUN. SupportsShouldProcess dava -WhatIf zdarma. Kdo pousti davku
           poprve na produkci bez -WhatIf, dela chybu, kterou uz nelze vzit zpet.

        3. RETRY JEN NA SPRAVNE CHYBY. 429 a 5xx se opakuji s respektem k hlavicce
           Retry-After, 4xx mimo 429 se NEOPAKUJI - opakovat "nemas pravo" nema
           smysl a jen to prodlouzi beh. Klasifikace chyb je z
           day-2/graph-fundamentals.

        Skript nic nemaze. Polozky, ktere jsou v seznamu a nejsou ve zdroji, jen
        hlasi jako 'Orphan' - smazani je samostatne rozhodnuti, ktere ma videt
        clovek. Automaticke mazani podle zdroje, ktery se zkratka nenacetl cely,
        je nejrychlejsi cesta ke ztrate dat.

    .PARAMETER SourceItem
        Zdrojove objekty. Kazdy musi mit pole uvedene v -KeyField.

    .PARAMETER ListName
        Cilovy seznam.

    .PARAMETER KeyField
        Pole, podle ktereho se paruje zdroj s cilem. Musi byt v obou.

    .PARAMETER FieldMap
        Hashtable zdrojove pole -> cilove pole. Bez nej se prenasi pole se stejnymi
        nazvy jako v KeyField objektu.

    .PARAMETER MaxRetry
        Kolikrat opakovat po transientni chybe. Vychozi 3.

    .EXAMPLE
        Sync-CourseList -SourceItem $rows -ListName 'Zakazky' -KeyField 'ExternalId' -WhatIf

        Dry-run: vypise, co by se stalo, a nic nezmeni.

    .EXAMPLE
        $result = Sync-CourseList -SourceItem $rows -ListName 'Zakazky' -KeyField 'ExternalId'
        $result | Group-Object Action | Select-Object Name, Count

        Ostry beh a souhrn akci.

    .OUTPUTS
        PSCustomObject: Key, Action (Created|Updated|Unchanged|Orphan|Failed),
        Changed (seznam zmenenych poli), Error.

    .NOTES
        NEOTESTOVANO PROTI ZIVEMU TENANTU. Overena je logika parovani, detekce zmen,
        idempotence, klasifikace chyb a dodrzeni -WhatIf; skutecna volani zavisi na
        seznamu a opravnenich.
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]] $SourceItem,

        [Parameter(Mandatory)]
        [string] $ListName,

        [Parameter(Mandatory)]
        [string] $KeyField,

        [hashtable] $FieldMap,

        [ValidateRange(0, 10)]
        [int] $MaxRetry = 3
    )

    # --- Nacteni cile ------------------------------------------------------
    # Cilovy stav se cte JEDNIM dotazem a indexuje do hashtable. Alternativa
    # "pro kazdou zdrojovou polozku se zeptej, jestli existuje" je O(n) dotazu
    # a nad par tisici polozkami to je rozdil mezi minutami a hodinami.

    $existing = @{}
    foreach ($item in @(Invoke-WithRetry -MaxRetry $MaxRetry -Action {
                Get-PnPListItem -List $ListName -PageSize 500 -ErrorAction Stop })) {

        $key = $item.FieldValues[$KeyField]
        if ($key) { $existing[[string]$key] = $item }
    }

    Write-Verbose "V seznamu '$ListName' je $($existing.Count) polozek s vyplnenym klicem."

    $seenKeys = [System.Collections.Generic.HashSet[string]]::new()

    # --- Zdroj -> cil ------------------------------------------------------

    foreach ($source in $SourceItem) {

        $key = [string] $source.$KeyField

        if ([string]::IsNullOrWhiteSpace($key)) {
            # Polozka bez klice se neda sparovat. Preskocit ji tise by znamenalo,
            # ze se ztrati bez zaznamu - proto se hlasi jako Failed.
            [pscustomobject]@{
                Key = $null; Action = 'Failed'; Changed = @()
                Error = "Zdrojova polozka nema vyplnene pole '$KeyField'."
            }
            continue
        }

        [void] $seenKeys.Add($key)
        $values = Get-MappedValue -Source $source -FieldMap $FieldMap -KeyField $KeyField

        try {
            if (-not $existing.ContainsKey($key)) {

                if ($PSCmdlet.ShouldProcess("$ListName / $key", 'Vytvorit polozku')) {
                    Invoke-WithRetry -MaxRetry $MaxRetry -Action {
                        Add-PnPListItem -List $ListName -Values $values -ErrorAction Stop
                    } | Out-Null
                }

                [pscustomobject]@{ Key = $key; Action = 'Created'; Changed = @($values.Keys); Error = $null }
            }
            else {
                # Zavorky @() jsou nutne, ne kosmetika. PowerShell pri vraceni
                # z funkce rozbaluje pole: prazdne pole se vrati jako $null
                # a jednoprvkove jako ten jediny prvek. Nasledne $changed.Count
                # by pak pod Set-StrictMode spadlo - a bez strict mode by to
                # tise "fungovalo" jen pro dve a vic zmenenych poli.
                $changed = @(Get-ChangedField -Existing $existing[$key] -Values $values)

                if ($changed.Count -eq 0) {
                    # Jadro idempotence: zadna zmena znamena ZADNE volani.
                    # Bez teto vetve by druhy beh poslal update na kazdou polozku -
                    # coz je technicky "nic se nezmenilo", ale prakticky zbytecne
                    # tisice zapisu, throttling a nepouzitelna verzovaci historie.
                    [pscustomobject]@{ Key = $key; Action = 'Unchanged'; Changed = @(); Error = $null }
                }
                else {
                    if ($PSCmdlet.ShouldProcess("$ListName / $key", "Aktualizovat pole: $($changed -join ', ')")) {
                        Invoke-WithRetry -MaxRetry $MaxRetry -Action {
                            Set-PnPListItem -List $ListName -Identity $existing[$key].Id `
                                -Values $values -ErrorAction Stop
                        } | Out-Null
                    }

                    [pscustomobject]@{ Key = $key; Action = 'Updated'; Changed = $changed; Error = $null }
                }
            }
        }
        catch {
            # Selhani jedne polozky nesmi zastavit davku. Zaznam s Action=Failed
            # je to, co po behu resi clovek.
            [pscustomobject]@{ Key = $key; Action = 'Failed'; Changed = @(); Error = $_.Exception.Message }
        }
    }

    # --- Orphans -----------------------------------------------------------
    # Polozky v cili, ktere zdroj nezna. NEMAZOU se - jen se hlasi.

    foreach ($key in $existing.Keys) {
        if (-not $seenKeys.Contains($key)) {
            [pscustomobject]@{ Key = $key; Action = 'Orphan'; Changed = @(); Error = $null }
        }
    }
}

function Get-MappedValue {
    <#
    .SYNOPSIS
        Prevede zdrojovy objekt na hashtable hodnot pro PnP cmdlety.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] $Source,
        [hashtable] $FieldMap,
        [Parameter(Mandatory)][string] $KeyField
    )

    $values = @{}

    if ($FieldMap -and $FieldMap.Count -gt 0) {
        foreach ($sourceField in $FieldMap.Keys) {
            $values[$FieldMap[$sourceField]] = $Source.$sourceField
        }
    }
    else {
        foreach ($property in $Source.PSObject.Properties) {
            $values[$property.Name] = $property.Value
        }
    }

    # Klic musi byt ve values vzdy, jinak by nove vytvorena polozka nesla
    # pri dalsim behu sparovat a vznikaly by duplikaty.
    if (-not $values.ContainsKey($KeyField)) {
        $values[$KeyField] = $Source.$KeyField
    }

    return $values
}

function Get-ChangedField {
    <#
    .SYNOPSIS
        Vrati nazvy poli, ktera se v cili skutecne lisi od zdroje.

    .DESCRIPTION
        Vlastni funkce, aby se na porovnani dal napsat test. Prazdna hodnota
        a $null se povazuji za totez - SharePoint vraci nevyplnene textove pole
        jako $null, kdezto ze zdroje casto prijde prazdny retezec, a hlasit
        to jako zmenu by znamenalo, ze skript nikdy neni idempotentni.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] $Existing,
        [Parameter(Mandatory)][hashtable] $Values
    )

    $changed = @()

    foreach ($field in $Values.Keys) {
        $old = $Existing.FieldValues[$field]
        $new = $Values[$field]

        $oldEmpty = ($null -eq $old) -or ($old -is [string] -and [string]::IsNullOrEmpty($old))
        $newEmpty = ($null -eq $new) -or ($new -is [string] -and [string]::IsNullOrEmpty($new))

        if ($oldEmpty -and $newEmpty) { continue }

        if ([string]$old -ne [string]$new) { $changed += $field }
    }

    return $changed
}

function Invoke-WithRetry {
    <#
    .SYNOPSIS
        Spusti akci a po TRANSIENTNI chybe ji zkusi znovu.

    .DESCRIPTION
        Klasifikace z day-2/graph-fundamentals:
          - 429 a 5xx  = transientni, opakovat
          - 4xx krome 429 = permanentni, NEOPAKOVAT

        Opakovat "403 nemas pravo" nema smysl: odpoved bude stejna, jen to
        prodlouzi beh a zvysi zatez sluzby. Prodleva respektuje hlavicku
        Retry-After, kdyz ji sluzba poslala - pevny Start-Sleep je horsi
        odhad nez cislo, ktere vam sluzba sama dala.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock] $Action,
        [int] $MaxRetry = 3
    )

    for ($attempt = 0; $attempt -le $MaxRetry; $attempt++) {
        try {
            return & $Action
        }
        catch {
            $status = Get-StatusCode -ErrorRecord $_

            $transient = ($status -eq 429) -or ($status -ge 500 -and $status -le 599)

            if (-not $transient -or $attempt -eq $MaxRetry) { throw }

            $delay = Get-RetryDelaySecond -ErrorRecord $_ -Attempt $attempt
            Write-Verbose "Transientni chyba $status, pokus $($attempt + 1)/$MaxRetry, cekam $delay s."
            Start-Sleep -Seconds $delay
        }
    }
}

function Get-StatusCode {
    <#
    .SYNOPSIS
        Vytahne HTTP status z chybove zpravy nebo z vyjimky.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param([Parameter(Mandatory)] $ErrorRecord)

    if ($ErrorRecord.Exception.PSObject.Properties.Name -contains 'Response' -and
        $ErrorRecord.Exception.Response) {
        $code = $ErrorRecord.Exception.Response.StatusCode
        if ($code) { return [int] $code }
    }

    # Fallback: cast modulu status jen napise do zpravy.
    $match = [regex]::Match([string]$ErrorRecord.Exception.Message, '\b(4\d{2}|5\d{2})\b')
    if ($match.Success) { return [int] $match.Value }

    return 0
}

function Get-RetryDelaySecond {
    <#
    .SYNOPSIS
        Vrati prodlevu pred dalsim pokusem - z Retry-After, jinak exponencialne.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)] $ErrorRecord,
        [int] $Attempt = 0
    )

    try {
        $headers = $ErrorRecord.Exception.Response.Headers
        if ($headers) {
            $retryAfter = $headers['Retry-After']
            if ($retryAfter) { return [int] $retryAfter }
        }
    }
    catch {
        Write-Verbose "Retry-After se necetl, pouzivam exponencialni backoff: $($_.Exception.Message)"
    }

    return [math]::Pow(2, $Attempt)
}
