# Instructor notes — Staging prostředí: DEV, TEST, PROD

## Timing

- 40 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- DEV/TEST/PROD weby si studenti vytvořili sami v D1 labu ([`../../day-1/powershell-deep-dive/lab-cert-auth-sites.md`](../../day-1/powershell-deep-dive/lab-cert-auth-sites.md));
  ráno před blokem zkontrolovat, že je mají všichni (kdo ne — doprovisionovat
  `New-CourseStudentSites.ps1` fallbackem) a že seedovací skript do nich vložil úmyslný
  drift (naplánovaný rozdíl pro cvičení) — ve všech studentských webech, ne jen v jednom
  testovacím.
- Zkontrolovat aktuální limit 100 site scriptů/site designů na tenant — po opakovaných bězích
  kurzu se mohou hromadit nepoužité artefakty z minulých kohort.

## Tripwires

- Studenti si pletou "diff mezi dvěma prostředími" s "diff proti baseline" — u prvního nejde o
  správnost, jen o rozdíl; u druhého je baseline autoritativní zdroj pravdy.
- Nenechat lab sklouznout k psaní obecného "site cloner" nástroje — cíl je detekce a report
  driftu, ne automatická synchronizace/oprava (to přijde v [`../../day-3/lifecycle-compliance/`](../../day-3/lifecycle-compliance/)).

## Vazby

- Dopředu: baseline/diff koncept se rozšiřuje o compliance pravidla v `lifecycle-compliance`.
- Zpět: navazuje na stránkování/ingest vzory z [`../graph-fundamentals/`](../graph-fundamentals/) (čtení stavu webu ve velkém).
