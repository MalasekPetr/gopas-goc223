# Explainer · PSScriptAnalyzer a Pester: proč je automatizace instaluje

Doplněk k [`README.md`](README.md), sekci o `tasks.json`. Oba moduly jste nainstalovali
v [`../toolchain-setup/`](../toolchain-setup/) a zapojili do `lint` a `test` úlohy —
tady je důvod, proč.

## Rámec: nemáte rollback

Vývojář aplikace má luxus, který vy ne. Nasadí, kouká na chyby, rolluje zpět. **Skript,
který smaže špatných 200 webů, rollback nemá** — záloha SharePointu není `Ctrl+Z`.
Migrace, která přepíše metadata, se nedá „nasadit znovu, ale lépe".

Z toho plyne věta, na které oba nástroje stojí:

> **Celý rozpočet na kvalitu musíte utratit před prvním reálným spuštěním.**

A přesně na to jsou — každý na jinou polovinu problému.

| | PSScriptAnalyzer | Pester |
|---|---|---|
| Otázka | **Je to napsané správně?** | **Dělá to správnou věc?** |
| Kdy | čte skript, **nespouští** ho | spustí vaši logiku proti falešným datům |
| Najde | anti-patterny, chybějící `-WhatIf`, hesla v kódu | špatný filtr, chybnou retry větev, neidempotentní běh |
| Nenajde | logickou chybu v korektně napsaném kódu | to, na co nikdo nenapsal test |

## PSScriptAnalyzer — statická analýza

**Čte skript, ale nespouští ho.** To je celá jeho hodnota: u skriptu, který maže weby,
chcete nástroj, který řekne, že je něco špatně, **než ho jednou pustíte**.

Je to sada pravidel. Vypsat si je můžete sami — a je to lepší než jakýkoli seznam v kurzu,
protože pravidla přibývají:

```powershell
Get-ScriptAnalyzerRule | Select-Object RuleName, Severity | Sort-Object Severity
Invoke-ScriptAnalyzer -Path ./scripts -Recurse
```

Pravidla mají **severity** (`Error` / `Warning` / `Information`) a výchozí stav — část je
vypnutá a musíte si ji zapnout. Pro automatizaci nad produkčním tenantem jsou nejcennější:

| Pravidlo | Proč právě tohle |
|---|---|
| `UseShouldProcessForStateChangingFunctions` | funkce `Remove-*` / `Set-*` / `New-*` **bez podpory `-WhatIf`** je nález — dry-run disciplína kurzu vynucená strojem |
| `UseSupportsShouldProcess`, `ShouldProcess` | dvě sousední pravidla: deklarovat `SupportsShouldProcess` a pak ho **skutečně použít** |
| `AvoidUsingConvertToSecureStringWithPlainText` | severity **Error** — heslo v kódu převedené na „secure" string není secure |
| `AvoidUsingPlainTextForPassword`, `AvoidUsingUsernameAndPasswordParams` | totéž o vrstvu výš, u parametrů funkce |
| `AvoidUsingComputerNameHardcoded` | severity **Error**; přímý průmět pravidla „žádné identifikátory natvrdo" |
| `AvoidUsingEmptyCatchBlock` | `catch {}` je nejtišší způsob, jak přijít o chybu, kterou budete hledat týden |
| `AvoidUsingWriteHost` | `Write-Host` píše na obrazovku a nikam jinam — výstup, který nejde poslat do `Export-Csv` ani zachytit v CI, není výstup, ale dekorace |
| `AvoidUsingCmdletAliases` | `?`, `%`, `gci` fungují ve vaší konzoli; ve skriptu, který po vás bude někdo čítat za rok, jsou to hádanky |

> [!IMPORTANT] Prefix `PS` v názvech
> Dokumentace uvádí pravidla **bez** prefixu (`AvoidUsingWriteHost`), ale
> `Invoke-ScriptAnalyzer` je ve výstupu hlásí **s** prefixem (`PSAvoidUsingWriteHost`).
> Obojí je správné jméno téhož pravidla — jen když ho budete hledat v docs, hledejte
> bez `PS`.

### Nenápadně nejužitečnější pravidla pro tento kurz

`UseCompatibleSyntax` a `UseCompatibleCmdlets` umí zkontrolovat skript **proti konkrétní
verzi PowerShellu**. Ve světě, kde se PS7 potkává s Windows PowerShellem 5.1 (migrační
nástroje, viz [`../../day-3/migration-patterns/explainer-migration-tools.md`](../../day-3/migration-patterns/explainer-migration-tools.md)),
je to způsob, jak zjistit, že skript na cílovém stroji nepojede — **bez toho stroje**.
Obě jsou ve výchozím stavu **vypnutá**, takže si je musíte zapnout v nastavení.

Nastavení pravidel patří do souboru, který se **commitne do repa**. Tím se z „my to tak
píšeme" stane standard platný i pro kolegu a pro pipeline.

## Pester — testy pro skripty

Tady přijde otázka, kterou dostane každý admin: **„jak mám testovat skript, jehož celá
práce je změnit živý tenant?"**

Odpověď je jedno slovo: **mock**. Podstrčíte falešný cmdlet.

```powershell
Describe 'Get-MigrationWave' {
  It 'vynecha weby, ktere uz jsou zmigrovane' {
    Mock Get-PnPTenantSite {
      @(
        [pscustomobject]@{ Url = 'https://t.sharepoint.com/sites/a'; Migrated = $true  }
        [pscustomobject]@{ Url = 'https://t.sharepoint.com/sites/b'; Migrated = $false }
      )
    }

    $wave = Get-MigrationWave -Batch 1
    $wave.Url | Should -Be 'https://t.sharepoint.com/sites/b'
  }
}
```

Žádný tenant se nedotkl. Testuje se **vaše rozhodovací logika**, ne Microsoftovo API —
to funguje, na to testy nepotřebujete.

### Co se v automatizaci reálně vyplatí testovat

- **Výběr a filtry** — obsahuje vlna to, co má? A hlavně: **neobsahuje to, co nemá?**
  Filtr `-like "*-dev"` vezme i `sites/legacy-dev` a v produkci to zjistíte pozdě.
- **Chybové větve** — retry na `429`, žádný retry na `404`
  ([`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/)). Tuhle logiku
  v produkci nevyzkoušíte na přání; s mockem ano.
- **Idempotence** — druhý běh nesmí udělat nic. Test to ověří za sekundu, ruční zkouška
  za půl hodiny.
- **Že se destruktivní cesta nespustila**, když neměla:

```powershell
It 'pri -WhatIf nic nemaze' {
  Mock Remove-PnPTenantSite {}
  Invoke-Cleanup -WhatIf
  Should -Not -Invoke Remove-PnPTenantSite
}
```

Tenhle test kontroluje **samotný bezpečnostní mechanismus** — je to nejcennější test,
jaký v automatizaci můžete napsat, a odpovídá na otázku „a jak víte, že vám `-WhatIf`
opravdu funguje?". `Should -Invoke` umí i `-Times`, `-Exactly` a `-ParameterFilter`,
takže lze tvrdit i „zavolalo se to právě jednou a právě s tímto webem".

Druhá hodnota přijde později: až budete po půl roce přepisovat 500řádkový migrační skript,
testy jsou to jediné, co vám řekne, že jste nic nerozbili.

> [!IMPORTANT] Pester 5+, ne 4
> `Should -Invoke` / `Should -Not -Invoke` je syntaxe **Pesteru 5 a novějších**
> (k 2026-09 je aktuální Pester 6, syntaxe zůstává). Starší
> `Assert-MockCalled` z Pesteru 4 najdete v polovině příkladů na internetu — a v Pesteru 5
> je to zastaralá cesta. Souvisí to i s tripwirem z instalace: Windows má předinstalovanou
> Pester 3.4.0 a bez `-SkipPublisherCheck` se novější verze nenainstaluje.

## Proč potřebujete oba

Nejsou to alternativy, chytají různé věci:

- Analyzer projde skript, kde `Remove-PnPTenantSite` **nemá** `-WhatIf` → nález.
  Pester by to nepoznal, kdyby na to nikdo test nenapsal.
- Pester odhalí, že filtr bere o jeden web víc → nález. Analyzer to poznat **nemůže**,
  ten kód je syntakticky bezvadný.

Stručně: **Analyzer hlídá, jak je to napsané. Pester hlídá, co to udělá.**

A obojí patří do `tasks.json`, ne jen do editoru — v CI žádný editor neběží
([`README.md`](README.md)).

## Klíčové rozlišení

- **Statická analýza vs test** — první čte kód, druhý ho spouští. Skript, který se nesmí
  omylem spustit, potřebuje obojí, ale statická analýza je ta, která funguje první.
- **Testovat vlastní logiku vs testovat API** — mock existuje proto, abyste netestovali
  Microsoft. Test, který volá živý tenant, není unit test, ale zkouška v produkci.
- **Severity vs výchozí stav pravidla** — `Error` pravidlo může být vypnuté
  (`UseCompatibleSyntax`) a `Warning` pravidlo vždy zapnuté. Zapnutá sada je rozhodnutí
  týmu, které se commituje.
- **Nález lintu vs selhaný test** — první říká „takhle se to nepíše", druhý „takhle to
  nefunguje". Obojí zastaví merge, ale opravuje se jinak.

## Zdroje (Microsoft)

- [List of PSScriptAnalyzer rules](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme)
- [Using PSScriptAnalyzer (nastavení, potlačení pravidel)](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer)
- [Invoke-ScriptAnalyzer](https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/invoke-scriptanalyzer)
- [Everything you wanted to know about ShouldProcess](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-shouldprocess)
- [Pester — Should](https://pester.dev/docs/commands/Should) a [Mock](https://pester.dev/docs/commands/Mock) (pester.dev, ne Microsoft)
- Funkční ukázka mockování v tomto kurzu: [`../../day-2/powershell-deep-dive/solution/Connect-CourseTarget.Tests.ps1`](../../day-2/powershell-deep-dive/solution/Connect-CourseTarget.Tests.ps1)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Seznam pravidel PSScriptAnalyzeru **roste a mění se jim výchozí stav** — proto je v tomto
> souboru `Get-ScriptAnalyzerRule` jako primární zdroj a tabulka výše jen jako výběr.
> U Pesteru ověřit, že se na kurzovních strojích načítá **verze 5+**, ne předinstalovaná
> 3.4.0 — jinak `Should -Invoke` neexistuje a příklady výše selžou.
