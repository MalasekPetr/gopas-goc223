# Kdo má k čemu přístup: reporting oprávnění

> Typ: povinný · Den: 5 · Odhad: 35 min výklad + 40 min lab

Nejčastější dotaz, který dostane SharePoint admin od HR, právníků nebo bezpečáka, zní
**„k čemu má tenhle člověk přístup?"** — typicky když někdo odchází, mění oddělení, nebo
se má rozhodnout o Copilot licenci. Portál na to přímou odpověď nedává: ukáže vám
oprávnění **jednoho webu**, ne všechny weby jednoho člověka.

Tenhle blok je o obrácení dotazu a o tom, proč je to těžší, než vypadá.

## Cíle
- Vyjmenovat **všechny cesty**, kterými se člověk dostane k obsahu — a poznat, které
  z nich naivní skript minul.
- Napsat reverzní report „co vidí uživatel X" a vědět, co je jeho **slepá místa**.
- Rozhodnout mezi vlastním skriptem a **reportem Data Access Governance (DAG) ze SharePoint Advanced Management (SAM)** podle licence, rozsahu a limitů.
- Odlišit **snapshot** od živého dotazu a vědět, čemu odpovídá číslo v reportu.

## Výklad

### Pět cest k obsahu — a čtyři z nich skript snadno minou

Když se ptáte „vidí Novák tenhle web?", odpověď může být ano z kterékoli z těchto příčin:

| Cesta | Jak se zjistí |
|---|---|
| **Site collection admin** | `Get-PnPSiteCollectionAdmin` — **ale pozor, viz varování níž** |
| **Členství v SharePoint skupině** | `Get-PnPGroup` + `Get-PnPGroupMember` |
| **Členství v Entra skupině**, která je členem SharePoint skupiny | `Get-PnPGroupMember` vrátí **skupinu**, ne lidi v ní — nutné rozbalit přes Graph |
| **Přímé oprávnění na položce/knihovně** (porušená dědičnost) | `HasUniqueRoleAssignments` na listu/položce — **vyžádat přes `-Includes`** |
| **Sharing link** | samostatná soustava, v členstvích skupin není vidět vůbec |

> [!WARNING] `Get-PnPSiteCollectionAdmin` pod app-only identitou tiše lže
> S read-only rolí vrátí **prázdný seznam a nevyhodí chybu**; skutečné administrátory
> vrátí až identita s `Sites.FullControl.All`. Do reportu se tím zapíše
> **„0 administrátorů"** — a to se čte jako **nález**, ne jako chybějící oprávnění.
>
> Je to přesně ta falešná negativa, před kterou tenhle blok varuje, jen o patro níž:
> tentokrát ji nevyrobí zapomenutá Entra skupina, ale **vlastní nedostatečné oprávnění.**
>
> Dvě možnosti a obě jsou legitimní:
> 1. běžet identitou, která to opravdu přečte (`Sites.FullControl.All`), nebo
> 2. **to volání vynechat a mezeru v reportu pojmenovat** — „administrátory tento běh
>    nekontroloval".
>
> **Co nesmíte je vypsat nulu.** Pravidlo, které z toho plyne pro celý report:
> **nedostatečné oprávnění se nikdy nesmí zobrazit jako prázdný výsledek.**

Naivní report projde weby a hledá `LoginName` uživatele v členech skupin. To pokryje
**první dvě** cesty. Uživatel, který má přístup přes bezpečnostní skupinu Entra
(v reálném tenantu ten nejběžnější případ), v takovém reportu **nefiguruje** — a report
tvrdí „žádný přístup". Falešně negativní odpověď na otázku od právníků je horší než
žádná odpověď.

Řešení pro třetí cestu je Graph a **tranzitivní** členství, ne přímé:

```powershell
# vsechny skupiny, jejichz je uzivatel clenem - vcetne vnorenych
Get-MgUserTransitiveMemberOf -UserId <upn> -All |
  Select-Object -ExpandProperty Id
```

Pak se hledá průnik těchto ID s tím, co je členem SharePoint skupin na webu.
Rozdíl mezi `memberOf` a `transitiveMemberOf` je přesně ten rozdíl mezi reportem, který
platí, a reportem, který uklidní.

### Proč to nejde dělat naivně přes celý tenant

Reverzní dotaz je z principu drahý: neexistuje index „uživatel → weby", takže se musí
projít weby a v každém se ptát. To je **O(počet webů)** na jednoho uživatele, s throttlingem
(viz [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/)) a s tím, že
web, ke kterému se nelze připojit, nesmí shodit celý běh.

Praktické důsledky pro skript:

- **Scope si vynuťte parametrem**, nikdy „projdi všechno" jako výchozí chování.
- Nepřístupný web **zaznamenat a pokračovat**, ne `throw`.
- Výstup jako **objekty** do `Export-Csv`, ne `Write-Host` — tenhle report někdo dostane
  mailem a bude ho filtrovat v Excelu.
- U CSV pro Excel `-Encoding utf8BOM -UseCulture` (viz
  [`../../day-2/powershell-deep-dive/explainer-formats-encoding.md`](../../day-2/powershell-deep-dive/explainer-formats-encoding.md)).

### Druhá otázka, kterou nikdo neumí zodpovědět: „a které *aplikace* tam mají přístup?"

Celý blok zatím řešil lidi. Jenže od D4 umíte aplikaci **udělit per-site grant** — a ten
grant je z pohledu správce **neviditelný**:

- **není žádná stránka v admin centru**, která by je vypsala,
- **není inventurní cmdlet** pro celý tenant,
- grant **přežije toho, kdo o něj požádal**, i projekt, kvůli kterému vznikl.

Jediná cesta, jak je najít, je ptát se **web po webu** — přesně jako u reverzního dotazu
na uživatele, a ze stejného důvodu: **index neexistuje.**

> [!IMPORTANT] Tenhle report uzavírá týden
> Ve dni 4 jste se naučili takový grant **vytvořit**. Tady se učíte ho **najít** — a to je
> jediný důvod, proč po vás někdo za rok nebude chtít vysvětlit, proč má tříletá aplikace
> `FullControl` na personálním webu.

#### `Sites.Selected` už dávno není jediný

Model se rozrostl a je to jeden z mála případů, kdy se oprávnění v Microsoft 365 (M365) vyvíjejí směrem
**k větší granularitě**. Dokumentace to formuluje takhle:

> „Initially, Sites.Selected existed to restrict an application's access to a single site
> collection. **Now, lists, list items, folders, and files are also supported**, and all
> Selected scopes now support delegated and application modes."

| Scope | Rozsah |
|---|---|
| `Sites.Selected` | jedna **site collection** |
| `Lists.SelectedOperations.Selected` | konkrétní **seznam** |
| `ListItems.SelectedOperations.Selected` | **položky/složky** (i soubory) |
| `Files.SelectedOperations.Selected` | **soubory** v knihovnách |

Novější se jmenují celým tuplem `*.SelectedOperations.Selected`; dokumentace říká, že
*„there is no functional difference between this format and the `Sites.Selected` format"* —
je to jen důsledek vývoje pojmenovávání, ne jiný mechanismus.

**Očekávejte, že se to bude rozšiřovat dál.** Beta Graph nese granulární scopes dřív, než
se objeví v `v1.0`, takže kdo staví governance nad aplikačním přístupem, má sledovat obojí.

#### Tři vlastnosti, které z toho dělají governance problém

Všechny tři jsou z dokumentace a všechny tři překvapí:

1. **Grantů může být víc, na různých úrovních.** *„Applications can have multiple Selected
   consents and those consents can apply at various levels across the tenant."* Report jen
   nad `/sites/{id}/permissions` tedy **nevidí** granty na seznamech a souborech.
2. **Odebrání jednoho scope neodebere přístup získaný jiným.** Když aplikace má `Sites.*`
   i `Lists.*` a odeberete consent k `Sites.*`, **přístup k seznamu, který dostala přes
   `Lists.*`, jí zůstane.** Kdo „to zrušil" odebráním jednoho scope, nezrušil nic.
3. **Grant na seznam nebo položku rozbije dědění oprávnění** na tom prvku — takže se
   započítává do limitu unikátních oprávnění. Granty na úrovni site collection dědění
   nerozbíjejí, protože jsou jeho kořenem.

> [!WARNING] Čtení grantů stojí `Sites.FullControl.All` a alternativa neexistuje
> Dokumentace uvádí u `site` právě tohle oprávnění a zdůvodňuje to: *„Because you can grant
> full control permissions to a site collection by using Sites.Selected, this requirement
> is necessarily high."* **Není tu least-privileged varianta** — kdo chce inventuru grantů,
> musí mít na tenant plnou kontrolu. To je informace pro toho, kdo takový report schvaluje.

#### Mimochodem: tím se odpovídá i na otázku z dne 4

Tabulka *„What permissions do I need to manage permissions?"* říká, že ke správě oprávnění
**položky** potřebujete `Sites.FullControl.All`, **`Sites.Selected` + `FullControl`**, nebo
**`Sites.Selected` + `Owner`** (případně totéž s `Lists.SelectedOperations.Selected`).

`Write` tam **není** — což přesně odpovídá tomu, na co jste narazili v labu D4. Graph navíc
dokumentuje role jako **`read` · `write` · `owner` · `fullcontrol`**, zatímco PnP nabízí
`Read` · `Write` · `Manage` · `FullControl`. Jestli PnP `Manage` odpovídá Graph `owner`,
dokumentace neříká — a je to přesně ten rozdíl, který v labu D4 měříte.

### SAM: hotová odpověď, pokud na ni máte

**SharePoint Advanced Management (SAM)** má mezi Data access governance reporty
**Site permissions for users** — přesně tenhle dotaz jako produktovou funkci. Vrátí
seznam webů dostupných uživateli včetně toho, **jestli je přístup přímý nebo přes skupinu**
a kolika položek se týká.

Zásadní je znát jeho hranice, protože rozhodují o použitelnosti:

| Vlastnost | Hodnota |
|---|---|
| Licence | **stačí jedna přiřazená licence Microsoft Copilot v tenantu** (uživatel nemusí být admin), nebo SAM Plan 1 add-on |
| Role | SharePoint Administrator, nebo SharePoint Advanced Management Administrator |
| Stáří dat | až **48 hodin** |
| Počet reportů | max **5** |
| Opakovaný běh | jednou za **30 dní** |
| Předpoklad | org-wide report *Site permissions* musí proběhnout aspoň jednou |

Ty poslední dva řádky znamenají, že SAM report **není nástroj na ad-hoc dotaz**. Když
v úterý přijde otázka na tři lidi, skript odpoví za minuty; SAM řekne „za 30 dní zas".

### Rozhodovací osa

| | Vlastní skript | SAM DAG report |
|---|---|---|
| Licence | žádná navíc | Copilot licence nebo SAM Plan 1 |
| Ad-hoc dotaz | ano | **ne** (1× za 30 dní) |
| Item-level a sharing links | musíte dopsat | v reportu jsou |
| Tranzitivní Entra skupiny | musíte dopsat | řeší produkt |
| Auditní stopa | vaše | produktová, s datem snapshotu |
| Kdy sáhnout | rychlá odpověď, tenant bez SAM, opakovatelná automatizace | pravidelný governance cyklus, podklad pro Copilot rollout |

Pravidlo: **SAM na periodický přehled, skript na otázku, která přišla dnes.**

```mermaid
flowchart TD
  Q[Otazka: k cemu ma X pristup?] --> L{Ma tenant SAM?}
  L -->|Ne| S[Vlastni skript]
  L -->|Ano| T{Ad-hoc, nebo periodicky?}
  T -->|Ad-hoc dnes| S
  T -->|Periodicky governance| D[SAM DAG:<br/>Site permissions for users]
  S --> G[Rozbalit Entra skupiny<br/>transitiveMemberOf]
  G --> C[CSV pro zadavatele]
  D --> C
```

## Klíčové rozlišení
- **Přímé členství vs tranzitivní** — `memberOf` vs `transitiveMemberOf`; rozdíl mezi
  reportem, který platí, a reportem, který jen uklidní.
- **Falešně negativní vs chybějící odpověď** — report, který přehlédne přístup přes
  Entra skupinu, je horší než přiznané „nevím"; zadavatel podle něj jedná.
- **Snapshot vs živý dotaz** — SAM report popisuje stav starý až 48 h; skript se ptá teď.
  U personální otázky („měl přístup, když odcházel?") je to podstatný rozdíl.
- **Oprávnění vs sharing link** — dvě různé soustavy; link se v členstvích skupin neobjeví.
- **Uživatelský přístup vs aplikační grant** — dvě různé inventury nad týmž webem.
  Report o lidech aplikace nevidí a naopak. Od D4 umíte granty vytvářet, takže
  je umíte i vyrobit v množství, které nikdo neeviduje.
- **Prázdný výsledek vs nedostatečné oprávnění** — `Get-PnPSiteCollectionAdmin`
  pod app-only vrátí tiše nulu. Report, který nerozliší „nic tam není" od
  „nesměli jsme se podívat", nabízí ujištění tam, kde má přiznat mezeru.
- **Ambientní vs explicitní připojení** — `-Connection` u každého volání. Nad víc
  tenanty není ambientní připojení pohodlí, ale defekt.
- **Reverzní dotaz (uživatel → weby) vs běžný (web → kdo)** — portál umí jen druhý,
  a proto tenhle blok existuje.

## Lab
Viz [`lab-user-access-report.md`](lab-user-access-report.md).

## Zdroje (Microsoft)
- [SharePoint Advanced Management overview](https://learn.microsoft.com/en-us/sharepoint/advanced-management)
- [Prerequisites for SharePoint Advanced Management](https://learn.microsoft.com/en-us/sharepoint/sharepoint-advanced-management-prerequisites)
- [Data access governance reports — site permissions for users](https://learn.microsoft.com/en-us/sharepoint/data-access-governance-site-permissions-users-report)
- [DAG reports and PowerShell](https://learn.microsoft.com/en-us/sharepoint/powershell-for-data-access-governance)
- [List a user's transitive memberOf (Microsoft Graph)](https://learn.microsoft.com/en-us/graph/api/user-list-transitivememberof)
- [Overview of Selected Permissions in OneDrive and SharePoint](https://learn.microsoft.com/en-us/graph/permissions-selected-overview) — čtyři Selected scopes, role `read`/`write`/`owner`/`fullcontrol`, chování při odebrání consentu, a co je potřeba ke správě oprávnění na každé úrovni
- [Create permission (site)](https://learn.microsoft.com/en-us/graph/api/site-post-permissions) — `POST /sites/{id}/permissions`; ke čtení i zápisu grantů je nutné `Sites.FullControl.All`
- [Get-PnPSiteCollectionAdmin](https://pnp.github.io/powershell/cmdlets/Get-PnPSiteCollectionAdmin.html)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> **SAM je nejrychleji se měnící část tohoto bloku.** Licenční podmínky (dnes stačí jedna
> Copilot licence v tenantu), seznam DAG reportů i limity (5 reportů, běh 1× za 30 dní,
> data 48 h stará) se mění po měsících. Před KAŽDÝM během projít
> [prerekvizity](https://learn.microsoft.com/en-us/sharepoint/sharepoint-advanced-management-prerequisites)
> a ověřit, zda kurzovní tenant SAM vůbec má — jinak je SAM část jen screenshotové demo.
