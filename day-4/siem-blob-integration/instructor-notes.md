# Instructor notes — SIEM integrace přes Azure Blob

## Timing

- 45 min výklad + 75 min lab (nejnáročnější lab dne — víc služeb propojených dohromady).

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že Storage Account per student je **general-purpose v2** — jinak Event Grid trigger
  nepůjde nastavit a lab spadne na starší polling chování.
- Rozhodnout předem, zda studenti mají vlastní Log Analytics workspace, nebo sdílený se
  samostatnou DCR per student (kvůli izolaci dat mezi studenty) — připravit před kurzem.
- Ověřit aktuální DCR konfiguraci (`logsIngestion` vlastnost bez nutnosti DCE) na demo
  prostředí den předem.

## Tripwires

- Nezaměňovat Event Grid-based trigger (5.x+ rozšíření) se starším polling-based Blob
  triggerem — na Consumption plánu je Event Grid varianta nutná, ne volitelná optimalizace.
- Zdůraznit pseudonymizaci PII **před** zápisem (v transformu), ne jako dodatečný krok —
  v ověření labu kontrolovat cílovou tabulku, ne jen mezikrok.
- KQL je case-sensitive — časté drobné chyby v názvech sloupců/tabulek u začátečníků.

## Vazby

- Dopředu: logging/retry vzory se shrnují v `performance-cost-capstone` (M5.3).
- Zpět: navazuje na Function skeleton z M4.1 a retry/error klasifikaci z M2.1.
