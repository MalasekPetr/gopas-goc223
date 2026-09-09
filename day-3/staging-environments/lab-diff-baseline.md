# Lab · Diff & baseline report skript

> Odhad: 60 min · **Volitelný** · Režim: simulace | živý tenant

> [!IMPORTANT] Tenhle lab je volitelný — v reálném běhu 2026-09-09 se neodučil
> Blok se odučil jako výklad a na lab čas nezbyl. Povinné jádro modulu je tedy **výklad**;
> lab spouštěj **při časové rezervě** nebo ho zadej jako samostudium.
>
> Nic jiného v kurzu na jeho výstupu nestojí. Laby v
> [`../provisioning-patterns/`](../provisioning-patterns/) a
> [`../../day-4/lifecycle-compliance/`](../../day-4/lifecycle-compliance/) skript odsud
> **uvítají, ale nevyžadují** — kdo ho má, použije ho; kdo ne, jede podle jejich vlastního
> zadání. Dřív to tak nebylo a byla to skrytá křehkost: závislost existovala jen jako
> studentský výstup, takže vypuštění tohohle labu tiše rozbilo vstup dvou dalších.

## Cíl

Student má skript, který porovná aktuální stav webu proti deklarativní baseline (site script
JSON) a vypíše strukturovaný report driftu (přidáno/chybí/změněno).

## Předpoklady

- Přístup do per-student DEV/TEST/PROD sandbox webů (viz `environment.md`).
- `Get-AllGraphResults`/connect wrapper z [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/) a [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).

## Kroky

1. Definovat jednoduchou baseline (JSON: očekávané sloupce v konkrétním listu, očekávaný theme).
2. Načíst aktuální stav DEV webu (sloupce, theme) přes PnP/Graph.
3. Porovnat a vypsat strukturovaný diff (přidáno oproti baseline / chybí oproti baseline /
   změněný typ sloupce).
4. Spustit stejný skript i proti TEST/PROD sandboxu a porovnat výstupy.

## Ověření

- [ ] Report jasně rozlišuje tři kategorie odchylky (přidáno/chybí/změněno), ne jen "liší se".
- [ ] Skript korektně nahlásí nulový drift, když je stav shodný s baseline (žádné falešné pozitivy).
- [ ] Skript odhalí úmyslně vložený rozdíl v TEST/PROD sandboxu.

## Fallback

Pokud per-student sandbox weby nejsou dostupné (provisioning selhal), instruktor poskytne
export baseline i aktuálního stavu jako statické JSON soubory a lab pokračuje nad těmito
soubory bez nutnosti živého připojení.
