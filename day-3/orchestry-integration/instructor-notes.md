# Instructor notes — Orchestry integrace & vlastní skripty (simulace)

## Timing

- 40 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Jasně komunikovat studentům hned na začátku, že jde o simulaci bez živé Orchestry licence —
  předejít očekávání, že uvidí reálné UI.
- Zkontrolovat aktuální stav funkcí na orchestry.com těsně před kurzem (vendor produkt se
  vyvíjí nezávisle na tomto materiálu).

## Tripwires

- Nenechat diskuzi sklouznout k prodejnímu srovnání "je Orchestry lepší než vlastní kód" —
  cíl je pochopení integračních vzorů (hooky, kontrakty), ne doporučení nákupu.
- Trvat na konkrétním, strukturovaném kontraktu hooků (vstup/výstup) — vágní "hook se zavolá"
  bez datového kontraktu neprojde ověřením.

## Vazby

- Dopředu: governance artefakty (attestace, sprawl) se srovnávají s nativní Microsoft variantou
  v `lifecycle-compliance` (M3.3, Site Attestation).
- Zpět: navazuje na PnP provisioning artefakt z M3.1, který zde slouží jako cíl post-provision
  hooku.
