# GOC223 — obsah pro web (gopas.cz)

> [!NOTE] Pro editora
> Každý nadpis „##" níže odpovídá jednomu poli na stránce kurzu; text pod ním vlož do daného pole. Bloky „Pro editora" samotné nejsou obsah stránky — nekopírovat na web.
>
> Oproti aktuálně živé stránce se mění: titulek nově obsahuje „PowerShell"; osnova je nově strukturovaná po dnech (živá stránka je plochý číslovaný seznam 1–15 bez rozdělení na dny); doplněn chybějící úvodní modul „Onboarding & pravidla práce" (na živé stránce zcela chybí); modul „Orchestry integrace" je nově označen jako volitelný (na živé stránce vystupuje jako běžná číslovaná položka bez označení, na EN verzi je navíc nesprávně přeložený jako „Orchestration integration" — ztrácí se název produktu Orchestry); u modulu SPFx je aktualizován popis dev toolchainu na Heft (výchozí od SPFx 1.22) namísto zastaralého Gulpu, který živá stránka stále uvádí; vypuštěno doporučení certifikace AZ-204 jako dalšího kroku po kurzu — kurzový materiál sám upozorňuje na její ukončení k 31. 7. 2026 ve prospěch nové AI-200.

## URL

`microsoft-365-pokrocila-automatizace-a-migrace-sharepoint_goc223`

> [!NOTE] Pro editora
> Slug se nemění — beze změny zůstává i stávající SEO historie, není potřeba nastavovat redirect.

## Titulek kurzu

Microsoft 365: PowerShell, pokročilá automatizace a migrace SharePoint

## Krátký popis (meta description / teaser)

Praktický pětidenní kurz pokročilé automatizace a migrace SharePointu Online — PowerShell, Microsoft Graph a PnP do hloubky, dva rozsáhlé laby (fileshare migrace, provisioning), governance, Azure integrace a bezpečnost automatizovaných identit až po capstone blueprint.

## Popis kurzu

Kurz provede inženýry migrací a automatizace kompletním cyklem pokročilé automatizace a migrace SharePointu Online. Týden otevírá volba nástrojové strategie (PowerShell, Microsoft Graph, PnP, REST) a bezpečná identita automatizace, na ně navazuje PowerShell do hloubky se třemi produkčními moduly, čtyřmi autentizačními módy a prvním velkým labem (certifikát, app-only přihlášení, skriptované pracovní weby). Třetí den otevírá inženýrství nad Microsoft Graph — batching, delta query, throttling a klasifikaci chyb pro odolné skripty — a dál patří dvěma pilířům kurzu: skladbě migrací (wave planning, cutover taktiky, druhý velký lab: fileshare → SharePoint Online podle JSON plánu) a automatizaci zřizování přes PnP provisioning engine, doplněným o lifecycle a compliance enforcement. Čtvrtý den propojuje SharePoint s Azure integračními vzory (Logic Apps, Functions, Runbooks, Graph change notifications), SIEM pipeline přes Azure Blob až do Log Analytics a stagingem DEV/TEST/PROD s detekcí driftu. Poslední den řeší správu dodaných řešení v App Catalogu, reporting oprávnění („ke kterým webům má tenhle člověk přístup") a security hardening identit automatizace a končí capstone blueprintem, který spojuje migraci, provisioning a Azure integraci do jednoho end-to-end plánu s rollbackem a předávkou do provozu.

## Pro koho je kurz určen

- Inženýři migrací a automatizace
- Pokročilí administrátoři SharePoint Online / Microsoft 365
- DevOps / platformní inženýři pro governance
- Konzultanti navrhující škálovatelný provisioning a migrační rámce

## Předpokládané znalosti

- Základy PowerShellu
- Zkušenost se správou SharePoint Online
- Základy Azure (resource groups, identity)
- Výhodou: znalost JSON/REST, zkušenost s migračními nástroji (SPMT, ShareGate a podobné)

## Formát a délka

- 5 dní, instruktorem vedený kurz s praktickými laby v testovacím tenantu
- úroveň: pokročilí

> [!NOTE] Pro editora
> Cena záměrně vynechána — doplní ji obchodní oddělení GOPAS přímo v CMS/ceníku.

## Osnova kurzu

### Den 1 — Onboarding, prostředí a mapa API

- **Onboarding & pravidla práce** — vstup do sdíleného cvičného tenantu, registrace MFA a pravidla bezpečné spolupráce většího počtu administrátorů v jednom prostředí.
- **Toolchain skriptera** *(lab)* — PowerShell 7, Node a CLI for Microsoft 365, VS Code rozšíření a správa verzí; výstupem je vlastní ověřovací skript, který řekne, co na stroji chybí.
- **Mapa API nad M365 a SPO** *(cvičení)* — Azure, Entra ID, Microsoft Graph a SPO REST v jedné mapě, mrtvé vrstvy a jejich náhrady; každý účastník si sám zavolá první Graph dotazy v Graph Exploreru.
- **Inženýrské prostředí, VS Code a Copilot** *(lab)* — VS Code jako pracovní nástroj pro automatizaci, hygiena Git repozitáře a zodpovědné použití Microsoft Copilot Chatu při psaní skriptů.

### Den 2 — Strategie, oprávnění a PowerShell

- **Strategie automatizace: nástroje, identita a oprávnění** *(lab)* — orientace mezi PowerShell, Microsoft Graph, PnP a REST, návrh identity automatizace (app registrace), delegated vs application permissions a `Sites.Selected` místo generálního klíče.
- **PowerShell do hloubky** *(Lab 1)* — tři PowerShell moduly (PnP, Graph, SPO) a čtyři autentizační módy; lab: certifikát, app-only přihlášení, skriptované vytvoření pracovních webů.

### Den 3 — Graph, migrace, provisioning & lifecycle

- **Microsoft Graph — inženýrské základy** — batching, delta query, throttling a klasifikace chyb pro odolné automatizační skripty.
- **Skladba migrací** *(Lab 2)* — předmigrační kontroly, wave planning, cutover taktiky; lab: migrace z fileshare do SharePointu Online podle JSON plánu.
- **Vzory automatizace zřizování** — PnP provisioning engine, tenant templates a parametrizace žádanek na weby.
- **Lifecycle & compliance enforcement** — automatizace retence a citlivosti, governance sdílení, Site Attestation.

> Volitelně dle času skupiny: Orchestry integrace a vlastní skripty (simulace bez licence, návrh governance hooků proti PnP/Graph rozhraní).

### Den 4 — Azure integrace, SIEM a staging

- **Azure integrační vzory** *(Lab 3)* — Logic Apps vs Functions vs Runbooks, subscription lifecycle Graph change notifications; lab: dávkový sync jako plánovaný task pod aplikační identitou.
- **SIEM integrace přes Azure Blob** — logovací pipeline aplikace → Blob → Event Grid → Function → SIEM, KQL základy pro validaci a dashboardy.
- **Staging prostředí: DEV, TEST, PROD** — baseline jako deklarativní artefakt a detekce driftu mezi prostředími.

### Den 5 — App Catalog, security hardening & capstone

- **App Catalog: nasazení, upgrady a audit** *(lab)* — správcovský životní cyklus dodaného řešení skriptem: nasazení, instalace, upgrade napříč weby, audit API oprávnění a odebrání. Bez vývoje SPFx — balíček je black box od dodavatele.
- **Kdo má k čemu přístup: reporting oprávnění** *(lab)* — reverzní dotaz „ke kterým webům má tenhle člověk přístup a jak je udělený", včetně přístupů přes vnořené skupiny; kdy stačí skript a kdy se vyplatí SharePoint Advanced Management.
- **Security hardening & least privilege** — minimalizace oprávnění, Conditional Access pro service principaly, rotace certifikátů.
- **Výkon, náklady & capstone** — efektivita API, náklady logování a asynchronní fan-out vzory; závěrečný blueprint spojující migraci, provisioning a Azure integraci s rollback plánem.

## Výstup kurzu

Účastník odchází s vlastním end-to-end blueprintem migrace a provisioningu SharePointu Online pro svou organizaci — včetně wave plánu, provisioning artefaktu, Azure/SIEM integrace, hardened identity automatizace a explicitního rollback a předávacího plánu do provozu.

## Před publikací — kontrolní seznam pro editora

- [ ] Doplnit cenu kurzu (obchodní oddělení GOPAS).
- [ ] Ověřit aktuální PAYG / Flex Consumption náklady Azure labů dne 4 a dostupnost/životnost M365 Developer Program tenantu.
- [ ] Ověřit aktuální stav certifikace AZ-204 (plánovaný konec 31. 7. 2026) a její náhrady AI-200, než se cesty dalšího studia zmíní v propagačních materiálech.
- [ ] Ověřit minimální verze toolchainu (PowerShell pro PnP, Node pro CLI for Microsoft 365) před uvedením do textu.
- [ ] Zkontrolovat, že žádný blok „Pro editora" nezůstal zkopírovaný do publikovaného textu.
