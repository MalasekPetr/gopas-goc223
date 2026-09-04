# Explainer · Velké seznamy: threshold 5000, indexy a throttling ve velkém

Skript, který funguje na testovacím seznamu se 100 položkami, umí spadnout na produkčním
s 5001 — a v migračním projektu je produkční seznam pravidlem, ne výjimkou. Dvě
samostatné věci, které se pletou: **list view threshold** (limit jednoho dotazu)
a **throttling** (limit rychlosti volání).

## 1. List view threshold = 5000

**Není to strop velikosti seznamu.** SPO seznam může mít miliony položek. 5000 je limit
na to, kolik položek smí **jeden dotaz projít**, než ho server odmítne — chrání sdílenou
databázi před uzamčením řádků kvůli jednomu nešikovnému dotazu. **V SharePoint Online
se nedá zvýšit** (na rozdíl od on-premises, kde šlo okno posunout).

Typická chybová hláška: *„The attempted operation is prohibited because it exceeds the
list view threshold."*

Co ho spouští:

- zobrazení nebo dotaz **bez filtru na indexovaném sloupci**,
- **řazení** podle neindexovaného sloupce,
- seskupení, souhrny, filtr na vícehodnotovém sloupci,
- načtení „všech položek" bez stránkování.

## 2. Indexované sloupce — nástroj, jak dotaz zúžit

Index je pomocná vyhledávací struktura nad sloupcem. S filtrem na indexovaném sloupci
server **nejdřív zúží množinu** a threshold už nepřekročí.

```powershell
# Ktere sloupce jsou indexovane?
Get-PnPField -List "Dokumenty" |
  Where-Object Indexed -eq $true |
  Select-Object Title, InternalName, TypeAsString

# Pridat index na existujici sloupec
Set-PnPField -List "Dokumenty" -Identity "Stav" -Values @{ Indexed = $true }
```

V UI: *Nastavení seznamu → Indexované sloupce* (tam se dělá i **složený index** —
primární + sekundární sloupec pro dvojici filtrů, která se používá pořád).

Co je dobré vědět předem:

- **Maximum 20 indexů na seznam** — index není zdarma, zpomaluje zápis; indexovat to,
  podle čeho se reálně filtruje, ne všechno.
- **Indexovat nelze** vícehodnotové sloupce (multi-choice, multi-person, multi managed
  metadata), počítané sloupce a víceřádkový text.
- **Index zavést, dokud je seznam malý.** SPO si dnes část indexů zakládá sám
  (*automatic index management* nad uloženými zobrazeními a řazením v moderním
  rozhraní), ale **automatika se vypíná u seznamů nad 20 000 položek** — přesně tam,
  kde by byla nejvíc potřeba. Spoléhat se na ni při vlastním návrhu je hazard.
- Nejlepší místo, kde index nastavit hned při vzniku, je šablona seznamu
  ([`../../day-3/provisioning-patterns/explainer-site-list-templates.md`](../../day-3/provisioning-patterns/explainer-site-list-templates.md)).

## 3. Jak psát dotazy, aby threshold nebolel

**Anti-pattern** — stáhne celý seznam na klienta a filtruje až doma; na velkém seznamu
skončí chybou nebo minutami čekání:

```powershell
Get-PnPListItem -List "Dokumenty" | Where-Object { $_.FieldValues.Stav -eq "Nova" }
```

**Správně** — nechat filtrovat a stránkovat server:

```powershell
# a) PnP se strankovanim: nacita po davkach, threshold neprekroci
Get-PnPListItem -List "Dokumenty" -PageSize 500

# b) CAML dotaz s filtrem na INDEXOVANEM sloupci + RowLimit
$caml = @"
<View><Query>
  <Where><Eq><FieldRef Name='Stav'/><Value Type='Text'>Nova</Value></Eq></Where>
</Query><RowLimit>500</RowLimit></View>
"@
Get-PnPListItem -List "Dokumenty" -Query $caml

# c) Graph: filtr na serveru + pruchod strankami (viz lab-graph-ingest.md)
#    /sites/{id}/lists/{id}/items?$expand=fields&$filter=fields/Stav eq 'Nova'&$top=100
```

Pravidlo do praxe: **filtruj na serveru, ber po stránkách, na velký seznam nikdy
nesahej „celý".**

## 4. Throttling ve velkém — nad rámec Graph 429

Základ (429, závazné `Retry-After`, transientní vs permanentní chyby) je v
[`README.md`](README.md). Co k tomu patří u objemných operací proti SharePointu
— tedy u migrací, inventur a hromadných zápisů:

- **SPO throttluje per uživatele i per aplikaci** a vrací `429` nebo `503`
  s `Retry-After`. Je to pojistka, ne porucha.
- **Nehádat to paralelizací.** Deset paralelních vláken throttlingu nezbaví — přivolá
  ho. Rychlejší je jedna sekvenční dávka než pět zablokovaných vláken.
- **Dávkové API místo N volání**: `New-PnPBatch` / `Invoke-PnPBatch` u zápisů,
  `$batch` v Graphu (max 20 requestů) — méně volání znamená méně throttlingu.
- **Dekorace user agenta**: Microsoft u vlastních volání do SPO/CSOM žádá identifikaci
  aplikace ve tvaru `NONISV|<organizace>|<NazevAplikace>/1.0` — nedekorovaný provoz je
  throttlován agresivněji. PnP.PowerShell si dekorovaný user agent nastavuje sám;
  u přímých REST volání je potřeba ho doplnit:

  ```powershell
  Invoke-RestMethod -Uri $url -Headers $h -UserAgent "NONISV|<organizace>|InventuraWebu/1.0"
  ```

- **`RateLimit-*` hlavičky** (`RateLimit-Limit`, `-Remaining`, `-Reset`) umožňují zpomalit
  **dřív**, než přijde 429 — u dlouhých dávek se vyplatí je číst a zvolnit.
- Dlouhé úlohy pouštět mimo špičku a se **checkpointem** (kde skript skončil), aby se
  po přerušení nezačínalo od nuly — přímá vazba na wave planning v
  [`../../day-3/migration-patterns/`](../../day-3/migration-patterns/).

## 5. Checklist před spuštěním skriptu na velký seznam

- [ ] Vím, kolik položek seznam má (`(Get-PnPList "Dokumenty").ItemCount`).
- [ ] Filtruji na serveru, ne `Where-Object` po stažení všeho.
- [ ] Sloupce, podle kterých filtruji a řadím, jsou **indexované**.
- [ ] Čtu po stránkách (`-PageSize`, `RowLimit`, `@odata.nextLink`).
- [ ] Zápisy jdou dávkově (`Invoke-PnPBatch` / `$batch`).
- [ ] Retry respektuje `Retry-After`; nepouštím paralelní vlákna „pro rychlost".
- [ ] U dlouhé úlohy mám log a checkpoint, ať vím, kde pokračovat.

## Zdroje (Microsoft)

- [List View Threshold for large lists and libraries](https://support.microsoft.com/en-us/sharepoint/lists/data-and-lists/list-view-threshold-for-large-lists-and-libraries)
- [Living Large with Large Lists and Large Libraries](https://learn.microsoft.com/en-us/microsoft-365/community/large-lists-large-libraries-in-sharepoint)
- [Avoid getting throttled or blocked in SharePoint Online](https://learn.microsoft.com/en-us/sharepoint/dev/general-development/how-to-avoid-getting-throttled-or-blocked-in-sharepoint-online)
- [Microsoft Graph throttling guidance](https://learn.microsoft.com/en-us/graph/throttling)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Hodnoty limitů (5000 threshold, 20 indexů na seznam, hranice 20 000 položek pro
> automatické indexování, 20 requestů v `$batch`) i dostupnost `RateLimit-*` hlaviček
> se mění. Threshold ani počet indexů nejsou v SPO nastavitelné.
