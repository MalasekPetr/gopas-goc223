# Instructor notes — Microsoft Graph — inženýrské základy

## Timing

- 45 min výklad + 75 min lab (nejnáročnější lab dne — throttling se ne vždy podaří vyvolat
  na první pokus, počítat s rezervou).

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že kurzový tenant má dostatek objektů (uživatelé/weby), aby dotaz bez `$top`
  omezení reálně vyžadoval víc než jednu stránku — pokud ne, doplnit demo data předem.
- Zkusit den předem vyvolat 429 stejným postupem jako v labu — throttling limity se mění,
  ověřit, že postup pořád reálně throttling spustí.

## Tripwires

- Studenti často implementují pevný `Start-Sleep -Seconds N` místo čtení `Retry-After` z
  odpovědi — v ověření labu explicitně kontrolovat, že čtou hlavičku, ne hardcoded konstantu.
- Nezaměňovat batch-level HTTP 200 s úspěchem všech dílčích requestů — připravit demo, kde
  batch vrátí 200, ale jeden dílčí request je 429.
- Nechodit do hloubky change notifications (push model) — to je [`../../day-4/azure-integration-patterns/`](../../day-4/azure-integration-patterns/), zde jen zmínit rozdíl.

## Vazby

- Dopředu: retry/throttle klasifikace se přímo používá v `migration-patterns` (throttle-aware
  wave exekuce) a `siem-blob-integration` (spolehlivost pipeline).
- Zpět: navazuje na `Connect-CourseTarget` wrapper a auth módy z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).
