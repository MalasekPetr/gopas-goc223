# Explainer · Migrační nástroje: SPMT, Migration Manager, ShareGate a spol.

(Plná znění zkratek nástrojů jsou v tabulce hned níž — **SPMT** je SharePoint Migration Tool, **SMAT** je SharePoint Migration Assessment Tool.)

Deep-dive k [`README.md`](README.md). Wave plán a limity jsou nástrojově nezávislé — ale
exekuce potřebuje konkrétní nástroj. Mapa: dva Microsoft nástroje zdarma, jeden assessment
nástroj a komerční 3rd-party liga.

## Microsoft nástroje (zdarma)

| Nástroj | Co to je | Kdy |
|---|---|---|
| **SPMT** (SharePoint Migration Tool) | Desktop klient — SharePoint Server 2010-2019, file shares → SPO/OneDrive/Teams | On-prem SharePoint zdroje a menší/přímé file-share migrace z jednoho stroje |
| **Migration Manager** | Cloud orchestrace v SharePoint admin centru; nainstalovaní agenti dělají discovery a přenos, admin centrum drží tasky/stav/reporty | Větší file-share projekty (agent-based škálování napříč lokalitami) a cloud zdroje (Box, Dropbox, Google Workspace, Egnyte). **Ne** pro on-prem SharePoint weby — tam Microsoft odkazuje na SPMT |
| **SMAT** (SharePoint Migration Assessment Tool) | Scan z příkazové řádky on-prem farmy před migrací | Assess & remediate fáze (viz README) — najde problémy dřív, než začne přenos |

## SPMT PowerShell modul — skriptovatelná exekuce

`Microsoft.SharePoint.MigrationTool.PowerShell` se instaluje **spolu s desktop SPMT**
(ne z PowerShell Gallery — knihovny DLL se kopírují do `%userprofile%\Documents\WindowsPowerShell\Modules`).
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
> [`../../day-2/powershell-deep-dive/explainer-module-management.md`](../../day-2/powershell-deep-dive/explainer-module-management.md).

## Kde migrace vlastně běží — a proč tu Azure skoro nepomůže

Kurz vás v [`../../day-4/azure-integration-patterns/`](../../day-4/azure-integration-patterns/)
učí žebřík dospělosti automatizace: čím výš, tím míň železa a tajemství
(scheduled task → Function → kontejner → managed identity). **Na migrační exekuci se ten
žebřík z velké části nedá použít** a je dobré vědět proč, dřív než to slíbíte zákazníkovi.

### Migrace potřebuje Windows stroje, ne serverless

| Nástroj | Kde běží | Proč to nejde jinam |
|---|---|---|
| **SPMT** (desktop i PS modul) | Windows stroj s **Windows PowerShell 5.x + .NET Framework 4.6.2** | v PowerShellu 7 modul neběží → žádná Linux Function, žádný `mcr.microsoft.com/powershell` kontejner |
| **Migration Manager** | jeden nebo více **počítačů či virtuálních strojů (VM)** s nainstalovaným agentem | agent je Windows služba, ne cloudová komponenta; orchestrace je v cloudu, **přenos ne** |
| **ShareGate** | Windows stroj, PowerShell 3.0+ | PS7 nepodporován (viz tripwire výše) |

Praktický důsledek: „migraci hodíme do Azure Functions" nefunguje. Co **do Azure hodit
jde**, je stroj — agent Migration Manageru i SPMT běží na VM stejně dobře jako na
fyzickém počítači, a u **cloudových zdrojů** (Box, Dropbox, Google Workspace) dává VM
smysl víc než stanice v kanceláři, protože data netečou přes firemní linku.

### Co si o agentech ověřit dřív, než se plánuje vlna

- **Místo na disku**: každý agent má pracovní složku `%appdata%\Microsoft\SPMigration`
  a Microsoft požaduje **minimálně 150 GB volného místa**, u velkých objemů víc.
  Tohle je nejčastější důvod, proč vlna spadne v polovině.
- **Účet**: servisní účet s **Read** na zdroj a SharePoint/OneDrive admin na cíl.
  **Cizí nástroj pro vícefaktorové ověření (MFA) není podporovaný** (Microsoft MFA ano) — u zákazníka s cizím
  MFA providerem je to blocker, na který se přijde pozdě.
- **Počet agentů — méně je víc.** Microsoft doporučuje **nejmenší počet agentů, který
  vlnu stihne v požadovaném okně**. Víc agentů znamená vyšší API request rate a tím
  **vyšší throttling** — přidávání agentů výkon v určitém bodě zhoršuje, ne zlepšuje.
  Je to tentýž mechanismus jako u dávkových skriptů v
  [`../../day-3/graph-fundamentals/`](../graph-fundamentals/): propustnost
  neurčuje váš hardware, ale to, co vám služba dovolí.

Nosná věta: **migrační kapacita se neškáluje penězi za compute, ale plánováním vln.**
To je přesně důvod, proč je wave plán v [`README.md`](README.md) nástrojově nezávislý —
a proč se v migračním projektu neplatí za víc strojů, ale za lepší rozvrh.

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
- [Setup Migration Manager agents](https://learn.microsoft.com/en-us/sharepointmigration/mm-setup-clients)
- [Migration Manager prerequisites and endpoints](https://learn.microsoft.com/en-us/sharepointmigration/mm-prerequisites)
- [Improve SPMT or Migration Manager agent performance](https://learn.microsoft.com/en-us/sharepointmigration/spmt-performance-guidance)
- [ShareGate PowerShell dokumentace](https://help.sharegate.com/en/collections/11073311-powershell) (vendor, ne Microsoft)

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — stav k 2026-07.
> Rychlosti/ceny 3rd-party nástrojů jsou marketingová čísla s krátkou životností — před
> během neuvádět konkrétní GB/h bez čerstvého ověření. U SPMT/ShareGate ověřit, zda PS7
> podpora stále chybí (obě omezení jsou dlouhodobá, ale ne garantovaná navždy). ShareGate
> přechází na "desktopless" cloud variantu — ověřit dopad na PS modul.
>
> Požadavky na agenty Migration Manageru (dnes **min. 150 GB** volného místa v pracovní
> složce, nepodporované third-party MFA) se mění — ověřit na
> [prerequisites](https://learn.microsoft.com/en-us/sharepointmigration/mm-prerequisites)
> a [performance guidance](https://learn.microsoft.com/en-us/sharepointmigration/spmt-performance-guidance)
> před přípravou zákaznického assessmentu.
