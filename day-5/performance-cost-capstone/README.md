# M5.3 · Výkon, náklady & capstone

> Typ: povinný · Den: 5 · Odhad: <min>

## Cíle
- <Efektivita API (batching, selektivní projekce)>
- <Náklady logování, asynchronní fan-out vzory>
- <Capstone: end-to-end blueprint migrace + provisioning>
- <Rizika & rollback; předávka do provozu>
- <Další kroky: Advanced Graph, AZ-204, SC-300>

## Výklad

<TODO: efektivita API — batching (viz M2.1), selektivní projekce (`$select`), snížení počtu round-tripů>

<TODO: náklady logování (viz M4.2) a asynchronní fan-out vzory pro škálování>

<TODO: capstone — spojení migrace (D2), provisioningu (D3) a integrací (D4) do jednoho end-to-end blueprintu>

<TODO: rizika & rollback plán, předávka do provozu (runbook, kontakty, eskalace)>

<TODO: další kroky — Advanced Graph, AZ-204, SC-300>

```mermaid
%% TODO: diagram — end-to-end blueprint: provisioning -> migrace -> integrace -> monitoring -> provoz
flowchart LR
  A[placeholder] --> B[placeholder]
```

## Klíčové rozlišení
- <optimalizace výkonu vs optimalizace nákladů — někdy protichůdné cíle>
- <rollback plán (připravený předem) vs improvizovaná náprava>

## Lab
Viz [`lab-capstone-blueprint.md`](lab-capstone-blueprint.md).

## Zdroje (Microsoft)
- <TODO: Graph `$select`/selektivní projekce dokumentace>
- <TODO: AZ-204, SC-300 certifikační cesty — přehled>

## Stav produktu / delta
- <TODO: ověřit aktuální doporučené certifikační cesty (AZ-204/SC-300) a jejich obsahovou náplň k datu běhu>
