# Lab · Diff & baseline report skript

> Odhad: 60 min · Režim: simulace | živý tenant

## Cíl

Student má skript, který porovná aktuální stav webu proti deklarativní baseline (site script
JSON) a vypíše strukturovaný report driftu (přidáno/chybí/změněno).

## Předpoklady

- Přístup do per-student DEV/TEST/PROD sandbox webů (viz `environment.md`).
- `Get-AllGraphResults`/connect wrapper z [`../graph-fundamentals/`](../graph-fundamentals/) a [`../../day-1/powershell-deep-dive/`](../../day-1/powershell-deep-dive/).

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
