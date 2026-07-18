# Lab · Migrace fileshare → SPO dle JSON plánu, včetně metadat

> Odhad: 105 min · Režim: živý tenant (Windows PowerShell 5.x pro SPMT část)

## Cíl

Druhý velký lab kurzu. Student navrhne migrační plán jako **JSON parametrický soubor**
(vlny, zdroje, cíle, mapování metadat), exekuuje migraci z lokálního fileshare do SPO
knihoven přes SPMT PowerShell modul a **doplní metadata PnP skriptem** — protože SPMT
obsah přenese, ale vlastní metadata nenaplní. Plán je verzovatelný artefakt v gitu,
ne klikání v GUI.

## Předpoklady

- SPMT nainstalovaný na učebním stroji + Windows PowerShell 5.1 (viz
  [`explainer-migration-tools.md`](explainer-migration-tools.md) — modul neběží v PS7).
- Cílové weby `-dev/-test/-prod` z labu [`../../day-2/powershell-deep-dive/lab-cert-auth-sites.md`](../../day-2/powershell-deep-dive/lab-cert-auth-sites.md).
- Zdrojový fileshare: instruktorem připravená lokální struktura složek/souborů
  (fiktivní data — oddělení, typy dokumentů).
- `Connect-CourseTarget` wrapper + retry vzory z [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/).

## Kroky

1. **Navrhnout plán jako JSON** — jeden soubor = celý migrační záměr:

   ```json
   {
     "waves": [
       {
         "name": "pilot",
         "tasks": [
           {
             "sourcePath": "C:\\MigrationSource\\HR",
             "targetSite": "https://<tenant>.sharepoint.com/sites/<jmeno-prijmeni>-test",
             "targetLibrary": "HR dokumenty",
             "metadata": { "Oddeleni": "HR", "Klasifikace": "Interni" }
           }
         ]
       },
       { "name": "hlavni", "tasks": [ ... ] }
     ]
   }
   ```

   Pořadí vln zdůvodnit (riziko/velikost/závislosti — viz README); pilot = malý,
   nízkorizikový vzorek.
2. **Připravit cílové knihovny skriptem** (PS7, PnP): pro každý task z JSON vytvořit
   knihovnu a metadatové sloupce (`Oddeleni`, `Klasifikace`) — parametrizovaně z plánu,
   žádné ruční zakládání.
3. **Exekuovat pilotní vlnu přes SPMT** (Windows PowerShell 5.x!):

   ```powershell
   Register-SPMTMigration -SPOCredential $cred -Force
   foreach ($task in $plan.waves[0].tasks) {
     Add-SPMTTask -FileShareSource $task.sourcePath `
       -TargetSiteUrl $task.targetSite -TargetList $task.targetLibrary
   }
   Start-SPMTMigration
   Get-SPMTMigration          # sledovat stav tasku
   ```

4. **Doplnit metadata PnP skriptem** (PS7): projít položky cílové knihovny a nastavit
   sloupce dle `metadata` bloku z JSON plánu — dávkově přes `New-PnPBatch`/`Invoke-PnPBatch`,
   ne položku po položce.
5. **Ověřovací report**: skript porovná počet souborů zdroj vs cíl per task a vypíše
   položky s nevyplněnými metadaty (očekávaný výsledek: nula).
6. Exekuovat hlavní vlnu (opakování 3-5 nad dalším blokem plánu) — beze změny kódu, jen
   jiný index vlny: důkaz, že plán je parametr, ne součást skriptu.

## Ověření

- [ ] JSON plán obsahuje minimálně 2 vlny se zdůvodněným pořadím a mapováním metadat.
- [ ] `Get-SPMTMigration` hlásí dokončené tasky; počty souborů zdroj = cíl per task.
- [ ] Metadatové sloupce cílových knihoven jsou naplněné dle plánu (report z kroku 5 = 0
      nevyplněných) a plnily se dávkově, ne per-item smyčkou.
- [ ] Hlavní vlna proběhla bez úpravy kódu — pouze změnou parametru (index/název vlny).
- [ ] Student umí říct, proč metadata neplnil SPMT (a kde je hranice nástroje).

## Fallback

- SPMT nedostupný/selhává → obsah pilotní vlny nahrát přes `Add-PnPFile` (PS7) nad stejným
  JSON plánem; kroky 4-6 beze změny. Menší věrnost (bez SPMT reportu), logika labu zůstává.
- Časová tíseň → hlavní vlnu (krok 6) přeskočit a ukázat instruktorsky; jádro hodnocení je
  pilot + metadata + report.
