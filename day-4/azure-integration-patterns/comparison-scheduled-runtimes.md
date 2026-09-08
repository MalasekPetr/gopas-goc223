# Comparison · Kde nechat běžet opakovaný PowerShell skript

Doplněk k [`README.md`](README.md). Žebřík v [`explainer-azure-orientation.md`](explainer-azure-orientation.md)
řadí možnosti podle toho, **kolik tajemství leží na discích**. Tenhle soubor je řadí podle
jiné osy: **co to udělá s PowerShellovým skriptem**, který má běžet opakovaně nad M365.

Ta osa je jiná, protože u PowerShellu rozhodují věci, které u C# Functions nikoho netrápí —
jak se do runtime dostanou moduly, jestli je jejich verze pod vaší kontrolou, a jestli
dávka nad tisíci weby vůbec doběhne.

## Rozhodovací tabulka

| | **Functions** (timer trigger) | **Automation Runbook** | **Container Apps Job** | **on-prem Task Scheduler** |
|---|---|---|---|---|
| Jak se dovnitř dostanou moduly | **v app content** (deployment package) — Flex Consumption managed dependencies **nepodporuje** | import do Automation accountu | **zapečené v image** | `Install-Module` na stroji |
| Kdo drží verzi modulu | vy, v deployment package | vy, ale mimo repo | **vy, v `Dockerfile` v repu** | vy, ručně |
| Strop doby běhu | 30 min default, **neomezeno** (Flex/Premium/Dedicated) | **3 h — fair share**, job je zastaven | `replicaTimeout` (nastavíte v sekundách) | žádný |
| Plánovač | timer trigger (NCRONTAB, **UTC** — `TZ`/`WEBSITE_TIME_ZONE` na Flexu nefunguje) | Automation schedule | **cron výraz, 5 polí, v UTC** | Task Scheduler (lokální čas) |
| Cena při nečinnosti | 0 (Flex Consumption) | 0 | **0 — scale-to-zero** | běžící železo |
| Credential | managed identity | managed identity | managed identity | certifikát v machine store |
| Spustí `.exe` / subprocess | ano | **ne** (Azure sandbox) | ano | ano |
| Kdy je to správná volba | krátká reakce na event, HTTP endpoint | jednoduchá periodická remediace v Azure | **dávka s pinovaným runtime, delší běh, vlastní nástroje** | dosah na on-prem zdroje |

## Tři věci, které rozhodují víc než tabulka

### 1. Fair share u Automation je 3 hodiny a job se NEVRÁTÍ

Azure Automation sdílí workery mezi účty a mechanismus **fair share** po **třech hodinách**
job odloží nebo zastaví. U **PowerShell a Python runbooků** je job **zastaven a znovu
nespuštěn** — stav skončí na `Stopped`.

Pro migrační nebo inventurní dávku nad velkým tenantem to je tvrdý strop, který nejde
zvednout konfigurací. Cesty ven jsou dvě: **Hybrid Runbook Worker** (fair share se na něj
nevztahuje) nebo child runbooky běžící paralelně. Obojí je práce, kterou Container Apps Job
nepotřebuje.

### 2. Azure sandbox u Automation neumí spustit `.exe`

Runbooky v Azure sandboxu **nepodporují volání procesů a subprocesů**. Sandbox navíc dává
**1 GB** temp místa, podporuje jen **.NET Framework 4.7.2** bez možnosti upgradu, neumožňuje
elevaci a v jednom sandboxu může běžet **až 10 jobů, které se navzájem ovlivňují** —
`Disconnect-AzAccount` v jednom runbooku odpojí **všechny ostatní joby ve stejném sandboxu**.

Pro tenhle kurz to má konkrétní důsledek: **migrační nástroje se do Automation Runbooku
nedostanou.** SPMT je desktop aplikace s PowerShell modulem nad Windows PowerShellem 5.x
(viz [`../../day-3/migration-patterns/explainer-migration-tools.md`](../../day-3/migration-patterns/explainer-migration-tools.md)),
což sandbox neumí ani spustit.

> [!IMPORTANT] Azure Firewall na Key Vaultu zablokuje Automation
> Zapnutý firewall na **Azure Storage, Key Vault nebo Azure SQL** blokuje přístup
> z Automation runbooků — **a to i se zapnutou výjimkou „allow trusted Microsoft services",
> protože Automation na seznamu trusted services není.** Průchod pak existuje jen přes
> Hybrid Runbook Worker a service endpoint.
>
> Kurz přitom učí ukládat credentialy do Key Vaultu
> ([`../../day-1/vscode-copilot-env/explainer-runtime-environments.md`](../../day-1/vscode-copilot-env/explainer-runtime-environments.md)).
> Kombinace „runbook + zamčený Key Vault" je architektura, která vypadá správně a nefunguje.

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

Container Apps Job k tomu dává **cron plánovač, `replicaTimeout` podle vaší potřeby,
`replicaRetryLimit`, `parallelism`** a scale-to-zero, tedy stejnou ekonomiku jako
serverless. Cenou je, že si musíte postavit image — což pro tým, který už má repo
a pipeline, není nic navíc.

> [!NOTE] Tři vlastnosti Flex Consumption, které zaskočí při automatizaci
> **Jedna aplikace na jeden plán**, **deployment slots nejsou podporované** a **migrace
> existující aplikace na Flex (ani z Flexu jinam) není možná** — přechod znamená založit
> novou aplikaci a nasadit kód znovu. Kdo plánuje hostování dopředu, ať to ví teď, ne
> až u prvního nasazení.

## Rozhodovací osa v jedné větě

> **Krátká reakce na event → Functions. Jednoduchá periodická remediace v Azure →
> Automation Runbook. Dávka, kde záleží na verzi runtime, na vlastních nástrojích nebo na době běhu →
> Container Apps Job. Dosah na on-prem → scheduled task, pořád legitimní.**

A pravidlo, které platí napříč: **žádná z těch variant nesmí spoléhat na interaktivní
přihlášení.** Auth matice je v [`README.md`](README.md).

## Klíčové rozlišení

- **Modul v balíčku vs modul v image vs modul na stroji** — na Flex Consumption nese moduly
  deployment package (managed dependencies tam nejsou), u kontejneru image, u on-prem stroj.
  Ve všech třech držíte verzi vy — u Automation accountu ji držíte **mimo repo**.
- **Timeout, který se dá zvednout, vs strop, který nejde** — `replicaTimeout` je
  konfigurace; fair share u Automation je vlastnost služby.
- **Scale-to-zero vs běžící železo** — Functions (Flex), Automation i Container Apps Job
  neplatíte při nečinnosti; scheduled task na serveru platíte pořád.
- **Sandbox vs vlastní runtime** — Automation sandbox neumí `.exe` ani jiný .NET;
  kontejner umí, co si do něj dáte.

## Zdroje (Microsoft)

- [Azure Functions scale and hosting](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale) — timeouty a limity plánů
- [Flex Consumption plan](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan) — doporučený serverless plán; Consumption je legacy. „Flex Consumption doesn't support managed dependencies in PowerShell."
- [Azure Functions PowerShell developer guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell) — managed dependencies vs moduly v app content
- [Jobs in Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/jobs) — trigger typy, `replicaTimeout`, cron
- [Runbook execution in Azure Automation](https://learn.microsoft.com/en-us/azure/automation/automation-runbook-execution) — fair share, sandbox limity, trusted services
- [Azure Automation limits](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-automation-limits)
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
