# Instructor notes — Výkon, náklady & capstone

## Timing

- 30 min výklad + 60-120 min lab — poslední blok kurzu, **záměrně elastický**: studenti
  občas odcházejí o 1-2 h dřív. Kompresní plán při zkrácení: prezentace → pair-share ve
  dvojicích (5 min), konsolidace → jednostránkový blueprint místo plného dokumentu;
  **jádro se nekrátí nikdy** — propojení artefaktů týdne + rollback plán. Při plném čase
  navíc předávací runbook a individuální prezentace.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Spustit `solution/Get-HostingCost.ps1` a přepsat čísla v README.** Sekce „Kolik to
  reálně stojí" má konkrétní hodnoty v EUR a ty stárnou. Skript je bez závislostí a bez
  přihlášení (Retail Prices API je anonymní), takže je to práce na dvě minuty — ale musí
  se udělat, jinak instruktor u projektoru cituje starý ceník.
- **Ověřit, že učebna má na `prices.azure.com` výstup.** Kdyby ne, vygenerovat snapshot
  předem (`Get-HostingRate | ConvertTo-Json -Depth 6 > prices-snapshot.json`) a promítat
  s `-Offline -PricesPath`. Snapshot **nedávat do repa** — je to datum a region, ne obsah.

- Ověřit, že artefakty ze všech dnů jsou dostupné a nebyly smazány offboarding skriptem
  předchozího běhu (`scripts/README.md`).
- **Ověřit aktuální stav AZ-204 retirementu a AI-200 obsahové náplně těsně před kurzem** —
  toto je jediný fakt v celém materiálu s tak krátkým poločasem rozpadu (řádově dny/týdny
  k datu psaní), nespoléhat na currency marker v README jako trvale platný.

## Tripwires

- **Nulová tabulka není chyba kalkulátoru.** U noční dávky vyjdou všechny čtyři varianty
  na 0 EUR a někdo se ozve, že „to nepočítá". Počítá — vejde se to do free grantů, a to
  je celá pointa. Ukázat kontrast hned: `-LogGbPerMonth 100` je jediný nenulový řádek
  a je vyšší než nejdražší compute o řád.
- **Neříkat „Flex je vždycky lepší".** U vysokofrekvenčního běhu je Flex nejdražší varianta
  z celé tabulky, protože má čtyřikrát menší free grant než legacy Consumption. Volí se
  z jiných důvodů (viz D4), ne kvůli ceně, a je čestné to říct.
- Nenechat capstone sklouznout k dodělávání nedokončených labů z dřívějších dnů — je to
  konsolidace, ne dohánění (viz Fallback v labu).
- Prezentace na konci nemá být hodnocení/zkouška — udržet ji jako sdílení, ne stresující
  závěr kurzu.

## Vazby

- Dopředu: —
- Zpět: spojuje `migration-patterns`, `provisioning-patterns`,
  `azure-integration-patterns`/`siem-blob-integration`, `security-hardening`.
