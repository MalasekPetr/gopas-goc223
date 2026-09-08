# Prostředí kurzu — pracovní tenant a Azure

Referenční údaje o prostředí, na které se odkazují laby.

> [!IMPORTANT] Publikace
> Repo je **public** — tento soubor obsahuje jen student-facing část. Instructor-only údaje
> (tenant ID, admin účet, jmenný seznam účastníků, app registrace se secrety/certifikáty,
> Azure subscription ID) jsou drženy mimo repo, v instruktorském kanálu.

## Student-facing — M365 tenant

| Položka | Hodnota |
|---|---|
| Tenant | M365 Developer tenant (Microsoft 365 Developer Program) |
| Přihlašovací doména | `cloudedu.cz` |
| Účty studentů | `jmeno.prijmeni@cloudedu.cz` (bez diakritiky), max. 25 účtů |
| Licence | Microsoft 365 **E5 Developer** |
| Role | **Global administrator** — všichni studenti (viz [`day-1/onboarding/ways-of-working.md`](day-1/onboarding/ways-of-working.md)) |
| Hesla | přidělena na začátku kurzu, MFA povinné při prvním přihlášení |

> [!NOTE] Všichni studenti jsou Global administrátoři jednoho sdíleného tenantu — izolaci
> nezajišťují role, ale pravidla a naming konvence (`ways-of-working.md`). Tenant je zdarma
> (Developer Program) a po kurzu se obsah čistí offboarding skripty.

> [!WARNING] Ověřit k datu běhu.
> M365 Developer Program byl v roce 2024 omezen (nové sandboxy jen pro vybrané subscribery,
> obnova existujícího tenantu závisí na aktivitě). Ověřit životnost tenantu `cloudedu.cz`
> minimálně týden před během — náhrada se nedá zajistit přes noc.

## Student-facing — Azure

M365 Developer tenant **neobsahuje** Azure subscription — Azure laby (den 4) běží nad
samostatnou, placenou subscription připojenou k témuž tenantu.

| Položka | Hodnota |
|---|---|
| Azure subscription | dedikovaná kurzová subscription (instruktorský kanál) |
| Resource group per student | `rg-goc223-<jmeno-prijmeni>` — vytváří `New-CourseStudentAzureResources.ps1` |
| Rozsah | Storage Account (Blob, **general-purpose v2**), Function App (**Flex Consumption plan**), Event Grid Topic, **Log Analytics workspace + Data Collection Rule** — dle dne (D4) |
| Log Analytics | **sdílený workspace pro celý kurz + samostatná DCR per student** (izolace dat mezi studenty bez ceny za 25 workspaců) |
| Role studenta | Contributor jen na vlastní resource group, ne na subscription |

> [!NOTE] Global administrator v tenantu ≠ přístup k Azure — Entra role a Azure RBAC jsou
> oddělené soustavy (viz [`day-1/api-landscape/`](day-1/api-landscape/)).

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Azure Flex Consumption náklady jsou u tohoto rozsahu labů zanedbatelné, ale sledovat
> orfánní resources po předchozích bězích (`Get-AzResourceGroup -Name 'rg-goc223-*'`)
> a mít nastavený budget alert na subscription.
>
> **Log Analytics je jediná položka rozsahu, která se neúčtuje po výpočetním čase, ale
> po objemu ingestovaných dat a retenci.** U labu jde o kilobajty testovacích záznamů,
> takže reálný náklad je zanedbatelný — riziko není v labu, ale v **chybně nastavené DCR
> nebo zacyklené Function**, které umí ingestovat řádově víc. Budget alert na subscription
> je tu proto povinný, ne doporučený. Sazby a případný bezplatný objem ověřit
> v aktuálním Azure ceníku před během.

> [!IMPORTANT] Plán je Flex Consumption, ne Consumption — změna k 2026-09
> Consumption plan je u Azure Functions nyní **legacy** a Linux Consumption je retired;
> pro nové serverless function apps Microsoft doporučuje **Flex Consumption**. Kurzovní
> rozsah je proto na Flex Consumption a **není to kosmetická změna** — lab
> v [`day-4/siem-blob-integration/`](day-4/siem-blob-integration/) na tom plánu stojí:
> Flex Consumption podporuje **výhradně event-based Blob trigger**, takže Event Grid
> subscription je tam vynucená, ne volitelná.
>
> Před během ověřit **dostupnost Flex Consumption ve zvoleném regionu** — nepokrývá
> všechny a v nepodporovaném regionu se plán v portálu ani nezobrazí. Zdroj:
> [Flex Consumption plan](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan).

## Student-facing — vývojářské nástroje

| Položka | Hodnota |
|---|---|
| VS Code | poslední stabilní verze, rozšíření **PowerShell** (`ms-vscode.powershell`) + Azure Functions |
| PowerShell | **PowerShell 7.4+** vedle Windows PowerShell 5.1 (PnP PowerShell 7.4.0 vyžaduje) |
| Node.js | aktuální LTS (**Node 22**), instalovaný přes **fnm** — jediný důvod je CLI for Microsoft 365 (npm balíček); viz [`day-1/toolchain-setup/`](day-1/toolchain-setup/) |
| AI asistent | **Microsoft Copilot Chat** — v prohlížeči pod kurzovním účtem; žádná samostatná licence se nekupuje |
| Agent kurzu | **Scripting Advisor** — deklarativní agent poskytnutý autorem kurzu, publikovaný v tenantu (ne v Agent Store). Zdrojový kód a architektura: [`day-1/vscode-copilot-env/agent-scripting-advisor/`](day-1/vscode-copilot-env/agent-scripting-advisor/) |
| Git | instaluje se v bloku [`day-1/toolchain-setup/`](day-1/toolchain-setup/); `user.name`/`user.email` si student nastaví tam |
| Ověření | `scripts/verify-toolchain.ps1` — vzniká v labu [`day-1/toolchain-setup/`](day-1/toolchain-setup/) |

### Náklady — upozornění pro učebnu
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> AI asistent kurzu je **Microsoft Copilot Chat** v rámci kurzovního účtu — nic se
> nedokupuje ani nepřiřazuje před D1. Pokud se v běhu má ukazovat **agent nad firemními
> daty** (SharePoint agents, agent s capability `OneDriveAndSharePoint`/`Email`/`People`),
> jde o **měřenou spotřebu** (pay-as-you-go): před kurzem musí být v M365 admin centru
> založená **billing policy** navázaná na Azure subscription, připojená ke službě
> a s nastaveným rozpočtem. Rozpočet ale jen **notifikuje, nevynucuje** — tvrdá brzda je
> odpojení policy.
>
> Kurzovní agent **Scripting Advisor** je postavený tak, aby do téhle kategorie nespadl:
> nemá **žádnou capability nad daty tenantu**, jen WebSearch a MCP akci. Zda deklarovaná
> MCP akce zařazení mění, dokumentace neříká — **ověřit na řádku agenta v Copilot Credits
> reportu před během** (Reports > Usage > Microsoft Copilot > Credits). Dokud to není
> ověřeno, agent jede jako instruktorské demo na jednom sedadle.
> Mechanika a role: [`day-1/vscode-copilot-env/explainer-copilot-licensing.md`](day-1/vscode-copilot-env/explainer-copilot-licensing.md).
