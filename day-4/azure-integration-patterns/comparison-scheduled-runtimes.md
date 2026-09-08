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
| Jak se dovnitř dostanou moduly | `requirements.psd1` (managed dependencies) — platforma je stahuje | import do Automation accountu | **zapečené v image** | `Install-Module` na stroji |
| Kdo drží verzi modulu | platforma, s vaší konfigurací | vy, ale mimo repo | **vy, v `Dockerfile` v repu** | vy, ručně |
| Strop doby běhu | 30 min default, **neomezeno** (Flex/Premium/Dedicated) | **3 h — fair share**, job je zastaven | `replicaTimeout` (nastavíte v sekundách) | žádný |
| Plánovač | timer trigger (NCRONTAB) | Automation schedule | **cron výraz, 5 polí, v UTC** | Task Scheduler |
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

### 3. Determinismus runtime je hlavní argument pro kontejner

`Microsoft.Graph` je meta-modul s desítkami sub-modulů. Ve Functions se řeší
`requirements.psd1` a managed dependencies — platforma moduly stahuje a jejich přesná verze
se může posunout pod rukama. V kontejneru je **pin v `Dockerfile`, který leží v repu**
vedle skriptu, takže image je deterministická a přezkoumatelná.

Je to tentýž princip jako `#Requires` a `-RequiredVersion` z
[`../../day-1/toolchain-setup/`](../../day-1/toolchain-setup/), jen posunutý o vrstvu výš:
**co skript potřebuje k běhu, patří do repa** — a u kontejneru to platí i pro runtime.

Container Apps Job k tomu dává **cron plánovač, `replicaTimeout` podle vaší potřeby,
`replicaRetryLimit`, `parallelism`** a scale-to-zero, tedy stejnou ekonomiku jako
serverless. Cenou je, že si musíte postavit image — což pro tým, který už má repo
a pipeline, není nic navíc.

## Rozhodovací osa v jedné větě

> **Krátká reakce na event → Functions. Jednoduchá periodická remediace v Azure →
> Automation Runbook. Dávka, kde záleží na verzích modulů nebo na době běhu →
> Container Apps Job. Dosah na on-prem → scheduled task, pořád legitimní.**

A pravidlo, které platí napříč: **žádná z těch variant nesmí spoléhat na interaktivní
přihlášení.** Auth matice je v [`README.md`](README.md).

## Klíčové rozlišení

- **Platforma drží verzi vs vy držíte verzi** — managed dependencies vs pin v image.
  U skriptu, který má běžet měsíce beze změny, je to ta podstatná otázka.
- **Timeout, který se dá zvednout, vs strop, který nejde** — `replicaTimeout` je
  konfigurace; fair share u Automation je vlastnost služby.
- **Scale-to-zero vs běžící železo** — Functions (Flex), Automation i Container Apps Job
  neplatíte při nečinnosti; scheduled task na serveru platíte pořád.
- **Sandbox vs vlastní runtime** — Automation sandbox neumí `.exe` ani jiný .NET;
  kontejner umí, co si do něj dáte.

## Zdroje (Microsoft)

- [Azure Functions scale and hosting](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale) — timeouty a limity plánů
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
> **Tohle se dotýká kurzovního prostředí** — `environment.md` uvádí Function App na
> Consumption plánu a [`../siem-blob-integration/`](../siem-blob-integration/) na Consumption
> staví argument o vynucené Event Grid subscription. Před během ověřit, na jakém plánu
> studentské Function Apps reálně vzniknou, a případně přepsat na Flex Consumption.
>
> Timeout hodnoty (Consumption 5/10 min vs 30 min a neomezeno u ostatních) se mění —
> ověřit na [functions-scale](https://learn.microsoft.com/en-us/azure/azure-functions/functions-scale).

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Fair share u Automation (dnes 3 h), limity Azure sandboxu (1 GB temp, .NET Framework
> 4.7.2, 10 jobů na sandbox) a seznam trusted services se mění. Historie exekucí
> u Container Apps Jobs je dnes omezená na posledních 100 úspěšných a 100 neúspěšných —
> pro auditní stopu to nestačí, logy patří do Log Analytics
> ([`../siem-blob-integration/`](../siem-blob-integration/)).
