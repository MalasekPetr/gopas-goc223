# Prostředí kurzu — pracovní tenant

Referenční údaje o tenantu a Azure prostředí, na které se odkazují laby.

> [!IMPORTANT] Publikace
> Repo je **public** — tento soubor obsahuje jen student-facing část. Instructor-only údaje (tenant ID, admin účet, app registrace se secrety/certifikáty, model rolí, lifecycle účtů) jsou drženy mimo repo, v instruktorském kanálu.

## Student-facing — M365 tenant

| Položka | Hodnota |
|---|---|
| Tenant (org) | Malach IS |
| Přihlašovací doména | `spdemo.online` |
| Účty studentů | `user.11@spdemo.online` – `user.30@spdemo.online` (user 11–30) |
| Licence | Microsoft 365 **Business Basic** |
| SharePoint root URL | `https://ms365x17157302.sharepoint.com` |
| Hesla | přidělena na začátku kurzu |

> [!NOTE] Sdílený tenant s GOC224 (stejná doména/konvence účtů), samostatné app registrace a resource group per kurz — viz [`scripts/README.md`](scripts/README.md). Nikdy nesdílet ClientId/secret/cert mezi kurzy.

## Student-facing — Azure

| Položka | Hodnota |
|---|---|
| Azure subscription | dedikovaná kurzová subscription (instruktorský kanál) |
| Resource group per student | `rg-goc223-user<NN>` — vytváří `New-CourseStudentAzureResources.ps1` |
| Rozsah | Storage Account (Blob), Function App (Consumption plan), Event Grid Topic — dle dne (D4) |
| Role studenta | Contributor jen na vlastní resource group, ne na subscription |

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Azure Consumption-plan náklady jsou u tohoto rozsahu labů zanedbatelné, ale sledovat orfánní resources po předchozích bězích kurzu (Function Apps/Storage Accounts zapomenuté v resource group) — kontrola před každým under `Get-AzResourceGroup -Name 'rg-goc223-*'`.

## Student-facing — vývojářské nástroje

| Položka | Hodnota |
|---|---|
| VS Code | poslední stabilní verze, extension pack: PowerShell, GitHub Copilot, Azure Functions |
| Node.js | aktuální LTS (přesná verze — viz `day-5/spfx-fundamentals`, závisí na kompatibilitě s SPFx generátorem k datu běhu) |
| GitHub Copilot | individuální licence (Copilot Individual/Business) — **není** M365 Copilot, samostatný nákup mimo M365 tenant |
| Git | nainstalovaný, nakonfigurovaný `user.name`/`user.email` před D1 |

### Náklady — upozornění pro učebnu
> [!WARNING] Ověřit k datu běhu.
> GitHub Copilot licence musí být přidělena každému studentovi před D1 (samostatný nákup/trial, mimo M365 licenční tok) — ověřit dostupnost trial licencí nebo mít připravené sdílené/organizační sedadla dostatečně dopředu, ne den před kurzem.
