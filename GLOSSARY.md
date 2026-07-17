# Glosář — závazné názvosloví

Jediný zdroj pravdy pro nástroje, API a konvence používané v GOC223. Všechny moduly se odkazují sem.

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Throttling limity, verze PowerShell modulů a Azure ceny se mění po měsících. Před každým během projet položky s tímto markerem.

## PowerShell moduly (tři, ne jeden)

Kurz na rozdíl od administrátorských kurzů pokrývá všechny tři paralelně a učí, kdy který — to je nosný teaching point M1.3 a M1.2.

| Modul | Rozsah | Kdy použít |
|---|---|---|
| **PnP.PowerShell** | Community-driven, nejširší pokrytí SPO (weby, listy, provisioning templates, branding) | Provisioning, migrace obsahu, cokoli mimo tenant-admin scope |
| **Microsoft.Graph** (Graph PowerShell SDK) | Oficiální wrapper nad Microsoft Graph REST API | Identity, M365 skupiny, Teams, cross-workload operace, cokoli co SPO moduly nepokrývají |
| **SPO Management Shell** (`Microsoft.Online.SharePoint.PowerShell`) | Oficiální tenant-admin modul | Tenant-wide nastavení (`Set-SPOTenant`), site collection admin, sharing policy |

> [!IMPORTANT] Překryv
> PnP.PowerShell a SPO Management Shell se v site-admin oblasti překrývají. Preferovat PnP pro čitelnost a širší funkčnost, SPO modul jen tam, kde PnP ekvivalent chybí (typicky nejnovější tenant-wide preview nastavení — ta často přistanou v SPO modulu dřív).

## Autentizační strategie (app registration)

| Režim | Kdy | Poznámka |
|---|---|---|
| **Interactive (delegated)** | ad-hoc admin session, vývoj | Browser/WAM popup; pozor na default browser identity |
| **Device code** | headless/vzdálené prostředí, MFA | Kód zadaný v libovolném browseru/profilu |
| **Certificate (app-only)** | dávkové operace, produkční automatizace | Bez promptu; cert thumbprint + ClientId + TenantId |
| **Managed identity** | Azure-hosted automatizace (Functions, Runbooks) | Žádný spravovaný secret/cert — identita vázaná na Azure resource |

**Least privilege princip:** aplikační oprávnění (application permissions) se udělují na úrovni celého tenantu — každé navíc je rozšíření útočné plochy. Preferovat delegated tam, kde to dává smysl, a u app-only vždy sepsat přesný seznam permissions s odůvodněním (viz M5.2).

## Microsoft Graph — inženýrské pojmy

| Pojem | Co to je |
|---|---|
| **`$batch`** | Až 20 requestů v jednom HTTP volání — snižuje round-tripy, ale batch-level throttling se počítá jinak než jednotlivé requesty |
| **Delta query (`delta()`)** | Inkrementální sync — server vrací jen změny od posledního `deltaLink`, ne plný re-scan |
| **Throttling (429)** | Graph vrací `Retry-After` header — respektovat, ne pevný `Start-Sleep` |
| **Paging (`@odata.nextLink`)** | Výsledky nad limit stránky se stránkují — chybějící loop = tichá ztráta dat, ne chyba |
| **Klasifikace chyb** | 429 (throttling, retry) vs 5xx (transient, retry s backoff) vs 4xx mimo 429 (permanentní, nelogovat jako transient) |

## Azure integrační vzory

| Nástroj | Kdy použít |
|---|---|
| **Azure Logic Apps** | Nízkokódová orchestrace, konektory, byznys uživatel/citizen dev spoluautor |
| **Azure Functions** | Pro-code, event-driven, potřeba plné kontroly nad retry/error handling |
| **Azure Automation Runbooks** | PowerShell-native scheduled/dlouhoběžící úlohy, historicky pro on-prem hybrid |
| **Event Grid** | Pub/sub distribuce eventů (vč. Graph change notifications, Blob eventů) |
| **Graph change notifications (webhooks)** | Subscription na změny v M365 datech (max platnost subscription dle typu resource — nutno obnovovat) |

## SIEM pipeline (Azure Blob)

Standardní tvar pipeline v M4.2: `aplikace → Azure Blob Storage → Event Grid → Azure Function → SIEM` (Sentinel/Splunk/QRadar dle zákazníka).

- **Schéma logů**: strukturované (JSON), minimalizace PII (žádné celé UPN/e-maily v plain textu, kde to jde — hash/pseudonymizace).
- **Retence**: log retence odděleně od retence zdrojových dat — GDPR/compliance požadavky se liší.
- **Spolehlivost**: batching (snížení počtu Function invocations), retry s exponenciálním backoff, dead-letter queue pro trvale selhávající zprávy.
- **KQL** (Kusto Query Language) — dotazovací jazyk nad Log Analytics/Sentinel, používaný k validaci ingestované telemetrie a stavbě dashboardů.

## Microsoft Clarity

Bezplatný web analytics nástroj (heatmapy, session recordings). V SPO kontextu se injektuje přes **SPFx Application Customizer** (tenant-wide extension), ne ruční vkládání skriptu do stránek.

> [!WARNING] Ověřit k datu běhu
> Ověřit aktuální požadavky na cookie/souhlas banner a regionální ukládání dat (EU data residency) před nasazením u zákazníka — liší se dle Clarity plánu a legislativy cílové organizace.

## SPFx & App Catalog

| Pojem | Poznámka |
|---|---|
| **App Catalog** | Tenant-wide (jeden na tenant) vs site collection app catalog (per-web, od SPFx 1.15) |
| **`.sppkg`** | Balíček řešení — nahrává se do App Catalog, odtud se řešení „Deploy"-uje na cílové weby |
| **Trust** | Solution musí být v App Catalog označen jako „make this solution available to all sites" nebo přidán explicitně per-site |

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Ověřit, zda aktuální `@microsoft/generator-sharepoint` scaffolduje build přes `gulp`, nebo už přešel na Heft-based toolchain (SPFx generátor prošel touto migrací u některých verzí) — ovlivňuje přesné příkazy v M5.1 (`gulp serve`/`gulp bundle` vs `heft start`/`heft build`).

## Provisioning & Orchestry

| Přístup | Charakter |
|---|---|
| **PnP provisioning (tenant templates, `.pnp` balíčky)** | Deklarativní XML/JSON šablona + PnP.PowerShell/PnP Framework aplikuje na cílový web; plná kontrola, vyžaduje vlastní orchestraci žádanek a lifecycle |
| **Orchestry** (3rd-party SaaS) | Request center (žádanky na weby/Teams), katalog šablon pracovních prostorů, lifecycle hooky (pre/post-provision), governance artefakty (attestace vlastníků, sensitivity, sprawl reporting) — nižší vlastní kód, vendor lock-in a licenční náklad |

V kurzu se Orchestry probírá jako **simulace/koncept** (bez živé licence) — hooky a integrační body se navrhují na papíře/pseudokódu proti PnP.PowerShell/Graph rozhraní, ne proti reálnému Orchestry tenantu.

## Migrace — klíčové limity

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.

- **List view threshold**: 5000 položek na dotaz bez indexovaného sloupce — throttling, ne tvrdý strop na velikost listu.
- **Verze souborů**: výchozí retence verzí (major/minor) násobí objem migrovaných dat — řešit před migrací, ne po ní.
- **Search crawl delay**: po migraci obsah není okamžitě vyhledatelný — plánovat cutover s rezervou na re-index.
- **Wave planning**: rozdělení migrace do vln dle rizika/velikosti/závislostí, ne dle abecedy — kritické weby v pozdější vlně s delším bufferem na rollback.

## Formáty (proč je studenti potřebují)

| Formát | Role v kurzu |
|---|---|
| **JSON** | Graph/REST payloady, PnP provisioning šablony (JSON varianta), konfigurace |
| **YAML** | CI/CD pipeline definice, Azure Automation runbook metadata |
| **Markdown** | materiály kurzu, dokumentace, PR popisy |

## Vývojářské nástroje

| Nástroj | Role v kurzu |
|---|---|
| **VS Code** | primární editor — workspace, tasks.json, launch.json (ladění PowerShell/Node), formátování |
| **GitHub Copilot** | AI asistent při psaní automatizačního kódu — vlastní licence (mimo M365), probírá se s důrazem na prompting a bezpečnostní mantinely (žádné tajné klíče/tenant ID v promptu) |
| **Git** | hygiena repozitáře, branch strategie, PR/code review workflow pro infrastructure-as-code přístup kurzu |
