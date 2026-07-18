# Instructor notes — Azure integrační vzory

## Timing

- 40 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že `New-CourseStudentAzureResources.ps1` proběhl a Function App per student existuje
  a je dostupná (public endpoint pro Graph validation handshake).
- Zkusit den předem celý flow (vytvoření subscription → validation handshake → notifikace) —
  subscription lifecycle detaily (min/max expirace) se mohou lišit dle verze Graph API.

## Tripwires

- Studenti zapomínají na validační handshake při vytváření subscription — Function musí umět
  vrátit `validationToken` jako plain text, jinak vytvoření subscription selže s chybou.
- Nezaměňovat expiraci access tokenu (~1h) s expirací subscription (dny) — to je časté
  nedorozumění vedoucí ke zbytečné komplikaci renewal logiky.

## Vazby

- Dopředu: Function skeleton z tohoto labu je základ pro `siem-blob-integration`.
- Zpět: navazuje na Graph error/retry vzory z [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/) a delta query (kontrast pull vs push).
