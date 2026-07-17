# Instructor notes — Skladba migrací

## Timing

- 45 min výklad + 75 min lab (nejdelší lab dne — wave plánování vyžaduje diskuzi, ne jen kód).

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že `New-MigrationSeedData.ps1` naplnil fiktivní weby s dostatečně rozmanitou
  velikostí/rizikem, aby wave plánování mělo reálný smysl (ne 15 identických webů).
- Připravit alespoň jeden web s dostatkem položek, aby demonstrace list view threshold
  (5000) byla reálně viditelná.

## Tripwires

- Studenti řadí weby "podle abecedy" nebo "podle toho, co je hotové první" — explicitně
  vyžadovat zdůvodnění pořadí vln vázané na riziko/velikost/závislosti.
- Nezaměňovat list view threshold (limit na dotaz) s limitem velikosti listu (list může mít
  miliony položek) — časté nepochopení, které vede ke špatným doporučením pro zákazníky.
- Připomenout retention/eDiscovery hold jako důvod, proč se verze nemusí ořezat bez ohledu na
  nastavený limit — týmy na toto často zapomínají při odhadu objemu migrace.

## Vazby

- Dopředu: wave planning je přímý vstup do capstone (M5.3, end-to-end blueprint migrace).
- Zpět: navazuje na throttle/retry klasifikaci z M2.1 a baseline/diff koncept z M2.2
  (předmigrační kontrola = diff zdroje proti očekávanému stavu).
