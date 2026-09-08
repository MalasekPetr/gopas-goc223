# Microsoft Graph — inženýrské základy

> Typ: povinný · Den: 3 (otvírák) · Odhad: 45 min výklad + 75 min lab

## Cíle
- Batching, delta, řízení throttlingu.
- Klasifikace chyb a retry strategie.

## Výklad

### Batching (`$batch`)
JSON batching kombinuje až 20 jednotlivých requestů do jednoho HTTP volání
(`POST /$batch`) a snižuje počet round-tripů. Odpověď má vlastní pole `responses` s
individuálním status kódem pro každý dílčí request — **HTTP 200 na úrovni batch odpovědi
neznamená, že uspěly všechny dílčí requesty**. Každý request v batchi se navíc vyhodnocuje
proti throttling limitům samostatně; pokud jeden překročí limit, vrátí se 429 jen pro něj,
zbytek batch odpovědi může být v pořádku.

### Delta query
Delta query (`delta()`) je pull model pro inkrementální synchronizaci — server vrací jen
entity vytvořené/změněné/smazané od posledního volání, ne plný re-scan. Odpověď obsahuje buď
`@odata.nextLink` (další stránka téhož požadavku, se `skipToken`) nebo `@odata.deltaLink`
(uložit a použít při příštím inkrementálním dotazu, obsahuje `deltatoken`). Delta query je
protiklad k push modelu change notifications (webhooks) z [`../../day-4/azure-integration-patterns/`](../../day-4/azure-integration-patterns/) — different účel: delta = "co se
změnilo od X", webhook = "informuj mě hned, až se něco změní".

### Throttling (429) — řízení
Graph vrací HTTP 429 s hlavičkou `Retry-After` v sekundách — to číslo je závazné, ne
orientační. Nezkracovat, nezkoušet dřív "pro jistotu" — předčasný retry throttling jen
prodlouží. Pokud `Retry-After` chybí, použít exponenciální backoff. Graph SDK už mají vestavěné
retry handlery řešící `Retry-After` nebo výchozí backoff politiku — ne psát vlastní retry smyčku
od nuly, pokud SDK toto řeší.

### Klasifikace chyb a retry strategie
Chybový objekt Graphu má strojově čitelnou vlastnost `code` — kód programu se má vázat na ni,
ne na text `message` (ten se může kdykoli změnit). `innererror` může obsahovat vnořené, přesnější
kódy — projít je všechny a použít nejkonkrétnější, kterému aplikace rozumí. Ke každému requestu
přidat vlastní `client-request-id` (GUID) — usnadní to dohledání requestu při hlášení problému
Microsoftu. 429 a 5xx (transient) → retry s backoff; ostatní 4xx (permanentní, např. 403/404)
→ neretryovat, logovat jako chybu k řešení, ne jako throttling.

```mermaid
flowchart TD
  A[Request] --> B{Status kód}
  B -->|200/201| C[OK]
  B -->|429| D[Počkat Retry-After, pak retry]
  B -->|5xx| E[Exponenciální backoff, retry]
  B -->|jiné 4xx| F[Neretryovat, logovat jako chybu]
```

### Velké seznamy a throttling ve velkém
Throttling z Graphu je jen jedna polovina; druhou potkáte, jakmile skript opustí testovací
data. **List view threshold 5000** není strop velikosti seznamu ani throttling — je to limit
na to, kolik položek smí projít **jeden dotaz**, a v SPO se nedá zvýšit. Nástroj, jak se pod
něj vejít, je **indexovaný sloupec** (limit 20 na seznam, nelze u vícehodnotových
a počítaných sloupců). Pravidlo do praxe: **filtruj na serveru, ber po stránkách, na velký
seznam nikdy nesahej „celý"** (`Get-PnPListItem | Where-Object …` je anti-pattern).

U objemných operací proti SPO k tomu patří: paralelizací se throttlingu nezbavíte (přivoláte
ho), dávková API místo N volání (`Invoke-PnPBatch`, `$batch`), a u vlastních REST volání
**dekorovaný user agent** (`NONISV|<organizace>|<Aplikace>/1.0` — nedekorovaný provoz je
throttlován agresivněji; PnP si ho nastavuje sám). Detail, konkrétní příkazy a checklist
před spuštěním skriptu nad velkým seznamem: [`explainer-large-lists.md`](explainer-large-lists.md).

## Klíčové rozlišení
- **Batch-level 200 vs jednotlivý request status** — vždy kontrolovat `responses[].status`,
  ne jen kód celé batch odpovědi.
- **Delta query (pull, "co se změnilo") vs change notifications (push, "informuj mě hned")** —
  různé účely, viz [`../../day-4/azure-integration-patterns/`](../../day-4/azure-integration-patterns/).
- **`code` (stabilní, programově použitelný) vs `message` (lidsky čitelný, může se měnit)**
  v chybovém objektu.
- **Threshold vs throttling** — *jeden dotaz je moc velký* (chyba hned, řeší index
  a stránkování) vs *voláš moc často* (429/503 s `Retry-After`, řeší backoff a dávky).

## Lab
Viz [`lab-graph-ingest.md`](lab-graph-ingest.md).

## Tipy
- **Tahák SPO API**: [`tips-spo-api.md`](tips-spo-api.md) — jak zjistit ID webu, site
  a seznamu, definici seznamu a knihovny, **interní názvy polí** a povolené hodnoty choice
  polí (Graph / PnP / REST vedle sebe). Nepostradatelné při migračním mapování metadat.
- Dotaz nejdřív složit v Graph Exploreru, kde se chyba v `$filter` vrátí hned a čitelně;
  do skriptu přenášet až ověřenou variantu.
- Počet výsledků skriptu vždy porovnat s Graph Explorerem — skript bez `nextLink` smyčky
  selže tiše: vrátí méně dat bez jediné chybové hlášky.
- `Retry-After` číst z odpovědi; pevný `Start-Sleep -Seconds 30` je anti-pattern.

## Zdroje (Microsoft)
- [Microsoft Graph throttling guidance](https://learn.microsoft.com/en-us/graph/throttling)
- [Paging Microsoft Graph data in your app](https://learn.microsoft.com/en-us/graph/paging)
- [Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer)
- [Combine multiple HTTP requests using JSON batching](https://learn.microsoft.com/en-us/graph/json-batching)
- [Use delta query to track changes in Microsoft Graph data](https://learn.microsoft.com/en-us/graph/delta-query-overview)
- [Microsoft Graph error responses and resource types](https://learn.microsoft.com/en-us/graph/errors)

## Stav produktu / delta
- Ověřit k datu běhu — service-specific throttling limity (počet requestů/sec per aplikace/tenant)
  se liší po workloadu a mění se; ověřit aktuální hodnoty na [Microsoft Graph service-specific throttling limits](https://learn.microsoft.com/en-us/graph/throttling-limits) před demonstrací.
