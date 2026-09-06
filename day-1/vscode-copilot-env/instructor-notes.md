# Instructor notes — Inženýrské prostředí, VS Code a Copilot

## Timing

- 40 min výklad + 45 min lab. Blok se zkrátil (dřív 45 + 60): instalace nástrojů odešla do
  [`../toolchain-setup/`](../toolchain-setup/) a Git se učí v lineární podobě, ne přes
  branch/PR gate. Copilot Chat je součástí přihlášení kurzovním účtem —
  žádné licence se před kurzem nekupují ani nepřiřazují (změna proti dřívějšímu modelu
  s GitHub Copilotem).
- **Agent Scripting Advisor: 10 min instruktorského dema + read-along, uvnitř výkladového
  bloku.** Žádný nový lab, nulový časový náklad navíc. Demo běží **na jednom sedadle
  (lektorském)**, ne hands-on pro celou učebnu — důvod je řízení rizika, ne čas: dokud není
  ověřený metering (viz go/no-go níže), nepouštět 25 účtů proti agentovi s MCP akcí.
  Nejlepší demo je vedle sebe: stejná otázka do holého Copilot Chatu a do agenta.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Ověřit dostupnost Copilot Chatu na kurzovním tenantu vlastním testovacím účtem** —
  vstupní URL i dostupnost se mění (viz [`explainer-copilot-licensing.md`](explainer-copilot-licensing.md)).
  Pokud se v běhu má ukazovat agent nebo cokoli nad firemními daty pro nelicencované
  uživatele, musí být **předem** zapnutá billing policy s rozpočtem (Azure subscription) —
  jinak funkce chybí bez zjevného důvodu.
- **Projet Test A i Test B z priming promptu den předem.** Test B (PnP bez `-ClientId`)
  závisí na chování modelu — pokud už `-ClientId` generuje sám, mít připravený náhradní
  fail, jinak demo ztratí pointu.
- Ověřit dostupnost PowerShell Gallery / npm registry z učebny (firewall) — PSScriptAnalyzer/Pester
  instalace vyžaduje síť.
- **Agent musí být publikovaný a schválený v tenantu před během.** Deklarativní agent se
  do tenantu dostává jako aplikace (tenant app catalog), takže potřebuje schválení správce —
  to není otázka minut. Zdroj a postup:
  [`agent-scripting-advisor/README.md`](agent-scripting-advisor/README.md).
- **MCP consent otestovat na studentském, ne admin účtu.** `disclaimer` agenta vyzývá
  uživatele „Allow the Microsoft Learn connection when prompted". Když má tenant vypnutý
  user consent to apps, prompt selže a agent **tiše spadne zpátky na model knowledge** —
  protože `discourage_model_knowledge` je `false`, nedostanete chybu, jen horší odpovědi.
  To je přesně to selhání, kvůli kterému agent existuje, a v demu ho nepoznáte. Kontrolní
  otázka do agenta: nechat si vypsat zdroj odpovědi — bez MCP nebude citovat Learn.
- **Metering MCP akce.** Dokumentace váže měřenou spotřebu na *capabilities jiné než Web
  search*; agent žádnou takovou nemá. Zda ji spouští deklarovaná **MCP akce**, dokumentace
  neříká — ověřit řádek agenta v Copilot Credits reportu (Reports > Usage > Microsoft
  Copilot > Credits) po testovací konverzaci. Dokud to není ověřeno, platí demo na jednom
  sedadle. Rozpočet na billing policy jen **notifikuje, nevynucuje** — jediná tvrdá brzda
  je odpojení policy.

## Tripwires

- Studenti mají tendenci akceptovat první Copilot návrh bez čtení — trvat na nahlas vysloveném
  review před `git commit`.
- **Bez priming promptu se blok rozpadne na „AI si vymýšlí"** — vložení promptu na začátku
  každé konverzace je nepřeskočitelný krok, ne doporučení. Kdo ho vynechá, dostane v D2
  `Connect-PnPOnline` bez `-ClientId` a bude ladit `AADSTS700016`.
- **Otázka „proč nemůžu použít Claude Code / GitHub Copilot jako doma" padne u agenta znovu.**
  Odpověď není obranná: doma ty nástroje používejte, jsou dobré. Na kurzu se pracuje s tím,
  co je v učebně, a agent ukazuje, že to není ústupek — MCP grounding, vynucené guardrails
  a auditovatelné hranice jsou vlastnosti, které obecný chat nemá bez ohledu na to, který
  model za ním stojí. Nesklouznout k porovnávání modelů; téma je **architektura nástroje**.
- **U dema nezůstat u „hele, umí to odpovědět".** Pointa je v `instruction.txt` a
  `ai-plugin.json` otevřených vedle chatu — student má vidět, že chování, které pozoruje,
  je někde napsané a verzované. Bez read-alongu je demo jen další chatbot.
- Otázka „proč ne GitHub Copilot" padne skoro jistě — odpověď je věcná: kurz jede na
  asistentovi, který je součástí firemního M365 přihlášení, s ochranou firemních dat
  a bez nákupu další licence; nákladovou osu (a kde začíná měřená spotřeba) drží
  [`explainer-copilot-licensing.md`](explainer-copilot-licensing.md).
- Diskuze o hostingu repozitáře (GitHub vs Azure DevOps) umí sežrat 20 minut — mít
  [`explainer-git-hosting.md`](explainer-git-hosting.md) jako odkaz a vrátit se k labu.
- Nenechat diskuzi o Copilotu sklouznout k obecné debatě "nahradí nás AI" — cíl bloku je
  konkrétní pracovní návyk (prompt s kritérii → review → test), ne filozofie.
- **Nenechat se vtáhnout do branch/PR debaty.** Lab jede lineárně v `main` schválně; kdo se
  ptá na branch strategii, dostane odpověď „cílový stav pro tým, ne vstupní požadavek"
  a odkaz na README. Ušetřených 20 minut je přesně to, čím se blok zkrátil.
- Část skupiny (SPO admini) bude zvyklá na ISE — ukázat "PowerShell: Enable ISE Mode" jako
  můstek, ale netrávit v něm zbytek týdne; laby počítají s plným VS Code workflow (tasks,
  debugger). Argument pro přechod: ISE neumí PowerShell 7, kterým kurz jede.

## Vazby

- Dopředu: repo hygiena a review disciplína z tohoto bloku se vyžaduje po celý zbytek týdne
  (všechny laby produkují kód do stejného repozitáře). App registration strategie v [`../automation-strategy/`](../automation-strategy/) na
  toto přímo navazuje.
- Zpět: navazuje na účet a pravidla z [`../onboarding/`](../onboarding/) (pracovní profil
  Edge, naming konvence pro repo složky).
