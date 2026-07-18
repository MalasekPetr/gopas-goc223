# Explainer · Migrační nástroje: SPMT, Migration Manager, ShareGate a spol.

Deep-dive k [`README.md`](README.md). Wave plán a limity jsou nástrojově nezávislé — ale
exekuce potřebuje konkrétní nástroj. Mapa: dva Microsoft nástroje zdarma, jeden assessment
nástroj a komerční 3rd-party liga.

## Microsoft nástroje (zdarma)

| Nástroj | Co to je | Kdy |
|---|---|---|
| **SPMT** (SharePoint Migration Tool) | Desktop klient — SharePoint Server 2010-2019, file shares → SPO/OneDrive/Teams | On-prem SharePoint zdroje a menší/přímé file-share migrace z jednoho stroje |
| **Migration Manager** | Cloud orchestrace v SharePoint admin centru; nainstalovaní agenti dělají discovery a přenos, admin centrum drží tasky/stav/reporty | Větší file-share projekty (agent-based škálování napříč lokalitami) a cloud zdroje (Box, Dropbox, Google Workspace, Egnyte). **Ne** pro on-prem SharePoint weby — tam Microsoft odkazuje na SPMT |
| **SMAT** (SharePoint Migration Assessment Tool) | Command-line scan on-prem farmy před migrací | Assess & remediate fáze (viz README) — najde problémy dřív, než začne přenos |

## SPMT PowerShell modul — skriptovatelná exekuce

`Microsoft.SharePoint.MigrationTool.PowerShell` se instaluje **spolu s desktop SPMT**
(ne z PowerShell Gallery — DLL se kopírují do `%userprofile%\Documents\WindowsPowerShell\Modules`).
Cmdlet pipeline kopíruje wave-plan logiku z labu:

```powershell
# Windows PowerShell 5.x! (viz tripwire nize)
Register-SPMTMigration -SPOCredential $cred -Force          # session + nastaveni
Add-SPMTTask -FileShareSource $src -TargetSiteUrl $site `
             -TargetList "Dokumenty"                        # 1 task = 1 polozka vlny
Start-SPMTMigration                                          # exekuce
Get-SPMTMigration                                            # stav tasku + session
```

`Add-SPMTTask` umí tři typy: file share, SharePoint (on-prem zdroj) a JSON-definovaný task —
JSON varianta je přímý zápis wave plánu jako dat (soubor = vlna, verzovatelný v gitu).

> [!IMPORTANT] Tripwire: Windows PowerShell, ne PS7
> SPMT modul vyžaduje **Windows PowerShell 5.0 + .NET Framework 4.6.2** — v PowerShell 7
> neběží. Totéž platí pro ShareGate PS modul (PowerShell 3.0+, PS7 nepodporován). Migrace
> je dnes hlavní důvod, proč mít na stroji vedle PS7 pořád i 5.1 — přesně scénář z
> [`../../day-1/powershell-deep-dive/explainer-module-management.md`](../../day-1/powershell-deep-dive/explainer-module-management.md).

## 3rd-party liga (komerční)

Placené nástroje kupují rychlost, fidelitu (verze, permissions, metadata) a reporting —
relevantní tam, kde Microsoft nástroje narazí (tenant-to-tenant, restrukturalizace za běhu,
komplexní on-prem customizace):

| Nástroj | Profil | PowerShell |
|---|---|---|
| **ShareGate** | Nejčastější mid-market volba: SPO restrukturalizace, tenant-to-tenant, validace | Vlastní PS modul (`Copy-Content`, `Copy-Site`, `New-CopySettings -OnContentItemExists IncrementalUpdate` pro inkrementy); vyžaduje desktop instalaci, jen Windows PowerShell |
| **AvePoint (Fly)** | Regulovaná prostředí — nejpřesnější migrace permissions, governance/audit integrace, nejširší škála zdrojů | ano (Fly API/automatizace) |
| **Quest Content Matrix** | Velké legacy SP Server konsolidace — publishing weby, hluboké customizace, multi-farm | ano (PowerShell konzole) |

Rozhodovací osa pro kurz: **začni Microsoft nástroji (zdarma), 3rd-party kupuj, až když
narazíš na jejich hranice** — a tu hranici umíš pojmenovat (fidelita verzí/permissions,
tenant-to-tenant, rychlost při objemu, reporting pro zákazníka).

## Zdroje (Microsoft)

- [Overview of the SharePoint Migration Tool (SPMT)](https://learn.microsoft.com/en-us/sharepointmigration/introducing-the-sharepoint-migration-tool)
- [Migrate to SharePoint and OneDrive using PowerShell cmdlets](https://learn.microsoft.com/en-us/sharepointmigration/overview-spmt-ps-cmdlets)
- [Microsoft.SharePoint.MigrationTool.PowerShell — cmdlet reference](https://learn.microsoft.com/en-us/powershell/module/microsoft.sharepoint.migrationtool.powershell/?view=spmt-ps)
- [ShareGate PowerShell dokumentace](https://help.sharegate.com/en/collections/11073311-powershell) (vendor, ne Microsoft)

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Rychlosti/ceny 3rd-party nástrojů jsou marketingová čísla s krátkou životností — před
> během neuvádět konkrétní GB/h bez čerstvého ověření. U SPMT/ShareGate ověřit, zda PS7
> podpora stále chybí (obě omezení jsou dlouhodobá, ale ne garantovaná navždy). ShareGate
> přechází na "desktopless" cloud variantu — ověřit dopad na PS modul.
