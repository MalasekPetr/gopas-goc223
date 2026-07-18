# Lab · Inicializace repo, scaffolding, linting & testy

> Odhad: 60 min · Režim: simulace

## Cíl

Student má funkční repozitář s VS Code workspace konfigurací (tasks pro lint/test), zavedenou
branch/PR hygienou a první commit vzniklý s asistencí GitHub Copilotu prošlý review checklistem.

## Předpoklady

- VS Code + PowerShell extension + GitHub Copilot extension nainstalované a přihlášené.
- Git nainstalovaný, `user.name`/`user.email` nastavené.
- GitHub účet s přiřazenou Copilot licencí (viz `environment.md`).

## Kroky

1. Vytvořit nový lokální repozitář (`git init`) se strukturou `scripts/`, `tests/`.
2. Založit `.vscode/tasks.json` se třemi tasky: `lint` (PSScriptAnalyzer), `test` (Pester), `format`.
3. Napsat krátký PowerShell skript (placeholder funkce) s prompt-asistencí Copilotu — prompt musí
   explicitně obsahovat akceptační kritéria (co skript má/nemá dělat).
4. Provést code review vlastního návrhu podle checklistu z `README.md` (bezpečnostní mantinely,
   error handling) — zapsat nálezy jako komentář v PR, i když jde o self-review.
5. Spustit `lint` a `test` task, opravit nálezy.
6. Commit + push do vzdáleného repozitáře (GitHub), otevřít PR na `main` s popisem PROČ, ne jen CO.

## Ověření

- [ ] `.vscode/tasks.json` obsahuje minimálně `lint` a `test` task a oba proběhnou bez chyby.
- [ ] Commit historie obsahuje alespoň 2 malé commity s popisnou zprávou (ne jeden velký commit).
- [ ] PR obsahuje popis review checklistu a potvrzení, že v kódu nejsou hardcoded identifikátory.

## Fallback

Pokud instalace PSScriptAnalyzer/Pester selže kvůli síťovým omezením učebny, instruktor poskytne
předpřipravený repozitář se závislostmi nainstalovanými offline (USB/sdílená složka) a lab
pokračuje od kroku 2.
