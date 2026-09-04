# Lab · Inicializace repo, scaffolding, linting & testy

> Odhad: 60 min · Režim: simulace

## Cíl

Student má funkční repozitář s VS Code workspace konfigurací (tasks pro lint/test), zavedenou
branch/PR hygienou a první commit vzniklý s asistencí Copilot Chatu prošlý review checklistem.

## Předpoklady

- VS Code + PowerShell extension nainstalované; PowerShell 7.
- Git nainstalovaný, `user.name`/`user.email` nastavené.
- Přihlášený **Microsoft Copilot Chat** kurzovním účtem (viz [`../../environment.md`](../../environment.md)).

## Kroky

1. Vytvořit nový lokální repozitář (`git init`) se strukturou `scripts/`, `tests/`.
2. Založit `.vscode/tasks.json` se třemi tasky: `lint` (PSScriptAnalyzer), `test` (Pester), `format`.
3. Uložit si do repa **priming prompt** ([`copilot-priming-prompt.md`](copilot-priming-prompt.md))
   jako snippet a vyzkoušet **Test A** (návnada na neexistující cmdlet) — na vlastní oči vidět,
   co pravidla chytí. Pak s primovanou konverzací nechat navrhnout krátký PowerShell skript
   (placeholder funkce); prompt musí explicitně obsahovat akceptační kritéria (co skript
   má a nemá dělat).
4. Provést code review vlastního návrhu podle checklistu z `README.md` (bezpečnostní mantinely,
   error handling) — zapsat nálezy jako komentář v PR, i když jde o self-review.
5. Spustit `lint` a `test` task, opravit nálezy.
6. Commit + push do vzdáleného repozitáře (GitHub), otevřít PR na `main` s popisem PROČ, ne jen CO.

## Ověření

- [ ] `.vscode/tasks.json` obsahuje minimálně `lint` a `test` task a oba proběhnou bez chyby.
- [ ] Priming prompt je uložený v repu a student umí popsat, co Test A odhalil.
- [ ] Commit historie obsahuje alespoň 2 malé commity s popisnou zprávou (ne jeden velký commit).
- [ ] `.gitignore` obsahuje `*.pfx`, `*.pem` a `*credentials*` — dřív, než v D2 vznikne certifikát.
- [ ] PR obsahuje popis review checklistu a potvrzení, že v kódu nejsou hardcoded identifikátory.

## Fallback

Pokud instalace PSScriptAnalyzer/Pester selže kvůli síťovým omezením učebny, instruktor poskytne
předpřipravený repozitář se závislostmi nainstalovanými offline (USB/sdílená složka) a lab
pokračuje od kroku 2.
