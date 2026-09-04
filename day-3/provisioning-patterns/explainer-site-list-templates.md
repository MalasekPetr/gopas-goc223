# Explainer · Site scripty, site templates a list designy — deklarativní vrstva

Deep-dive k [`README.md`](README.md), který pokrývá **PnP provisioning engine**. Vedle
něj existuje druhá, „lehčí" deklarativní vrstva přímo v SharePointu: **site scripty
(JSON) + site templates + list designy**. Baseline a drift z
[`../../day-2/staging-environments/`](../../day-2/staging-environments/) stojí na site
scriptech; tenhle explainer dopovídá zbytek — jak šablonu **vyrobit z existujícího webu**,
jak šablonovat **jednotlivý seznam** a **kdy JSON nestačí a nastupuje PnP šablona**.

## Co je z klasického světa mrtvé

Než se začne hledat řešení z roku 2013: **„Save site as template" (`.wsp`)** na moderních
webech není a nebude, stejně jako **`.stp` šablony seznamů**. V migračních projektech se
na ně naráží pravidelně — zdrojová farma je jimi plná a v SPO pro ně neexistuje přímý
protějšek (souvislosti: [`../migration-patterns/explainer-legacy-layers.md`](../migration-patterns/explainer-legacy-layers.md)).
Dnešní ekvivalenty jsou právě site script / list design nebo PnP šablona.

## Site script + site template

**Site script** je JSON se seznamem **akcí** (`verb`) — vytvoř seznam, přidej sloupec,
nastav theme, přidej navigaci, spusť Flow. **Site template** (dřív *site design*) je
pojmenovaný obal nad jedním nebo více skripty; nabídne se uživateli při zakládání webu,
nebo se aplikuje na existující web.

```json
{
  "$schema": "schema.json",
  "actions": [
    {
      "verb": "createSPList",
      "listName": "Zadanky",
      "templateType": 100,
      "subactions": [
        { "verb": "setDescription", "description": "Zadanky o vybaveni" },
        { "verb": "addSPField", "fieldType": "Text", "displayName": "Stredisko", "isRequired": true },
        { "verb": "addSPField", "fieldType": "Choice", "displayName": "Stav",
          "choices": ["Nova", "Schvalena", "Zamitnuta"], "addToDefaultView": true }
      ]
    },
    { "verb": "applyTheme", "themeName": "<nazev-tematu>" }
  ]
}
```

```powershell
# Registrace a pouziti - PnP varianta (pripojeni na -admin URL)
$script = Get-Content .\zadanky.json -Raw -Encoding utf8
Add-PnPSiteScript -Title "Zadanky - struktura" -Content $script
Add-PnPSiteDesign -Title "Web oddeleni" -SiteScriptIds <id> -WebTemplate CommunicationSite
Invoke-PnPSiteDesign -Identity <design-id> -WebUrl <url>
```

> [!IMPORTANT] Názvosloví
> **„site design" → „site template"** v UI a dokumentaci, cmdlety ale zůstaly
> `*-SPOSiteDesign` / `*-PnPSiteDesign`. Když někdo řekne „site design", jde o totéž.

Limity, které je nutné znát předem: **100 site scriptů a 100 site templates na tenant**
(sdílené s baseline artefakty z D2 — testovací pokusy uklízet, jinak limit dojde),
strop cca 300 akcí / 100 000 znaků na skript, a **aplikace je asynchronní** — akce běží
až po vytvoření webu, takže skript, který výsledek ověřuje hned, může vidět nedokončený
stav. To je častá příčina falešně negativního výsledku diff kontroly.

## Reverzní cesta — šablona z hotového webu

Nejrychlejší způsob, jak vyrobit vlastní šablonu: web naklikat a pak z něj vygenerovat
JSON.

```powershell
Get-PnPSiteScriptFromWeb -Url <url-webu> -IncludeAll
Get-PnPSiteScriptFromWeb -Url <url-webu> -Lists "Dokumenty","Zadanky"   # jen vybrane seznamy
```

Výstup je hotový site script ke kontrole a úpravě — a zároveň nejlepší způsob, jak
zjistit, **jak se která akce jmenuje**. Obdoba na straně PnP enginu je
`Get-PnPSiteTemplate` / `Get-PnPTenantTemplate` (viz [`README.md`](README.md)).

## List designy — když stačí šablonovat jeden seznam

Nemusí se šablonovat celý web. Tři úrovně:

1. **Microsoftem dodané list templates** — hotové (Sledování problémů, Onboarding…),
   dostupné při zakládání seznamu; nekonfiguruje se nic.
2. **Vlastní list design** — tentýž JSON (jen akce nad seznamem) zaregistrovaný přes
   `Add-PnPListDesign -Title <nazev> -SiteScript <id>`; objeví se uživatelům v sekci
   „From your organization" při zakládání seznamu.
3. **Kopie z existujícího seznamu** — `Get-PnPSiteScriptFromWeb -Lists …`, výstup
   upravit a zaregistrovat.

Právě list design je nejlevnější způsob, jak do organizace dostat **seznam s předem
nastavenými indexy** — a tím předejít pádům na threshold 5000 dřív, než seznam vyroste
([`../../day-2/graph-fundamentals/explainer-large-lists.md`](../../day-2/graph-fundamentals/explainer-large-lists.md)).

## Kdy JSON nestačí — rozhodovací osa

| Potřeba | Nástroj |
|---|---|
| Samoobslužné zakládání webů uživateli, jednoduchá struktura | **site template** (JSON) |
| Opakovaný jeden seznam napříč weby | **list design** (JSON) |
| Obsahové typy napříč hubem, permission levels do detailu, obsah stránek, seznamy s daty | **PnP šablona** (`.pnp`/XML) |
| Hromadný provisioning řízený žádankou, parametrizace metadaty | **PnP šablona** + orchestrace ([`README.md`](README.md)) |

Rozdíl v jedné větě: **site template si vybere uživatel v UI, PnP šablonu spustí skript.**
V praxi se kombinují — samoobsluha pro běžné weby, PnP pro plnou kontrolu tam, kde na
struktuře záleží.

## Klíčové rozlišení

- **Site script (JSON, akce) vs site template (obal, který vidí uživatel)** — skript
  dělá práci, template ho zpřístupní.
- **Site template (self-service) vs PnP šablona (spustí skript)** — samoobsluha vs plná
  kontrola.
- **List design vs celý site template** — když se opakuje jeden seznam, není důvod
  šablonovat web.
- **Synchronní očekávání vs asynchronní aplikace** — ověřovat výsledek až po doběhnutí,
  jinak diff hlásí drift, který za chvíli zmizí.

## Zdroje (Microsoft)

- [SharePoint site design and site script overview](https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-overview)
- [Site design JSON schema](https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-json-schema)
- [Create list templates (list designs)](https://learn.microsoft.com/en-us/sharepoint/dev/declarative-customization/list-designs)
- [PnP PowerShell — Get-PnPSiteScriptFromWeb](https://pnp.github.io/powershell/cmdlets/Get-PnPSiteScriptFromWeb.html)
- [PnP PowerShell — Add-PnPListDesign](https://pnp.github.io/powershell/cmdlets/Add-PnPListDesign.html)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Limity (100 scriptů / 100 templates na tenant, strop akcí), sada podporovaných `verb`
> akcí a hodnoty `-WebTemplate` se mění; před během projít JSON schema a vyzkoušet
> registraci na kurzovním tenantu. `Add-PnPListDesign` i `Get-PnPSiteScriptFromWeb`
> vyžadují připojení na tenant admin URL.
