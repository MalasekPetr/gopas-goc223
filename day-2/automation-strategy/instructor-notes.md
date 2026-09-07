# Instructor notes — Strategie automatizace, identita a oprávnění

## Timing

- 50 min výklad + 55 min lab. Otvírák dne 2.
- **Blok vznikl 2026-09-07 sloučením** `automation-strategy` (byl v D1) a
  `permissions-consent`. Sloučené je to proto, že oba mluvily o least privilege a oba
  laby pracovaly na **téže app registraci** — spojením zmizel kontextový přesun mezi
  dvěma bloky nad jedním artefaktem a ušetřilo se ~30 min, které den 2 potřeboval.
- Lab má dvě části a **část B je ta, kvůli které blok existuje**. Když se krátí, krátí
  se písemná zdůvodnění (kroky 4 a 13), ne kroky 10-12.

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
  [`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md).
- Pojmenování app registrace vymáhat dle naming konvence — 25 aplikací pojmenovaných
  "test" v jednom tenantu je nedohledatelných. Od druhého kusu číslovat dvouciferně
  (`-02`) dle [`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md).
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
- **Delegated vs Application záložka.** Nejčastější chyba části B a příčina `Unauthorized`
  s prázdnou odpovědí v Labu 1. Ukázat obě záložky vedle sebe na plátně dřív, než začnou.
- **„Dal jsem consent a nic nefunguje" je u `Sites.Selected` správná odpověď.** Krok 10
  labu je na to nastražený schválně — nechat je narazit a teprve pak vysvětlit. Kdo to
  zažije, nezapomene; kdo to jen slyší, zapomene do oběda.
- **Nepřepálit to na „Sites.Selected vždycky".** Hned následující Lab 1 ho použít nemůže
  (zakládá site collections a vypisuje tenant) a skupina si toho všimne. Pointa je
  *nejužší rozsah, který úlohu splní*, ne jméno oprávnění — viz sekce v README. Otázka
  „a proč tady ne Sites.Selected?" je nejlepší možný začátek Labu 1.
- **Všichni jsou GA, takže consent past neuvidí.** Vyslovit nahlas jako varování do praxe:
  *test pod adminem neprokáže nic*. Je to jediná věc z bloku, kterou si v kurzovním
  tenantu nemohou vyzkoušet — o to důrazněji ji říct.
- Ověřit Object ID service principalu vs App registrace — studenti je zaručeně zamění.
  Mít připravený jednořádkový návod, kde se které bere.
- Nesklouznout do Conditional Access ani do obsahových oprávnění (skupiny, dědičnost) —
  blok je **o aplikacích**, ne o lidech. Reporting přístupů lidí je
  [`../../day-5/permission-discovery/`](../../day-5/permission-discovery/).

## Vazby

- Dopředu: tato app registrace se používá napříč celým týdnem.
  [`../powershell-deep-dive/`](../powershell-deep-dive/) jí hned dá certifikát a přihlásí
  se app-only; `security-hardening` na konci kurzu provádí audit a hardening přesně
  této aplikace. Audit uděleného consentu se vrací i v
  [`../../day-5/app-catalog-lifecycle/`](../../day-5/app-catalog-lifecycle/) — API access
  u SPFx je tentýž problém na jiném objektu.
- Zpět: navazuje na repo hygienu z [`../../day-1/vscode-copilot-env/`](../../day-1/vscode-copilot-env/)
  a hotový toolchain z [`../../day-1/toolchain-setup/`](../../day-1/toolchain-setup/).
