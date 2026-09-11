# Tahák · SPO API triky: ID, definice seznamů a interní názvy polí

Praktické dotazy, které při automatizaci a migraci SharePointu potřebujete pořád dokola.
Tři cesty k témuž: **Graph** (URL do Graph Exploreru nebo `Invoke-MgGraphRequest`),
**PnP PowerShell** (cmdlety) a **SharePoint REST** (`/_api/…` — funguje i v adresním
řádku prohlížeče, když jste přihlášení na webu).

## ID objektů — site, web, seznam

Skoro každé API volání chce nějaké ID. Jak je zjistit:

```http
# Graph: site ID z URL webu (hostname + server-relativni cesta)
GET https://graph.microsoft.com/v1.0/sites/<tenant>.sharepoint.com:/sites/<nazev-webu>
# -> "id": "<hostname>,<siteCollectionId>,<webId>" (trojice - Graph ji pouziva celou)

# Korenovy web tenantu
GET https://graph.microsoft.com/v1.0/sites/root
```

```powershell
# PnP (po Connect-PnPOnline na dany web)
Get-PnPSite -Includes Id | Select-Object Id          # site collection ID
Get-PnPWeb | Select-Object Id, Title                 # web ID
Get-PnPList | Select-Object Id, Title                # ID vsech seznamu
```

```http
# SharePoint REST (i v prohlizeci)
https://<tenant>.sharepoint.com/sites/<web>/_api/site/id
https://<tenant>.sharepoint.com/sites/<web>/_api/web/id
```

## Definice seznamu a knihovny

Co to vlastně je za seznam — šablona, skrytost, sloupce, obsahové typy:

```http
# Graph: seznamy webu vcetne "list" facetu (template, hidden)
GET /sites/{site-id}/lists?$select=id,displayName,list

# Kompletni definice jednoho seznamu
GET /sites/{site-id}/lists/{list-id}?$expand=columns,contentTypes
```

```powershell
# PnP: zaklad + plna definice poli
Get-PnPList -Identity "Dokumenty"
Get-PnPList -Identity "Dokumenty" -Includes Fields, ContentTypes
```

Skryté systémové seznamy se odfiltrují přes `Get-PnPList | Where-Object Hidden -eq $false`.

## Interní názvy polí (InternalName)

Zobrazovaný název (`Title`) je pro lidi a **dá se kdykoli přejmenovat**; interní název
(`InternalName`) vzniká při založení pole a **už se nikdy nemění** — a právě ten chtějí
Dotazy CAML (Collaborative Application Markup Language), REST filtry i Graph `fieldValueSet`. Záludnost: mezera nebo diakritika
v názvu při založení se zakóduje (`Datum schválení` → `Datum_x0020_schv_x00e1_len_x00ed_`)
— proto pole zakládat bez diakritiky a mezer a teprve pak přejmenovat zobrazovaný název.
V migracích je to nejčastější příčina „mapování metadat nesedí".

```powershell
# PnP: mapa display -> internal pro dany seznam
Get-PnPField -List "Dokumenty" |
  Where-Object Hidden -eq $false |
  Select-Object Title, InternalName, TypeAsString | Sort-Object Title
```

```http
# REST ekvivalent
/_api/web/lists/getbytitle('Dokumenty')/fields?$select=Title,InternalName,TypeAsString&$filter=Hidden eq false
```

## Choice pole — povolené hodnoty

Než začne dávkový zápis, je potřeba vědět, co pole vůbec přijme:

```powershell
# PnP
(Get-PnPField -List "Dokumenty" -Identity "Status").Choices
```

```http
# Graph: v definici sloupce
GET /sites/{site-id}/lists/{list-id}/columns
# -> hledat "choice": { "choices": [...] }

# REST
/_api/web/lists/getbytitle('Dokumenty')/fields?$filter=TypeAsString eq 'Choice'
```

## Velikost seznamu a indexy

Před každým dotazem nad neznámým seznamem dvě otázky: kolik toho tam je a podle čeho
lze filtrovat bez pádu na threshold 5000.

```powershell
# Kolik polozek a kdy naposledy zmena
Get-PnPList -Identity "Dokumenty" | Select-Object Title, ItemCount, LastItemUserModifiedDate

# Ktere sloupce jsou indexovane (= podle ceho lze bezpecne filtrovat)
Get-PnPField -List "Dokumenty" |
  Where-Object Indexed -eq $true |
  Select-Object Title, InternalName, TypeAsString
```

Souvislosti, limity a checklist: [`explainer-large-lists.md`](explainer-large-lists.md).

## Rychlé kombinace do praxe

```powershell
# Prehled webu na jeden pohled: co tu je a jak je to velke
Get-PnPList | Where-Object Hidden -eq $false |
  Select-Object Title, ItemCount, LastItemUserModifiedDate |
  Sort-Object ItemCount -Descending
```

- `ItemCount` + `LastItemUserModifiedDate` je nejlevnější vstup do inventury před
  migrací — „co je velké a co je mrtvé" jedním dotazem.
- Dotaz vyzkoušet v Graph Exploreru dřív, než půjde do skriptu — chybu v `$filter`
  vrátí hned a čitelně.
- `$select` používat všude — méně dat, rychlejší odpověď, čitelnější JSON.
- Interní názvy polí patří i do promptu, když si necháváte skript generovat
  (viz [`../../day-1/vscode-copilot-env/copilot-priming-prompt.md`](../../day-1/vscode-copilot-env/copilot-priming-prompt.md))
  — model je sám nezná a vymyslí si je.

## Zdroje (Microsoft)

- [Working with SharePoint sites in Microsoft Graph](https://learn.microsoft.com/en-us/graph/api/resources/sharepoint)
- [columnDefinition resource type (Graph)](https://learn.microsoft.com/en-us/graph/api/resources/columndefinition)
- [Working with lists and list items with REST](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/working-with-lists-and-list-items-with-rest)
- [PnP PowerShell — Get-PnPField](https://pnp.github.io/powershell/cmdlets/Get-PnPField.html)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Pokrytí SharePointu v Graphu roste; některé dotazy, které dnes vyžadují SPO REST,
> mohou mít nový Graph ekvivalent. Tvar `id` u `/sites` (trojice) je stabilní, ale
> ověřit u nových endpointů.
