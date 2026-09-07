# Explainer · Runtime prostředí: DEV stanice, kontejnery, servery

Deep-dive k [`README.md`](README.md). Automatizační skript žije na třech typech strojů —
DEV stanice, CI/kontejner, server pro plánované běhy — a každý má jiné požadavky na
instalaci, aktualizace a hlavně autentizaci.

## DEV stanice — reprodukovatelnost přes konfiguraci

- Jednotný základ: VS Code + PowerShell 7 + extension pack, verze modulů dle
  [`../../day-2/powershell-deep-dive/explainer-module-management.md`](../../day-2/powershell-deep-dive/explainer-module-management.md).
- **Devcontainer** (`.devcontainer/devcontainer.json` v repu) definuje celé prostředí jako
  kód — nový člen týmu (nebo nová učebna) dostane identické prostředí za minuty místo
  půldne ručního ladění "u mě to funguje".
- Auth na DEV stanici: interaktivní/device code (delegated) — vývojář je přítomen.

## Kontejnery a CI

- `mcr.microsoft.com/powershell` image = čistý, reprodukovatelný PS7 runtime pro pipeline
  agenty; verze modulů se instalují v build kroku s pinem (`Install-PSResource -Version`),
  takže image je deterministická.
- CLI for Microsoft 365 (npm balíček, bez PowerShell závislosti) sedí do `node` image —
  přesně tady je jeho místo v nástrojové mapě (viz
  [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/)).
- Auth v CI: **nikdy interaktivní** — certificate (secret/cert z pipeline secret store,
  ne v repu) nebo federated credentials, kde je platforma podporuje.

## Servery pro plánované běhy

| Kde | Plánovač | Auth |
|---|---|---|
| On-premise server | Task Scheduler | certifikát v **machine** certificate store (ne user store — task běží pod servisním účtem) |
| Azure | Automation Runbook / Function timer | **managed identity** — žádný spravovaný secret |

- Detailně v [`../../day-4/azure-integration-patterns/`](../../day-4/azure-integration-patterns/)
  (srovnání plánovačů) a [`../../day-5/security-hardening/`](../../day-5/security-hardening/)
  (rotace certifikátů).
- Zlaté pravidlo: **žádný secret v definici tasku, plaintext souboru ani skriptu** —
  cert store, Key Vault, nebo managed identity. Nic jiného.

## Aktualizační strategie napříč prostředími

DEV průběžně (chceš vidět breaking changes první), CI/server pin + vědomý, otestovaný
upgrade. Nikdy `Update-Module` v produkčním scheduled tasku "aby bylo aktuální".

## Zdroje (Microsoft)

- [Managed identities for Azure resources — overview](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)
- [Install-PSResource (PSResourceGet)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/install-psresource)

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — dostupné tagy `mcr.microsoft.com/powershell` image a
> aktuální doporučení pro federated credentials v CI platformách se mění; ověřit před
> přípravou demo pipeline.
