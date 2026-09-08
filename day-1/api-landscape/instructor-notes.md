# Instructor notes — Mapa API nad M365 a SPO

## Timing

- 25 min výklad + 20 min cvičení ([`exercise-graph-explorer.md`](exercise-graph-explorer.md)).
- **Cvičení se neškrtá.** Je to jediný hands-on moment dne 1 před
  [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/) a první okamžik, kdy student něco
  sám udělá. Při skluzu se zkracuje výklad (časová osa se dá odbýt jedním slidem), ne cvičení.
- Uvnitř cvičení se smí vypustit kroky 6-7 (Graph vs SPO REST nad jedním webem); kroky 2-4
  ne.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Ověřit consent do Graph Exploreru pro studentský účet, ne pro svůj.** Graph Explorer
  žádá o delegated permissions při prvním použití; pokud má tenant vypnutý user consent,
  student se zasekne na prvním dotazu a cvičení padá. Projít celé přihlášení testovacím
  účtem `user.NN`.
- **Projet kroky 6-7 na kurzovním tenantu** a poznamenat si konkrétní URL webu — improvizovat
  `_api/web/lists` URL před 25 lidmi je zbytečné riziko.
- Ověřit, že cvičení jde v **pracovním profilu Edge** — v osobním profilu se student
  přihlásí špatným účtem a diví se cizím datům.

## Tripwires

- **Nesklouznout do hloubky auth flows** — to je [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/);
  tady jen „všechny cesty nesou Entra token".
- **Nesklouznout do Graph batching/throttlingu** — to je [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/).
  Krok 5 cvičení (`@odata.nextLink`) je návnada na tuhle debatu; odpověď je „zítra".
- **SPO REST v prohlížeči vrátí XML, ne JSON.** Není to chyba a je to dobrý teaching point
  (starší vrstva, jiné výchozí chování). Mít odpověď připravenou, ne se jí lekat — fallback
  je v cvičení.
- U kroku 7 se skoro jistě rozjede debata „tak proč vůbec Graph, když SPO REST umí víc" —
  odpověď je konzistentní auth, jednotný tvar odpovědi napříč workloady a batching/delta.
  Utnout po dvou minutách, je to celý blok [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/).
- Časová osa mrtvých vrstev umí sežrat 15 minut nostalgie. Držet dvě ponaučení (moduly
  umírají, REST zůstává; poznat mrtvou vrstvu je dovednost pro assessment) a jít dál —
  detail je v [`../../day-3/migration-patterns/explainer-legacy-layers.md`](../../day-3/migration-patterns/explainer-legacy-layers.md).

## Vazby

- Dopředu: mapa je rozhodovací rámec pro [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/)
  (nástrojová osa) a permissions úvaha z kroku 4 cvičení pokračuje přímo v
  [`../../day-2/automation-strategy/lab-app-registration.md`](../../day-2/automation-strategy/lab-app-registration.md).
  Mrtvé vrstvy se vracejí v migračním assessmentu
  [`../../day-3/migration-patterns/`](../../day-3/migration-patterns/).
- Zpět: navazuje na onboarding (rozlišení tenant vs subscription z `environment.md`,
  pracovní profil Edge) a na hotový stroj z [`../toolchain-setup/`](../toolchain-setup/).

> [!NOTE] Změna proti dřívější verzi
> Modul byl do 2026-09 volitelný (`opt-architecture-overview`) a bez hands-on. Povýšen na
> povinný a doplněn o cvičení podle ověřeného běhu KURZ-26-07-29 — mapa API se ukázala
> jako rozhodovací rámec, na který se zbytek týdne odkazuje, ne jako doplněk.
