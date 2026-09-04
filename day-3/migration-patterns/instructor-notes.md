# Instructor notes — Skladba migrací

## Timing

- 45 min výklad + 105 min lab (druhý velký lab kurzu, nejdelší blok dne — plán v JSON
  vyžaduje diskuzi, exekuce má reálné čekací časy).

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Nainstalovat desktop SPMT na učební stroje předem** (PS modul se instaluje s klientem,
  není v PowerShell Gallery) a ověřit dostupnost Windows PowerShell 5.1 vedle PS7.
- **Připravit zdrojový fileshare** na učebních strojích (`C:\MigrationSource\...`) —
  fiktivní struktura oddělení/typů dokumentů, dost souborů, aby report počtů dával smysl
  (řádově stovky, ne 5). Distribuovat přes image učebny nebo kopírovací skript.
- Projít celý flow (JSON → knihovny → SPMT pilot → metadata → report) den předem na
  testovacím účtu — SPMT verze se mění a instalace umí přepsat PS modul.
- Ověřit, že studenti mají weby `-dev/-test/-prod` z D1 labu — kdo nedokončil, potřebuje
  je doprovisionovat před blokem (viz [`../../scripts/`](../../scripts/)).
- Připravit alespoň jeden web s dostatkem položek, aby demonstrace list view threshold
  (5000) byla reálně viditelná.

## Tripwires

- **Přepínání shellů je záměrná lekce, ale i past**: SPMT kroky = Windows PowerShell 5.x,
  PnP kroky (knihovny, metadata) = PS7. Studenti reflexivně jedou vše v jednom okně —
  mít na slidu, které kroky patří do kterého shellu, a nechat obě okna otevřená vedle sebe.
- Trvat na tom, že plán je JEDINÝ zdroj parametrů — jakmile se v kroku 6 objeví úprava
  kódu místo změny parametru, návrh plánu byl špatně (tvrdá kontrola v ověření).
- Studenti řadí vlny "podle abecedy" — vyžadovat zdůvodnění vázané na riziko/velikost/závislosti.
- Metadata dávkově (`New-PnPBatch`), ne per-item smyčkou — při stovkách položek je rozdíl
  viditelný na čase; nechat schválně jednoho studenta změřit obojí, pokud čas dovolí.
- Nezaměňovat list view threshold (limit na dotaz) s limitem velikosti listu — časté
  nepochopení vedoucí ke špatným doporučením pro zákazníky. Podklad:
  [`../../day-2/graph-fundamentals/explainer-large-lists.md`](../../day-2/graph-fundamentals/explainer-large-lists.md).
- Otázka „a co naše stará řešení?" přijde skoro vždy — Add-iny a ACS jsou v M365 vypnuté
  od 2. 4. 2026, **v on-premises ale běží dál**, takže migrace je typicky odhalí. Nenechat
  se stáhnout do dlouhé debaty; mapa a otázky do assessmentu jsou v
  [`explainer-legacy-layers.md`](explainer-legacy-layers.md).
- Migrovaný obsah zapsaný app-only identitou nese v `Author`/`Editor` **jméno aplikace**,
  ne původního autora — nástroje to řeší zvlášť; zaznít to má dřív, než se na to někdo
  zeptá po cutoveru.
- Připomenout retention/eDiscovery hold jako důvod, proč se verze nemusí ořezat bez ohledu
  na nastavený limit — u fileshare zdroje nerelevantní (nemá verze), ale při SP→SP migraci
  je to hlavní položka odhadu objemu.
- U 3rd-party nástrojů (ShareGate a spol.) neuvádět konkrétní rychlosti/ceny z paměti —
  marketingová čísla, viz currency marker v [`explainer-migration-tools.md`](explainer-migration-tools.md).

## Vazby

- Dopředu: JSON plán + exekuce je přímý vstup do capstone ([`../../day-5/performance-cost-capstone/`](../../day-5/performance-cost-capstone/),
  end-to-end blueprint); knihovny s metadaty z tohoto labu jsou zdroj/cíl pro plánovaný
  sync task v [`../../day-4/azure-integration-patterns/`](../../day-4/azure-integration-patterns/).
- Zpět: navazuje na throttle/retry klasifikaci z [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/), baseline/diff z
  [`../../day-2/staging-environments/`](../../day-2/staging-environments/) (předmigrační kontrola) a weby + cert identitu z
  [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).
