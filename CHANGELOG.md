# Historie změn kurzu

Záznam přestaveb agendy a věcných korektur GOC223, nejnovější nahoře. **Není to studentský
materiál** — studenta nezajímá, jaká byla předchozí verze, a záznam změn ve studentském
textu jen odvádí pozornost od látky (pravidlo v [`CONVENTIONS.md`](CONVENTIONS.md)).
Pro lektora je to naopak podstatné: každý záznam říká, **proč** je něco jinak, aby se
zrušené rozhodnutí nevrátilo omylem zpátky.

Aktuální stav agendy drží [`agenda.md`](agenda.md), aktuální stav rozpracování `CLAUDE.md`.

---

## 2026-09-11 — editorial pass a nákladová/eventová látka

- **Nákladové ohraničení Azure** doplněno do
  [`day-4/azure-integration-patterns/explainer-azure-orientation.md`](day-4/azure-integration-patterns/explainer-azure-orientation.md)
  (stručně) a [`day-5/performance-cost-capstone/`](day-5/performance-cost-capstone/)
  (detailně). Klíčové zjištění pro výklad: **budget je hlásič, ne jistič** a denní strop
  ingestu přestřelí, přičemž přestřelené se účtuje.
- **Nové srovnání** [`day-4/azure-integration-patterns/comparison-event-reaction.md`](day-4/azure-integration-patterns/comparison-event-reaction.md)
  — event handler vs webhook vs CRON na příkladu SPO seznamu. Nosný bod: synchronní
  (*-ing*) zásah v SharePoint Online neexistuje a notifikace neobsahuje obsah změny,
  takže pull zůstává pod push variantou v obou případech.
- **Pravidla proti nafouknutí callloutů** zapsána do [`CONVENTIONS.md`](CONVENTIONS.md):
  tři testovatelná kritéria místo vkusu, historie změn ven ze studentských souborů,
  rozepisování zkratek při prvním použití na stránce, výkladový registr.
- **Rejstřík zkratek** vznikl v [`GLOSSARY.md`](GLOSSARY.md) — předtím neexistoval,
  přitom kurz používá přes 80 zkratek.
- Tenhle soubor vznikl a přebral záznamy změn z `agenda.md`, `day-1/README.md`,
  `day-2/README.md`, `day-3/README.md` a `day-4/README.md`, kde se částečně duplikovaly.

## 2026-09-10 — den 4: přestavba proti akademičnosti

**Důvod:** den 4 mluvil o Azure hostingu a identitách celý den, ale studenti si nic
nepostavili — a v celém repu nebyl **jediný postup, jak skript do Azure dostat**.

Co přišlo:

- **Blok 2** [`day-4/elevated-access/`](day-4/elevated-access/) (30 výklad + 60 lab) —
  plnohodnotný modul se step-by-step labem o **13 krocích v šesti částech**
  (ručně → certifikát → nic). Do té doby to bylo 15min demo uvnitř bloku 1.
- **Tutorial** [`day-4/azure-integration-patterns/tutorial-script-to-azure.md`](day-4/azure-integration-patterns/tutorial-script-to-azure.md)
  — krok za krokem přes Automation Runbook na neutrálním skriptu. Lab bloku 2 jede tutéž
  cestu v části 5.

Čím se zaplatilo — **70 min z bloku 1** (150 → 80):

- **Lab 3: 90 → 45 min.** Registrace do Task Scheduleru odešla do bloku 2, kde se táž věc
  dělá **v Azure**. Task Scheduler na učebním image bývá blokovaný policy, takže to byl
  krok s nejvyšší mírou selhání. Zůstalo jádro: delta přes business klíč a idempotence.
- **Demo kopie s metadaty: −20 min z povinného odhadu.** README ho označovalo za „mimo
  agendu" a přitom se počítalo do 150 — to byl rozpor, ne rozhodnutí. Demo zůstává,
  spouští se na dotaz.
- **Výklad: 40 → 35 min.** Srovnání Runbook vs Function je teď v tutoriálu.

**Výsledek: 80 + 90 + 120 + 100 = 390 min = 6,5 h**, přesně na stropu — a reálný běh ten
odhad **potvrdil**. Den 4 je zatím jediný den, u kterého odhad seděl.

## 2026-09-09 — rekalibrace dne 3 a korektura baseline skriptu

**Rekalibrace D3 podle reálného běhu.** Den se odučil **podle plánu**, přestože repo na
něj počítalo 470 min. Co se skutečně stalo: **staging se odučil bez labu** (jen výklad)
a **Lab 2 vypadl celý** (výklad zkrácen). Oba laby jsou proto **volitelné** a povinné
jádro dne je **305 min / 5,1 h** (120 + 40 + 45 + 100).

Tím se rozpustila i premisa „ubrat 70 min" — nebyla to kapacita, byly to nafouknuté
odhady plus dva laby, které se nestíhají učit.

Cena rekalibrace: hands-on dne 3 stojí na labu `provisioning-patterns`. Rezerva pod
stropem je ale dost velká na zkrácený Lab 2 (~75 min → 6,3 h), takže je **první v řadě**,
když čas je.

**Korektura: diff/baseline skript nebyl tím, čím ho repo tvrdilo.** Do 2026-09-09 se
v `agenda.md`, `day-3/README.md` i `day-4/README.md` psalo, že diff/baseline skript ze
`staging-environments` je vstupem tří labů a je to „nejvíc znovupoužitý artefakt kurzu".
Na tom argumentu se 2026-09-08 staging vrátil z D4 na D3.

**Reálný běh tu vazbu nikdy nevyzkoušel:** staging se odučil bez labu, takže skript
nevznikl — a provisioning se přesto odučil, jen se ten krok obešel. Byla to skrytá
křehkost: závislost existovala **jen jako studentský výstup**, takže vypuštění jednoho
volitelného labu tiše bralo vstup dvěma dalším.

Co se změnilo: oba konzumenti jsou přeformulovaní tak, že skript **uvítají, ale
nevyžadují**; tvrzení je zrušené v `agenda.md`, `day-3/README.md`, `day-4/README.md`
i v marketingu cs/en/sk. `day-4/lifecycle-compliance/lab-compliance-drift.md` si baseline
zapíše jako pár řádků JSON, což je stejně všechno, co potřebuje. Staging na D3 zůstává,
ale už z kapacitních důvodů — přesun na D4 by ho po přestavbě 2026-09-10 vytáhl na 7,2 h.

**Poučení, které z toho platí dál:** než se modul přesune kvůli „rozbitému předpokladu",
ověřit, že ten předpoklad někdo v reálném běhu skutečně použil. Zapsáno jako guardrail
v `CLAUDE.md`.

**Blok 1 dne 4.** ~30min instruktorské demo change notifications nahradilo **20min demo
kopie dat se zachováním metadat**
([`day-4/azure-integration-patterns/guide-copy-metadata.md`](day-4/azure-integration-patterns/guide-copy-metadata.md)).
Z obou dem je to jediné, které **reálně zapíše do SharePointu z Functiony běžící v Azure** —
a den je přitom celý o Azure integraci. Function App, kterou demo nasadí, si navíc přebírá
blok 2 pro Blob trigger. Bonus je vazba na blok 3: zápis přes `SystemUpdate` nechá
`Modified` nedotčené, takže detekce driftu postavená na `Modified` ho neuvidí — blok 1 tu
slepou skvrnu pojmenuje, blok 3 na ni narazí. Zadání labu change notifications zůstává
jako samostudium.

**Lab 2 už marketing neslibuje** — instruktor očekává, že bude vypadávat i dál. Zmínka
vypuštěna z cs/en/sk včetně číslování labů. Kdyby se vrátil jako pevná součást, doplnit
zpátky.

## 2026-09-08 — reálný běh dne 2, přesuny mezi D2/D3/D4

- **`graph-fundamentals` odešel z D2 na D3**, protože se na něj ve dni 2 nedostalo — den
  skončil po bloku o PowerShellu.
- **Přibyl volitelný blok základů PowerShellu** [`day-2/opt-powershell-basics/`](day-2/opt-powershell-basics/).
  Reálný běh ukázal, že část skupiny je potřebuje, a bez nich se `powershell-deep-dive`
  pro takovou skupinu odučit nedá. D2 je tím **4,0 h povinně / 5,0 h s ním**.
- **`staging-environments` se vrátil z D4 na D3** — tehdy s odůvodněním, že jeho baseline
  skript potřebují tři laby. **To odůvodnění o den později padlo** (viz 2026-09-09), blok
  tu ale zůstává z kapacitních důvodů.
- **`lifecycle-compliance` odešel z D3 na D4**, kde navazuje na SIEM. Den 4 se tím časově
  nezměnil (oba bloky 100 min) a vazba na staging míří správným směrem, tedy do
  předchozího dne. Retenci logů (blok 2) a retenci obsahu (blok 3) je přitom potřeba
  držet oddělené — jsou to jiné compliance požadavky.
- **Kalkulátor nákladů hostingu** `day-5/performance-cost-capstone/solution/Get-HostingCost.ps1`
  bez změny agendy.

## 2026-09-07 — reálný běh dne 1, vypuštění Clarity

- **`automation-strategy` přesunut z D1 na začátek D2.** V reálném běhu se na něj
  nedostalo: den byl naplánovaný na 6,3 h a onboarding s MFA u 25 účtů je nepředvídatelný.
  Na D2 navíc sedí logicky lépe — app registrace, kterou vytváří jeho lab, je vstup pro
  consent i pro certifikát ve Labu 1. Zbytek dne 1 běžel podle plánu (VS Code funkční,
  výklad srozumitelný); D1 je tím **4,9 h**.
- **`automation-strategy` sloučen s bývalým blokem `permissions-consent`** — oba mluvily
  o least privilege a jejich laby pracovaly na téže app registraci.
- **Microsoft Clarity vypuštěna z kurzu.** Z celého týdne to bylo téma nejvzdálenější
  automatizaci a migraci. Obecný mechanismus SPFx tenant-wide deploymentu, který Clarity
  demonstrovala, zůstává — řeší ho [`day-5/app-catalog-lifecycle/`](day-5/app-catalog-lifecycle/).
  **Je to jediná nevratná část přestavby:** kdyby se měla Clarity vrátit, nemá slot.
  Na její místo v D4 tehdy přišel `staging-environments`.

## 2026-09-06 — permission discovery, deklarativní agent

- Vývoj SPFx z kurzu vypuštěn; `day-5/app-catalog-lifecycle` řeší jen správcovský
  životní cyklus balíčku. Verze generátoru ani vazba Node ↔ SPFx tím přestaly být
  pre-run položkou.
- Nový blok [`day-5/permission-discovery/`](day-5/permission-discovery/) se SAM.
- Doplněn deklarativní agent **Scripting Advisor** jako instruktorské demo
  (`day-1/vscode-copilot-env/agent-scripting-advisor/`).

## 2026-09-04 — zpětný přenos z běhu KURZ-26-07-29

Do modulů doplněny materiály ověřené reálným během zakázkového kurzu postaveného
z GOC223: troubleshooting autentizace, tahák SPO API, velké seznamy, certifikáty
a formáty, site & list designy, mrtvé vrstvy (Add-ins/ACS), Azure orientace, správa
SPFx, Copilot priming prompt.

**Agenda se neměnila** — vše přistálo jako supporting soubory uvnitř existujících modulů
(nulový časový náklad). Jediný nový lab
(`day-2/powershell-deep-dive/lab-write-identities.md`) je označený jako **volitelný**.

Opravena věcná chyba v `GLOSSARY.md`: list view threshold != throttling.

Rozhodnuto, že kurz jede na **Microsoft Copilot Chat** (součást firemního přihlášení,
žádný nákup navíc) plus pay-as-you-go pro agenty nad firemními daty.

## 2026-07-18 — zrušeno číslování modulů

Pořadová čísla modulů zrušena v nadpisech i v odkazech kvůli flexibilitě vkládání
modulů; odkazuje se slugem. Pořadí drží výhradně [`agenda.md`](agenda.md).

## 2026-07-17 — všech 5 dnů rozpracováno do plné hloubky

Konec fáze 2. Zbývá finální průchod všemi currency-markery těsně před prvním reálným
během kurzu.
