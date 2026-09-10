# Lab · Dávkový sync seznamu pod aplikační identitou

> Odhad: 45 min · Režim: živý tenant

## Cíl

Student napíše **idempotentní sync skript**: čte zdrojová data (CSV/JSON), dávkově provádí
CRUD operace nad SPO seznamem s metadaty a běží čistě pod **aplikační identitou**
(certifikát z D2, žádný prompt).

> [!NOTE] Zkráceno 2026-09-10 z 90 na 45 min — a plánování odešlo do bloku 2
> Lab dřív končil registrací do **Task Scheduleru** (kroky 5-6). Ta část se přesunula
> do [`../elevated-access/lab-elevated-access.md`](../elevated-access/lab-elevated-access.md),
> krok 8, kde se stejná věc dělá **v Azure** přes
> [`tutorial-script-to-azure.md`](tutorial-script-to-azure.md) — tedy tam, kam plánovaný
> běh v tomhle kurzu patří. Task Scheduler na učebním image navíc bývá zablokovaný policy,
> takže to byl krok s nejvyšší mírou selhání a nejmenším výnosem.
>
> Zůstalo jádro, které se nikde jinde neučí: **delta přes business klíč a idempotence.**

## Předpoklady

- Certifikátová app-only identita z [`../../day-2/powershell-deep-dive/lab-cert-auth-sites.md`](../../day-2/powershell-deep-dive/lab-cert-auth-sites.md).
- Knihovna/seznam s metadatovými sloupci z [`../../day-3/migration-patterns/lab-fileshare-migration.md`](../../day-3/migration-patterns/lab-fileshare-migration.md)
  (nebo instruktorem seedovaný seznam).
- Zdrojový dataset (CSV/JSON, fiktivní — např. evidence zařízení/zaměstnanců) od instruktora,
  ve dvou verzích: `v1` (initial) a `v2` (změny: nové řádky, upravené hodnoty, smazané řádky).

## Kroky

1. **Sync logika**: skript porovná zdrojová data s aktuálním stavem seznamu přes
   business klíč (např. `EvidencniCislo`) a rozdělí položky na create / update / delete —
   **žádné "smaž vše a nahraj znovu"**.
2. **Dávkové provedení**: všechny tři kategorie přes `New-PnPBatch` → `Add-PnPListItem` /
   `Set-PnPListItem` / `Remove-PnPListItem -Batch` → `Invoke-PnPBatch`; respektovat
   throttling vzory z [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/).
3. **Aplikační identita**: připojení výhradně `Connect-CourseTarget -AuthMode Certificate`
   (žádný interaktivní prompt kdekoli ve skriptu) + strukturovaný log (co se
   vytvořilo/změnilo/smazalo, počty, trvání).
4. **První běh** nad `v1` (vše create), **druhý běh** nad `v1` znovu — musí ohlásit nulu
   změn (idempotence). **Třetí běh** nad `v2` — jen delta (create+update+delete dle rozdílu).

## Ověření

- [ ] Druhý běh nad stejnými daty hlásí 0 create / 0 update / 0 delete (idempotence).
- [ ] Běh nad `v2` provede přesně deltu (počty odpovídají rozdílu datasetů), dávkově.
- [ ] Skript nikde nevyvolá interaktivní prompt a neobsahuje žádný secret/heslo.
- [ ] Běh zapíše strukturovaný log: počty create/update/delete a trvání.
- [ ] Student umí říct, co by se na skriptu změnilo při nasazení do Azure (auth →
      managed identity) — a v bloku 2 to pak skutečně udělá.

> [!NOTE] Referenční řešení
> [`solution/Sync-CourseList.ps1`](solution/Sync-CourseList.ps1) + **18 testů**.
> Otevřete až po vlastním pokusu. Tři testy dokazují to, co u dávkového skriptu nad
> produkcí nelze „vyzkoušet": **druhý běh nezapíše nic** (idempotence), **s `-WhatIf`
> neproběhne ani jeden zápis** a **retry se opakuje jen na 429/5xx, ne na 403**.
> Poslední z nich vysvětluje, proč `Invoke-WithRetry` existuje jako samostatná funkce —
> jinak by na klasifikaci chyb nešlo napsat test.

## Fallback

- **Nestíháte ani 45 min**: dodejte krok 1 (rozdělení na create/update/delete) hotový
  a nechte studenty dopsat jen krok 2, dávkové provedení. Idempotenci (krok 4) nekrátit —
  je to jediné ověření, které se nedá obejít výmluvou.
- Kdo nemá funkční cert identitu z D2, běží delegated (`-Interactive`) a cert větev
  doplní o přestávce — ale ověření "bez promptu" pak neprojde, řešit individuálně.
