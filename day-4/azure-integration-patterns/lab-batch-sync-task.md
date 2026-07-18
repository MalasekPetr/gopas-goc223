# Lab · Dávkový sync seznamu pod aplikační identitou + plánovaný task

> Odhad: 90 min · Režim: živý tenant

## Cíl

Třetí velký lab kurzu. Student napíše **idempotentní sync skript**: čte zdrojová data
(CSV/JSON), dávkově provádí CRUD operace nad SPO seznamem s metadaty, běží čistě pod
**aplikační identitou** (certifikát z D1, žádný prompt) — a nakonec ho zaregistruje jako
**plánovaný task** dle rozhodovací tabulky z [`README.md`](README.md).

## Předpoklady

- Certifikátová app-only identita z [`../../day-1/powershell-deep-dive/lab-cert-auth-sites.md`](../../day-1/powershell-deep-dive/lab-cert-auth-sites.md).
- Knihovna/seznam s metadatovými sloupci z [`../../day-2/migration-patterns/lab-fileshare-migration.md`](../../day-2/migration-patterns/lab-fileshare-migration.md)
  (nebo instruktorem seedovaný seznam).
- Zdrojový dataset (CSV/JSON, fiktivní — např. evidence zařízení/zaměstnanců) od instruktora,
  ve dvou verzích: `v1` (initial) a `v2` (změny: nové řádky, upravené hodnoty, smazané řádky).

## Kroky

1. **Sync logika**: skript porovná zdrojová data s aktuálním stavem seznamu přes
   business klíč (např. `EvidencniCislo`) a rozdělí položky na create / update / delete —
   **žádné "smaž vše a nahraj znovu"**.
2. **Dávkové provedení**: všechny tři kategorie přes `New-PnPBatch` → `Add-PnPListItem` /
   `Set-PnPListItem` / `Remove-PnPListItem -Batch` → `Invoke-PnPBatch`; respektovat
   throttling vzory z [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/).
3. **Aplikační identita**: připojení výhradně `Connect-CourseTarget -AuthMode Certificate`
   (žádný interaktivní prompt kdekoli ve skriptu) + strukturovaný log (co se
   vytvořilo/změnilo/smazalo, počty, trvání).
4. **První běh** nad `v1` (vše create), **druhý běh** nad `v1` znovu — musí ohlásit nulu
   změn (idempotence). **Třetí běh** nad `v2` — jen delta (create+update+delete dle rozdílu).
5. **Registrace plánovaného tasku** (Task Scheduler — on-prem větev z rozhodovací tabulky):

   ```powershell
   $action = New-ScheduledTaskAction -Execute "pwsh.exe" `
     -Argument "-NoProfile -File C:\Course\sync-list.ps1"
   $trigger = New-ScheduledTaskTrigger -Daily -At 06:00
   Register-ScheduledTask -TaskName "goc223-<jmeno-prijmeni>-sync" `
     -Action $action -Trigger $trigger
   ```

   V definici tasku **nesmí být žádný secret ani heslo** — auth řeší certifikát v cert
   store (v učebně CurrentUser store, v produkci machine store + servisní účet — umět
   vysvětlit rozdíl, viz [`../../day-1/vscode-copilot-env/explainer-runtime-environments.md`](../../day-1/vscode-copilot-env/explainer-runtime-environments.md)).
6. Spustit task ručně (`Start-ScheduledTask`) a ověřit v logu, že běh proběhl bez
   interakce a se stejným výsledkem jako ruční spuštění.

## Ověření

- [ ] Druhý běh nad stejnými daty hlásí 0 create / 0 update / 0 delete (idempotence).
- [ ] Běh nad `v2` provede přesně deltu (počty odpovídají rozdílu datasetů), dávkově.
- [ ] Skript nikde nevyvolá interaktivní prompt a neobsahuje žádný secret/heslo
      (ani v definici tasku).
- [ ] Task existuje dle naming konvence, ruční spuštění projde a zapíše strukturovaný log.
- [ ] Student umí vysvětlit, kdy by task přesunul do Azure (Runbook/Function) a co by se
      změnilo na auth (managed identity) — vazba na rozhodovací tabulku v README.

## Fallback

- Pokud Task Scheduler na učebních strojích nejde použít (policy), krok 5-6 nahradit
  registrací do "suchého" XML exportu (`Export-ScheduledTask` ekvivalent návrhu) + diskuzí
  nad Azure variantou; jádro labu (idempotentní dávkový sync pod app identitou) zůstává.
- Kdo nemá funkční cert identitu z D1, běží delegated (`-Interactive`) a cert větev
  doplní o přestávce — ale ověření "bez promptu" pak neprojde, řešit individuálně.
