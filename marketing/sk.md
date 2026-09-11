# GOC223 — obsah pre web (gopas.sk)

> [!NOTE] Poznámka pre editora
> Každý nadpis „##" nižšie zodpovedá jednému poľu na stránke kurzu; text pod ním vlož do daného poľa. Bloky „Poznámka pre editora" samotné nie sú obsah stránky — nekopírovať na web.
>
> Oproti aktuálne živej stránke sa mení: titulok teraz obsahuje „PowerShell"; osnova je novo štruktúrovaná po dňoch (živá stránka je plochý číslovaný zoznam 1–15 bez rozdelenia na dni); doplnený chýbajúci úvodný modul „Onboarding & pravidlá práce" (na živej stránke úplne chýba); modul „Orchestry integrácia" je novo označený ako voliteľný (na živej stránke vystupuje ako bežná číslovaná položka bez označenia, na EN verzii je navyše nesprávne preložený ako „Orchestration integration" — stráca sa názov produktu Orchestry); pri module SPFx je aktualizovaný popis dev toolchainu na Heft (predvolený od SPFx 1.22) namiesto zastaraného Gulpu, ktorý živá stránka stále uvádza; vypustené odporúčanie certifikácie AZ-204 ako ďalšieho kroku po kurze — kurzový materiál sám upozorňuje na jej ukončenie k 31. 7. 2026 v prospech novej AI-200.

## URL

`microsoft-365-pokrocila-automatizacia-a-migracia-sharepoint_goc223`

> [!NOTE] Poznámka pre editora
> Slug sa nemení — nie je potrebné nastavovať redirect, zachováva sa existujúca SEO (search engine optimization) história.

## Titulok kurzu

Microsoft 365: PowerShell, pokročilá automatizácia a migrácia SharePoint

## Krátky popis (meta description / teaser)

Praktický päťdňový kurz pokročilej automatizácie a migrácie SharePointu Online — PowerShell, Microsoft Graph a PnP do hĺbky, tri rozsiahle laby (app-only identita, provisioning, dávkový sync), governance, Azure integrácia a bezpečnosť automatizovaných identít až po capstone blueprint.

## Popis kurzu

Kurz prevedie inžinierov migrácií a automatizácie kompletným cyklom pokročilej automatizácie a migrácie SharePointu Online. Týždeň otvára voľba nástrojovej stratégie (PowerShell, Microsoft Graph, PnP, REST) a bezpečná identita automatizácie, na ne nadväzuje PowerShell do hĺbky s tromi produkčnými modulmi, štyrmi autentizačnými módmi a prvým veľkým labom (certifikát, app-only prihlásenie, skriptované pracovné weby). Tretí deň otvára inžinierstvo nad Microsoft Graph — batching, delta query, throttling a klasifikáciu chýb pre odolné skripty — a ďalej patrí dvom pilierom kurzu: skladbe migrácií (predmigračné kontroly, wave planning, cutover taktiky) a automatizácii zriaďovania cez PnP provisioning engine, doplneným o model troch prostredí DEV/TEST/PROD s detekciou driftu. Štvrtý deň prepája SharePoint s Azure integračnými vzormi (Logic Apps, Functions, Runbooks, Graph change notifications), SIEM pipeline cez Azure Blob až do Log Analytics a lifecycle a compliance enforcement. Posledný deň rieši správu dodaných riešení v App Catalogu, reporting oprávnení („ku ktorým webom má tento človek prístup") a security hardening identít automatizácie a končí capstone blueprintom, ktorý spája migráciu, provisioning a Azure integráciu do jedného end-to-end plánu s rollbackom a odovzdaním do prevádzky.

## Pre koho je kurz určený

- Inžinieri migrácií a automatizácie
- Pokročilí administrátori SharePoint Online / Microsoft 365
- DevOps / platformní inžinieri pre governance
- Konzultanti navrhujúci škálovateľný provisioning a migračné rámce

## Predpokladané znalosti

- Základy PowerShellu — ak si nie ste istí, kurz ich na začiatku druhého dňa v prípade potreby zjednotí
- Skúsenosť so správou SharePoint Online
- Základy Azure (resource groups, identita)
- Výhodou: znalosť JSON/REST, skúsenosť s migračnými nástrojmi (SharePoint Migration Tool, ShareGate a podobné)

## Formát a dĺžka

- 5 dní, kurz vedený lektorom s praktickými labmi v testovacom tenante
- úroveň: pokročilí

> [!NOTE] Poznámka pre editora
> Cena zámerne vynechaná — doplní ju obchodné oddelenie GOPAS priamo v redakčnom systéme (CMS)/cenníku.

## Osnova kurzu

### Deň 1 — Onboarding, prostredie a mapa API

- **Onboarding & pravidlá práce** — vstup do zdieľaného cvičného tenantu, registrácia viacfaktorového overenia (MFA) a pravidlá bezpečnej spolupráce väčšieho počtu administrátorov v jednom prostredí.
- **Toolchain skriptera** *(lab)* — PowerShell 7, Node a nástroj příkazové řádky CLI for Microsoft 365, rozšírenia VS Code a správa verzií; výstupom je vlastný overovací skript, ktorý povie, čo na stroji chýba.
- **Mapa API nad Microsoft 365 (M365) a SharePoint Online (SPO)** *(cvičenie)* — Azure, Entra ID, Microsoft Graph a SPO REST v jednej mape, mŕtve vrstvy a ich náhrady; každý účastník si sám zavolá prvé Graph dotazy v Graph Exploreri.
- **Inžinierske prostredie, VS Code a Copilot** *(lab)* — VS Code ako pracovný nástroj pre automatizáciu, hygiena Git repozitára a zodpovedné použitie Microsoft Copilot Chatu pri písaní skriptov.

### Deň 2 — Stratégia, oprávnenia a PowerShell

- **Stratégia automatizácie: nástroje, identita a oprávnenia** *(lab)* — orientácia medzi PowerShell, Microsoft Graph, PnP a REST, návrh identity automatizácie (app registrácia), delegated vs. application permissions a `Sites.Selected` namiesto generálneho kľúča.

- **PowerShell do hĺbky** *(veľký lab)* — tri PowerShell moduly (PnP, Graph, SPO) a štyri autentizačné módy; lab: certifikát, app-only prihlásenie, skriptované vytvorenie pracovných webov.

> Voliteľne podľa vstupnej úrovne skupiny: **zjednotenie základov PowerShellu** (objekty v pipeline, filtrovanie vľavo, čítanie výstupov cmdletov) — instruktor blok zaradí, keď ho skupina potrebuje, aby na nadväzujúcu prácu so skriptami stačili všetci.

### Deň 3 — Graph, staging, migrácia a provisioning

- **Microsoft Graph — inžinierske základy** — batching, delta query, throttling a klasifikácia chýb pre odolné automatizačné skripty.
- **Staging prostredie: DEV, TEST, PROD** — baseline ako deklaratívny artefakt a detekcia driftu medzi prostrediami. Koncept baseline vs drift sa vracia v provisioningu aj v lifecycle a compliance enforcement.
- **Skladba migrácií** — predmigračné kontroly, wave planning, cutover taktiky, veľké zoznamy a throttling.
- **Vzory automatizácie zriaďovania** — PnP provisioning engine, tenant templates a parametrizácia žiadaniek na weby.

> Voliteľne podľa času skupiny: Orchestry integrácia a vlastné skripty (simulácia bez licencie, návrh governance hookov proti PnP/Graph rozhraniu).

### Deň 4 — Azure integrácia, SIEM a lifecycle

- **Azure integračné vzory** *(veľký lab)* — Logic Apps vs. Functions vs. Runbooks, subscription lifecycle Graph change notifications; lab: idempotentný dávkový sync pod aplikačnou identitou; krok za krokom, ako skript dostať do Azure a spustiť ho tam.
- **Elevovaný prístup: self-service žiadosť o oprávnenie** *(lab)* — najčastejšie stavaná automatizácia nad SharePointom: užívateľ požiada o prístup, aplikačná identita mu ho pridelí. Dvojstupňová autorizačná brána, `Sites.Selected` zúžený na jeden web, auditované zamietnutie — a nasadenie do Azure bez jediného hesla.
- **SIEM integrácia cez Azure Blob** — logovacia pipeline aplikácia → Blob → Event Grid → Function → SIEM, základy KQL (Kusto Query Language) pre validáciu a dashboardy.
- **Lifecycle & compliance enforcement** — automatizácia retencie a citlivosti, governance zdieľania, Site Attestation.

### Deň 5 — App Catalog, security hardening a capstone

- **App Catalog: nasadenie, upgrady a audit** *(lab)* — správcovský životný cyklus dodaného riešenia skriptom: nasadenie, inštalácia, upgrade naprieč webmi, audit API oprávnení a odobratie. Bez vývoja SPFx — balíček je black box od dodávateľa.
- **Kto má k čomu prístup: reporting oprávnení** *(lab)* — reverzná otázka „ku ktorým webom má tento človek prístup a ako je udelený", vrátane prístupov cez vnorené skupiny; kedy stačí skript a kedy sa vyplatí SharePoint Advanced Management.
- **Security hardening & least privilege** — minimalizácia oprávnení, Conditional Access pre service principaly, rotácia certifikátov.
- **Výkon, náklady & capstone** — efektivita API, náklady logovania a asynchrónne fan-out vzory; záverečný blueprint spájajúci migráciu, provisioning a Azure integráciu s rollback plánom.

## Výstup kurzu

Účastník odchádza s vlastným end-to-end blueprintom migrácie a provisioningu SharePointu Online pre svoju organizáciu — vrátane wave plánu, provisioning artefaktu, Azure/SIEM integrácie, hardened identity automatizácie a explicitného rollback a odovzdávacieho plánu do prevádzky.

## Pred publikáciou — kontrolný zoznam pre editora

- [ ] Doplniť cenu kurzu (obchodné oddelenie GOPAS).
- [ ] Overiť aktuálne PAYG / Flex Consumption náklady Azure labov dňa 4 a dostupnosť/životnosť M365 Developer Program tenantu.
- [ ] Overiť aktuálny stav certifikácie AZ-204 (plánovaný koniec 31. 7. 2026) a jej náhrady AI-200, než sa cesty ďalšieho štúdia spomenú v propagačných materiáloch.
- [ ] Overiť minimálne verzie toolchainu (PowerShell pre PnP, Node pre CLI for Microsoft 365) pred uvedením do textu.
- [ ] Skontrolovať, že žiadny blok „Poznámka pre editora" nezostal skopírovaný do publikovaného textu.
