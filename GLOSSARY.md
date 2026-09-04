# Glosář — závazné názvosloví

Jediný zdroj pravdy pro nástroje, API a konvence používané v GOC223. Všechny moduly se odkazují sem.

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Throttling limity, verze PowerShell modulů a Azure ceny se mění po měsících. Před každým během projet položky s tímto markerem.

## PowerShell moduly (tři, ne jeden)

Kurz na rozdíl od administrátorských kurzů pokrývá všechny tři paralelně a učí, kdy který — to je nosný teaching point [`day-2/powershell-deep-dive/`](day-2/powershell-deep-dive/) a [`day-1/automation-strategy/`](day-1/automation-strategy/).

| Modul | Rozsah | Kdy použít |
|---|---|---|
| **PnP.PowerShell** | Community-driven, nejširší pokrytí SPO (weby, listy, provisioning templates, branding) | Provisioning, migrace obsahu, cokoli mimo tenant-admin scope |
| **Microsoft.Graph** (Graph PowerShell SDK) | Oficiální wrapper nad Microsoft Graph REST API | Identity, M365 skupiny, Teams, cross-workload operace, cokoli co SPO moduly nepokrývají |
| **SPO Management Shell** (`Microsoft.Online.SharePoint.PowerShell`) | Oficiální tenant-admin modul | Tenant-wide nastavení (`Set-SPOTenant`), site collection admin, sharing policy |

> [!IMPORTANT] Překryv
> PnP.PowerShell a SPO Management Shell se v site-admin oblasti překrývají. Preferovat PnP pro čitelnost a širší funkčnost, SPO modul jen tam, kde PnP ekvivalent chybí (typicky nejnovější tenant-wide preview nastavení — ta často přistanou v SPO modulu dřív).

## Evoluce modulů: legacy → současnost → budoucnost

Nosná pointa pro [`day-1/automation-strategy/`](day-1/automation-strategy/): **moduly umírají, REST API zůstává** — proto kurz učí principy nad Graph/REST, ne jen konkrétní cmdlety.

| Generace | Moduly | Stav |
|---|---|---|
| **Mrtvé (retired)** | MSOnline (`Connect-MsolService`), AzureAD/AzureADPreview | Deprecated 2024-03, nefunkční od poloviny 2025. U zákazníků se stále potkávají ve starých skriptech — umět je poznat a migrovat. Pozor: license assignment, filtering a "get all" dotazy nejde přepsat 1:1 |
| **Současnost** | Microsoft.Graph SDK, PnP.PowerShell, SPO Management Shell, ExchangeOnlineManagement (V3, REST-backed), MicrosoftTeams | Aktivně vyvíjené; PnP od 2024-09 vyžaduje vlastní app registraci (`-ClientId`) i pro interaktivní login |
| **Nastupující** | Microsoft Entra PowerShell (`Microsoft.Entra`) — přátelštější vrstva nad Graph SDK, ~98% pokrytí starých AzureAD/MSOnline cmdletů, `Enable-EntraAzureADAlias` pro rychlou migraci | Sledovat; pro identity skripty pravděpodobný budoucí default |

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Verze a stav modulů se mění po měsících (např. ExchangeOnlineManagement 3.10.0 nově vyžaduje PowerShell 7.6+). Před během projet aktuální verze všech modulů použitých v demích.

Totéž platí o vrstvách customizace, ne jen o modulech: **SharePoint Add-ins a Azure ACS jsou v Microsoft 365 vypnuté od 2. 4. 2026** (v SharePoint on-premises retirement neplatí), custom script je od 11/2024 vynucovaně vypnutý s per-site výjimkou. Mapa mrtvých vrstev pro migrační assessment: [`day-3/migration-patterns/explainer-legacy-layers.md`](day-3/migration-patterns/explainer-legacy-layers.md).

## Širší mapa modulů (mimo fokus kurzu)

Kurz jde do hloubky u trojice PnP/Graph/SPO (fokus = SharePoint Online). Zbytek M365 ekosystému jen jako mapa — studenti mají vědět, že existují, ne je ovládat:

| Modul/nástroj | Workload | Poznámka |
|---|---|---|
| **ExchangeOnlineManagement** (EXO V3) | Exchange Online + Security & Compliance (`Connect-IPPSSession`) | REST-backed, cert-based app-only podporováno |
| **MicrosoftTeams** | Teams admin (týmy, policies, telefonie) | |
| **Microsoft.PowerApps.Administration.PowerShell** | Power Platform admin (environments, DLP) | service principal nutný při MFA |
| **Az PowerShell** | Azure resources | používá se v D4 (Functions, Blob) — ne M365 samotné |
| **CLI for Microsoft 365** (`@pnp/cli-microsoft365`) | cross-workload, npm/Node | **úzká role v kurzu: CI/CD pipeline a SPFx tooling** (`spfx doctor`, project upgrade) — ne obecná alternativa PnP.PowerShell pro administraci; překryv s PnP je u SPO ~80 % a učit oba na stejný problém nedává smysl |

## TypeScript/Node cesta

Alternativa k PowerShellu pro vývojářské týmy: **Graph JS SDK** (`@microsoft/microsoft-graph-client` + `@microsoft/microsoft-graph-types`) s `@azure/identity` credentials (stejná auth matice jako PowerShell — device code / certificate / managed identity) a **PnPjs** (`@pnp/sp`) pro SPO-native volání. Detail: [`day-1/automation-strategy/explainer-typescript-graph.md`](day-1/automation-strategy/explainer-typescript-graph.md).

## App registrace vs Enterprise Application

- **App registrace** (application object) = globální šablona aplikace — credentials,
  požadované permissions, `signInAudience`; žije jen v domovském tenantu.
- **Enterprise Application** (service principal) = lokální instance v každém tenantu, kde
  aplikace působí — udělený consent, assignment, sign-in logy.
- **Single-tenant** (`AzureADMyOrg`) je doporučený default; **multi-tenant**
  (`AzureADMultipleOrgs`) jen s reálným scénářem a consent governance.
- Detail a practices: [`day-1/automation-strategy/explainer-app-registrations-enterprise-apps.md`](day-1/automation-strategy/explainer-app-registrations-enterprise-apps.md).

## Autentizační strategie (app registration)

| Režim | Kdy | Poznámka |
|---|---|---|
| **Interactive (delegated)** | ad-hoc admin session, vývoj | Browser/WAM popup; pozor na default browser identity |
| **Device code** | headless/vzdálené prostředí, MFA | Kód zadaný v libovolném browseru/profilu |
| **Certificate (app-only)** | dávkové operace, produkční automatizace | Bez promptu; cert thumbprint + ClientId + TenantId |
| **Managed identity** | Azure-hosted automatizace (Functions, Runbooks) | Žádný spravovaný secret/cert — identita vázaná na Azure resource |

**Least privilege princip:** aplikační oprávnění (application permissions) se udělují na úrovni celého tenantu — každé navíc je rozšíření útočné plochy. Preferovat delegated tam, kde to dává smysl, a u app-only vždy sepsat přesný seznam permissions s odůvodněním (viz [`day-5/security-hardening/`](day-5/security-hardening/)).

**Public client vs confidential client** — dělení aplikací podle toho, zda umí udržet tajemství. **Confidential client** běží mimo dosah uživatele (server, Azure Function) a prokazuje sám sebe vlastním credentialem (certifikát, secret). **Public client** běží na zařízení uživatele (PowerShell konzole, desktop) — cokoli zadrátovaného by šlo vytáhnout, proto se prokazuje **jen uživatel**. Jak Entra typ pozná: primárně z platformy redirect URI (*Web* = confidential, *Mobile and desktop applications* / *SPA* = public — proto `-Interactive` s redirectem `http://localhost` funguje bez dalšího nastavování); u flow **bez redirect URI** (device code) rozhoduje fallback přepínač *Allow public client flows* (`isFallbackPublicClient`) — vypnutý znamená `AADSTS7000218`. Certifikátový app-only režim je confidential z podstaty; jedna app registrace může podporovat obojí. Mnemotechnika: *public = prokazuje se člověk, confidential = prokazuje se aplikace.* Diagnostika: [`day-2/powershell-deep-dive/troubleshooting-auth.md`](day-2/powershell-deep-dive/troubleshooting-auth.md).

**Formáty credentialů**: `.cer` = jen veřejná část (nahrává se do Entra), `.pfx`/`.p12` = certifikát **včetně privátního klíče**, `.pem` = textová obálka (podle obsahu i s klíčem). Windows úložiště `Cert:\CurrentUser\My` (profil, GUI „Osobní") vs `Cert:\LocalMachine\My` (stroj — pro scheduled tasky). Detail: [`day-2/powershell-deep-dive/explainer-certificates-keys.md`](day-2/powershell-deep-dive/explainer-certificates-keys.md).

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

Standardní tvar pipeline v [`day-4/siem-blob-integration/`](day-4/siem-blob-integration/): `aplikace → Azure Blob Storage → Event Grid → Azure Function → SIEM` (Sentinel/Splunk/QRadar dle zákazníka).

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
| **API access** | Schvalování oprávnění pro SPFx řešení v SharePoint admin centru — oprávnění se přidává **jedinému sdílenému service principalu** pro celý tenant („SharePoint Online Client Extensibility Web Application Principal"), takže ho využije i každé další SPFx řešení. Zmírnění: **isolated web parts** (vlastní principal). Audit: `Get-PnPTenantServicePrincipalPermissionGrants` / `…PermissionRequests` |
| **Tenant-wide extensions** | Seznam na webu App Catalogu, kterým běží application customizery na všech stránkách bez instalace na konkrétní web — první místo ke kontrole, když se „rozbije SharePoint všem" |

Správcovský pohled (nasazení, API access, verze, hygiena): [`day-5/spfx-fundamentals/explainer-spfx-admin.md`](day-5/spfx-fundamentals/explainer-spfx-admin.md). SPFx kód běží **pod identitou přihlášeného uživatele**, ne pod vlastním credentialem jako app registrace.

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Vyřešeno k datu psaní: od SPFx v1.22 generátor defaultně scaffolduje **Heft-based toolchain** (`heft start`/`heft build`), Gulp je dostupný jen přes `--use-gulp` pro starší projekty. Microsoft plánuje vynucený konec podpory Gulp toolchainu kolem SPFx 1.24 (cca září 2026) — ověřit před každým během, zda se harmonogram nezměnil a zda kurzový baseline (SPFx 1.21.1+ / Node 22 LTS) stále odpovídá aktuální doporučené kombinaci.

## Provisioning & Orchestry

| Přístup | Charakter |
|---|---|
| **Site script + site template** (dřív *site design*) | JSON se seznamem akcí (`verb`) + pojmenovaný obal, který se nabídne uživateli při zakládání webu; limit 100 scriptů a 100 templates na tenant, aplikace je **asynchronní**. Obdoba pro jeden seznam = **list design** (`Add-PnPListDesign`) |
| **PnP provisioning (tenant templates, `.pnp` balíčky)** | Deklarativní XML/JSON šablona + PnP.PowerShell/PnP Framework aplikuje na cílový web; plná kontrola, vyžaduje vlastní orchestraci žádanek a lifecycle |
| **Orchestry** (3rd-party SaaS) | Request center (žádanky na weby/Teams), katalog šablon pracovních prostorů, lifecycle hooky (pre/post-provision), governance artefakty (attestace vlastníků, sensitivity, sprawl reporting) — nižší vlastní kód, vendor lock-in a licenční náklad |

Rozdíl v jedné větě: **site template si vybere uživatel v UI, PnP šablonu spustí skript** — v praxi se kombinují; rozhodovací osa a reverzní cesta (`Get-PnPSiteScriptFromWeb`) je v [`day-3/provisioning-patterns/explainer-site-list-templates.md`](day-3/provisioning-patterns/explainer-site-list-templates.md). Klasické `.wsp` („Save site as template") a `.stp` šablony seznamů jsou na moderních webech **mrtvé**.

V kurzu se Orchestry probírá jako **simulace/koncept** (bez živé licence) — hooky a integrační body se navrhují na papíře/pseudokódu proti PnP.PowerShell/Graph rozhraní, ne proti reálnému Orchestry tenantu.

## Migrační nástroje

| Nástroj | Kategorie | Poznámka |
|---|---|---|
| **SPMT** (SharePoint Migration Tool) | Microsoft, zdarma, desktop | SP Server 2010-2019 + file shares → SPO/OneDrive/Teams; PS modul `Microsoft.SharePoint.MigrationTool.PowerShell` (`Register-SPMTMigration` → `Add-SPMTTask` → `Start-SPMTMigration`) se instaluje s klientem, **jen Windows PowerShell 5.x** |
| **Migration Manager** | Microsoft, zdarma, cloud (SharePoint admin centrum) | agent-based škálování pro file shares + cloud zdroje (Box, Dropbox, Google Workspace); **ne** pro on-prem SP weby |
| **SMAT** (SharePoint Migration Assessment Tool) | Microsoft, zdarma, CLI | pre-migrační scan on-prem farmy (assess & remediate) |
| **ShareGate / AvePoint Fly / Quest Content Matrix** | 3rd-party, komerční | kupují fidelitu (verze/permissions), tenant-to-tenant a reporting; ShareGate má vlastní PS modul (`Copy-Content`, také jen Windows PowerShell) |

Detail a rozhodovací osa: [`day-3/migration-patterns/explainer-migration-tools.md`](day-3/migration-patterns/explainer-migration-tools.md).

## Migrace — klíčové limity

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.

- **List view threshold**: 5000 = limit na to, kolik položek smí projít **jeden dotaz** — **ne** strop velikosti listu (ten je v milionech) a **ne** throttling. V SPO se nedá zvýšit.
- **Indexovaný sloupec**: pomocná struktura, která dotaz zúží pod threshold; filtr nebo řazení na indexovaném sloupci projde i nad velkým listem. Limit 20 indexů na list; nelze indexovat vícehodnotové a počítané sloupce ani víceřádkový text; zavádět, dokud je list malý (automatické indexování SPO se nevztahuje na listy nad 20 000 položek). `Set-PnPField -List X -Identity Y -Values @{Indexed=$true}`.
- **Threshold vs throttling**: threshold = *jeden dotaz je moc velký* (chyba okamžitě), throttling = *voláš moc často* (429/503 + `Retry-After`). Dvě různé věci, dvě různá řešení: index a stránkování vs backoff a dávky.
- **Dekorace user agenta**: vlastní REST/CSOM volání do SPO označit `NONISV|<organizace>|<Aplikace>/1.0` — nedekorovaný provoz je throttlován agresivněji (PnP.PowerShell si UA nastavuje sám).
- Detail a checklist: [`day-2/graph-fundamentals/explainer-large-lists.md`](day-2/graph-fundamentals/explainer-large-lists.md).
- **Verze souborů**: výchozí retence verzí (major/minor) násobí objem migrovaných dat — řešit před migrací, ne po ní.
- **Search crawl delay**: po migraci obsah není okamžitě vyhledatelný — plánovat cutover s rezervou na re-index.
- **Wave planning**: rozdělení migrace do vln dle rizika/velikosti/závislostí, ne dle abecedy — kritické weby v pozdější vlně s delším bufferem na rollback.

## Formáty (proč je studenti potřebují)

| Formát | Role v kurzu |
|---|---|
| **JSON** | Graph/REST payloady, site scripty a list designy, PnP provisioning šablony (JSON varianta), `tasks.json`, konfigurace |
| **YAML** | CI/CD pipeline definice, Azure Automation runbook metadata — jen čteme |
| **XML** | PnP provisioning šablony, CAML dotazy, starší SPO REST (ATOM) — poznat a upravit |
| **CSV** | migrační mapování, inventury, reporty pro zadavatele (`Import-Csv`/`Export-Csv`) |
| **Markdown** | materiály kurzu, dokumentace, PR popisy |

**UTF-8** — API (Graph/REST) mluví UTF-8 vždy; problémy s diakritikou vznikají až na hranici se soubory. PowerShell 7 má UTF-8 jako default, Windows PowerShell 5.1 ne — ve skriptech psát `-Encoding utf8` explicitně a **CSV pro Excel exportovat s `-Encoding utf8BOM -UseCulture`**. Detail: [`day-2/powershell-deep-dive/explainer-formats-encoding.md`](day-2/powershell-deep-dive/explainer-formats-encoding.md).

## Vývojářské nástroje

| Nástroj | Role v kurzu |
|---|---|
| **VS Code** | primární editor — workspace, tasks.json, launch.json (ladění PowerShell/Node), formátování |
| **Microsoft Copilot Chat** | AI asistent kurzu pro přípravu a testování skriptů — součást firemního přihlášení, s ochranou firemních dat; vždy s priming promptem ([`day-1/vscode-copilot-env/copilot-priming-prompt.md`](day-1/vscode-copilot-env/copilot-priming-prompt.md)) a bez tajných klíčů/tenant ID v promptu. Agenti nad firemními daty pro nelicencované uživatele = **měřená spotřeba** (pay-as-you-go, [`day-1/vscode-copilot-env/explainer-copilot-licensing.md`](day-1/vscode-copilot-env/explainer-copilot-licensing.md)). GitHub Copilot = placená editor-integrace mimo M365, v kurzu se nepoužívá |
| **Git** | hygiena repozitáře, branch strategie, PR/code review workflow pro infrastructure-as-code přístup kurzu; volba hostingu [`day-1/vscode-copilot-env/explainer-git-hosting.md`](day-1/vscode-copilot-env/explainer-git-hosting.md) |
