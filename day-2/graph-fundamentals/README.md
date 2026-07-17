# M2.1 · Microsoft Graph — inženýrské základy

> Typ: povinný · Den: 2 · Odhad: <min>

## Cíle
- <Batching, delta, řízení throttlingu>
- <Klasifikace chyb a retry strategie>

## Výklad

<TODO: `$batch`, delta query, throttling (429/Retry-After) — viz GLOSSARY.md>

<TODO: klasifikace chyb (429 vs 5xx vs permanentní 4xx) a odpovídající retry strategie>

```mermaid
%% TODO: diagram — request -> throttling detekce -> retry/backoff -> úspěch/dead-letter
flowchart LR
  A[placeholder] --> B[placeholder]
```

## Klíčové rozlišení
- <retry na 429 (respektovat Retry-After) vs retry na transient 5xx (backoff) vs no-retry na permanentní 4xx>
- <stránkování (`@odata.nextLink`) vs delta query — různé účely>

## Lab
Viz [`lab-graph-ingest.md`](lab-graph-ingest.md).

## Zdroje (Microsoft)
- <TODO: Microsoft Graph throttling dokumentace>
- <TODO: Microsoft Graph delta query dokumentace>
- <TODO: Microsoft Graph batching dokumentace>

## Stav produktu / delta
- <TODO: ověřit aktuální throttling limity a batch velikost k datu běhu>
