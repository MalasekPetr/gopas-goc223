# Comparison · Kde se co v SPO dá vypnout — čtyři vrstvy a co je jen kosmetika

Doplněk k [`README.md`](README.md), sekci o SPO Management Shellu. Odpovídá na otázku,
která v kurzu i v praxi padá pořád: **„jde vypnout tohle tlačítko?"** — a hlavně na
tu důležitější: **„vypne se tím i cesta, nebo jen tlačítko?"**

Zároveň je to konkrétní odpověď na „proč vůbec SPO modul, když mám PnP": většina
tenant-wide a site-wide přepínačů níže žádný PnP ekvivalent nemá, nebo ho dostane později.

## Čtyři vrstvy

| Vrstva | Čím se nastavuje | Granularita | Povaha |
|---|---|---|---|
| **Tenant** | `Set-SPOTenant` | celý tenant, nic užšího | skutečné vypnutí funkce |
| **Site collection** | `Set-SPOSite` | jeden web (a jeho podweby) | skutečné vypnutí / vynucení |
| **Web** | `ExcludeFromOfflineClient` (CSOM/PnP property) | jeden web, i každý subweb zvlášť | **doporučení klientovi**, ne vynucení |
| **List / view** | `commandBarProps` v JSON formátování view | jeden view | **jen UI**, obejitelné |

Pravidlo, které z tabulky plyne: **čím níž jdete, tím měkčí to je.** Tenant a site
collection přepínají chování služby; web a view jen ovlivňují, co uživatel vidí.

## Vrstva 1 — tenant (`Set-SPOTenant`)

Globální přepínače. Role: **SharePoint Administrator** (Global Admin není potřeba).

```powershell
Connect-SPOService -Url https://<tenant>-admin.sharepoint.com

# zakazat "Pridat zastupce do OneDrivu" pro cely tenant
Set-SPOTenant -DisableAddShortCutsToOneDrive $true

# skryt tlacitko Sync na tymovych webech
Set-SPOTenant -HideSyncButtonOnTeamSite $true

# kontrola
Get-SPOTenant | Format-List DisableAddShortCutsToOneDrive, HideSyncButtonOnTeamSite
```

Dvě věci, které překvapí:

- **Vypnutí neodstraní, co už vzniklo.** `DisableAddShortCutsToOneDrive` zablokuje
  vytváření nových zástupců; ty existující zůstanou uživatelům v OneDrivu.
- **Propagace není okamžitá.** Počítejte s desítkami minut, než se změna projeví napříč
  weby — při testování to vypadá jako „nefunguje to".

> [!IMPORTANT] Tenant-wide znamená tenant-wide
> Tyhle přepínače nemají užší variantu. Před `Set-SPO*` si ověřte, ke kterému tenantu
> jste připojeni (`Get-SPOTenant` hned po `Connect-SPOService`) — omylem přepnutý
> globální přepínač se projeví všem uživatelům naráz a nikdo si toho nevšimne hned.
> Platí i pravidlo z [`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md):
> žádné tenant-wide `Set-*` v kurzovním tenantu bez instruktora.

## Vrstva 2 — site collection (`Set-SPOSite`)

Tady je většina reálné governance. Výběr toho, co se v praxi používá nejčastěji:

| Oblast | Parametry |
|---|---|
| Stahování / DLP | `BlockDownloadPolicy`, `ReadOnlyForBlockDownloadPolicy`, `ExcludeBlockDownloadPolicySiteOwners` |
| Nespravovaná zařízení | `ConditionalAccessPolicy`, `ReadOnlyForUnmanagedDevices` |
| Sdílení | `SharingCapability`, `DisableSharingForNonOwners`, `DisableCompanyWideSharingLinks`, `SharingDomainRestrictionMode` |
| Customizace | `DenyAddAndCustomizePages` (NoScript) |
| Stránky | `CommentsOnSitePagesDisabled`, `SocialBarOnSitePagesDisabled` |
| Přístup | `RestrictedAccessControl`, `RestrictedAccessControlGroups` |

**`BlockDownloadPolicy`** stojí za zvláštní zmínku: uživatel zůstane produktivní
v prohlížeči, ale nemůže stahovat, tisknout ani synchronizovat. Je to site-level a
**tenant-wide varianta neexistuje**.

> [!WARNING] Gotcha: `BlockDownloadPolicy` rozbije upload `.sppkg`
> Na webu, který hostuje **site collection app catalog**, selže nahrání nebo aktualizace
> SPFx balíčku hláškou *„App package is invalid"* a Product ID zůstane prázdné. Řešení je
> dočasně `BlockDownloadPolicy` vypnout, balíček nahrát a zase zapnout. Souvislost:
> [`../../day-5/app-catalog-lifecycle/`](../../day-5/app-catalog-lifecycle/).

> [!IMPORTANT] `DisableFlows` a `DisableAppViews` jsou mrtvé
> Parametry pro vypnutí tlačítek Power Automate a Power Apps v `Set-SPOSite` **stále
> existují v dokumentaci i v syntaxi cmdletu**, ale Microsoft je označil:
> *„This parameter has been retired and no longer functions."* Power Platform se dnes
> omezuje **DLP politikou v Power Platform admin centru**, ne ze SharePointu.
>
> Je to nejlepší živý příklad pointy z [`../../day-1/api-landscape/`](../../day-1/api-landscape/):
> parametr v dokumentaci ještě neznamená funkční parametr. Skript, který ho volá,
> nespadne — jen tiše nic neudělá.

## Vrstva 3 — web (`ExcludeFromOfflineClient`)

Property webu (ne site collection — nastavuje se i pro každý subweb zvlášť), v UI
*Offline Client Availability = No*. Skryje tlačítko Sync.

**Není to vynucení.** Je to doporučení klientovi: už běžící synchronizaci nezastaví
a nezabrání přístupu jinou cestou.

## Vrstva 4 — list / view (`commandBarProps`)

Jediný podporovaný způsob, jak skrýt konkrétní tlačítka v knihovně — a jediné místo,
kde se dá sáhnout na **Export to Excel**, **Integrate** a **Automate**. Nastavuje se
ve *View formatting → Format current view → Command bar*:

```json
{
  "$schema": "https://developer.microsoft.com/json-schemas/sp/v2/command-bar-formatting.schema.json",
  "commandBarProps": {
    "commands": [
      { "key": "exportExcel", "hide": true },
      { "key": "integrate", "hide": true },
      { "key": "automate", "hide": true },
      { "key": "sync", "hide": true }
    ]
  }
}
```

Hromadné nasazení na defaultní view napříč weby:

```powershell
Set-PnPView -List "Documents" -Identity "All Documents" -Values @{ CustomFormatter = $json }
```

Skrytí se propíše i do kontextového menu položky. Vlastní příkazy z SPFx ListView
Command Setu mají klíč ve tvaru `SpfxCustomActionNavigationCommand_<id>_<command>`.

> [!IMPORTANT] Tohle není bezpečnostní hranice
> `commandBarProps` je **kosmetika**. Konkrétně:
> - platí **per view** — uživatel si založí vlastní view a tlačítka jsou zpátky;
> - kdokoli s právem *Manage Lists* JSON přepíše;
> - **REST i Graph fungují dál** — data odejdou, jen ne tímhle tlačítkem.
>
> Když je požadavek „uživatelé nesmí exportovat do Excelu", JSON ho nesplní.

## Rozhodovací osa: kosmetika, nebo hranice?

| Požadavek | Kosmetika (UX) | Skutečná hranice |
|---|---|---|
| „Nechceme, aby lidi exportovali do Excelu" | `commandBarProps` → `exportExcel` | odebrat **Use Client Integration Features** z permission levelu |
| „Nechceme, aby stahovali soubory" | `commandBarProps` → `download` | `Set-SPOSite -BlockDownloadPolicy $true` |
| „Nechceme sync" | `ExcludeFromOfflineClient`, `commandBarProps` → `sync` | `Set-SPOTenant -HideSyncButtonOnTeamSite` + politika zařízení |
| „Nechceme zástupce v OneDrivu" | — | `Set-SPOTenant -DisableAddShortCutsToOneDrive` (jen tenant-wide) |

**Ptejte se zadavatele, kterou z těch dvou věcí chce.** „Ať to tam nesvítí" a „ať to
nejde" jsou dva různé požadavky s různou cenou; smíchat je znamená slíbit bezpečnost
a dodat kosmetiku. Stejná úvaha jako u `-WhatIf` a dry-runů: co skript **ukazuje** vs
co skript **vynutí**.

Pozor u permission levelu: odebrání *Use Client Integration Features* vypne i *Open in app*
a *Open in File Explorer*, a **kumuluje se** — když je uživatel zároveň v jiné skupině
s vyšším levelem, nižší level ho neomezí.

## Zdroje (Microsoft)

- [Set-SPOTenant](https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/set-spotenant)
- [Set-SPOSite](https://learn.microsoft.com/en-us/powershell/module/sharepoint-online/set-sposite)
- [Command bar customization syntax reference](https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/view-commandbar-formatting)
- [Block download policy for SharePoint sites and OneDrive](https://learn.microsoft.com/en-us/sharepoint/block-download-from-sites)
- [Recommended sync app configuration](https://learn.microsoft.com/en-us/sharepoint/ideal-state-configuration)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> **Seznam parametrů `Set-SPOSite` a `Set-SPOTenant` je nejrychleji stárnoucí obsah tohoto
> souboru** — parametry přibývají, jsou označovány jako retired (`DisableFlows`,
> `DisableAppViews`, `AllowDownloadingNonWebViewableFiles`) a mění chování. Výše je
> **výběr**, ne úplný seznam; úplný patří do cmdlet reference, ne do kurzovního materiálu.
> Před během proklikat odkazy výše a ověřit konkrétní parametry, které budete ukazovat.
> Totéž platí pro seznam klíčů `commandBarProps` — je jich přes osmdesát a přibývají.
