# Explainer · Správa PowerShell modulů: scopes, pinning, PSResourceGet

Deep-dive k [`README.md`](README.md). Instalace modulu není jednorázový klik — na DEV
stanici, CI agentovi a produkčním serveru se řeší jinak, a špatná strategie aktualizací
je nejčastější příčina "včera to fungovalo".

## Instalační scope

| Scope | Kam | Kdy |
|---|---|---|
| `-Scope CurrentUser` (default v PS7) | profil uživatele, bez admin práv | DEV stanice, sdílené stroje |
| `-Scope AllUsers` | `Program Files`, vyžaduje admin | server, kde skripty běží pod servisním účtem jiným než ten, kdo instaloval |

Klasická past: modul nainstalovaný jako `CurrentUser` pod admin účtem není vidět pro
scheduled task běžící pod servisním účtem — "funguje ručně, nefunguje z plánovače".

## PSResourceGet — moderní package manager

**Microsoft.PowerShell.PSResourceGet** je nástupce PowerShellGet v2: výrazně rychlejší,
spolehlivější chybové stavy, jednotný pojem "PSResource" pro moduly/skripty/DSC resources.
Klíčové cmdlety: `Install-PSResource`, `Find-PSResource`, `Update-PSResource`. Pro starší
skripty existuje kompatibilní vrstva **CompatPowerShellGet**, která staré `Install-Module`
příkazy přesměruje — migrace nemusí být big-bang.

```powershell
# Moderni instalace s pinem na presnou verzi
Install-PSResource -Name PnP.PowerShell -Version 3.1.0 -Scope CurrentUser
```

## Version pinning a side-by-side verze

- **DEV stanice**: aktuální verze, `Update-PSResource` průběžně — chceš vidět breaking
  changes dřív než produkce.
- **Server/CI**: **pin na přesnou verzi** (`-Version x.y.z`), aktualizace jen jako vědomý,
  otestovaný krok. `Update-Module`/`Update-PSResource` v produkci bez testu = incident
  čekající na spuštění.
- PowerShell umí držet víc verzí modulu vedle sebe (`Get-InstalledPSResource -Name X` je
  vypíše); skript si vynutí konkrétní verzi přes
  `Import-Module PnP.PowerShell -RequiredVersion 3.1.0`.

Konkrétní příklad, proč pinovat: **ExchangeOnlineManagement 3.10.0 (červen 2026) vyžaduje
PowerShell 7.6+** — nepinovaná automatizace na serveru s PS 7.4 by po autoupdate modulu
přestala fungovat, přestože se "nic nezměnilo".

## PS 5.1 vs 7.x

- Nové moduly cílí na PS7 (EXO 3.10+ dokonce PS 7.6+); Windows PowerShell 5.1 zůstává
  relevantní jen pro legacy závislosti.
- SPO Management Shell má v PS7 historicky quirky (`-UseWindowsPowerShell` import fallback
  na některých verzích — viz tripwires v [`instructor-notes.md`](instructor-notes.md)).
- Praktické pravidlo kurzu: **vše v PS7**, PS 5.1 jen když konkrétní modul jinak nejde.

## Zdroje (Microsoft)

- [Install-PSResource (Microsoft.PowerShell.PSResourceGet)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/install-psresource)
- [What's new in the Exchange Online PowerShell module](https://learn.microsoft.com/en-us/powershell/exchange/whats-new-in-the-exo-module?view=exchange-ps)

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Verze modulů a jejich minimální PS požadavky (EXO 3.10 → PS 7.6+) se mění po měsících;
> před během ověřit aktuální čísla verzí používaná v ukázkách.
