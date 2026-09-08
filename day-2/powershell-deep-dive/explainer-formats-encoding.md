# Explainer · Formáty dat a UTF-8: JSON, YAML, XML, CSV bez nehod

Deep-dive k [`README.md`](README.md). Automatizační skript je z velké části **přesun dat
mezi formáty** — Graph vrátí JSON, migrační plán je CSV, PnP šablona je XML, pipeline je
YAML. Tenhle explainer neučí formáty od nuly; řeší **role každého z nich v automatizaci
M365** a jedno téma, které v českém prostředí spolehlivě rozbíjí výstupy: **kódování**.

## Role formátů v automatizaci M365

| Formát | Kde ho potkáte | Co s ním děláme |
|---|---|---|
| **JSON** | odpovědi Graph/REST, site scripty a list designy, `tasks.json`, column/view formatting, vstupní plány labů | čteme i píšeme (`ConvertFrom-Json` / `ConvertTo-Json`) |
| **XML** | PnP provisioning šablony, CAML dotazy, starší SPO REST (ATOM) | čteme a upravujeme; nepíšeme od nuly |
| **CSV** | migrační mapování, inventury, reporty pro zadavatele | `Import-Csv` / `Export-Csv` — můstek k Excelu |
| **YAML** | definice CI/CD pipeline, devcontainer/konfigurace | čteme; odsazení nese význam (mezery, nikdy tabulátor) |

Praktická poznámka k CAML a XML: v migracích se s nimi potkáte i tam, kde byste nechtěli —
starý skript zákazníka, exportovaná šablona, definice pole. Nutná úroveň je „přečtu,
najdu v tom `FieldRef` a rozumím, co dotaz dělá", ne „napíšu CAML zpaměti".

## UTF-8 — jediné kódování, ale jen na papíře

Data SPO jsou plná diakritiky (displayName, názvy webů, názvy souborů z fileshare).
Pravidla, aby přežila celou cestu:

1. **API je v pořádku.** Graph i SharePoint REST mluví UTF-8 vždy (JSON je UTF-8
   z definice). Problémy vznikají **až na hranici se soubory a konzolí** — tam, kde si
   skript sahá na disk.
2. **PowerShell 7 má UTF-8 jako default, Windows PowerShell 5.1 ne.** Ve skriptech proto
   psát kódování **explicitně** (`-Encoding utf8`), i když to v PS7 vypadá zbytečně:
   skript se dřív nebo později spustí pod 5.1 — typicky v migračním nástroji, který
   běží jen tam (SPMT PowerShell modul, ShareGate modul; viz
   [`../../day-3/migration-patterns/explainer-migration-tools.md`](../../day-3/migration-patterns/explainer-migration-tools.md)).
3. **CSV pro Excel = `utf8BOM`**:

   ```powershell
   $report | Export-Csv .\inventura.csv -Encoding utf8BOM -UseCulture -NoTypeInformation
   ```

   Bez BOM otevře český Excel soubor jako ANSI a z „Nováková" je „NovÃ¡kovÃ¡".
   `-UseCulture` navíc respektuje středník jako oddělovač českého prostředí. Tohle je
   nejčastější kódovací nehoda v praxi — a v reportu pro zadavatele nejviditelnější.
4. **JSON šablon čtěte s explicitním kódováním**:

   ```powershell
   $script = Get-Content .\sablona.json -Raw -Encoding utf8
   ```

   Jinak z „Žádanky" vznikne v názvu seznamu paskvil, který se pak protáhne celým
   provisioningem.
5. **Round-trip test** je jediný důkaz: zapsat řetězec s diakritikou, přečíst zpět,
   porovnat. Vizuální kontrola v konzoli nestačí — konzole má vlastní kódování.

## Pasti, které stojí čas

- **Interní názvy polí** kódují diakritiku a mezery (`_x0020_`, `_x00e1_`) — pole
  zakládat bez nich, přejmenovat až zobrazovaný název
  ([`../graph-fundamentals/tips-spo-api.md`](../../day-3/graph-fundamentals/tips-spo-api.md)).
- **Názvy souborů z fileshare** nesou diakritiku i znaky, které SPO nepovoluje —
  sanitizace patří do migračního plánu, ne do improvizace při běhu.
- **`ConvertTo-Json` má výchozí `-Depth 2`** — hlubší struktury tiše ořízne; u vnořených
  objektů (site script, Graph payload) `-Depth` vždy nastavit explicitně.
- **CSV není typované**: `Import-Csv` vrací všechno jako řetězce; čísla a data převádět
  explicitně, jinak se porovnání chová nečekaně.

## Klíčové rozlišení

- **JSON vs YAML** — stejná data, jiný zápis; JSON pro API a konfiguraci, YAML pro
  pipeline. Píšeme JSON, YAML čteme.
- **XML vs JSON** — stejná role, starší generace; XML čteme v PnP šablonách a CAML.
- **UTF-8 vs UTF-8 s BOM** — pro API a soubory `utf8`, pro CSV do Excelu `utf8BOM`.
- **Objekt vs text** — PowerShell pipeline nese objekty; `Export-Csv` na konci je
  převod do textu, ne způsob práce s daty.

## Zdroje (Microsoft)

- [about_Character_Encoding (PowerShell)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding)
- [Import-Csv](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-csv)
- [ConvertTo-Json](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-json)
- [Invalid characters in file and folder names (SharePoint/OneDrive)](https://support.microsoft.com/en-us/office/restrictions-and-limitations-in-onedrive-and-sharepoint-64883a5d-228e-48f5-b3d2-eb39e07630fa)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Seznam znaků nepovolených v názvech souborů SPO/OneDrive se v čase zmenšuje
> (Microsoft postupně povoluje dřív zakázané znaky) — před migračním labem ověřit
> aktuální stav v odkazu výše.
