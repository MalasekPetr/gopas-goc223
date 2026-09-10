# Instructor notes — Azure integrační vzory

## Timing

- 40 min výklad + 90 min lab (batch sync, třetí velký lab kurzu) + **20 min instruktorské
  demo kopie s metadaty** ([`guide-copy-metadata.md`](guide-copy-metadata.md)) = 150 min.
  Batch sync nikdy nekrátit — je to povinné jádro dne.
- **Změna 2026-09-09:** to místo držel ~30min demo change notifications. Vyměněno, blok se
  tím zkrátil o 10 min. Důvod: z obou dem jen kopie s metadaty **reálně zapíše do
  SharePointu z Functiony běžící v Azure** — handshake demo vracelo token a logovalo,
  takže celý den mluvil o Azure hostingu, ale studenti nikdy neviděli, jak z Azure sáhne
  skript na obsah. Zadání labu change notifications zůstává jako samostudium a subscription
  lifecycle zůstává ve výkladu; vypuštěné je jen to demo.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Kopie s metadaty** ([`guide-copy-metadata.md`](guide-copy-metadata.md)) je **demo na
  20 min** a jde do agendy místo dema change notifications. Před během: založit zdrojový
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
- Pro batch sync lab: připravit zdrojové datasety `v1`/`v2` (CSV/JSON, fiktivní data) a
  distribuovat na učební stroje; ověřit, že Task Scheduler není na image učebny zablokovaný
  policy (jinak rovnou aktivovat Fallback z labu).
- Ověřit, že studenti mají funkční cert identitu z D1 — batch sync lab na ní stojí; kdo ji
  nemá, opravit před blokem.
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
- U batch sync labu tvrdě kontrolovat idempotenci (druhý běh = 0 změn) — studenti rádi
  odevzdají "smaž vše a nahraj znovu", což ověřením projít nesmí; a žádný secret v definici
  tasku (zkontrolovat namátkou `Export-ScheduledTask` XML).

## Vazby

- Dopředu: **Function App nasazená v demu kopie s metadaty** je ten skeleton, který si
  `siem-blob-integration` přebírá pro Blob trigger (Flex Consumption + extension bundle).
- Dopředu: `lifecycle-compliance` staví detekci driftu, kterou zápis přes `SystemUpdate`
  obejde. Demo kopie s metadaty tu slepou skvrnu pojmenuje o dva bloky dřív —
  [`guide-copy-metadata.md`](guide-copy-metadata.md).
- Zpět: navazuje na Graph error/retry vzory z [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/) a delta query (kontrast pull vs push).
