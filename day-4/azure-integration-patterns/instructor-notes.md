# Instructor notes — Azure integrační vzory

## Timing

- 40 min výklad + 90 min lab (batch sync, třetí velký lab kurzu) + ~30 min instruktorské
  demo change notifications (validation handshake + jedna notifikace; plný lab vč. renewal
  skeletonu je samostudium). Batch sync nikdy nekrátit — je to povinné jádro dne.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že `New-CourseStudentAzureResources.ps1` proběhl a Function App per student existuje
  a je dostupná (public endpoint pro Graph validation handshake).
- Zkusit den předem celý flow (vytvoření subscription → validation handshake → notifikace) —
  subscription lifecycle detaily (min/max expirace) se mohou lišit dle verze Graph API.
- Pro batch sync lab: připravit zdrojové datasety `v1`/`v2` (CSV/JSON, fiktivní data) a
  distribuovat na učební stroje; ověřit, že Task Scheduler není na image učebny zablokovaný
  policy (jinak rovnou aktivovat Fallback z labu).
- Ověřit, že studenti mají funkční cert identitu z D1 — batch sync lab na ní stojí; kdo ji
  nemá, opravit před blokem.

## Tripwires

- Studenti zapomínají na validační handshake při vytváření subscription — Function musí umět
  vrátit `validationToken` jako plain text, jinak vytvoření subscription selže s chybou.
- Nezaměňovat expiraci access tokenu (~1h) s expirací subscription (dny) — to je časté
  nedorozumění vedoucí ke zbytečné komplikaci renewal logiky.
- U batch sync labu tvrdě kontrolovat idempotenci (druhý běh = 0 změn) — studenti rádi
  odevzdají "smaž vše a nahraj znovu", což ověřením projít nesmí; a žádný secret v definici
  tasku (zkontrolovat namátkou `Export-ScheduledTask` XML).

## Vazby

- Dopředu: Function skeleton z tohoto labu je základ pro `siem-blob-integration`.
- Zpět: navazuje na Graph error/retry vzory z [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/) a delta query (kontrast pull vs push).
