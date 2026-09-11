# Explainer · Mrtvé vrstvy: co všechno najdete ve zdrojovém prostředí

Migrace nikdy nepřenáší jen obsah — přenáší i **customizace, které na cílové straně
nemají kam přistát**. Tenhle explainer je mapa vrstev, na které v assessmentu narazíte,
s jednou nosnou pointou: **nástroje a moduly umírají, REST API zůstává.** Kdo rozumí
principu pod vrstvou, řešení přepíše; kdo znal jen konkrétní nástroj, začíná od nuly.

## Časová osa vrstev

| Éra | Vrstva | Stav dnes |
|---|---|---|
| 2007– | SOAP web services (`_vti_bin/*.asmx`) | mrtvé, jen v legacy kódu |
| 2010–2013 | CSOM (.NET) a JSOM (JavaScript) | CSOM přežívá uvnitř nástrojů (i PnP), JSOM mrtvý |
| 2010–2016 | Sandbox solutions s kódem | code-based vypnuté 2016 |
| 2013–2026 | **SharePoint Add-ins** (add-in model) + **Azure ACS** auth (`AppRegNew.aspx`, app-only přes `accesscontrol.windows.net`) | **v SPO vypnuté 2. 4. 2026** — viz níže |
| 2013– | „JS injection" — JSLink, Script Editor, ScriptLink custom actions | na moderních stránkách nefunguje; custom script je od 11/2024 vynucovaně vypnutý |
| 2013– | SharePoint REST `_api` | živé, pokrývá SPO detaily mimo Graph |
| 2012– | MSOnline (`Msol*`), AzureAD modul | oba vypnuté — poznat ve starých skriptech |
| 2014– | SPO Management Shell (`*-SPO*`) | živé, tenant-admin nastavení |
| 2014– | PnP (OfficeDevPnP → PnP.PowerShell) | živé, nejširší SPO pokrytí |
| 2015– | Microsoft Graph + Graph PowerShell SDK | živé, strategické |

## Tři vrstvy, které dnes reálně blokují migrace

### SharePoint Add-ins a Azure ACS — v SPO konec

Add-iny byly oficiální cesta, jak do SharePointu dostat aplikace a formuláře; **ACS**
k nim dával app-only přístup — registrace přes `AppRegNew.aspx` a „client secret na rok"
bez admin consentu. Obojí v Microsoft 365 skončilo: pro nové tenanty od 1. 11. 2024,
**pro všechny tenanty 2. 4. 2026**, bez možnosti prodloužení.

Dva praktické důsledky pro migrační projekt:

- **Zdroj běží dál, cíl ne.** Add-iny v **SharePoint on-premises nejsou retired** a na
  zdrojové farmě fungují. Migrace tedy typicky odhalí řešení, které roky běželo — a pro
  které v SPO neexistuje protějšek. Náhrada je vždy dvojice: **Entra app registrace**
  (identita, viz [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/))
  a **SPFx** (customizace, viz [`../../day-5/app-catalog-lifecycle/`](../../day-5/app-catalog-lifecycle/)).
- **Staré app-only skripty přestaly fungovat.** Cokoli, co se autentizovalo přes ACS
  (client id + secret registrovaný v `AppRegNew.aspx`), je nefunkční — přepsat na
  certifikátové app-only přihlášení proti Entra
  ([`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/)).

### Custom script — vypnutý, ale per-site povolitelný

Custom script (Script Editor webpart, JSLink, vlastní `.aspx` s kódem) Microsoft od
11/2024 vynucuje jako **vypnutý**: nastavení se u webů vrací na výchozí hodnotu, a to
i po ruční změně (typicky do 24 hodin), pokud se nenastaví explicitně na úrovni webu:

```powershell
Set-SPOSite <SiteURL> -DenyAddAndCustomizePages 0      # SPO Management Shell
Set-PnPSite -Identity <SiteURL> -NoScriptSite $false    # PnP ekvivalent
```

Tenant-wide odklad (`Set-SPOTenant -DelayDenyAddAndCustomizePagesEnforcement`) skončil.
V migraci to znamená: **weby, které custom script potřebují, se musí evidovat** a
povolení nastavovat vědomě a dokumentovaně — je to bezpečnostní ústupek, ne konfigurace.

### Klasické šablony (`.wsp`, `.stp`)

Zdrojová farma bývá plná šablon webů a seznamů uložených „Save site as template".
V SPO neexistují; ekvivalent je site script / list design nebo PnP šablona
([`../provisioning-patterns/explainer-site-list-templates.md`](../provisioning-patterns/explainer-site-list-templates.md)).

## Assessment — na co se ptát před migrací

- Které weby mají **povolený custom script** a proč (`Get-PnPTenantSite` / SPO admin).
- Které aplikace se autentizují přes **ACS** (starý client id / secret model).
- Jsou v prostředí **Add-iny** z App Catalogu, a kdo je dodal?
- Existují **JSLink / Script Editor** customizace na klasických stránkách?
- Které skripty používají **MSOnline / AzureAD** moduly?
- Které šablony webů a seznamů (`.wsp`, `.stp`) se reálně používají při zakládání?

Odpovědi patří do migračního plánu jako samostatná položka — **náhrada customizací je
projekt vedle přesunu obsahu**, ne detail cutoveru. Nástrojově pomůže SMAT
([`explainer-migration-tools.md`](explainer-migration-tools.md)) na zdrojové farmě.

## Klíčové rozlišení

- **Vrstva vypnutá v SPO vs stále živá on-premises** — Add-iny v on-prem fungují dál;
  konec se týká Microsoft 365.
- **Konec autentizace (ACS) vs konec modelu (Add-ins)** — obojí padlo současně, ale
  náhrada je jiná: identitu řeší Entra app registrace, customizaci SPFx.
- **Custom script vypnutý globálně vs povolený na konkrétním webu** — per-site výjimka
  existuje, je to ale evidované riziko, ne výchozí stav.
- **Modul vs API** — moduly umírají (MSOnline, AzureAD), REST kontrakt zůstává; proto
  se kurz učí principy nad Graph/REST, ne sadu cmdletů.

## Zdroje (Microsoft)

- [SharePoint Add-ins and Azure ACS retirement FAQ (často kladené otázky)](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/add-ins-and-azure-acs-retirements-faq)
- [Azure ACS retirement in Microsoft 365](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/retirement-announcement-for-azure-acs)
- [SharePoint Add-In retirement in Microsoft 365](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/retirement-announcement-for-add-ins)
- [Allow or prevent custom script](https://learn.microsoft.com/en-us/sharepoint/allow-or-prevent-custom-script)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Retirementy Add-ins a ACS v Microsoft 365 proběhly 2. 4. 2026; ověřit aktuální znění
> FAQ (zbytkové výjimky, dopad na Power Platform konektory) a chování vynucení custom
> scriptu — Microsoft ho průběžně zpřísňuje.
