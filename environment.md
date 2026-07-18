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
| Rozsah | Storage Account (Blob), Function App (Consumption plan), Event Grid Topic — dle dne (D4) |
| Role studenta | Contributor jen na vlastní resource group, ne na subscription |

> [!NOTE] Global administrator v tenantu ≠ přístup k Azure — Entra role a Azure RBAC jsou
> oddělené soustavy (viz [`day-1/opt-architecture-overview/`](day-1/opt-architecture-overview/)).

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Azure Consumption-plan náklady jsou u tohoto rozsahu labů zanedbatelné, ale sledovat
> orfánní resources po předchozích bězích (`Get-AzResourceGroup -Name 'rg-goc223-*'`)
> a mít nastavený budget alert na subscription.

## Student-facing — vývojářské nástroje

| Položka | Hodnota |
|---|---|
| VS Code | poslední stabilní verze, extension pack: PowerShell, GitHub Copilot, Azure Functions |
| PowerShell | PowerShell 7 (aktuální LTS) vedle Windows PowerShell 5.1 |
| Node.js | aktuální LTS kompatibilní s SPFx generátorem (viz [`day-5/spfx-fundamentals/`](day-5/spfx-fundamentals/)) |
| GitHub Copilot | individuální licence (Copilot Individual/Business) — **není** M365 Copilot, samostatný nákup mimo tenant |
| Git | nainstalovaný, nakonfigurovaný `user.name`/`user.email` před D1 |

### Náklady — upozornění pro učebnu
> [!WARNING] Ověřit k datu běhu.
> GitHub Copilot licence musí být přidělena každému studentovi před D1 (samostatný nákup/trial,
> mimo M365 licenční tok) — zajistit dostatečně dopředu, ne den před kurzem.
