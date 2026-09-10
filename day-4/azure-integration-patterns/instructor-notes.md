# Instructor notes — Azure integrační vzory

## Timing

- **35 min výklad + 45 min Lab 3 = 80 min.** Demo kopie s metadaty
  ([`guide-copy-metadata.md`](guide-copy-metadata.md), 20 min) je **mimo agendu** —
  spouští se na dotaz.
- **Zkráceno 2026-09-10 ze 150 na 80 min**, aby se do dne vešel nový blok 2
  ([`../elevated-access/`](../elevated-access/)). Tři škrty:
  - **Lab 3: 90 → 45 min.** Registrace do Task Scheduleru (bývalé kroky 5-6) odešla
    do bloku 2, kde se stejná věc dělá **v Azure**. Task Scheduler na učebním image
    bývá blokovaný policy, takže to byl krok s nejvyšší mírou selhání. Zůstalo jádro:
    **delta přes business klíč a idempotence.**
  - **Demo kopie s metadaty: -20 min z povinného odhadu.** README ho označovalo za
    „mimo agendu" a přitom se počítalo do 150 — to byl rozpor, ne rozhodnutí.
  - **Výklad: 40 → 35 min.** Srovnání Runbook vs Function je teď v
    [`tutorial-script-to-azure.md`](tutorial-script-to-azure.md), takže ho výklad
    nemusí probírat dvakrát.
- **Idempotenci v Labu 3 nekrátit** (krok 4). Je to jediné ověření, které se nedá obejít
  výmluvou, a studenti rádi odevzdají „smaž vše a nahraj znovu".
- **Změna 2026-09-09:** to místo držel ~30min demo change notifications. Vyměněno, blok se
  tím zkrátil o 10 min. Důvod: z obou dem jen kopie s metadaty **reálně zapíše do
  SharePointu z Functiony běžící v Azure** — handshake demo vracelo token a logovalo,
  takže celý den mluvil o Azure hostingu, ale studenti nikdy neviděli, jak z Azure sáhne
  skript na obsah. Zadání labu change notifications zůstává jako samostudium a subscription
  lifecycle zůstává ve výkladu; vypuštěné je jen to demo.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Kopie s metadaty** ([`guide-copy-metadata.md`](guide-copy-metadata.md)) je **demo na
  20 min** MIMO agendu, spouští se na dotaz. Před během: založit zdrojový
  a cílový seznam, **nechat pár položek založit jinými účty a před demem to ověřit** —
  pointa je vidět jen na položkách, které mají v `Created By` někoho jiného než tebe.
  A ty účty musí být i v site user information listu **cílového** webu, jinak fáze 2 spadne.
- Pokud na demo není čas, stačí pustit
  [`solution/Copy-ListContent.Tests.ps1`](solution/Copy-ListContent.Tests.ps1) — 27 testů,
  žádný nechodí na síť. `ve WriteMode Quiet metadata NEPREDA a nahlasi to` a
  `ve WriteMode Fidelity pouzije UpdateOverwriteVersion` sdělí celý fork za třicet sekund.
- Ověřit, že `New-CourseStudentAzureResources.ps1` proběhl a Function App per student existuje.
  **Tuhle Function App si přebírá blok 2** pro Blob trigger — musí být na Flex Consumption
  a mít v `host.json` extension bundle `[4.0.0, 5.0.0)`.
- Kdo bude ukazovat i samostudijní lab change notifications, potřebuje navíc **veřejně
  dostupný endpoint** (Graph validation handshake) a měl by den předem zkusit celý flow —
  subscription lifecycle detaily (min/max expirace) se mohou lišit dle verze Graph API.
- Pro Lab 3: připravit zdrojové datasety `v1`/`v2` (CSV/JSON, fiktivní data) a distribuovat
  na učební stroje. **Task Scheduler už lab nepotřebuje** — ta část odešla do bloku 2.
- Ověřit, že studenti mají funkční cert identitu z **D2** — Lab 3 i celý blok 2 na ní stojí; kdo ji
  nemá, opravit před blokem.
- **Na dotaz „a jak se runbooky verzují?" mít připravený** [`explainer-runbook-cicd.md`](explainer-runbook-cicd.md).
  Padne skoro vždycky. Pointa: nativní source control integration umí publikovat na commit,
  ale **jen pro PowerShell 5.1 runbooky** — na runtime 7.2 s PnP.PowerShell nedosáhne,
  a sync joby navíc nepodporují MFA, které kurzový tenant vynucuje. Cesta je pipeline.
- Pro skupiny bez Azure zkušeností poslat den předem
  [`explainer-azure-orientation.md`](explainer-azure-orientation.md) jako pre-read
  (tenant vs subscription, RBAC vs Entra role, kde skript běží) — den je nejhustší v kurzu
  a základní orientace v něm nemá kde vzniknout. Zároveň ověřit, že studenti mají roli
  Contributor na **vlastní** resource group, ne na subscription.

## Tripwires

- **U Power Automate nesklouznout do hanění.** Studenti tam mají postavené věci, které
  fungují, a materiál to říká výslovně: flow dělá interakci s člověkem, skript dělá
  privilegovanou operaci. Kdo z bloku odejde s dojmem „Power Automate je špatný", odnesl
  si opak toho, co je v [`comparison-power-automate.md`](../elevated-access/comparison-power-automate.md).
- **U kopie s metadaty nezačínat cmdletem.** Nejsilnější moment není `-UpdateType`, ale
  otázka „a jak se tenhle zápis projeví ve vašem compliance reportu?" — odpověď je, že
  zápis přes `SystemUpdate` nechá `Modified` nedotčené, takže **detekce driftu podle
  `Modified` ho neuvidí**. Tuhle detekci staví blok 3. Kdo z dema odejde s dojmem, že šlo
  o parametr, minul pointu.
- **Nesnažit se ten fork rozřešit.** Studenti budou hledat volbu, která zachová metadata
  a nespustí flow. Neexistuje — a to je právě to, co si mají odnést. Provozní řešení je
  vypnout flow na dobu migračního okna, ne najít lepší přepínač.
- Studenti zapomínají na validační handshake při vytváření subscription — Function musí umět
  vrátit `validationToken` jako plain text, jinak vytvoření subscription selže s chybou.
- Nezaměňovat expiraci access tokenu (~1h) s expirací subscription (dny) — to je časté
  nedorozumění vedoucí ke zbytečné komplikaci renewal logiky.
- U Labu 3 tvrdě kontrolovat idempotenci (druhý běh = 0 změn) — studenti rádi
  odevzdají "smaž vše a nahraj znovu", což ověřením projít nesmí; a žádný secret ve
  skriptu.

## Vazby

- Dopředu: **Function App nasazená v demu kopie s metadaty** je ten skeleton, který si
  `siem-blob-integration` přebírá pro Blob trigger (Flex Consumption + extension bundle).
- Dopředu: `lifecycle-compliance` staví detekci driftu, kterou zápis přes `SystemUpdate`
  obejde. Demo kopie s metadaty tu slepou skvrnu pojmenuje o dva bloky dřív —
  [`guide-copy-metadata.md`](guide-copy-metadata.md).
- Zpět: navazuje na Graph error/retry vzory z [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/) a delta query (kontrast pull vs push).
