# Instructor notes — Staging prostředí: DEV, TEST, PROD

## Timing

- **40 min výklad povinně. Lab volitelný.** Ověřeno reálným během 2026-09-09: blok se
  odučil **jako výklad a lab vypadl úplně**, a den 3 tím vyšel podle plánu.
- Původní odhad 40 min výklad + 60 min lab jako povinné jádro se **nepotvrdil** — lab se
  do dne nevešel. Neplánuj s ním jako s jistotou; když na něj čas je, ber ho jako bonus.
- **Důsledek, který je potřeba znát dopředu:** baseline/diff skript, který lab vyrábí,
  v tom běhu **nikdy nevznikl**. Laby, které ho dřív měly ve `Předpokladech`
  ([`../provisioning-patterns/`](../provisioning-patterns/),
  [`../../day-4/lifecycle-compliance/`](../../day-4/lifecycle-compliance/)), jsou proto
  přeformulované tak, aby na studentském výstupu nestály. Kdo lab odučí, dá jim lepší
  vstup; kdo ne, nerozbije je.

## Go/no-go — KLÍČOVÉ, otestovat před během

- DEV/TEST/PROD weby si studenti vytvořili sami v D1 labu ([`../../day-2/powershell-deep-dive/lab-cert-auth-sites.md`](../../day-2/powershell-deep-dive/lab-cert-auth-sites.md));
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
  driftu, ne automatická synchronizace/oprava (to přijde v [`../../day-4/lifecycle-compliance/`](../../day-4/lifecycle-compliance/)).

## Vazby

- Dopředu: baseline/diff koncept se rozšiřuje o compliance pravidla v `lifecycle-compliance`.
- Zpět: navazuje na stránkování/ingest vzory z [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/) (čtení stavu webu ve velkém).
