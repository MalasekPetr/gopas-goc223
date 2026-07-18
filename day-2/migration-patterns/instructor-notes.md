# Instructor notes — Skladba migrací

## Timing

- 45 min výklad + 75 min lab (nejdelší lab dne — wave plánování vyžaduje diskuzi, ne jen kód).

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že `New-MigrationSeedData.ps1` naplnil fiktivní weby s dostatečně rozmanitou
  velikostí/rizikem, aby wave plánování mělo reálný smysl (ne 15 identických webů).
- Připravit alespoň jeden web s dostatkem položek, aby demonstrace list view threshold
  (5000) byla reálně viditelná.
- Pro volitelný SPMT krok: **nainstalovat desktop SPMT na učební stroje předem** (PS modul
  se instaluje s klientem, není v PowerShell Gallery) a ověřit, že Windows PowerShell 5.1
  je na strojích dostupný vedle PS7. Připravit malý lokální file share (pár složek/souborů)
  jako zdroj.

## Tripwires

- Studenti řadí weby "podle abecedy" nebo "podle toho, co je hotové první" — explicitně
  vyžadovat zdůvodnění pořadí vln vázané na riziko/velikost/závislosti.
- Nezaměňovat list view threshold (limit na dotaz) s limitem velikosti listu (list může mít
  miliony položek) — časté nepochopení, které vede ke špatným doporučením pro zákazníky.
- Připomenout retention/eDiscovery hold jako důvod, proč se verze nemusí ořezat bez ohledu na
  nastavený limit — týmy na toto často zapomínají při odhadu objemu migrace.
- SPMT krok spouštět z Windows PowerShell 5.x — studenti ho reflexivně pustí v PS7 a modul
  se nenačte; mít na slidu vedle příkazů. U 3rd-party nástrojů (ShareGate a spol.) neuvádět
  konkrétní rychlosti/ceny z paměti — marketingová čísla, viz currency marker v explaineru.

## Vazby

- Dopředu: wave planning je přímý vstup do capstone ([`../../day-5/performance-cost-capstone/`](../../day-5/performance-cost-capstone/), end-to-end blueprint migrace).
- Zpět: navazuje na throttle/retry klasifikaci z [`../graph-fundamentals/`](../graph-fundamentals/) a baseline/diff koncept z [`../staging-environments/`](../staging-environments/)
  (předmigrační kontrola = diff zdroje proti očekávanému stavu).
