# Instructor notes — Inženýrské prostředí, VS Code a Copilot

## Timing

- 45 min výklad + 60 min lab. Instalace GitHub Copilot licence pro studenty musí proběhnout
  před kurzem (viz `environment.md`) — neřešit na místě, žere čas celé skupiny.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že všichni studenti mají aktivní GitHub Copilot licenci a Copilot extension se
  úspěšně přihlásí ve VS Code (test alespoň 3 dny předem, ne den před kurzem).
- Ověřit dostupnost PowerShell Gallery / npm registry z učebny (firewall) — PSScriptAnalyzer/Pester
  instalace vyžaduje síť.

## Tripwires

- Studenti mají tendenci akceptovat první Copilot návrh bez čtení — trvat na nahlas vysloveném
  review před `git commit`.
- Nenechat diskuzi o Copilotu sklouznout k obecné debatě "nahradí nás AI" — cíl bloku je
  konkrétní pracovní návyk (prompt s kritérii → review → test), ne filozofie.
- Git branch/PR hygiena je pro część skupiny nová látka — nepředpokládat znalost `rebase`/`merge`
  rozdílu, mít připravené jednořádkové vysvětlení.

## Vazby

- Dopředu: repo hygiena a review disciplína z tohoto bloku se vyžaduje po celý zbytek týdne
  (všechny laby produkují kód do stejného repozitáře). App registration strategie v [`../automation-strategy/`](../automation-strategy/) na
  toto přímo navazuje.
- Zpět: —
