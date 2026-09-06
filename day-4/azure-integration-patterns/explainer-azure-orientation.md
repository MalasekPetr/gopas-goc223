# Explainer · Azure orientace: subscription, RBAC a kde skript vlastně běží

Vstupní srovnání úrovní před laby tohoto dne — určeno i k přečtení předem. Odpovídá na
tři otázky, které rozhodují dřív, než se napíše první řádek Function kódu: **kdo tam
vůbec smí**, **kde skript poběží** a **co to znamená pro credentialy**.

## Tenant vs subscription — dvě soustavy, jeden účet

**Entra tenant** je adresář identit (uživatelé, skupiny, app registrace, role).
**Azure subscription** je fakturační a provozní kontejner pro cloudové zdroje, *připojený*
k tenantu. Z toho plyne věta, která šetří hodiny zmatku: **Global administrator v tenantu
nemá automaticky žádný přístup k Azure.** Entra role a Azure RBAC jsou oddělené soustavy.

Hierarchie: subscription → **resource group** (logická krabice na související zdroje,
jednotka úklidu a účtování) → **resource** (Function App, Storage Account, Key Vault…).

## Azure RBAC — role na scope

Přístup v Azure = **role** (co smím: Reader / Contributor / Owner nebo jemnější)
přiřazená na **scope** (kde to smím: subscription / resource group / jednotlivý resource).
Least-privilege princip z [`../../day-1/automation-strategy/`](../../day-1/automation-strategy/)
platí beze změny — jen se místo API permissions přiřazují role na co nejužší scope.
Vzor pro kurz: student = Contributor jen na vlastní resource group, ne na subscription
(viz [`../../environment.md`](../../environment.md)).

## Kde skript běží — žebřík dospělosti automatizace

| Kde | Kdy stačí | Credentials |
|---|---|---|
| Vlastní stanice, ručně | ad-hoc, vývoj | interactive / device code (delegated) |
| Scheduled task na serveru | pravidelný běh on-prem | certifikát v **LocalMachine** store ([`../../day-2/powershell-deep-dive/explainer-certificates-keys.md`](../../day-2/powershell-deep-dive/explainer-certificates-keys.md)) |
| Azure Functions / Automation | pravidelný běh bez vlastního železa | **managed identity** — žádný spravovaný secret |
| Container Instances (ACI) | jednorázový nebo dávkový běh | managed identity, případně federated credentials |
| Container Apps Job | plánovaný běh v kontejneru, scale-to-zero | managed identity |
| CI/CD pipeline | build, test, nasazení skriptů | federated credentials / cert z Key Vaultu |

Pointa žebříku: čím výš, tím **méně tajemství leží na discích** — managed identity nemá
co ukrást ani co zapomenout zrotovat. Srovnání plánovačů a rozhodovací osa pro tento
kurz jsou v [`README.md`](README.md).

> [!NOTE] Kde žebřík neplatí
> **Migrační exekuce se po něm nedá posunout nahoru.** SPMT i ShareGate vyžadují Windows
> PowerShell 5.x, agenti Migration Manageru jsou Windows služba — žádná Linux Function,
> žádný `mcr.microsoft.com/powershell` kontejner. Do Azure jde přesunout jen *stroj*,
> ne runtime. Proč a co z toho plyne pro plánování vln:
> [`../../day-3/migration-patterns/explainer-migration-tools.md`](../../day-3/migration-patterns/explainer-migration-tools.md).

## Kontejnery — přenositelné běhové prostředí

Kontejner je zabalený běhový svět (OS knihovny + runtime + nástroje), který se všude
spustí stejně. Image `mcr.microsoft.com/powershell` obsahuje PowerShell 7 na Linuxu —
tentýž skript z labů v něm běží beze změny, jen bez `Cert:` provideru (na Linuxu
neexistuje, proto PEM). **Devcontainer** (`devcontainer.json` v repu) dá týmu identické
vývojové prostředí ve VS Code — navazuje na runtime prostředí z
[`../../day-1/vscode-copilot-env/explainer-runtime-environments.md`](../../day-1/vscode-copilot-env/explainer-runtime-environments.md).

Podstatná zpráva pro adminy: **kontejnery není nutné provozovat, aby se daly použít.**

| Služba | K čemu | Poznámka |
|---|---|---|
| **Cloud Shell** | konzole v prohlížeči | sama je kontejner s PS7; efemérní, přežije jen `$HOME` |
| **Container Instances (ACI)** | „spusť image, vypiš log, zmiz" | jeden příkaz, účtuje se po sekundách |
| **Container Apps Job** | plánovaný běh (cron), scale-to-zero | dospělejší varianta pro opakované úlohy |
| **Container Registry (ACR)** | kde bydlí vlastní image | až když si obraz stavíte sami |

Lokální Docker/Podman je potřeba teprve tehdy, když chcete image **stavět** — pro
spouštění stačí Azure.

```powershell
# Davkovy beh skriptu v kontejneru bez lokalniho Dockeru
$rg = "rg-<jmeno-prijmeni>-demo"
az group create -n $rg -l westeurope

az container create -g $rg -n kurz-pwsh `
  --image mcr.microsoft.com/powershell:latest `
  --os-type Linux --cpu 1 --memory 1 --restart-policy Never `
  --command-line 'pwsh -NoProfile -Command "$PSVersionTable.PSVersion.ToString()"'

az container logs   -g $rg -n kurz-pwsh
az container delete -g $rg -n kurz-pwsh --yes     # uklid - uctuje se po sekundach
```

`--restart-policy Never` = dávková úloha, ne služba. `--assign-identity <resourceId>`
přidá kontejneru managed identitu — pak v něm neběží žádný secret ani certifikát.

## Klíčové rozlišení

- **Entra role vs Azure RBAC vs M365 licence** — tři oddělené soustavy; GA != přístup
  do Azure, licence != oprávnění.
- **Resource group jako jednotka úklidu** — co vznikne spolu, ať zmizí spolu; základ
  nákladové hygieny (a podmínka cleanupu po kurzu).
- **Managed identity vs certifikát** — obojí app-only; managed identity jen na Azure
  resourcech, zato bez čehokoli, co jde ukrást nebo zapomenout zrotovat.
- **Kontejner vs VM** — kontejner nese běhové prostředí procesu, ne celý OS; startuje
  v sekundách a je definovaný souborem v repu.

## Tipy

- Kontejnery zkoušet v Azure (Cloud Shell, ACI), ne na vlastním stroji — lokální runtime
  řešit teprve, až se budou image **stavět**.
- ACI vždy uklidit (`az container delete`); zapomenutý kontejner s `--restart-policy Always`
  běží věčně. Dema nikdy do produkční resource group.
- Na Windows vyžadují Docker Desktop i Podman **WSL2** — instalace znamená restart
  stroje; nepouštět se do ní pět minut před tím, než je potřeba.
- Docker Desktop je pro větší organizace placený; Podman toto omezení nemá a příkazy
  jsou stejné.

## Zdroje (Microsoft)

- [Azure fundamental concepts](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/considerations/fundamental-concepts)
- [What is Azure role-based access control (RBAC)?](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)
- [Managed identities for Azure resources](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)
- [Azure Container Instances — quickstart (Azure CLI)](https://learn.microsoft.com/en-us/azure/container-instances/container-instances-quickstart)
- [Container Apps Jobs](https://learn.microsoft.com/en-us/azure/container-apps/jobs)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Syntaxe `az container`, podpora managed identity v ACI, vzhled Cloud Shellu a licenční
> podmínky Docker Desktopu se mění. Ceny a cleanup po kurzu ověřit proti aktuálnímu
> Azure ceníku před během.
