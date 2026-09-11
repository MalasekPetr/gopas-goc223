# Guide · Kopie dat se zachováním metadat — a co to udělá s detekcí driftu

Postup pro nasazení [`solution/Copy-ListContent.ps1`](solution/Copy-ListContent.ps1) —
kopie položek mezi seznamy, která zachová původní `Created`, `Modified`, `Author`
a `Editor`. Sesterský materiál k [`../elevated-access/lab-elevated-access.md`](../elevated-access/lab-elevated-access.md): tam šlo
o to, **pod čí identitou** operace běží, tady o to, **čí identitu po sobě zanechá**.

Je to **instruktorské demo**, ne studentský lab. Odhad 20 minut, nasazuje se jako
PowerShell Function na Flex Consumption — a ta Function App je zároveň ten skeleton,
který si blok 2 přebírá pro Blob trigger.

## Proč to není jen cvičení na cmdlety

Začněte tímhle, ne tabulkou parametrů. Zápis přes `SystemUpdate` **nechá `Modified`
nedotčené**. Znamená to, že detekce driftu postavená na otázce *„co se změnilo od včerejška
podle `Modified`"* takový zápis **neuvidí**.

A to je přesně detekce, kterou o dva bloky dál staví
[`../lifecycle-compliance/`](../lifecycle-compliance/).

Není to chyba PnP. Je to vlastnost, kterou musí znát ten, kdo governance navrhuje —
protože kdo ji nezná, postaví compliance report se slepou skvrnou přesně ve velikosti
všech automatizovaných zápisů v tenantu.

## Fork, ze kterého není volné východisko

`Set-PnPListItem` má tři update typy a jejich chování se **vzájemně vylučuje**:

| Chci… | Volba | Cena |
|---|---|---|
| **normální zápis** s auditní stopou, kdo a kdy | `Update` (default) | nová verze; `Modified`/`Modified By` přepsáno na **aplikační identitu a čas zápisu** |
| **zachovat původní časy a autory** (migrace, archivace) | **`UpdateOverwriteVersion`** | **flow se spustí** — na 10 000 položek 10 000 běhů |
| **neprobudit flow** a nezaplavit verze (opakovaný sync) | **`SystemUpdate`** | **`Modified`/`Modified By` nastavit NELZE** — a zápis je neviditelný pro drift podle `Modified` |

Dokumentace to říká natvrdo. `SystemUpdate`: *„The 'Modified By' and 'Modified' fields are
not updated and **can not be set**"* + *„Power Automate Flows are **not** triggered"*.
`UpdateOverwriteVersion`: *„…**but can be set** by passing the field values in the update.
HINT: use 'Editor' to set the 'Modified By' field"* + *„Power Automate Flows **ARE**
triggered"*.

**V jednom volání to obojí mít nejde.** Skript proto má parametr `-WriteMode`
(`Fidelity` \| `Quiet`) a nutí to rozhodnout vědomě.

> [!IMPORTANT] Ve `Quiet` režimu skript metadata nepředá vůbec — a řekne to nahlas
> Bylo by pohodlnější je do `-Values` přidat a doufat. SharePoint by je tiše zahodil
> a kopie by **vypadala** věrně. Tiše selhat je horší než selhat nahlas, takže funkce
> místo toho vrátí `$false` a vydá varování. Dokazuje to test
> `ve WriteMode Quiet metadata NEPREDA a nahlasi to`.

## Kopie je vždycky dvoufázová

Tohle není volba návrhu, tohle je vynucené. `Add-PnPListItem` dokumentuje: *„The author is
set to the **current authenticated user** executing the cmdlet. In order to set the author
to a different user, please refer to `Set-PnPListItem`."*

```text
faze 1:  Add-PnPListItem      -> polozka vznikne, Author = aplikacni identita (zmenit nelze)
faze 2:  Set-PnPListItem      -> az tady se vrati puvodni Created/Modified/Author/Editor
         -UpdateType UpdateOverwriteVersion
```

Kdo fázi 2 vynechá, má v cílovém seznamu tisíce položek založených servisním účtem
v jedné minutě. Migrace technicky proběhla, auditní hodnota obsahu je nulová.

## Krok 1 — Dva seznamy a business klíč

Zdroj a cíl. Nutná podmínka je **pole s věcným významem**, podle kterého kopie pozná, co už
v cíli je — evidenční číslo, uživatelské jméno (UPN), číslo smlouvy:

| Interní název | Typ | Poznámka |
|---|---|---|
| `EvidencniCislo` | Text, **indexované** | business klíč; podle něj se drží idempotence |
| `Title` | Text | data |
| `Castka` | Number | data — a zároveň locale past, viz níž |

> Klíčem **není `ID` položky**. To si cílový seznam generuje sám a se zdrojem nemá nic
> společného. Kdo indexuje podle `ID`, vyrobí při druhém běhu druhou sadu kopií — je to
> nejčastější chyba v kopírovacích skriptech vůbec.

## Krok 2 — Původní autor musí v cíli existovat

`Author` a `Editor` lze nastavit jen na uživatele, který je v **site user information
listu** cílového webu. Když tam není, zápis spadne — v dokumentaci
`Add-PnPListItem` je k tomu poznámka o `New-PnPUser`.

Skript to řeší tak, že selhání metadat u jedné položky **neshodí celou dávku**: kopie
zůstane, jen se v návratu označí `MetadataCopied = $false`. Po běhu je pak vidět číslo,
které u migrace chce vidět zadavatel — *kolik kopií má věrnou metadatovou stopu a kolik ne*.

## Krok 3 — Připojení a nasazení

Managed identity, bez tajemství na disku (`Sites.Selected` + per-site `Write` grant se
uděluje stejně jako v [`../elevated-access/lab-elevated-access.md`](../elevated-access/lab-elevated-access.md), krok 2):

```powershell
Connect-PnPOnline -Url $env:SITE_URL -ManagedIdentity
```

Timer trigger, **zápis NCRONTAB v UTC** (`TZ` ani `WEBSITE_TIME_ZONE` na Flexu nefungují):

```powershell
param($Timer)

. "$PSScriptRoot/Copy-ListContent.ps1"

Connect-PnPOnline -Url $env:SITE_URL -ManagedIdentity

Copy-ListContent `
  -SourceListTitle $env:SOURCE_LIST `
  -TargetListTitle $env:TARGET_LIST `
  -KeyField        $env:KEY_FIELD `
  -DataField       ($env:DATA_FIELDS -split ',') `
  -WriteMode       Fidelity
```

> [!WARNING] Na Flex Consumption `requirements.psd1` nefunguje
> Flex Consumption **nepodporuje managed dependencies v PowerShellu**, takže
> `PnP.PowerShell` musí být **v app content** — do `Modules/` v deployment package.
> Non-C# aplikace navíc potřebuje v `host.json` extension bundle `[4.0.0, 5.0.0)`.
> Detaily: [`comparison-scheduled-runtimes.md`](comparison-scheduled-runtimes.md).

## Krok 4 — Locale past, na kterou se v českém prostředí narazí tvrdě

`Add-PnPListItem` dokumentuje verbatim:

> „For numeric and currency fields, when using `-Batch`, provide the value using the comma
> and dots matching the **regional setting of the site** you're adding the listitem to.
> When **not** using batch, you must always provide the value in the **American notation**,
> so dot for decimals and comma for thousands separators."

Na cs-CZ webu tedy **dávkový** zápis chce `1234,56` a **nedávkový** `1234.56`. A protože
`"$hodnota"` na českém stroji vyrobí `1234,56`, je nedávkový zápis čísla přes běžné
převedení na string rozbitý — mlčky.

Skript proto formátuje čísla přes `[cultureinfo]::InvariantCulture`, nikoli `ToString()`
bez parametru. Test `prevede desetinne cislo do americke notace i na ceskem stroji`
kulturu vlákna **skutečně přepne** — jinak by na anglickém stroji prošel i rozbitý kód.

> [!IMPORTANT] Přepnutí skriptu na dávky ten požadovaný formát změní
> Refaktor z nedávkového zápisu na `-Batch` tedy není jen výkonová optimalizace: mění
> notaci, ve které se čísla musí předat. Kdo to přehlédne, dostane rozbitá čísla
> u zápisu, který jinak funguje.

## Krok 5 — První běh vždy s `-WhatIf`

```powershell
Copy-ListContent -SourceListTitle 'Evidence' -TargetListTitle 'Evidence archiv' `
  -KeyField 'EvidencniCislo' -DataField @('Title', 'Castka') -WhatIf
```

## Ověření

- [ ] Zkopírovaná položka má v cíli **původní** `Created`, `Modified`, `Created By`
      a `Modified By`, ne servisní účet a čas běhu.
- [ ] Druhý běh nad stejnými daty nezaloží nic (`Outcome = Exists`).
- [ ] `-WhatIf` neprovede ani jeden zápis.
- [ ] Běh s `-WriteMode Quiet` položku zkopíruje, **vydá varování** a `MetadataCopied`
      je `$false`.
- [ ] Číslo s desetinnou částí dorazí do cíle správně (ne `123456` místo `1234.56`).
- [ ] Položka bez business klíče se přeskočí a nahlásí, nezaloží se bez klíče.
- [ ] Zápis přes `SystemUpdate` **není vidět** v reportu driftu postaveném na `Modified` —
      tohle je ta pointa, kvůli které demo existuje.

První šest bodů odpovídá testům v
[`solution/Copy-ListContent.Tests.ps1`](solution/Copy-ListContent.Tests.ps1) — **27 testů**,
žádný nechodí na síť, takže se dají spustit i před nasazením.

## Fallback

- **Nasazení Function na Flexu se nepovede před skupinou**: demo jde odvykládat lokálně —
  dot-source skript, připojit se a spustit `Copy-ListContent` s `-WhatIf`. Pointa
  (dvoufázová kopie, fork update typů, slepá skvrna driftu) se neztratí.
- **Není čas na živé demo**: pustit jen Pester testy. `ve WriteMode Quiet metadata NEPREDA
  a nahlasi to` a `ve WriteMode Fidelity pouzije UpdateOverwriteVersion` sdělí celý fork
  za třicet sekund.
- **Původní autoři nejsou v cílovém webu**: nechat běh proběhnout a ukázat na
  `MetadataCopied = $false` — degradace je součást materiálu, ne porucha dema.

> [!NOTE] Soubory a knihovny jsou mimo rozsah tohoto materiálu
> Pro kopii souborů existuje `Copy-PnPFile` (umí i verzovou historii,
> `-IgnoreVersionHistory` ji zahodí). **Jak se u něj chová `Created`/`Author`, ale
> dokumentace neuvádí**, takže to tady netvrdíme ani jedním směrem. Kdo to potřebuje,
> musí si to na svém tenantu změřit — a zapsat s datem měření.

## Zdroje (Microsoft a PnP)

- [Set-PnPListItem](https://pnp.github.io/powershell/cmdlets/Set-PnPListItem.html) — `-UpdateType`: `Update` \| `SystemUpdate` \| `UpdateOverwriteVersion`, včetně toho, který z nich spouští flow a u kterého lze `Modified`/`Editor` nastavit
- [Add-PnPListItem](https://pnp.github.io/powershell/cmdlets/Add-PnPListItem.html) — autor = volající identita; notace čísel u `-Batch` vs bez něj; `New-PnPUser` u chybějícího principalu
- [Copy-PnPFile](https://pnp.github.io/powershell/cmdlets/Copy-PnPFile.html) — kopie souborů a `-IgnoreVersionHistory`
- [Flex Consumption plan](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan) — nepodpora managed dependencies v PowerShellu
- [Timer trigger for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer) — NCRONTAB výrazy

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Chování tří update typů je **nosný argument celého materiálu** — ověřit citace proti
> [Set-PnPListItem](https://pnp.github.io/powershell/cmdlets/Set-PnPListItem.html) před
> během. Kdyby PnP přidal typ, který umí nastavit `Modified` **a** nespustí flow, fork
> výše přestane platit a demo se zkrátí na jeden odstavec.
>
> **PnP má pro tentýž pojem u dvou cmdletů jinou syntaxi — nespoléhat na analogii.**
> Ověřeno 2026-09-10 proti dokumentaci:
>
> | Cmdlet | Jak se SystemUpdate zapíše |
> |---|---|
> | `Set-PnPListItem` | **jen `-UpdateType SystemUpdate`** — switch `-SystemUpdate` **neexistuje** |
> | `Set-PnPListItemPermission` | **switch `-SystemUpdate`** existuje („Update the item permissions without creating a new version or triggering MS Flow.") |
>
> Záměna vyhodí `A parameter cannot be found that matches parameter name 'SystemUpdate'`.
> Do 2026-09-10 tu stálo, že „starší parametr `-SystemUpdate` existuje vedle `-UpdateType`
> a dělá totéž" — **to bylo špatně** a `Grant-RequestedAccess.ps1` na tom kvůli mně reálně
> spadl. Před během ověřit u **každého** cmdletu zvlášť:
> `Get-Help Set-PnPListItem -Full`.
