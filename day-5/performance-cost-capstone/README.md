# Výkon, náklady & capstone

> Typ: povinný · Den: 5 · Odhad: 30 min výklad + 60-120 min lab (elastický blok)

## Cíle
- Efektivita API (batching, selektivní projekce).
- Náklady logování, asynchronní fan-out vzory.
- Spočítat náklad hostování plánovaného skriptu ze živého ceníku, ne odhadem.
- Capstone: end-to-end blueprint migrace + provisioning.
- Rizika & rollback; předávka do provozu.
- Další kroky: Advanced Graph, certifikační cesty.

## Výklad

### Efektivita API
`$select` omezuje vrácené vlastnosti jen na ty, které aplikace skutečně potřebuje — snižuje
síťovou zátěž i dobu odezvy. Graph bez `$select` v odpovědi vrací tip
(`@microsoft.graph.tips`) doporučující ho použít. U resources Microsoft Entra (user, group)
je `$select` dokonce **povinný**, pokud chce aplikace vlastnosti mimo výchozí sadu. V
kombinaci s `$expand` lze `$select` aplikovat i na vnořené (expanded) položky — ale u Entra
resources `$expand` vrací max. 20 položek, což je nutné zohlednit ve stránkování. Spolu s
batchingem ([`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/)) je toto hlavní pákový bod pro snížení objemu přenášených dat a počtu
requestů.

### Náklady logování a asynchronní fan-out
Logovací náklady ([`../../day-4/siem-blob-integration/`](../../day-4/siem-blob-integration/))
rostou s objemem a granularitou. Držet je dole pomáhají dvě věci: dávkování zápisů
a transformace v Data Collection Rule (DCR) ještě **před** uložením — tedy filtrovat hned,
ne logovat všechno a filtrovat až v dotazu.
Asynchronní fan-out (jeden trigger → N paralelních dílčích úloh, např. per-web migrace v
rámci jedné vlny z [`../../day-3/migration-patterns/`](../../day-3/migration-patterns/)) škáluje propustnost, ale musí respektovat throttling limity ([`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/))
per cíl, ne jen agregátně.


### Kolik to reálně stojí: floor, grant a jediný rostoucí náklad

Kvalitativní srovnání hostingů je v
[`../../day-4/azure-integration-patterns/comparison-scheduled-runtimes.md`](../../day-4/azure-integration-patterns/comparison-scheduled-runtimes.md).
Kvantitativní protějšek je [`solution/Get-HostingCost.ps1`](solution/Get-HostingCost.ps1) —
tahá sazby živě z **Azure Retail Prices API**, což je *anonymní* endpoint: nepotřebuje
přihlášení, subscription ani token, takže se dá spustit i na stroji bez Azure přístupu.

Výsledek pro **noční skript** (30 běhů po 10 minutách, 10 MB (megabajtů) logu na běh):

| Varianta | EUR / měsíc | Proč |
|---|---|---|
| Automation Runbook | **0** | 300 min z 500 min zdarma |
| Functions Flex Consumption | **0** | 36 000 z 100 000 GB-s zdarma |
| Functions Consumption (legacy) | **0** | 36 000 z 400 000 GB-s zdarma |
| Container Apps Job | **0** | 9 000 z 180 000 vCPU-s zdarma |
| Log Analytics (ingest) | **0** | 0,3 GB z 5 GB zdarma |

**Plánovaný administrátorský skript je na hostování zdarma, a to na všech čtyřech
variantách.** To je ten teaching point: debata „Functions nebo Runbook" se u typické
noční dávky nevede o peníze, ale o determinismus runtime a strop doby běhu. Rozhodujte
podle toho, ne podle ceny.

Náklad se objeví ve dvou situacích, a jsou velmi nestejné:

| Scénář | Nejdražší compute | Log Analytics |
|---|---|---|
| Běh každých 5 minut po minutě | 20,92 EUR (Flex) | 0 |
| **Chybně nastavená DCR, 100 GB/měsíc** | 0 | **243,90 EUR** |

Jedna špatná DCR tedy stojí **víc než desetinásobek** nejdražší varianty compute. Přesně
proto je budget alert u [`../../day-4/siem-blob-integration/`](../../day-4/siem-blob-integration/)
označený jako povinný, ne doporučený — riziko nikdy neleželo ve výpočtu.

A jeden nečekaný výsledek u častého běhu: **Container Apps Job vyjde nejlevněji (2,86 EUR)
a Flex Consumption nejdráž (20,92 EUR)** — přičemž legacy Consumption je na 8,75 EUR.
Není to tím, že by Flex měl horší sazbu; má **čtyřikrát menší free grant** (100 000 vs
400 000 GB-s). Flex je správná volba z jiných důvodů (viz D4), ale u vysokofrekvenčního
běhu za to zaplatíte.

> [!IMPORTANT] Proč se sazby derivují z USD
> Azure Retail Prices API zaokrouhluje **sub-centové EUR metery na nulu** — v EUR jsou
> nulové *všechny* výkonové metery Functions i Container Apps. Kdo je vezme, jak jsou,
> dostane nulový hosting a uvěří tomu. Skript proto tyhle sazby tahá v USD a přepočítává
> faktorem odvozeným **živě** z meteru, který má obě valuty nenulové, a každou takovou
> sazbu ve výstupu **označí jako derivovanou**. Číslo bez dohledatelného původu nepatří
> do nabídky zákazníkovi.

### Zastropování útraty — co Azure opravdu zastaví

Předchozí tabulka končí nepříjemným zjištěním: jedna chybně nastavená Data Collection Rule
(DCR) stojí víc než desetinásobek nejdražšího compute. Otázka, která z toho přirozeně plyne,
je „dá se v Azure nastavit, že víc než X se utratit nesmí". Základní orientaci
v nástrojích má [`../../day-4/azure-integration-patterns/explainer-azure-orientation.md`](../../day-4/azure-integration-patterns/explainer-azure-orientation.md);
tady jde o tu část, která se týká peněz, a o její háčky.

Odpověď je nepříjemná: **jistič v Azure neexistuje.** Budget v Microsoft Cost Management
je hlásič — *„Resources aren't affected, and your consumption isn't stopped."* Spending
limit, který služby skutečně vypne, je k dispozici jen u předplatných s kreditem:
*„The spending limit isn't available for subscriptions with commitment plans or with
pay-as-you-go pricing."* Vlastní hodnotu nastavit nelze vůbec (*„Custom spending limits
aren't available."*). U komerčního předplatného tedy zbývají tři částečné nástroje.

#### 1. Denní strop ingestu (daily cap) na Log Analytics

Tohle je jediný skutečný strop, který se v tomto kurzu týká té nejdražší položky — ingestu
logů. Zastaví *„collection of billable log data for tables in the Analytics or Basic table
plans for the rest of a 24-hour period"*. Má ale tři vlastnosti, které se musí říct nahlas,
protože každá z nich umí zaskočit:

| Háček | Co to znamená |
|---|---|
| **Nezastaví přesně na hodnotě** | *„The daily cap can't stop data collection at precisely the specified cap level and some excess data is expected... If data is collected above the cap, it's still billed."* Přestřelené množství se **účtuje**. |
| **Tabulky v plánu Auxiliary strop neřeší** | *„Tables in the Auxiliary table plan are not subject to any daily cap."* |
| **Po dosažení stropu jste slepí** | Sběr se zastaví — a to je u bezpečnostní pipeline z [`../../day-4/siem-blob-integration/`](../../day-4/siem-blob-integration/) rozhodnutí, ne detail. |

Ten třetí bod je u kurzu o SIEM (Security Information and Event Management) nejdůležitější
a Microsoft ho formuluje ostře: *„When the daily cap is met, you are effectively blind to
the current state of your monitored environment and no collecting potentially critical
events that might be needed later."* Strop na ingestu bezpečnostních logů je tedy
**volba mezi nákladovým a bezpečnostním rizikem**. Doporučení Microsoftu je jednoznačné:
strop je záchranná brzda proti nečekanému nárůstu, **ne nástroj pro řízení nákladů** —
na to je transformace v DCR, tedy filtrovat před zápisem. Praktický postup: nastavit strop
vysoko, a k němu alert na hodnotu **pod** stropem, aby byl čas zasáhnout dřív, než sběr
stojí.

#### 2. Budget, který spustí automatizaci

Budget na úrovni subscription nebo resource group umí místo e-mailu spustit **action group**,
a ta dál Logic App, Azure Function nebo Automation Runbook, který drahé zdroje vypne. Je to
jediná obecná cesta k automatické reakci — a má vestavěné zpoždění:
*„Cost and usage data is typically available within 8-24 hours and budgets are evaluated
against these costs every 24 hours."* K překročení tedy reálně dojde; automatizace jen
zkrátí, jak dlouho bude trvat. Action groups jsou navíc podporované jen pro scope
subscription a resource group.

#### 3. Azure Policy jako prevence

Policy spotřebu neměří, ale nedovolí drahou věc **založit** — povolené velikosti strojů
(SKU), povolené regiony, zakázané typy zdrojů. Pro kurzovní a zákaznická prostředí je to
nejlepší návratnost úsilí: co nevznikne, nic nestojí.

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> **Denní kvóta u Azure Functions není v aktuální dokumentaci Flex Consumption
> doložená.** Nastavení denní kvóty v GB-s (`dailyMemoryTimeQuota`) je vlastnost
> **legacy Consumption** plánu; stránky *Flex Consumption plan* ani *Estimating
> consumption-based costs* ji nezmiňují. Kurzovní prostředí jede na Flex Consumption —
> nepočítat tedy s tím, že se Function App dá zastropovat, dokud to někdo neověří
> v portálu. Strop pro Functions stavět přes budget + automatizaci, nebo přes Policy.

Souhrn pro zákazníka jednou větou: **Policy brání, budget varuje, kvóta konkrétní služby
zastaví jednu věc, smazání resource group ukončí všechno.** Rozpočet sám nechrání nic.

### Capstone — konsolidace týdne
Capstone spojuje: wave plán a throttle-aware exekuci ([`../../day-3/migration-patterns/`](../../day-3/migration-patterns/)),
provisioning artefakt ([`../../day-3/provisioning-patterns/`](../../day-3/provisioning-patterns/)),
Azure integrační/SIEM blueprint ([`../../day-4/azure-integration-patterns/`](../../day-4/azure-integration-patterns/) + [`../../day-4/siem-blob-integration/`](../../day-4/siem-blob-integration/))
a hardened app registraci ([`../security-hardening/`](../security-hardening/)) do jednoho
end-to-end blueprintu migrace + provisioningu. Součástí je explicitní rollback plán (co
dělat, když vlna selže v polovině) a předávací runbook do provozu (kdo je vlastník po
kurzu, jak se hlásí incidenty, jaký je patch/update cyklus).

### Další kroky — certifikační cesty

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> **AZ-204 (Developing Solutions for Microsoft Azure) a certifikace Azure Developer
> Associate končí 31. 7. 2026** — nahrazuje je nová certifikace **AI-200 (Azure AI Cloud
> Developer Associate)**. K datu psaní tohoto materiálu je to během několika dní od konce
> platnosti AZ-204 jako aktivní cesty — **nedoporučovat studentům AZ-204** jako další krok,
> doporučit AI-200 jako přímého nástupce. **SC-300 (Identity and Access Administrator)**
> zůstává platnou cestou pro prohloubení identity/Conditional Access témat z [`../security-hardening/`](../security-hardening/). Ověřit
> aktuální stav obou certifikací (obsahová náplň AI-200 se teprve ustaluje) před
> doporučením konkrétního studijního plánu.

```mermaid
flowchart LR
  A[Wave plán — migration-patterns] --> E[Capstone blueprint]
  B[Provisioning — provisioning-patterns] --> E
  C[Azure/SIEM — D4 integrace] --> E
  D[Hardened identity — security-hardening] --> E
  E --> F[Rollback plán]
  E --> G[Předávací runbook]
```

## Klíčové rozlišení
- **`$select` povinný (Entra resources) vs doporučený (většina ostatních resources)** —
  u Entra bez něj aplikace nevidí vlastnosti mimo výchozí sadu vůbec, ne jen "zbytečně moc dat".
- **Optimalizace výkonu (rychlost) vs optimalizace nákladů (cena)** — někdy protichůdné
  (agresivní batching může zvýšit latenci jednotlivého requestu kvůli čekání na naplnění batch).
- **Floor vs sklon** — u plánovaného skriptu je náklad plochý floor daný free granty,
  ne cena za běh. Sklon se objeví teprve u vysoké frekvence, a i tam je mírný.
- **Compute vs telemetrie** — jediný náklad, který u automatizace reálně roste, je ingest
  logů. Chybná DCR přebije nejdražší compute o řád.
- **Sazba vs free grant** — Flex má lepší vlastnosti a menší grant než legacy Consumption.
  Levnější plán není totéž co lepší plán.
- **Rollback plán připravený předem vs improvizovaná náprava za běhu** — capstone vyžaduje první.

## Lab
Viz [`lab-capstone-blueprint.md`](lab-capstone-blueprint.md).

## Zdroje (Microsoft)
- [Customize Microsoft Graph responses with query parameters](https://learn.microsoft.com/en-us/graph/query-parameters)
- [Best practices for working with Microsoft Graph](https://learn.microsoft.com/en-us/graph/best-practices-concept)
- [Azure Retail Prices API](https://learn.microsoft.com/en-us/rest/api/cost-management/retail-prices/azure-retail-prices) — anonymní endpoint, ze kterého kalkulátor tahá sazby
- [Billing in Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/billing) — free granty vCPU-s a GiB-s (nejsou v API, jen v dokumentaci)
- [Study guide for Exam AZ-204](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-204) (k ověření stavu retirementu)
- [Tutorial: Create and manage budgets](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets) — „Resources aren't affected, and your consumption isn't stopped."; latence dat 8-24 h; action groups jen pro scope subscription a resource group
- [Azure spending limit](https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/spending-limit) — není u pay-as-you-go ani u commitment plánů; „Custom spending limits aren't available."
- [Set daily cap on Log Analytics workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/daily-cap) — přestřelený objem se účtuje, plán Auxiliary stropu nepodléhá, po dosažení stropu sběr stojí
- [Azure Policy — allowed resource types / SKUs](https://learn.microsoft.com/en-us/azure/governance/policy/overview) — prevence na úrovni založení zdroje

## Stav produktu / delta
- Ověřit k datu běhu — AZ-204 retirement (31. 7. 2026) a přesná náplň AI-200 jako náhrady;
  toto je nejrychleji se měnící fakt v celém kurzu a musí se ověřovat před **každým** během,
  ne jen jednou při psaní materiálu.

> [!WARNING] Čísla v sekci o nákladech necitovat z materiálu — přepočítat
> Konkrétní hodnoty (243,90 EUR za 100 GB ingestu, 2,86 vs 20,92 EUR u častého běhu) jsou
> stav k **2026-09-08** pro region `westeurope`. Sazby, velikosti free grantů i tarifní
> pásma se mění. Před během spustit
> [`solution/Get-HostingCost.ps1`](solution/Get-HostingCost.ps1) a čísla v sekci
> „Kolik to reálně stojí" nahradit aktuálními; skript je právě proto napsaný tak, aby
> sazby netahal z konstant v kódu.
