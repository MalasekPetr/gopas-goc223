# Instructor notes — Inženýrské prostředí, VS Code a Copilot

## Timing

- 45 min výklad + 60 min lab. Copilot Chat je součástí přihlášení kurzovním účtem —
  žádné licence se před kurzem nekupují ani nepřiřazují (změna proti dřívějšímu modelu
  s GitHub Copilotem).

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

## Tripwires

- Studenti mají tendenci akceptovat první Copilot návrh bez čtení — trvat na nahlas vysloveném
  review před `git commit`.
- **Bez priming promptu se blok rozpadne na „AI si vymýšlí"** — vložení promptu na začátku
  každé konverzace je nepřeskočitelný krok, ne doporučení. Kdo ho vynechá, dostane v D2
  `Connect-PnPOnline` bez `-ClientId` a bude ladit `AADSTS700016`.
- Otázka „proč ne GitHub Copilot" padne skoro jistě — odpověď je věcná: kurz jede na
  asistentovi, který je součástí firemního M365 přihlášení, s ochranou firemních dat
  a bez nákupu další licence; nákladovou osu (a kde začíná měřená spotřeba) drží
  [`explainer-copilot-licensing.md`](explainer-copilot-licensing.md).
- Diskuze o hostingu repozitáře (GitHub vs Azure DevOps) umí sežrat 20 minut — mít
  [`explainer-git-hosting.md`](explainer-git-hosting.md) jako odkaz a vrátit se k labu.
- Nenechat diskuzi o Copilotu sklouznout k obecné debatě "nahradí nás AI" — cíl bloku je
  konkrétní pracovní návyk (prompt s kritérii → review → test), ne filozofie.
- Git branch/PR hygiena je pro část skupiny nová látka — nepředpokládat znalost `rebase`/`merge`
  rozdílu, mít připravené jednořádkové vysvětlení.
- Část skupiny (SPO admini) bude zvyklá na ISE — ukázat "PowerShell: Enable ISE Mode" jako
  můstek, ale netrávit v něm zbytek týdne; laby počítají s plným VS Code workflow (tasks,
  debugger). Argument pro přechod: ISE neumí PowerShell 7, kterým kurz jede.

## Vazby

- Dopředu: repo hygiena a review disciplína z tohoto bloku se vyžaduje po celý zbytek týdne
  (všechny laby produkují kód do stejného repozitáře). App registration strategie v [`../automation-strategy/`](../automation-strategy/) na
  toto přímo navazuje.
- Zpět: navazuje na účet a pravidla z [`../onboarding/`](../onboarding/) (pracovní profil
  Edge, naming konvence pro repo složky).
