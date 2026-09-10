# Lab · Elevovaná operace nad SharePointem — krok za krokem

> Odhad: 60 min · Režim: živý tenant

## Cíl

Postavíte self-service žádost o přístup k dokumentu, kde privilegovanou operaci provádí
**aplikační identita**, ne connection nějakého člověka. Na konci to poběží v Azure,
zamítne žádost „za někoho jiného" a bude to mít v auditu.

Proč tuhle cestu a co za ni platíte: [`comparison-power-automate.md`](comparison-power-automate.md).

## Předpoklady

- App registrace z [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/)
  s **`Sites.Selected`** (application permission na SharePoint) a udělený admin consent.
- Vlastní web a v něm knihovna dokumentů s alespoň jedním dokumentem.
- PnP.PowerShell a certifikátová identita z
  [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).

Druhý účet **nepotřebujete** — celý lab včetně ověření brány projde z vašeho vlastního.

> [!IMPORTANT] Nic z tohohle nepatří do repa jako literál
> Tenant ID, ClientId, thumbprint ani URL webu se nikam nekomitují — jsou to parametry
> a application settings.

---

## Krok 1 — Seznam žádostí

Vytvořte seznam `Zadosti o pristup`. **Interní** názvy polí musí odpovídat hashtable
`$script:RequestFields` ve skriptu:

| Interní název | Typ | Poznámka |
|---|---|---|
| `RequestStatus` | Choice: `Pending`, `Granted`, `Rejected`, `Failed` | default `Pending` |
| `RequesterEmail` | Text | e-mail žadatele; kontroluje se proti `Author` |
| `TargetLibrary` | Text | název cílové knihovny |
| `TargetItemId` | Number | ID položky v knihovně |
| `RequestedRole` | Choice: `Read`, `Contribute` | povolená sada, vynucuje se i v kódu |
| `DecisionNote` | Note | vyplňuje skript |

> Pozor na rozdíl mezi **zobrazovaným** a **interním** názvem pole. Když sloupec vytvoříte
> jako „Request Status", interní název bude `Request_x0020_Status`, ne `RequestStatus`.
> Zkontrolujte to: `Get-PnPField -List 'Zadosti o pristup' | Select-Object Title, InternalName`.

## Krok 2 — Seznam auditu

Vytvořte seznam `Audit pristupu` s poli `Title`, `Requester`, `Outcome`, `Detail`,
`ProcessedU` (Text).

Nastavte ho podle disciplíny z [`../lifecycle-compliance/`](../lifecycle-compliance/):
skupině **Members jen čtení**, zapisuje výhradně aplikační identita.

> Audit, do kterého smí zapisovat ten, koho auditujete, není audit.

## Krok 3 — Zúžit oprávnění na jeden web

`Sites.Selected` po consentu **nedává přístup nikam**. Přidělte jeden web s právem zápisu:

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" `
  -ClientId <client-id> -Interactive

Grant-PnPAzureADAppSitePermission -AppId <client-id> `
  -DisplayName "<nazev-app-registrace>" `
  -Site "https://<tenant>.sharepoint.com/sites/<web>" `
  -Permissions Write
```

`Write` je minimum, které úlohu splní — přidělení role na položce je zápisová operace.
`Read` nestačí, `FullControl` je zbytečný. Tentýž princip jako u Labu 1 v D2.

**Ověřte, že grant existuje**, než půjdete dál:

```powershell
Get-PnPAzureADAppSitePermission
```

## Krok 4 — Připojit se bez člověka

Certifikát z machine store. Pozor na název parametru — PnP má `-Thumbprint`,
**ne** `-CertificateThumbprint`:

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" `
  -ClientId $env:CLIENT_ID -Tenant "<tenant>.onmicrosoft.com" `
  -Thumbprint $env:CERT_THUMBPRINT
```

Když tohle projde, jste přihlášení **jako aplikace**. Ověřte si, že opravdu nejste vy:

```powershell
Get-PnPProperty -ClientObject (Get-PnPWeb) -Property CurrentUser
```

## Krok 5 — První běh vždy s `-WhatIf`

Založte v seznamu žádostí **jednu vlastní** žádost (`RequesterEmail` = váš e-mail,
`TargetLibrary` = vaše knihovna, `TargetItemId` = ID dokumentu, `RequestedRole` = `Read`).

Pak nasucho:

```powershell
. ./solution/Grant-RequestedAccess.ps1

Invoke-AccessRequestQueue -RequestListTitle 'Zadosti o pristup' `
  -AuditListTitle 'Audit pristupu' -AllowedLibraryTitle 'Dokumenty' -WhatIf
```

Vypíše, co by se stalo, a **nezapíše nic**. U operace, která rozbíjí dědění oprávnění
na položce, je to minimum slušnosti k cizímu tenantu.

## Krok 6 — Naostro a ověřit, že to opravdu přidělilo

Spusťte totéž bez `-WhatIf`. Pak zkontrolujte **v SharePointu**, ne jen ve výstupu:
žadatel má u dokumentu přidělenou roli a řádek žádosti je `Granted`.

## Krok 7 — Nejdůležitější krok celého labu: zamítnutí

Tady se pozná, jestli jste postavili bránu, nebo generální klíč.

Založte **další vlastní řádek**, ale do `RequesterEmail` napište **cizí adresu** — třeba
`nekdo.jiny@contoso.com`. `Author` tedy budete vy, `RequesterEmail` někdo jiný. Spusťte
skript.

Musí se stát tři věci:

1. přístup se **nepřidělí**,
2. řádek dostane `Rejected` a v `DecisionNote` důvod,
3. **v auditu je záznam** — ne prázdno.

> [!NOTE] Invariant, který jste právě vynutili
> **Žádost musí přijít od toho, pro koho je.** Bez toho by kdokoli, kdo umí založit řádek,
> uměl přidělit přístup komukoli jinému — třeba externímu hostu, který o nic nepožádal.
> Nepotřebujete na to druhý účet: rozhoduje neshoda `RequesterEmail` s `Author`, a tu
> vyrobíte z jednoho účtu tím, že do pole napíšete cizí adresu.

Pak to samé s `RequestedRole` = `Full Control` (mimo povolenou sadu) a s knihovnou mimo
`AllowedLibraryTitle`. Aplikace na ten web technicky právo má — a stejně to nesmí projít.

## Krok 8 — Nechat to běžet v Azure

Teď z toho udělejte plánovaný běh. Postup je v
[`../azure-integration-patterns/tutorial-script-to-azure.md`](../azure-integration-patterns/tutorial-script-to-azure.md) —
projděte ho a místo `Provision-Site` nasaďte tenhle skript. Změna proti tutoriálu je jen
v těle runbooku:

```powershell
param(
    [Parameter(Mandatory = $true)] [string] $SiteUrl,
    [Parameter(Mandatory = $true)] [string] $RequestList,
    [Parameter(Mandatory = $true)] [string] $AuditList,
    [Parameter(Mandatory = $true)] [string] $AllowedLibrary
)

$ErrorActionPreference = 'Stop'

Connect-PnPOnline -Url $SiteUrl -ManagedIdentity

Invoke-AccessRequestQueue -RequestListTitle $RequestList `
    -AuditListTitle $AuditList -AllowedLibraryTitle $AllowedLibrary
```

Runbook nemá disk, takže funkce ze `solution/Grant-RequestedAccess.ps1` vložte **do
runbooku nad ten volací blok** (je to knihovna funkcí, dot-source jen v labu na vlastním
stroji). Rozvrh nastavte na pár minut, ať to za sebou vidíte běžet.

> [!TIP] Alternativa: Azure Function s timer triggerem
> Kdo chce Function místo Runbooku, potřebuje NCRONTAB v **UTC** (`TZ` ani
> `WEBSITE_TIME_ZONE` na Flexu nefungují):
>
> ```json
> { "bindings": [ { "name": "Timer", "type": "timerTrigger",
>   "direction": "in", "schedule": "0 */5 * * * *" } ] }
> ```
>
> A pozor: **Flex Consumption nepodporuje managed dependencies v PowerShellu**, takže
> `PnP.PowerShell` musí být v `Modules/` v deployment package a `host.json` potřebuje
> extension bundle `[4.0.0, 5.0.0)`. Proto tutorial vede přes Runbook.

---

## Ověření

- [ ] Žádost, kterou žadatel založil sám na povolenou knihovnu, skončí `Granted`
      a uživatel dokument **opravdu vidí**.
- [ ] Žádost s `RequesterEmail` jiným než `Author` skončí `Rejected` — a **v auditu je
      řádek**, ne prázdno.
- [ ] Žádost na knihovnu mimo `AllowedLibraryTitle` skončí `Rejected`, i když aplikace
      na ten web technicky právo má.
- [ ] Žádost s `RequestedRole` = `Full Control` se nepřidělí.
- [ ] Druhý běh nad stejnými daty neudělá nic (žádný řádek už není `Pending`).
- [ ] `-WhatIf` neprovede ani jeden zápis.
- [ ] V audit seznamu **nemá skupina Members právo zápisu**.
- [ ] Skript běží v Azure pod managed identitou a **nikde v něm není secret**.

Prvních šest bodů odpovídá testům v
[`solution/Grant-RequestedAccess.Tests.ps1`](solution/Grant-RequestedAccess.Tests.ps1) —
17 testů, žádný nechodí na síť, takže se dají spustit i před nasazením:

```powershell
Invoke-Pester ./solution/Grant-RequestedAccess.Tests.ps1
```

## Fallback

- **`Sites.Selected` grant selže nebo se cmdlet jmenuje jinak**: názvy PnP cmdletů pro
  per-site grant se mezi verzemi měnily — ověřit
  `Get-Command -Module PnP.PowerShell *SitePermission*`. Alternativa je Graph
  `POST /sites/{siteId}/permissions`.
- **Máte druhý účet a chcete jít dál** (nad rámec labu): nechte ho založit řádek s vaší
  adresou v `RequesterEmail`. Zamítne se ze stejného důvodu, jen z druhé strany — a je na
  tom vidět, že brána chrání i vás před tím, aby vám někdo „přidělil" přístup, o který
  jste nežádali.
- **Nedostanete se do Azure** (krok 8): kroky 1-7 jsou jádro labu a stojí samy. Plánovaný
  běh se dá ukázat i lokálně přes `Register-ScheduledTask`, jako v Labu 3.
- **Není čas na celý lab**: pusťte jen Pester testy. `zamitne zadost za nekoho jineho`
  a `s -WhatIf neprovede ani jeden zapis` sdělí celou myšlenku za třicet sekund.

## Zdroje (Microsoft a PnP)

- [Set-PnPListItemPermission](https://pnp.github.io/powershell/cmdlets/Set-PnPListItemPermission.html) — `-User`, `-AddRole`, `-SystemUpdate` (mění položku bez verzování a bez spuštění flow)
- [Connect-PnPOnline](https://pnp.github.io/powershell/cmdlets/Connect-PnPOnline.html) — `-ManagedIdentity` funguje v Azure Functions, Automation Runbookech a Cloud Shellu; certifikát je `-Thumbprint`
- [Grant-PnPAzureADAppSitePermission](https://pnp.github.io/powershell/cmdlets/Grant-PnPAzureADAppSitePermission.html) — per-site grant pro `Sites.Selected`
- [Timer trigger for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer) — NCRONTAB výrazy
- [Flex Consumption plan](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan) — nepodpora managed dependencies v PowerShellu
