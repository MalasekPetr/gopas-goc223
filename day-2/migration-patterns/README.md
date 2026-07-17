# M2.3 · Skladba migrací

> Typ: povinný · Den: 2 · Odhad: <min>

## Cíle
- <Předmigrační kontroly a plánování>
- <Paralelizace, wave planning, cutover taktiky>
- <Velké seznamy, verze, throttling, zpoždění vyhledávání>

## Výklad

<TODO: předmigrační kontroly — co ověřit před spuštěním migrace (viz GLOSSARY.md limity)>

<TODO: wave planning — rozdělení do vln dle rizika/velikosti/závislostí, ne abecedně>

<TODO: paralelizace a throttle-aware exekuce, cutover taktiky>

<TODO: limity velkých seznamů, verze souborů, search crawl delay po migraci>

```mermaid
%% TODO: diagram — wave plan: pilot vlna -> hlavní vlny -> kritická vlna s bufferem
flowchart LR
  A[placeholder] --> B[placeholder]
```

## Klíčové rozlišení
- <migrace obsahu vs migrace metadat/verzí>
- <throttling limit vs tvrdý strop velikosti>

## Lab
Viz [`lab-wave-plan.md`](lab-wave-plan.md).

## Zdroje (Microsoft)
- <TODO: SharePoint Online limits dokumentace>
- <TODO: migrační nástroje — přehled dokumentace>

## Stav produktu / delta
- <TODO: ověřit aktuální list view threshold a throttling limity k datu běhu>
