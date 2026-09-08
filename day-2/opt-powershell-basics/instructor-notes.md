# Instructor notes — PowerShell základy (volitelný blok)

## Timing

- 40 min výklad + 20 min cvičení. **Hard stop na 60 minutách** — viz tripwires.
- Den 2 je bez tohoto bloku na 4,0 h, s ním na 5,0 h. Prostor tedy je; nebezpečí není
  v rozpočtu dne, ale v tom, že se blok rozteče.

## Rozhodnutí, jestli blok pustit

Tohle je jediný blok v kurzu, o kterém se rozhoduje **až během běhu**. Rozhodovat se má
podle labu bloku 1, ne podle dojmu z představování.

**Signály, že blok pustit:**

- Student u labu bloku 1 nedokáže přečíst výstup `Get-MgServicePrincipalAppRoleAssignment`
  a hledá „kde je ta tabulka".
- Objeví se dotaz typu „jak z toho dostanu jen ten jeden sloupec".
- Někdo kopíruje příkazy, ale nedokáže je upravit na vlastní hodnoty.

**Signály, že blok NEpouštět:**

- Skupina sama zkracuje příkazy aliasy a používá `Where-Object` bez pobídky.
- Nikdo se neptá na výstupy, jen na oprávnění a auth.

Pokud je skupina rozdělená, pustit blok **pro všechny** a rychleji. Nechat polovinu
skupiny odejít na pauzu je horší varianta: kdo základy má, ztratí hodinu, ale kdo je
nemá a nedostane je, ztratí celý týden.

## Go/no-go — otestovat před během

- **Projít celé cvičení na učebním stroji.** Běží lokálně, takže jediné riziko je
  chybějící `Get-Service` na jiné platformě než Windows — pro ten případ je ve cvičení
  fallback.
- Ověřit, že `Get-Help Stop-Process -Parameter WhatIf` na stroji vrací nápovědu, ne
  hlášku o chybějícím helpu. Pokud ano, spustit `Update-Help` (běží dlouho, ne před
  skupinou).
- Nachystat si výstup `Get-Process | Get-Member` na druhé obrazovce — je dlouhý a hledat
  v něm live před skupinou zdržuje.

## Tripwires

- **Největší riziko bloku není čas, ale rozsah.** Kdo začne vysvětlovat funkce, moduly,
  classes a remoting, skončí u dvou hodin a den 2 se rozsype. Blok má **jediný cíl**:
  aby student dokázal přečíst, co mu cmdlet vrátil. Všechno ostatní je mimo rozsah —
  a je legitimní odpovědět „to je samostatný kurz" a jít dál.
- **Nepřednášet historii ani porovnání s bashem víc než dvě minuty.** Diagram v `README.md`
  ten kontrast pokrývá; delší odbočka nikomu nepomůže napsat příkaz.
- **Krok 5 cvičení nechat studenty odpovědět dřív, než ho spustí.** Ta past (`Select-Object`
  vyhodí vlastnost, podle které chcete filtrovat) je nastražená schválně a její hodnota je
  v tom, že si na ni přijdou sami. Když ji rovnou vysvětlíte, zbude z ní jedna informace
  místo návyku.
- **Nezapomenout na `Get-Member` jako návyk, ne jako cmdlet.** Pokud si skupina odnese
  jednu věc, má to být „u neznámého výstupu se nejdřív zeptám, co to je".
- Aliasy (`?`, `%`, `select`) v ukázkách nepoužívat. Ve skriptech kurzu nikde nejsou
  a pro začátečníka jsou to jen další neznámé znaky.

## Vazby

- **Dopředu:** celý zbytek týdne. Bezprostředně blok 3 dne 2
  ([`../powershell-deep-dive/`](../powershell-deep-dive/)), který předpokládá čtení
  výstupů jako hotovou věc.
- *Filter left* z tohoto bloku je vstupní intuice pro throttling a velké seznamy
  v [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/).
- Past s unwrappingem polí a non-terminating chybami se v kurzu objeví znovu jako
  **komentáře v referenčních řešeních**
  ([`../powershell-deep-dive/solution/Connect-CourseTarget.ps1`](../powershell-deep-dive/solution/Connect-CourseTarget.ps1),
  [`../../day-4/azure-integration-patterns/solution/Sync-CourseList.ps1`](../../day-4/azure-integration-patterns/solution/Sync-CourseList.ps1))
  — dobré je na to při výkladu ukázat, ať student ví, že to není teorie.
- `-WhatIf` jako návyk navazuje na disciplínu „report-only před remediací" z
  [`../../day-4/lifecycle-compliance/`](../../day-4/lifecycle-compliance/).

> [!NOTE] Proč blok existuje (2026-09-08)
> Přidán po reálném běhu dne 2. Kurz je cílený na pokročilé SPO adminy a inženýry migrací,
> ale reálná skupina se v základech jazyka rozpadla na dvě části. Bez tohoto bloku se pro
> slabší polovinu nedá odučit blok 3 — a ztratit je druhý den znamená ztratit je na celý
> týden. Zůstává **volitelný** právě proto, že u silné skupiny je to hodina navíc bez přínosu.
