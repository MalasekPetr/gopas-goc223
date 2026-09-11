# Lab · Blueprint ingest a transform skeleton

> Odhad: 75 min · Režim: živý tenant

## Cíl

Student má funkční pipeline Blob → Event Grid → Function → Log Analytics (Logs Ingestion
API), s minimalizací osobních údajů (PII) v logovaném schématu a ověřením přes dotazy KQL dotaz.

## Předpoklady

- **Function App studenta** na **Flex Consumption** plánu -- zakládá ji
  `New-CourseStudentAzureResources.ps1` do resource group studenta (viz
  [`../../environment.md`](../../environment.md)); v bloku 1 do ní instruktor nasazuje demo
  [`../azure-integration-patterns/guide-copy-metadata.md`](../azure-integration-patterns/guide-copy-metadata.md)
  -- **pokud to demo proběhlo** (je volitelné, spouští se na dotaz), je tím zároveň
  ověřené, že PowerShell Function v té app běží. Když neproběhlo, ověřte to na začátku
  tohoto labu sami: prázdná Function App na Flexu je nejčastější příčina toho, že se
  krok 1 rozbije až u Event Grid subscription.
- **General-purpose v2** Storage Account v resource group studenta -- event subscription na
  Azure Storage GPv2 vyžaduje.
- V `host.json` **extension bundle verze `[4.0.0, 5.0.0)`** nebo novější -- Event Grid Blob
  trigger je binding z 5.x+ Storage rozšíření a se starším bundlem v projektu neexistuje.
- Přístup do **sdíleného kurzovního Log Analytics workspace** a vlastní **DCR**
  (zakládá se spolu se zbytkem Azure rozsahu — viz [`../../environment.md`](../../environment.md)).
  Na DCR potřebujete roli **Monitoring Metrics Publisher**; Contributor na vlastní
  resource group nestačí, protože workspace leží mimo ni.

## Kroky

1. Nakonfigurovat **Event Grid subscription** na Blob container. Event Grid k tomu potřebuje
   **endpoint URL blob rozšíření**, které si musíte složit ručně -- v portálu ho nikde
   nezkopírujete:

   ```text
   https://<function-app>.azurewebsites.net/runtime/webhooks/blobs
     ?functionName=Host.Functions.<nazev-funkce>
     &code=<blobs_extension-key>
   ```

   Systémový klíč `blobs_extension` je v portálu pod *Function App -> App keys ->
   System keys*. V subscription pak **Endpoint Type = Web Hook** a **Filter to Event
   Types = Blob Created**. Pozor: po vytvoření subscription **endpoint URL už nejde
   změnit** -- při překlepu je nutné subscription smazat a vytvořit znovu.

2. Function: při triggeru přečíst obsah blobu, aplikovat transform (pseudonymizace UPN),
   zapsat výsledek přes Logs Ingestion API do custom tabulky (přes vlastní DCR).
3. Nahrát testovací blob obsahující fiktivní UPN a ověřit, že Function proběhne téměř
   okamžitě (ne se zpožděním typickým pro polling).
4. Napsat KQL dotaz (`where`/`project`/`summarize`) ověřující, že data dorazila a UPN je
   v cílové tabulce pseudonymizované, ne v plain textu.

## Ověření

- [ ] Event Grid subscription je nakonfigurovaná na containeru a v portálu (Storage Account
      -> Events -> Event Subscriptions) je vidět **doručený** event, ne jen existující
      subscription.
- [ ] Cílová tabulka v Log Analytics obsahuje pseudonymizovaný, ne plain-text UPN.
- [ ] KQL dotaz vrátí očekávaný počet záznamů odpovídající nahranému testovacímu blobu.

## Fallback

Pokud přístup do Log Analytics workspace není v kurzovém tenantu k dispozici, student
implementuje a otestuje transform + pseudonymizaci lokálně (Function zapíše výstup do
druhého Blob containeru místo Logs Ingestion API) a KQL dotaz napíše nad ukázkovými daty
poskytnutými instruktorem v Log Analytics demo workspace na projektoru.
