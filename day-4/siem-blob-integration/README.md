# SIEM integrace přes Azure Blob

> Typ: povinný · Den: 4 · Odhad: 45 min výklad + 75 min lab

## Cíle
- Logovací strategie: schéma, minimalizace PII, retence.
- Pipeline: app › Blob › Event Grid › Function › SIEM.
- Náklady a spolehlivost (batching, retry, dead-letter).
- KQL základy pro validaci a dashboardy.

## Výklad

### Logovací schéma a minimalizace PII
Strukturované (JSON) logy s konzistentním schématem — usnadňuje pozdější KQL dotazy i
transformace. PII (UPN, e-maily, jména) minimalizovat na zdroji, ne až v SIEM — hash nebo
pseudonymizovat identifikátory tam, kde plná hodnota není nutná k analýze. Retence logů se
řeší nezávisle na retenci zdrojových dat (viz [`../../day-3/lifecycle-compliance/`](../../day-3/lifecycle-compliance/)) — jiné compliance požadavky.

### Pipeline: aplikace → Blob → Event Grid → Function → SIEM
Novější verze Blob Storage rozšíření pro Azure Functions (5.x+) používají **Event Grid event
subscription** na containeru místo pollingu — funkce se spustí prakticky okamžitě při
změně, ne až při dalším pollovacím cyklu. Toto vyžaduje **general-purpose v2 storage
account**; na **Flex Consumption** plánu, na kterém jede kurzovní prostředí, není Event Grid
varianta volitelná optimalizace — Flex Consumption **podporuje výhradně event-based verzi
Blob triggeru**, polling na něm neexistuje.

Pro zápis do Log Analytics/Sentinel workspace slouží **Logs Ingestion API** — REST rozhraní,
které umí zapisovat do standardních i vlastních (custom) tabulek přes **Data Collection Rule
(DCR)**. DCR může navíc obsahovat KQL transformaci aplikovanou na data **před** uložením —
filtrování irelevantních záznamů, obohacení, maskování citlivých údajů přímo v ingest cestě,
ne až dodatečně v dotazech.

### Náklady a spolehlivost
Workspace se zapnutým Sentinelem **není** předmětem Azure Monitor ingestion filtering
poplatku bez ohledu na to, kolik dat transformace odfiltruje — cenová výhoda oproti čistému
Log Analytics workspace. Spolehlivost pipeline: batching (méně Function invocations za
stejný objem dat), retry s exponenciálním backoffem (viz [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/) klasifikace chyb), dead-letter
queue pro zprávy, které trvale selhávají — nezacyklit retry donekonečna.

### KQL základy
KQL dotaz je řetězec operátorů propojených `|` (pipe) — čistě read-only, bez úpravy dat.
Jazyk je **case-sensitive** (názvy tabulek, sloupců, operátorů). Základní operátory pro
validaci ingestu: `where` (filtr), `project` (výběr sloupců), `summarize` (agregace) —
dostatečné pro ověření "dorazila data, mají očekávaný tvar" a jednoduché dashboardy.

```mermaid
flowchart LR
  A[Aplikace: log event] --> B[Azure Blob Storage]
  B -->|Event Grid subscription| C[Azure Function]
  C -->|Logs Ingestion API + DCR| D[Log Analytics / Sentinel]
  D -->|KQL| E[Dashboard / validace]
  C -.trvalé selhání.-> F[Dead-letter]
```

## Klíčové rozlišení
- **Blob polling (starší, zpožděné) vs Event Grid subscription (novější, téměř okamžité)** —
  Flex Consumption podporuje výhradně druhou variantu.
- **Transformace v DCR (před uložením, KQL) vs transformace až v dotazu** — první šetří
  úložný prostor a skrývá PII už při zápisu.
- **Retry (transientní selhání, viz [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/)) vs dead-letter (trvalé selhání, needs review)**.

## Lab
Viz [`lab-siem-ingest-blueprint.md`](lab-siem-ingest-blueprint.md).

## Demo
[`demo-sentinel-incident.md`](demo-sentinel-incident.md) — 20 min uvnitř labu: analytics
rule nad tabulkou, kterou lab právě naplnil, a z nálezu **incident**. Ukazuje hranici,
u které lab jinak končí: **log odpovídá na otázku, kterou položíte; SIEM se ptá sám.**

## Zdroje (Microsoft)
- [Tutorial: Trigger Azure Functions on blob containers using an event subscription](https://learn.microsoft.com/en-us/azure/azure-functions/functions-event-grid-blob-trigger) — „The Flex Consumption plan only supports the event-based version of the Blob Storage trigger."
- [Flex Consumption plan](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan)
- [Logs Ingestion API in Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-ingestion-api-overview)
- [Custom data ingestion and transformation in Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/data-transformation)
- [Kusto Query Language (KQL) overview](https://learn.microsoft.com/en-us/kusto/query/?view=microsoft-fabric)

## Stav produktu / delta
- Ověřit k datu běhu — Logs Ingestion API už od 31. 3. 2024 nevyžaduje samostatný Data
  Collection Endpoint (DCE), stačí `logsIngestion` vlastnost DCR; ověřit, že aktuální verze
  nástrojů/dokumentace v labu s tímto počítá, ne se staršími DCE-first postupy.
