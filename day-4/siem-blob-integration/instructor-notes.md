# Instructor notes — SIEM integrace přes Azure Blob

## Timing

- 45 min výklad + 75 min lab (nejnáročnější lab dne — víc služeb propojených dohromady).

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že Storage Account per student je **general-purpose v2** — jinak Event Grid trigger
  nepůjde nastavit a lab spadne na starší polling chování.
- **Log Analytics workspace musí existovat před kurzem — není součástí M365 tenantu ani
  Consumption plánu.** Doporučená varianta: **jeden sdílený workspace pro celý kurz
  a samostatná DCR per student** — izolaci dat to zajistí, 25 workspaců se neplatí
  a cleanup je jeden resource. Založit spolu se zbytkem Azure rozsahu
  (viz [`../../environment.md`](../../environment.md)), ne ad-hoc ve čtvrtek.
- **Ověřit, že student má na DCR i workspace roli, která stačí na zápis** (Monitoring
  Metrics Publisher na DCR). Contributor na vlastní resource group nestačí, pokud
  workspace leží mimo ni — což u sdíleného workspacu leží.
- **Budget alert na subscription je u tohoto bloku povinný.** Log Analytics se účtuje po
  objemu ingestovaných dat; zacyklená Function nebo chybná DCR umí utrhnout účet způsobem,
  na který zbytek D4 rozsahu (Consumption plán) není schopný.
- Ověřit aktuální DCR konfiguraci (`logsIngestion` vlastnost bez nutnosti DCE) na demo
  prostředí den předem.

## Tripwires

- Nezaměňovat Event Grid-based trigger (5.x+ rozšíření) se starším polling-based Blob
  triggerem — na Consumption plánu je Event Grid varianta nutná, ne volitelná optimalizace.
- Zdůraznit pseudonymizaci PII **před** zápisem (v transformu), ne jako dodatečný krok —
  v ověření labu kontrolovat cílovou tabulku, ne jen mezikrok.
- KQL je case-sensitive — časté drobné chyby v názvech sloupců/tabulek u začátečníků.
- **Ingest do Log Analytics má latenci.** Po zápisu přes Logs Ingestion API se záznamy
  v tabulce neobjeví okamžitě — u custom tabulky počítat s několika minutami, u první
  ingesce do nově založené tabulky i déle. Studenti to hlásí jako „nefunguje to";
  říct to dřív, než se první ruka zvedne, a nechat je mezitím napsat KQL dotaz.

## Vazby

- Dopředu: logging/retry vzory se shrnují v `performance-cost-capstone`.
- Zpět: navazuje na Function skeleton z [`../azure-integration-patterns/`](../azure-integration-patterns/) a retry/error klasifikaci z [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/).
