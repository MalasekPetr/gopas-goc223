# Lab · Inicializace repo, scaffolding, linting & testy

> Odhad: 60 min · Režim: simulace

## Cíl

Student má funkční repozitář s VS Code workspace konfigurací (tasks pro lint/test),
zavedenou commit hygienou a první commit vzniklý s asistencí Copilot Chatu prošlý
review checklistem.

## Předpoklady

- **Hotový a ověřený toolchain** z [`../toolchain-setup/`](../toolchain-setup/) —
  PowerShell 7.4+, Git, VS Code s PowerShell rozšířením, PSScriptAnalyzer a Pester.
  Repozitář už obsahuje `verify-toolchain.ps1`, `.node-version` a `.vscode/extensions.json`.
- Git má nastavené `user.name` / `user.email`.
- Přihlášený **Microsoft Copilot Chat** kurzovním účtem (viz [`../../environment.md`](../../environment.md)).

## Kroky

1. Doplnit strukturu repozitáře z předchozího bloku o `tests/` (`scripts/` už existuje).
2. Založit `.vscode/tasks.json` se třemi tasky: `lint` (PSScriptAnalyzer), `test` (Pester),
   `format`. Je to JSON, který jde do repa a sdílí se s týmem — stejná logika jako
   `.vscode/extensions.json` z minulého bloku.
3. Uložit si do repa **priming prompt** ([`copilot-priming-prompt.md`](copilot-priming-prompt.md))
   jako snippet a vyzkoušet **Test A** (návnada na neexistující cmdlet) — na vlastní oči vidět,
   co pravidla chytí. Pak s primovanou konverzací nechat navrhnout krátký PowerShell skript
   (placeholder funkce); prompt musí explicitně obsahovat akceptační kritéria (co skript
   má a nemá dělat).
4. Provést code review vlastního návrhu podle checklistu z `README.md` (bezpečnostní mantinely,
   error handling) — **nálezy zapsat do commit message**, ne jen odkývat v hlavě.
5. Spustit `lint` a `test` task, opravit nálezy.
6. Commitnout v **alespoň dvou malých commitech** (konfigurace zvlášť, skript zvlášť)
   a pushnout do vzdáleného repozitáře.

## Ověření

- [ ] `.vscode/tasks.json` obsahuje minimálně `lint` a `test` task a oba proběhnou bez chyby.
- [ ] Priming prompt je uložený v repu a student umí popsat, co Test A odhalil.
- [ ] Commit historie obsahuje alespoň 2 malé commity s popisnou zprávou (ne jeden velký commit),
      a zpráva říká **proč**, ne jen co.
- [ ] `.gitignore` obsahuje `*.pfx`, `*.pem` a `*credentials*` — dřív, než v D2 vznikne certifikát.
- [ ] V kódu nejsou hardcoded identifikátory — ověřeno vlastním review, ne jen tvrzením.
- [ ] `git pull` proběhl před `push` (i když je repozitář jednouživatelský — je to návyk).

## Fallback

- Pokud lint/test task selže kvůli chybějícím modulům, vrátit se k
  [`../toolchain-setup/lab-toolchain-verify.md`](../toolchain-setup/lab-toolchain-verify.md) —
  `verify-toolchain.ps1` řekne, co chybí. Pokud je příčinou síť, instruktor poskytne
  předpřipravený repozitář se závislostmi nainstalovanými offline a lab pokračuje od kroku 2.
- Pokud student chce pracovat v branchi a otevřít PR, nic mu v tom nebrání — jen to není
  požadavek labu (viz `README.md`, sekce Git).
