# Lab · Diff & baseline report skript

> Odhad: 60 min · Režim: simulace | živý tenant

> [!NOTE] Odhad 60 min není potvrzený — reálný běh stihl celý blok za 30 min
> Běh 2026-09-09 vypustil výklad a lab odučil ve zbylém čase. **Které z kroků níž se do
> toho vešly v plném rozsahu, zaznamenané není** — plánujte podle 30 min na blok.
>
> Když se krátí, kroky **1-3 se krátit nesmí**: vyrábějí ten baseline skript, na kterém
> stojí lab v [`../provisioning-patterns/`](../provisioning-patterns/) (krok 5 a Ověření)
> i lab v [`../../day-4/lifecycle-compliance/`](../../day-4/lifecycle-compliance/).
> Prvním kandidátem na zkrácení je proto **krok 4** — pozor ale, že na něm visí třetí
> položka v `Ověření`, takže s ním odpadá i ta.

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
