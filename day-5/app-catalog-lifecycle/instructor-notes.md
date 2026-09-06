# Instructor notes — App Catalog: nasazení, upgrady a audit

## Timing

- 30 min výklad + 45 min lab. Blok se zkrátil (dřív 45 + 75) vypuštěním vývojové části —
  uvolněný čas jde do rezervy dne 5, který je záměrně volnější kvůli dřívějším odchodům.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Připravit dva `.sppkg` balíčky téhož řešení, verze 1.0.0 a 1.1.0.** Tohle je jediná
  reálná příprava bloku a bez ní lab nejede. Stačí libovolný triviální webpart; studenti
  ho nesestavují ani nečtou, je to nosič životního cyklu. Vyrobit **jednou** a mít
  v instruktorském archivu — nemusí se dělat před každým během.
- **Předem povolit site collection app catalog na sandbox webech studentů.** Ne kvůli
  oprávněním (všichni jsou GA), ale kvůli **izolaci**: 25 studentů nahrávajících do jednoho
  sdíleného Tenant App Catalogu = kolize názvů a vzájemné přepisování verzí.
- **Projít API access cestu v SharePoint admin centru** — po redesignu portálu se přesouvá
  a proklikat ji poprvé před skupinou je zbytečné riziko.
- **Ověřit názvy parametrů PnP cmdletů** (`Add-PnPApp`, `Update-PnPApp`, `Get-PnPTenantServicePrincipalPermissionGrants`)
  proti [pnp.github.io/powershell](https://pnp.github.io/powershell/) — mění se mezi verzemi
  a v labu jsou napsané natvrdo.
- Ověřit, že v tenantu **existuje aspoň jeden schválený permission grant**, aby krok 7 labu
  nevracel prázdno. Když ne, schválit něco neškodného předem — prázdný výstup zabije pointu.

## Tripwires

- **`-Publish` / „trust" krok.** Nahrání bez něj vypadá jako úspěch, ale řešení nejde použít.
  Nejčastější zádrhel labu, projít ho nahlas.
- **`Update-PnPApp` je per-web.** Studenti očekávají, že nahrání nové verze do katalogu
  upgraduje všechno. Krok 5 labu je na tenhle omyl nastražený schválně — nechat je odpovědět
  dřív, než to vysvětlíte.
- **API access je nejsilnější governance pointa celého bloku.** Oprávnění visí na **jednom
  sdíleném service principalu pro celý tenant**, ne na konkrétním řešení. Kdo tohle pochopí,
  odnese si z bloku to podstatné, i kdyby zapomněl všechny cmdlety. Navazuje audit
  v [`../security-hardening/`](../security-hardening/) hned v dalším bloku.
- **Dotaz „a jak takový balíček vznikne?" padne skoro jistě.** Odpověď je věcná a krátká:
  SPFx vývoj je samostatný kurz, tenhle kurz je o automatizaci a migraci. Ukázat strukturu
  `.sppkg` (je to zip) jako dvouminutovou zajímavost a jít dál — nezabřednout do generátoru,
  Heftu a verzí Node, což je přesně to, proč vývojová část z kurzu odešla.
- Část D (skript nad seznamem webů) je to, co blok povyšuje z klikání na automatizaci.
  Když dojde čas, radši zkrátit výklad než ji vypustit.

## Vazby

- Zpět: tenant-wide deployment mechanismus (Tenant Wide Extensions, `skipFeatureDeployment`)
  studenti poprvé viděli v [`../../day-4/clarity-configuration/`](../../day-4/clarity-configuration/) —
  tady se ukáže obecný případ, jehož konkrétní instancí Clarity byla.
- Dopředu: audit permission grants z části C labu pokračuje přímo v
  [`../security-hardening/`](../security-hardening/); `Get-AppInventory.ps1` je použitelný
  artefakt do capstone blueprintu
  ([`../performance-cost-capstone/`](../performance-cost-capstone/)).

> [!NOTE] Změna rozsahu (2026-09-06)
> Blok se jmenoval `spfx-fundamentals` a učil i vývoj SPFx. Vývojová část vypuštěna z kurzu.
> **Odpadlo tím celé go/no-go o verzové vazbě Node ↔ generátor a rozhodnutí Heft vs Gulp** —
> historicky nejkřehčí bod dne 5.
