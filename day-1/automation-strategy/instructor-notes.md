# Instructor notes — Strategie automatizace & nástrojová mapa

## Timing

- 40 min výklad + 45 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Studenti jsou Global administrátoři (viz `environment.md`) — registrace aplikace i admin
  consent si každý provede sám. Ověřit den předem na jednom testovacím účtu, že flow
  (registrace → permission → vlastní admin consent) projde bez překážek.
- Zkontrolovat, že v tenantu nezůstaly app registrace z minulého běhu — matou studenty
  a kolidují s naming konvencí (`<jmeno.prijmeni>-course-app`).

## Tripwires

- Studenti mají tendenci rovnou přidat `Sites.FullControl.All` "pro jistotu" — trvat na
  `Sites.Read.All` v tomto kroku, širší oprávnění přijdou přirozeně v pozdějších dnech, kdy
  budou reálně potřeba (a student uvidí PROČ).
- Nezaměňovat consent dialog uživatele (delegated, per-user) s admin consent (tenant-wide) —
  časté nedorozumění u prvního zkoušení; a protože každý student je GA, jeho admin consent
  je reálně tenant-wide akce — vztáhnout k pravidlům z
  [`../onboarding/ways-of-working.md`](../onboarding/ways-of-working.md).
- Pojmenování app registrace vymáhat dle naming konvence — 25 aplikací pojmenovaných
  "test" v jednom tenantu je nedohledatelných. Od druhého kusu číslovat dvouciferně
  (`-02`) dle [`../onboarding/ways-of-working.md`](../onboarding/ways-of-working.md).
- **Public client jsou dvě samostatná nastavení, ne jedno** (krok 2 labu): platforma
  *Mobile and desktop applications* + `http://localhost` řeší `-Interactive`, přepínač
  *Allow public client flows* řeší device code (nemá redirect URI). Kdo nastaví jen jedno,
  narazí v D2 na `AADSTS7000218` — a hledá chybu ve skriptu, ne v registraci.
- Studenti si pletou `-ClientId` (aplikace) s `-TenantId` (tenant) — obojí je na stránce
  Overview app registrace; zdůraznit hned, ušetří to čas v D2.
- App registration vs Enterprise Application: studenti oba pohledy uvidí ve vlastním (=
  domovském) tenantu, kde vznikají oba objekty najednou — rozdíl "vynikne" až u
  multi-tenant scénáře. Mít připravený druhý tenant (nebo screenshoty) pro demo, jak
  admin consent v cizím tenantu vytvoří jen Enterprise Application bez app registrace.
- Nezabřednout do consent governance detailů (user consent settings, admin consent
  workflow) — pro kurz stačí practices z explaineru; hloubka je téma pro SC-300.

## Vazby

- Dopředu: tato app registrace se používá napříč celým týdnem; `security-hardening`
  na konci kurzu provádí audit a hardening přesně této aplikace.
- Zpět: navazuje na repo hygienu z [`../vscode-copilot-env/`](../vscode-copilot-env/).
