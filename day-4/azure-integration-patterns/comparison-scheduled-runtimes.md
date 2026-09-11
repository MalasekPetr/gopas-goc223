# Comparison · Kde nechat běžet opakovaný PowerShell skript

Doplněk k [`README.md`](README.md). Žebřík v [`explainer-azure-orientation.md`](explainer-azure-orientation.md)
řadí možnosti podle toho, **kolik tajemství leží na discích**. Tenhle soubor je řadí podle
jiné osy: **co to udělá s PowerShellovým skriptem**, který má běžet opakovaně nad M365.

Ta osa je jiná, protože u PowerShellu rozhodují věci, které u C# Functions nikoho netrápí —
jak se do runtime dostanou moduly, jestli je jejich verze pod vaší kontrolou, a jestli
dávka nad tisíci weby vůbec doběhne.

## Pozitivní výběr: podle toho, co chcete

| Chci… | Volba |
|---|---|
| **reagovat na událost** do sekund, případně mít HTTP endpoint | **Functions** (Flex Consumption) |
| **naplánovaný skript bez vlastní infrastruktury** — rozvrh, credential store a historii jobů dostat jako službu | **Automation Runbook** v Azure sandboxu |
| **tentýž centrální rozvrh, ale výpočet na svém stroji** — vlastní runtime, dosah na on-prem, privátní síť bez odchozího internetu | **Automation + Hybrid Runbook Worker** |
| **deterministický runtime v repu**, vlastní nástroje a libovolně dlouhý běh, a přitom scale-to-zero | **Container Apps Job** |
| **nezávislost na Azure** a plnou kontrolu nad strojem | **on-prem scheduled task** |

Napříč všemi platí jedno pravidlo: **žádná z variant nesmí spoléhat na interaktivní
přihlášení.** Auth matice je v [`README.md`](README.md).

> [!NOTE] Proč zapisujeme výběr pozitivně
> Hosting se běžně vybírá negativně — „Automation ne, kvůli fair share; Functions ne, kvůli
> modulům" — a takový postup dovede člověka k **poslednímu nevyloučenému kandidátovi**,
> ne k nejvhodnějšímu. Limity v sekcích níž jsou proto zapsané jako **hranice zvolené
> varianty**, kterou je potřeba znát dopředu, ne jako důvody, proč něco nebrat.

## Rozhodovací tabulka

| | **Functions** (timer trigger) | **Automation Runbook** | **+ Hybrid Worker** | **Container Apps Job** | **on-prem Task Scheduler** |
|---|---|---|---|---|---|
| Jak se dovnitř dostanou moduly | **v app content** (deployment package) — Flex Consumption managed dependencies **nepodporuje** | import do Automation accountu | `Install-Module` na workeru | **zapečené v image** | `Install-Module` na stroji |
| Kdo drží verzi modulu | vy, v deployment package | vy, ale mimo repo | vy, na stroji | **vy, v `Dockerfile` v repu** | vy, ručně |
| Strop doby běhu | 30 min default, **neomezeno** (Flex/Premium/Dedicated) | **3 h — fair share**, job je zastaven | **žádný — fair share se nevztahuje** | `replicaTimeout` (nastavíte v sekundách) | žádný |
| Plánovač | timer trigger (NCRONTAB, **UTC** — `TZ`/`WEBSITE_TIME_ZONE` na Flexu nefunguje) | Automation schedule | **Automation schedule, centrálně** | **cron výraz, 5 polí, v UTC** | Task Scheduler (lokální čas) |
| Cena při nečinnosti | 0 (Flex Consumption) | 0 | běžící stroj | **0 — scale-to-zero** | běžící železo |
| Credential | managed identity | managed identity | managed identity stroje + Automation credential store | managed identity | certifikát v machine store |
| Spustí `.exe` / subprocess | ano | **ne** (Azure sandbox) | **ano** | ano | ano |
| Auditní stopa | Application Insights | historie jobů v Automation | **historie jobů v Automation** | 100 posledních exekucí | žádná, musíte si ji napsat |

## Čtyři věci, které rozhodují víc než tabulka

### 1. Fair share u Automation je 3 hodiny a job se NEVRÁTÍ

Azure Automation sdílí workery mezi účty a mechanismus **fair share** po **třech hodinách**
job odloží nebo zastaví. U **PowerShell a Python runbooků** je job **zastaven a znovu
nespuštěn** — stav skončí na `Stopped`.

Pro migrační nebo inventurní dávku nad velkým tenantem to je tvrdý strop, který nejde
zvednout konfigurací. Není to ale slepá ulička: dávku lze rozdělit na child runbooky, nebo
zvolit **Hybrid Runbook Worker**, na který se fair share nevztahuje vůbec — to je ale
samostatná architektura, ne přepínač, a má vlastní sekci níž.

### 2. Azure sandbox u Automation neumí spustit `.exe`

Runbooky v Azure sandboxu **nepodporují volání procesů a subprocesů**. Sandbox navíc dává
**1 GB** temp místa, podporuje jen **.NET Framework 4.7.2** bez možnosti upgradu, neumožňuje
elevaci a v jednom sandboxu může běžet **až 10 jobů, které se navzájem ovlivňují** —
`Disconnect-AzAccount` v jednom runbooku odpojí **všechny ostatní joby ve stejném sandboxu**.

Pro tenhle kurz to má konkrétní důsledek: **migrační nástroje do Azure sandboxu nepatří.**
SPMT je desktop aplikace s PowerShell modulem nad Windows PowerShellem 5.x
(viz [`../../day-3/migration-patterns/explainer-migration-tools.md`](../../day-3/migration-patterns/explainer-migration-tools.md)),
což sandbox neumí ani spustit. Pokud chcete migrační nástroj řídit z Automation, je to
rovnou volba Hybrid Workeru.

> [!IMPORTANT] Azure Firewall na Key Vaultu zablokuje runbook v sandboxu
> Zapnutý firewall na **Azure Storage, Key Vault nebo Azure SQL** blokuje přístup
> z Automation runbooků — **a to i se zapnutou výjimkou „allow trusted Microsoft services",
> protože Automation na seznamu trusted services není.**
>
> Zlaté pravidlo z [`../../day-1/vscode-copilot-env/explainer-runtime-environments.md`](../../day-1/vscode-copilot-env/explainer-runtime-environments.md)
> zní „cert store, Key Vault, nebo managed identity — nic jiného". U runbooku v sandboxu si
> z té trojice vyberte **managed identity**; kombinace „runbook v sandboxu + zamčený Key
> Vault" vypadá správně a nefunguje. Kdo potřebuje sáhnout na privátní službu ve VNetu,
> volí Hybrid Workera — a volí ho kvůli tomu, ne jako náhradní řešení.

### 3. Na Flex Consumption `requirements.psd1` nefunguje

Tenhle nález převrací obvyklé poučení. **Flex Consumption nepodporuje managed dependencies
v PowerShellu** — `requirements.psd1` na něm neplatí a moduly je nutné **přiložit k app
content**, tedy nést je v deployment package.

Pro praxi to má dva důsledky. Za prvé: kdo přijde s návykem „napíšu `requirements.psd1`
a platforma to dotáhne", narazí — a hláška o chybějícím cmdletu tuhle příčinu neprozradí.
Za druhé, a příznivěji: na Flex Consumption **držíte verzi modulu vy**, protože ji nesete
v balíčku. Determinismus, který jinak musíte hledat v kontejneru, tady dostanete i u Functions.

Zbývající argument pro kontejner proto není modul, ale **celý runtime**: verze PowerShellu
(Flex Consumption podporuje jen **PowerShell 7.4**), možnost přinést si vlastní `.exe`,
a strop doby běhu, který si nastavíte sami. `Microsoft.Graph` je meta-modul s desítkami
sub-modulů — v `Dockerfile` v repu je jeho pin vidět a přezkoumatelný vedle skriptu.

Je to tentýž princip jako `#Requires` a `-RequiredVersion` z
[`../../day-1/toolchain-setup/`](../../day-1/toolchain-setup/), jen posunutý o vrstvu výš:
**co skript potřebuje k běhu, patří do repa** — a u kontejneru to platí i pro runtime.

Kolik ty varianty reálně stojí, spočítá
[`../../day-5/performance-cost-capstone/solution/Get-HostingCost.ps1`](../../day-5/performance-cost-capstone/solution/Get-HostingCost.ps1)
ze živého ceníku. Krátká verze: u noční dávky **vyjdou všechny čtyři na nulu**, protože
se vejdou do free grantů, takže se tady nerozhoduje podle ceny — rozhoduje se podle
determinismu runtime a stropu doby běhu.

Container Apps Job k tomu dává **cron plánovač, `replicaTimeout` podle vaší potřeby,
`replicaRetryLimit`, `parallelism`** a scale-to-zero, tedy stejnou ekonomiku jako
serverless. Cenou je, že si musíte postavit image — což pro tým, který už má repo
a pipeline, není nic navíc.

> [!NOTE] Tři vlastnosti Flex Consumption, které zaskočí při automatizaci
> **Jedna aplikace na jeden plán**, **deployment slots nejsou podporované** a **migrace
> existující aplikace na Flex (ani z Flexu jinam) není možná** — přechod znamená založit
> novou aplikaci a nasadit kód znovu. Kdo plánuje hostování dopředu, ať to ví teď, ne
> až u prvního nasazení.

### 4. Přes hranici tenantu se managed identita nedostane

Tohle v tabulkách výše není a u zákazníka rozhoduje častěji než strop doby běhu — zvlášť
když spravujete víc tenantů najednou.

**Managed identita je service principál tenantu, ke kterému je připojená ta subscription.**
Dokumentace: *„A service principal of a special type is created in Microsoft Entra ID for
the identity. The service principal is tied to the lifecycle of that Azure resource."*
Nedá se „nakonsentovat" jinam — a nejde to obejít, protože **není co přenést**.

Certifikátová app registrace se naopak dostane všude, kde ji pustí. „Pustí" znamená tři
věci, a všechny tři musí platit:

1. app registrace je **multitenant** (jinak jen domovský tenant),
2. v cílovém tenantu proběhl **admin consent** → vznikl tam service principál,
3. tam má `Sites.Selected` **a** per-site grant.

#### Čtyři cesty a co která stojí

| Cesta | Existuje secret? | Přes tenanty? | Co drží co |
|---|---|---|---|
| **Managed identita přímo** | **ne** | **ne** | MI je identita i přístup |
| **Certifikát** (cert store / deployment package) | ano, u vás | ano | certifikát je identita i přístup |
| **MI → Key Vault → certifikát** | **ano, v trezoru** | ano | MI otevře trezor, certifikát jede k zákazníkovi |
| **MI jako federated credential (FIC)** na app registraci | **ne** | ano | MI dokazuje běh, app registrace drží přístup |

Poslední řádek je na ose „kolik secretů existuje" nejlepší a Microsoft ho tak i formuluje:
*„Whenever an Entra ID app is required, this is the recommended way to be credential-free."*
Cena je **limit 20 federated credentials na aplikaci** a nutnost nastavit tu důvěru.

Key Vault má proti federaci dvě výhody: **žádný limit** a funguje **s čímkoli, co umí vzít
certifikát** — tedy i s klientem, který federaci neumí nebo ho nemáte pod kontrolou.

> [!WARNING] Kombinace „Automation Runbook + Key Vault" se ale sama vylučuje
> Runbook v cloud sandboxu **neprojde firewallem na Key Vaultu** — Automation není
> „trusted Microsoft service", takže ho nepustí ani volba *allow trusted Microsoft
> services* (viz rozhodovací tabulka v [`README.md`](README.md)).
>
> A Key Vault, ve kterém držíte certifikáty k zákaznickým tenantům, je **přesně ten trezor,
> který síťově omezit chcete**. Takže buď otevřený vault (u tohohle obsahu ne), nebo
> **Hybrid Runbook Worker** či **Function s VNet integrací** místo cloud runbooku.
>
> Tohle je nejlepší příklad toho, proč se hosting a identita nedají rozhodovat odděleně:
> volba runtime tady **zneplatní** jinak správnou volbu úložiště pro credential.

> [!NOTE] Praktický vzor pro multi-tenant provoz
> **MI drží identitu běhu, app registrace drží přístup k zákazníkovi.** Ať už to slepíte
> federací (lepší) nebo certifikátem v Key Vaultu (univerzálnější), tahle dělba je ta
> správná — managed identita se nikdy nepokouší být identitou v cizím tenantu.

## Automation jako control plane, ne jako runtime

Hybrid Runbook Worker mění to, **co v Automation kupujete**. Skript neběží v Azure sandboxu,
ale na **vašem stroji** — Azure VM, on-prem serveru nebo stroji připojeném přes **Azure Arc**.
Automation zůstává řídicí vrstvou: rozvrh, credential store, historie jobů, identita.

Je to jediná varianta v celé tabulce, kde **control plane a runtime nejsou tatáž věc**.
Proto se nevybírá jako „Automation, ale lepší" — vybírá se tehdy, když chcete centrální
řízení nad výpočtem, který z nějakého důvodu musí zůstat u vás.

Microsoft pro to dokumentuje pět scénářů a všechny jsou pozitivní volby:

1. **Správa in-guest** na Azure VM a na Arc-enabled serverech — tedy i na strojích mimo
   Azure, na firemní síti nebo u jiného cloud providera.
2. **Dlouhé a náročné běhy.** Fair share se na workera nevztahuje a neplatí ani limity
   sandboxu na disk, pamět a sockety; skript může běžet **s elevací**.
3. **Data residency.** Organizace nechce, aby joby běžely v cloudu — worker to řeší, aniž
   byste přišli o centrální rozvrh.
4. **Jeden onboardovaný stroj jako odrazový můstek** pro automatizaci ostatních lokálních
   nebo multicloud strojů.
5. **Přístup k privátním službám ve VNetu bez otevírání odchozího internetu.**

Pro tenhle kurz jsou nejdůležitější body 2 a 5. **SPMT** nad Windows PowerShellem 5.x
se do sandboxu nedostane, ale na Hybrid Workeru běží — a migrace tím získá centrální rozvrh
a auditní stopu, kterou čistý Task Scheduler nemá. A bod 5 je řešení té situace s firewallem
na Key Vaultu ze sekce 2.

Provozní vlastnosti, které je nutné znát dopředu:

| Vlastnost | Chování |
|---|---|
| Instalace | **extension-based (V2)** přes VM extension; mimo Azure přes Azure Connected Machine agent (Arc) |
| Identita | **system-assigned managed identity stroje** |
| Skupiny | worker patří do skupiny; skupina dělá HA a load balancing, job cílíte na **skupinu, ne na stroj** |
| Odběr jobů | worker se ptá každých **30 s** a vezme si **~4 joby na jeden ping** |
| Když skupina neodpovídá | bez pingu po **30 min** se job po třech pokusech suspenduje |
| Kontext běhu | lokální **System** (Windows) / `nxautomation` (Linux) |
| Strop | 4 000 workerů na jeden Automation account |

> [!IMPORTANT] Restart stroje spustí job od začátku
> Když se hostitelský stroj rebootuje, běžící job se **spustí znovu od začátku**, a po více
> než třech restartech se suspenduje. U dávky nad tenantem to znamená, že **idempotence
> není hezká vlastnost, ale podmínka** — přesně to, co dokazují testy u
> [`solution/Sync-CourseList.ps1`](solution/Sync-CourseList.ps1): druhý běh nad stejnými
> daty nesmí udělat nic.

> [!WARNING] Starší agent-based worker je mrtvý — nefungují na něj staré návody
> **Agent-based (V1) User Hybrid Runbook Worker byl ukončen 31. 8. 2024** a od
> **1. 4. 2025** se joby na něm nespouští. Podporovaná je výhradně **extension-based (V2)**
> varianta. Starší návody vedou na Log Analytics agenta — ty ignorovat.

## Klíčové rozlišení

- **Control plane vs runtime** — u Hybrid Runbook Workeru kupujete rozvrh, credential store
  a auditní stopu, ne výpočet. Výpočet je váš, a s ním i runtime, moduly a limity stroje.
  U všech ostatních variant dostáváte obojí v jednom.
- **Modul v balíčku vs modul v image vs modul na stroji** — na Flex Consumption nese moduly
  deployment package (managed dependencies tam nejsou), u kontejneru image, u on-prem stroj.
  Ve všech třech držíte verzi vy — u Automation accountu ji držíte **mimo repo**.
- **Timeout, který se dá zvednout, vs strop, který nejde** — `replicaTimeout` je
  konfigurace; fair share u Automation je vlastnost služby, kterou obejde až jiná
  architektura.
- **Scale-to-zero vs běžící železo** — Functions (Flex), Automation v sandboxu i Container
  Apps Job neplatíte při nečinnosti; Hybrid Worker a scheduled task platíte pořád, protože
  platíte stroj.
- **Sandbox vs vlastní runtime** — Azure sandbox neumí `.exe` ani jiný .NET; kontejner
  i Hybrid Worker umí, co si do nich dáte.
- **Identita vázaná na resource vs identita, kterou lze vzít s sebou** — managed
  identita nemá secret, a proto ji **nelze přenést do cizího tenantu**. Certifikát
  přenést lze, protože secret je. U jednoho tenantu vyhrává MI, u víc tenantů je
  odpověď **MI jako federated credential na app registraci** (bez secretu), nebo
  certifikát v Key Vaultu (univerzálnější, ale secret existuje).

## Zdroje (Microsoft)

- [Azure Functions scale and hosting](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale) — timeouty a limity plánů
- [Flex Consumption plan](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan) — doporučený serverless plán; Consumption je legacy. „Flex Consumption doesn't support managed dependencies in PowerShell."
- [Azure Functions PowerShell developer guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell) — managed dependencies vs moduly v app content
- [Jobs in Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/jobs) — trigger typy, `replicaTimeout`, cron
- [Runbook execution in Azure Automation](https://learn.microsoft.com/en-us/azure/automation/automation-runbook-execution) — fair share, sandbox limity, trusted services
- [Azure Automation Hybrid Runbook Worker overview](https://learn.microsoft.com/en-us/azure/automation/automation-hybrid-runbook-worker) — pět scénářů, extension-based V2, nezávislost na fair share, chování při restartu stroje
- [Azure Automation limits](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-automation-limits)
- [Managed identities for Azure resources](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview) — service principál vázaný na životní cyklus resource; managed identita jako federated credential na Entra ID aplikaci (limit 20 FIC)
- [Configure an application to trust a managed identity](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-config-app-trust-managed-identity) — cesta přes hranici tenantu bez secretu
- [Connect-PnPOnline](https://pnp.github.io/powershell/cmdlets/Connect-PnPOnline.html) — `-CertificateBase64Encoded` pro certifikát vytažený z Key Vaultu; `-Tenant` je u certifikátových cest povinný
- [Integration and automation platform options in Azure](https://learn.microsoft.com/en-us/azure/azure-functions/functions-compare-logic-apps-ms-flow-webjobs)

## Stav produktu / delta

> [!WARNING] Consumption plan je LEGACY — stav k 2026-09
> Microsoft označuje **Consumption plan jako legacy** a pro nové serverless function apps
> doporučuje **Flex Consumption**. Linux Consumption je **retired**; hostování na Linux
> Consumption se ruší **30. 9. 2028** a apps na v3 runtime na Linux Consumption přestaly
> běžet **30. 9. 2026**.
>
> **Kurzovní prostředí je na Flex Consumption** — přepsáno 2026-09-08 v `environment.md`,
> `scripts/README.md` a v [`../siem-blob-integration/`](../siem-blob-integration/). Ta změna
> není kosmetická: Flex Consumption podporuje **výhradně event-based Blob trigger**, takže
> argument o vynucené Event Grid subscription na něm platí silněji než na Consumption —
> polling-based varianta tam neexistuje vůbec.
>
> Zbývá ověřovat **dostupnost Flex Consumption ve zvoleném regionu** — plán nepokrývá
> všechny a v nepodporovaném se v portálu ani nezobrazí.
>
> Ověřovat i **nepodporu managed dependencies v PowerShellu** — je to dnes uvedené
> mezi *Considerations* Flex Consumption plánu, ale je to typ omezení, které Microsoft
> časem odstraňuje. Kdyby padlo, řádek o modulech v tabulce se mění.
>
> Timeout hodnoty (Consumption 5/10 min vs 30 min a neomezeno u ostatních) se mění —
> ověřit na [functions-scale](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale).

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Fair share u Automation (dnes 3 h), limity Azure sandboxu (1 GB temp, .NET Framework
> 4.7.2, 10 jobů na sandbox) a seznam trusted services se mění. Historie exekucí
> u Container Apps Jobs je dnes omezená na posledních 100 úspěšných a 100 neúspěšných —
> pro auditní stopu to nestačí, logy patří do Log Analytics
> ([`../siem-blob-integration/`](../siem-blob-integration/)).
>
> **Účtování Hybrid Runbook Workeru neuvádět z hlavy.** Kalkulátor
> [`../../day-5/performance-cost-capstone/solution/Get-HostingCost.ps1`](../../day-5/performance-cost-capstone/solution/Get-HostingCost.ps1)
> počítá **cloudové** minuty jobu (meter `Basic Runtime`); u Hybrid Workeru je model jiný
> a hlavní náklad je stejně samotný stroj. Před citováním čísla zákazníkovi ověřit
> v aktuálním Azure ceníku Automation.
>
> **Konfigurační část Automation se zužuje.** State Configuration (DSC) a Update Management
> se přesouvají do Azure Machine Configuration a Azure Update Manageru, takže role
> Automation míří na plánování skriptů. Přesná data retirementu ověřit před během — tento
> materiál je záměrně neuvádí.
