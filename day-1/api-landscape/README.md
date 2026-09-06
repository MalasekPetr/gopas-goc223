# Mapa API nad M365 a SPO: Azure, Entra ID, Graph, SPO REST

> Typ: povinný · Den: 1 · Odhad: 25 min výklad + 20 min cvičení

## Cíle
- Student umí zařadit pojmy Azure, Entra ID, Microsoft 365 a SharePoint Online do jedné mapy
  a ví, co je čeho součást.
- Student rozumí, kudy vedou API cesty k datům (Microsoft Graph vs SPO REST v1/CSOM) a kde
  v obrázku sedí autentizace.
- Student si obě cesty **sám vyzkouší na živém tenantu** a umí pojmenovat, čím se liší
  jejich odpovědi — viz [`exercise-graph-explorer.md`](exercise-graph-explorer.md).
- Student pozná v zákaznickém prostředí **mrtvou vrstvu** a ví, čím se dnes nahrazuje.

> [!NOTE] Proč je tenhle blok povinný
> Mapa API je rozhodovací rámec, na kterém stojí zbytek týdne: „Graph first, SPO REST tam,
> kde Graph nestačí" se vrací v každém dalším labu. Cvičení v Graph Exploreru je zároveň
> **jediný hands-on moment dne 1** před blokem
> [`../automation-strategy/`](../automation-strategy/) — první úspěch, který nemá vypadnout.

## Výklad

### Tři platformy, jedna identita

**Microsoft Entra ID** je identitní vrstva společná pro všechno — uživatelé, skupiny, app
registrace, role. **Microsoft 365** (SharePoint, Exchange, Teams...) je SaaS vrstva nad ní.
**Azure** je IaaS/PaaS vrstva (subscriptions, resource groups, Functions, Storage) — sdílí
s M365 tenant a identitu, ale má **oddělený billing** (subscription) a oddělený admin model
(RBAC role na resources, ne Entra admin role). Prakticky: náš kurzový M365 tenant je zdarma
(E5 Developer), Azure laby jedou nad samostatnou placenou subscription — viz
[`../../environment.md`](../../environment.md).

### API cesty k SharePoint datům

- **Microsoft Graph** (`graph.microsoft.com`) — jednotná brána nad celým M365 včetně
  SharePointu (`/sites`, `/drives`). Moderní default, konzistentní auth (Entra tokeny),
  batching/delta (viz [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/)).
- **SPO REST v1** (`<tenant>.sharepoint.com/_api/...`) a **CSOM** — starší, SharePoint-native
  rozhraní. Pokrývají věci, které Graph dosud neumí (jemné detaily listů, provisioning
  artefakty) — proto PnP.PowerShell pod kapotou kombinuje obojí.
- Pravidlo: **Graph first, SPO REST tam, kde Graph nestačí** — stejná logika jako
  "wrapper vs přímé volání" v [`../automation-strategy/`](../automation-strategy/).

### Časová osa: proč je krajina takhle rozdělená
Dnešní dvojice Graph + SPO REST je výsledek generační výměny, ne návrhu na zelené louce.
Postupně zemřely: SOAP web services (`_vti_bin/*.asmx`), JSOM, sandbox solutions s kódem,
**SharePoint Add-ins + Azure ACS** (v Microsoft 365 vypnuté 2. 4. 2026) a „JS injection"
(JSLink, Script Editor — custom script je od 11/2024 vynucovaně vypnutý). Na straně
PowerShellu totéž: MSOnline a AzureAD moduly jsou mrtvé, PnP a Graph SDK žijí.

Dvě ponaučení, která nesou celý kurz: (1) **moduly a vrstvy umírají, REST API zůstává** —
kdo rozumí principu pod nástrojem, řešení přepíše; (2) prostředí zákazníků jsou mrtvých
vrstev plná a **umět je poznat je samostatná dovednost**, kterou potřebujete hned při
migračním assessmentu — mapa i otázky do assessmentu jsou v
[`../../day-3/migration-patterns/explainer-legacy-layers.md`](../../day-3/migration-patterns/explainer-legacy-layers.md).
Náhrada je vždy táž dvojice: **Entra app registrace** (identita) a **SPFx** (customizace).

### Kde sedí autentizace

Každé volání — Graph i SPO REST — nese Entra token. App registrace (identita aplikace),
permissions (co token smí) a auth flow (jak se token získá) jsou společné pro všechny cesty;
liší se jen resource, na který token zní. Detajlně v
[`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).

```mermaid
flowchart TD
  E[Microsoft Entra ID — identita, app registrace, tokeny] --> M365[Microsoft 365 SaaS]
  E --> AZ[Azure — subscription, resource groups]
  M365 --> SPO[SharePoint Online]
  S[Skript / aplikace] -->|token| G[Microsoft Graph]
  S -->|token| R[SPO REST v1 / CSOM]
  G --> SPO
  R --> SPO
```

## Klíčové rozlišení
- **Tenant (identita + M365 služby) vs Azure subscription (billing + resources)** — jeden
  tenant může mít 0 i N subscriptions; náš kurz má tenant zdarma a subscription placenou.
- **Entra admin role (Global admin) vs Azure RBAC (Contributor na resource group)** — dvě
  různé autorizační soustavy; GA v tenantu automaticky neznamená přístup k Azure resources.
- **Graph (jednotná brána, moderní) vs SPO REST v1/CSOM (starší, širší SPO pokrytí)** —
  ne konkurence, ale doplněk; PnP je wrapper nad oběma.
- **Mrtvá vrstva vs podporovaná náhrada** — Add-ins/ACS, JSOM, MSOnline a AzureAD moduly
  v zákaznickém prostředí stále běží; poznat je a znát náhradu je dovednost pro migrační
  assessment, ne historická poznámka.

## Cvičení
Viz [`exercise-graph-explorer.md`](exercise-graph-explorer.md) — každý účastník si sám
zavolá `/me`, `$select` a seznamy jednoho webu přes Graph i přes SPO REST, a porovná
odpovědi.

> [!NOTE] Formáty odpovědí
> JSON je v tomto kurzu předpokládaná znalost; kdo si chce doplnit UTF-8 disciplínu
> a export do CSV pro Excel (česká diakritika), má to v
> [`../../day-2/powershell-deep-dive/explainer-formats-encoding.md`](../../day-2/powershell-deep-dive/explainer-formats-encoding.md).

## Zdroje (Microsoft)
- [Microsoft Graph overview](https://learn.microsoft.com/en-us/graph/overview)
- [Get to know the SharePoint REST service](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/get-to-know-the-sharepoint-rest-service)
- [What is Microsoft Entra ID?](https://learn.microsoft.com/en-us/entra/fundamentals/whatis)

## Stav produktu / delta
- Ověřit k datu běhu — tempo přesunu SPO funkcí do Graphu (pokrytí `/sites` API roste);
  hranice "co Graph umí vs neumí nad SharePointem" se posouvá každý rok.
