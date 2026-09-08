# Instructor notes — SIEM integrace přes Azure Blob

## Timing

- 45 min výklad + 75 min lab (nejnáročnější lab dne — víc služeb propojených dohromady).
- Uvnitř labu **20 min instruktorské demo** [`demo-sentinel-incident.md`](demo-sentinel-incident.md)
  (ingest → incident). Beze změny agendy; spouštět ve chvíli, kdy mají studenti data
  v tabulce a čekají na ověření.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že Storage Account per student je **general-purpose v2** — event subscription na
  Azure Storage ji vyžaduje. Na Flex Consumption **není kam sestoupit**: polling-based Blob
  trigger na tomto plánu neexistuje, takže bez GPv2 lab nemá jak nastartovat.
- **Ověřit dostupnost Flex Consumption ve zvoleném regionu.** Plán nepokrývá všechny regiony
  a v nepodporovaném se v portálu ani nezobrazí — `New-CourseStudentAzureResources.ps1` pak
  skončí chybou, kterou nikdo nečeká. Sestup na (legacy) Consumption plán **není fallback**,
  protože by změnil trigger model celého labu.
- **Vyzkoušet celou cestu k systémovému klíči `blobs_extension`** (Function App -> App keys
  -> System keys). Endpoint URL pro Event Grid subscription se skládá ručně a je to
  nejfiddly krok labu; navíc ho po vytvoření subscription nejde změnit.
- **Log Analytics workspace musí existovat před kurzem — není součástí M365 tenantu ani
  Flex Consumption plánu.** Doporučená varianta: **jeden sdílený workspace pro celý kurz
  a samostatná DCR per student** — izolaci dat to zajistí, 25 workspaců se neplatí
  a cleanup je jeden resource. Založit spolu se zbytkem Azure rozsahu
  (viz [`../../environment.md`](../../environment.md)), ne ad-hoc ve čtvrtek.
- **Ověřit, že student má na DCR i workspace roli, která stačí na zápis** (Monitoring
  Metrics Publisher na DCR). Contributor na vlastní resource group nestačí, pokud
  workspace leží mimo ni — což u sdíleného workspacu leží.
- **Budget alert na subscription je u tohoto bloku povinný.** Log Analytics se účtuje po
  objemu ingestovaných dat; zacyklená Function nebo chybná DCR umí utrhnout účet způsobem,
  na který zbytek D4 rozsahu (Flex Consumption) není schopný.
- Ověřit aktuální DCR konfiguraci (`logsIngestion` vlastnost bez nutnosti DCE) na demo
  prostředí den předem.
- **Sentinel zapnout nad kurzovním workspacem těsně před během, ne dřív.** Trial je
  **10 GB/den zdarma po 31 dní** a běží od zapnutí — kdo ho zapne měsíc dopředu, má na
  kurzu placený provoz. Limit je 20 workspaců na tenant; při opakovaných bězích ze stejného
  workspacu druhý běh zdarma nebude.
- **Pokud se má ukazovat varianta nad reálnou SharePoint aktivitou**: připojit Microsoft 365
  konektor **na začátku kurzu** (první nasazení trvá 2–3 h, než se cokoli objeví) a nechat
  studenty vytvořit anonymní sdílený odkaz už **ve dni 3**. Audit logy mají latenci 60–90 min
  bez SLA — akce udělaná ve čtvrtek se ve čtvrtek nezobrazí.
- **Mít v záloze incident z předchozího běhu.** Čekání u projektoru na naplánované spuštění
  pravidla je nejhorší možné využití dvaceti minut.

## Tripwires

- Nezaměňovat Event Grid-based trigger (5.x+ rozšíření) se starším polling-based Blob
  triggerem — na Flex Consumption je Event Grid varianta **jediná podporovaná**, ne volitelná
  optimalizace. Polling-based varianta na tomto plánu neexistuje.
- Zdůraznit pseudonymizaci PII **před** zápisem (v transformu), ne jako dodatečný krok —
  v ověření labu kontrolovat cílovou tabulku, ne jen mezikrok.
- **`FUNCTIONS_WORKER_RUNTIME` se na Flex Consumption nepodporuje.** Kdo publikuje projekt
  z VS Code a nahraje local settings tak, jak jsou, dostane selhání na nastavení, které bylo
  na starším plánu povinné. Před `Upload Local Settings...` ten záznam z `local.settings.json`
  odstranit. Non-C# aplikace navíc na Flex Consumption **musí** mít v `host.json`
  extension bundle verze `[4.0.0, 5.0.0)` nebo novější — bez toho Event Grid Blob trigger
  není k dispozici.
- KQL je case-sensitive — časté drobné chyby v názvech sloupců/tabulek u začátečníků.
- **Ingest do Log Analytics má latenci.** Po zápisu přes Logs Ingestion API se záznamy
  v tabulce neobjeví okamžitě — u custom tabulky počítat s několika minutami, u první
  ingesce do nově založené tabulky i déle. Studenti to hlásí jako „nefunguje to";
  říct to dřív, než se první ruka zvedne, a nechat je mezitím napsat KQL dotaz.

## Cleanup po kurzu

- **Odebrání Sentinelu neodstraní Log Analytics workspace** ani jeho účtování — jsou to
  dva samostatné kroky. Ve cleanup checklistu je nutné mít oba.
- Analytics rules a incidenty zůstávají ve workspacu; při opakovaném běhu buď smazat,
  nebo vědomě nechat jako připravenou zálohu pro demo (viz go/no-go).

## Vazby

- Dopředu: logging/retry vzory se shrnují v `performance-cost-capstone`.
- Zpět: navazuje na Function skeleton z [`../azure-integration-patterns/`](../azure-integration-patterns/) a retry/error klasifikaci z [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/).
