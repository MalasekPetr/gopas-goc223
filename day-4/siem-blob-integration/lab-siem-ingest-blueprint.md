# Lab · Blueprint ingest a transform skeleton

> Odhad: 75 min · Režim: živý tenant

## Cíl

Student má funkční pipeline Blob → Event Grid → Function → Log Analytics (Logs Ingestion
API), s minimalizací PII v logovaném schématu a ověřením přes KQL dotaz.

## Předpoklady

- Function skeleton z [`../azure-integration-patterns/`](../azure-integration-patterns/), general-purpose v2 Storage Account v resource group studenta.
- Přístup do Log Analytics workspace (per student nebo sdílený s odděleným DCR per student).

## Kroky

1. Nakonfigurovat Event Grid subscription na Blob container (ne polling).
2. Function: při triggeru přečíst obsah blobu, aplikovat transform (pseudonymizace UPN),
   zapsat výsledek přes Logs Ingestion API do custom tabulky (přes vlastní DCR).
3. Nahrát testovací blob obsahující fiktivní UPN a ověřit, že Function proběhne téměř
   okamžitě (ne se zpožděním typickým pro polling).
4. Napsat KQL dotaz (`where`/`project`/`summarize`) ověřující, že data dorazila a UPN je
   v cílové tabulce pseudonymizované, ne v plain textu.

## Ověření

- [ ] Event Grid subscription je nakonfigurovaná na containeru (ne fallback na polling).
- [ ] Cílová tabulka v Log Analytics obsahuje pseudonymizovaný, ne plain-text UPN.
- [ ] KQL dotaz vrátí očekávaný počet záznamů odpovídající nahranému testovacímu blobu.

## Fallback

Pokud přístup do Log Analytics workspace není v kurzovém tenantu k dispozici, student
implementuje a otestuje transform + pseudonymizaci lokálně (Function zapíše výstup do
druhého Blob containeru místo Logs Ingestion API) a KQL dotaz napíše nad ukázkovými daty
poskytnutými instruktorem v Log Analytics demo workspace na projektoru.
