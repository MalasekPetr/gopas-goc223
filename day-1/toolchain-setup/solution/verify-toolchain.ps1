<#
.SYNOPSIS
    Overi, ze na stroji je kompletni toolchain pro kurz GOC223, a rekne, co chybi.

.DESCRIPTION
    Referencni reseni labu 'lab-toolchain-verify.md', cast D.

    Skript projde vsechny polozky toolchainu, u kazde zjisti nalezenou verzi
    a porovna ji proti minimu. Nespadne na prvni chybejici polozce - vzdy projde
    vsechno a vrati souhrn, takze student po jednom spusteni vi, co vse musi
    doinstalovat.

    Vystup jsou OBJEKTY, ne text na obrazovku:
      - da se poslat do Export-Csv nebo ConvertTo-Json,
      - da se filtrovat (Where-Object Status -ne 'OK'),
      - a projde PSScriptAnalyzerem (pravidlo AvoidUsingWriteHost).
    Citelny souhrn jde do warning streamu, ne do vystupu - proto se nemicha s daty.

    Exit kod je 0, kdyz je vsechno v poradku, a 1, kdyz cokoli chybi nebo je
    prilis stare. Diky tomu se skript da pouzit jako krok v CI pipeline.

.PARAMETER MinPowerShellVersion
    Minimalni verze PowerShellu. Default 7.4.0, protoze PnP.PowerShell nizsi nenacte.

.PARAMETER MinNodeVersion
    Minimalni verze Node.js. Default 18.0.0 podle CLI for Microsoft 365 v11.
    Pro negativni test z labu sem docasne dejte 99.0.0.

.PARAMETER MinPesterVersion
    Minimalni verze Pesteru. Default 5.0.0 a NENI to formalita: Windows ma
    predinstalovanou Pester 3.4.0, ve ktere neexistuje syntaxe 'Should -Invoke',
    kterou kurz uci. Bez teto kontroly by skript ohlasil OK na stroji,
    kde testy z kurzu nepobezi.

.PARAMETER Quiet
    Potlaci citelny souhrn ve warning streamu. Vraci jen objekty a exit kod -
    vhodne pro CI, kde souhrn cte stroj, ne clovek.

.EXAMPLE
    ./verify-toolchain.ps1

    Overi toolchain a vypise tabulku vcetne prikazu pro doinstalovani.

.EXAMPLE
    ./verify-toolchain.ps1 | Where-Object Status -ne 'OK' | Format-List

    Jen problemy, s celym prikazem k oprave.

.EXAMPLE
    ./verify-toolchain.ps1 -MinNodeVersion 99.0.0

    Negativni test z labu: musi ohlasit nesoulad, navrhnout prikaz
    a skoncit nenulovym exit kodem.

.OUTPUTS
    PSCustomObject se sloupci Category, Name, Required, Found, Status, FixCommand.

.NOTES
    Kurz GOC223 - day-1/toolchain-setup
    U vetsiny modulu se zamerne NEPINUJE verze: tenhle skript overuje, ze clovek
    ma cim pracovat (globalni nastroj). Konkretni verze, na ktere stoji dany skript,
    patri do repa toho skriptu pres #Requires - viz 'Tri vrstvy, ktere se pletou'
    v README modulu.

    Vyjimkou je Pester. Windows ma predinstalovanou verzi 3.4.0 a ta se pri kontrole
    "je modul k dispozici?" tvari jako splneny pozadavek - jenze syntaxe, kterou kurz
    uci (Should -Invoke), v ni neexistuje. Pravidlo tedy zni: pinovat tam, kde
    STARA verze na stroji uz je a mlcky by prosla, ne "pro poradek".
#>

[CmdletBinding()]
param(
    [version] $MinPowerShellVersion = '7.4.0',
    [version] $MinNodeVersion       = '18.0.0',
    [version] $MinPesterVersion     = '5.0.0',
    [switch]  $Quiet
)

Set-StrictMode -Version Latest

#region Pomocne funkce

function Get-VersionFromText {
    <#
    .SYNOPSIS
        Vytahne prvni verzi ve tvaru X.Y(.Z) z libovolneho textu.
    .DESCRIPTION
        Kazdy nastroj hlasi verzi jinak:
          git   -> "git version 2.43.0.windows.1"
          node  -> "v22.11.0"
          m365  -> "v11.4.0"
        Regex je proto spolehlivejsi nez parsovani podle formatu jednotlivych nastroju.
        Vraci $null, kdyz v textu zadna verze neni - volajici to musi umet zpracovat.
    #>
    param([string] $Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }

    $match = [regex]::Match($Text, '\d+\.\d+(\.\d+)?')
    if (-not $match.Success) { return $null }

    try   { return [version] $match.Value }
    catch { return $null }   # napr. "1.2.3.4.5" - nevalidni [version]
}

function New-ToolchainResult {
    <#
    .SYNOPSIS
        Slozi jeden radek vysledku. Jedno misto, kde se rozhoduje o Status.
    .NOTES
        Potlaceni pravidla nize: PSScriptAnalyzer oznaci kazdou funkci New-*, ktera
        nepodporuje -WhatIf (UseShouldProcessForStateChangingFunctions). Tady je to
        falesny nalez - funkce jen sklada objekt v pameti a nic nemeni, takze -WhatIf
        by nemelo co potlacit. Pravidlo se proto nevypina globalne, jen se na jednom
        miste zdokumentuje vyjimka. Atribut patri NA param() blok, ne pred klicove
        slovo function - tam ho parser odmitne.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Funkce vraci objekt v pameti, nemeni zadny stav.'
    )]
    param(
        [Parameter(Mandatory)][string] $Category,
        [Parameter(Mandatory)][string] $Name,
        [version] $Required,
        [version] $Found,
        [Parameter(Mandatory)][string] $FixCommand
    )

    # Poradi podminek je zamerne: nejdriv "chybi", pak "je stare".
    # Student pak nedostane matouci "prilis stara verze" u neceho,
    # co na stroji vubec neni.
    $status = if     ($null -eq $Found)                       { 'Missing'  }
              elseif ($Required -and $Found -lt $Required)    { 'TooOld'   }
              else                                            { 'OK'       }

    [pscustomobject]@{
        Category   = $Category
        Name       = $Name
        Required   = if ($Required) { $Required.ToString() } else { '(jakakoli)' }
        Found      = if ($Found)    { $Found.ToString()    } else { '(nenalezeno)' }
        Status     = $status
        FixCommand = if ($status -eq 'OK') { '' } else { $FixCommand }
    }
}

function Test-ExternalTool {
    <#
    .SYNOPSIS
        Overi nastroj na PATH (git, node, npm, m365).
    .DESCRIPTION
        Get-Command se SilentlyContinue je tu proto, aby chybejici nastroj
        neshodil cely skript - to je pozadavek z labu. Volani samotneho nastroje
        je jeste v try/catch, protoze existujici soubor na PATH muze pri spusteni
        selhat (rozbita instalace, chybejici runtime).
    #>
    param(
        [Parameter(Mandatory)][string] $Command,
        [string]  $VersionArgument = '--version',
        [version] $Required,
        [Parameter(Mandatory)][string] $FixCommand
    )

    $found = $null

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        try {
            # 2>&1 proto, ze cast nastroju hlasi verzi na stderr.
            $output = & $Command $VersionArgument 2>&1 | Out-String
            $found  = Get-VersionFromText -Text $output
        }
        catch {
            Write-Verbose "Nastroj '$Command' je na PATH, ale spusteni selhalo: $($_.Exception.Message)"
        }
    }

    New-ToolchainResult -Category 'Nastroj' -Name $Command `
        -Required $Required -Found $found -FixCommand $FixCommand
}

function Test-PowerShellModule {
    <#
    .SYNOPSIS
        Overi pritomnost PowerShell modulu a vrati jeho nejvyssi nainstalovanou verzi.
    .DESCRIPTION
        -ListAvailable hleda v PSModulePath, takze modul nemusi byt naimportovany.
        Vedle sebe muze byt verzi vic; bere se nejvyssi.
    #>
    param(
        [Parameter(Mandatory)][string] $Name,
        [version] $Required,
        [string]  $FixCommand
    )

    $found = Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue |
             Sort-Object Version -Descending |
             Select-Object -First 1 -ExpandProperty Version

    if (-not $FixCommand) {
        $FixCommand = "Install-Module $Name -Scope CurrentUser -Force"
    }

    New-ToolchainResult -Category 'Modul' -Name $Name `
        -Required $Required -Found $found -FixCommand $FixCommand
}

#endregion

#region Kontroly

$results = [System.Collections.Generic.List[object]]::new()

# --- Runtime -----------------------------------------------------------------

# PowerShell se nezjistuje pres externi prikaz: bezi prave v nem,
# takze $PSVersionTable je presnejsi i rychlejsi.
$results.Add(
    (New-ToolchainResult -Category 'Runtime' -Name 'PowerShell' `
        -Required $MinPowerShellVersion -Found $PSVersionTable.PSVersion `
        -FixCommand 'winget install --id Microsoft.PowerShell --source winget')
)

$results.Add(
    (Test-ExternalTool -Command 'git' `
        -FixCommand 'winget install --id Git.Git --source winget')
)

$results.Add(
    (Test-ExternalTool -Command 'node' -Required $MinNodeVersion `
        -FixCommand 'fnm install 22; fnm default 22   # nebo: winget install --id Schniz.fnm')
)

$results.Add(
    (Test-ExternalTool -Command 'npm' `
        -FixCommand 'npm je soucasti Node - doinstalujte Node (viz radek vyse)')
)

# --- Globalni nastroj --------------------------------------------------------

$results.Add(
    (Test-ExternalTool -Command 'm365' `
        -FixCommand 'npm install -g @pnp/cli-microsoft365')
)

# --- Moduly ------------------------------------------------------------------
# Poradi odpovida labu. Bez minimalnich verzi zamerne - viz .NOTES.

foreach ($module in @(
    'PnP.PowerShell'
    'Microsoft.Graph'
    'Microsoft.Online.SharePoint.PowerShell'
    'PSScriptAnalyzer'
)) {
    $results.Add((Test-PowerShellModule -Name $module))
}

# Pester ma minimum a vlastni fix prikaz: -SkipPublisherCheck je nutny proto,
# ze predinstalovana Pester 3.4.0 je podepsana Microsoftem a bez toho prepinace
# instalace novejsi verze selze na neshode vydavatele.
$results.Add(
    (Test-PowerShellModule -Name 'Pester' -Required $MinPesterVersion `
        -FixCommand 'Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck')
)

#endregion

#region Souhrn a exit kod

$problems = @($results | Where-Object Status -ne 'OK')

if (-not $Quiet) {
    if ($problems.Count -eq 0) {
        Write-Warning 'Toolchain je kompletni. Vsech 10 polozek OK.'
    }
    else {
        Write-Warning "Toolchain NENI kompletni - problemu: $($problems.Count) z $($results.Count)."
        foreach ($problem in $problems) {
            Write-Warning ("  [{0}] {1}: pozadovano {2}, nalezeno {3}" -f `
                $problem.Status, $problem.Name, $problem.Required, $problem.Found)
            Write-Warning ("      oprava: {0}" -f $problem.FixCommand)
        }
        Write-Warning 'Po instalaci OTEVRETE NOVE OKNO terminalu - jinak se zmena v PATH neprojevi.'
    }
}

# Objekty jdou do pipeline vzdy, bez ohledu na -Quiet.
$results

# Nenulovy exit kod umoznuje pouzit skript jako krok v CI.
if ($problems.Count -gt 0) { exit 1 }
exit 0

#endregion
