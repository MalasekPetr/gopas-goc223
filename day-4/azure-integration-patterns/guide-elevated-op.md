# Guide · Elevovaná operace nad SharePointem místo Power Automate flow

Postup pro nasazení [`solution/Grant-RequestedAccess.ps1`](solution/Grant-RequestedAccess.ps1) —
self-service žádosti o přístup k dokumentu, kde privilegovanou operaci provádí **aplikační
identita**, ne connection nějakého člověka. Proč zvolit tuhle cestu místo flow a co za to
platíte: [`comparison-power-automate.md`](comparison-power-automate.md).

Je to **instruktorské demo**, ne studentský lab — agenda se kvůli němu neposouvá. Odhad
15 minut, spouští se ve chvíli, kdy padne dotaz „a proč to nenapsat v Power Automate?".

## Předpoklady

- App registrace z [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/)
  s **`Sites.Selected`** (application permission na SharePoint) a udělený admin consent.
- Web, na kterém demo běží, a v něm knihovna dokumentů.
- PnP.PowerShell a připojení app-only — buď certifikát
  ([`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/)), nebo managed
  identity, pokud už jde o nasazenou Function.

> [!IMPORTANT] Nic z tohohle nepatří do repa jako literál
> Tenant ID, ClientId, thumbprint ani URL webu se nikam nekomitují — jsou to parametry
> a application settings. V kurzovním repu jsou proto všude zástupné hodnoty.

## Krok 1 — Dva seznamy

**Seznam žádostí** (uživatelé v něm zakládají řádky). Interní názvy polí musí odpovídat
hashtable `$script:RequestFields` ve skriptu:

| Interní název | Typ | Poznámka |
|---|---|---|
| `RequestStatus` | Choice: `Pending`, `Granted`, `Rejected`, `Failed` | default `Pending` |
| `RequesterEmail` | Text | e-mail žadatele; kontroluje se proti `Author` |
| `TargetLibrary` | Text | název cílové knihovny |
| `TargetItemId` | Number | ID položky v knihovně |
| `RequestedRole` | Choice: `Read`, `Contribute` | povolená sada, vynucuje se i v kódu |
| `DecisionNote` | Note | vyplňuje skript |

**Seznam auditu** (`Title`, `Requester`, `Outcome`, `Detail`, `ProcessedU`). Nastavit ho
podle disciplíny z [`../lifecycle-compliance/`](../lifecycle-compliance/): členům **jen
čtení**, zapisuje výhradně aplikační identita.

> Oprávnění seznamu žádostí **jsou autorizační brána prvního stupně** — kdo do něj smí
> zapisovat, ten smí požádat. Druhý stupeň je v kódu (`Test-RequestAllowed`). Jeden bez
> druhého nestačí: samotná oprávnění nezabrání žádosti „za někoho jiného", samotný kód
> nezabrání tomu, aby řádek založil kdokoli z tenantu.

## Krok 2 — Rozsah oprávnění na jeden web

`Sites.Selected` po consentu **nedává přístup nikam** — to je celý jeho smysl. Přidělení
jednoho webu s právem zápisu:

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" `
  -ClientId <client-id> -Interactive

Grant-PnPAzureADAppSitePermission -AppId <client-id> `
  -DisplayName "<nazev-app-registrace>" `
  -Site "https://<tenant>.sharepoint.com/sites/<web>" `
  -Permissions Write
```

`Write` je tu minimum, které úlohu splní: přidělení role na položce je zápisová operace.
`Read` nestačí, `FullControl` je zbytečný — tentýž princip jako u Labu 1 v D2.

## Krok 3 — Připojení bez člověka

Ve Function nebo Runbooku **managed identity**, bez jakéhokoli tajemství na disku:

```powershell
Connect-PnPOnline -Url $env:SITE_URL -ManagedIdentity
```

Mimo Azure certifikát z machine store. Pozor na název parametru — PnP má `-Thumbprint`,
ne `-CertificateThumbprint`:

```powershell
Connect-PnPOnline -Url $env:SITE_URL -ClientId $env:CLIENT_ID `
  -Tenant "<tenant>.onmicrosoft.com" -Thumbprint $env:CERT_THUMBPRINT
```

## Krok 4 — Nasazení jako plánovaný běh

Timer trigger na **Flex Consumption**, protože kurzovní prostředí je tam
(viz [`comparison-scheduled-runtimes.md`](comparison-scheduled-runtimes.md)).

> [!WARNING] Na Flex Consumption `requirements.psd1` nefunguje
> Flex Consumption **nepodporuje managed dependencies v PowerShellu**, takže
> `PnP.PowerShell` je nutné **přiložit k app content** — do `Modules/` v deployment
> package. Kdo se spolehne na `requirements.psd1`, dostane hlášku o chybějícím cmdletu,
> která příčinu neprozradí.
>
> Non-C# aplikace navíc musí mít v `host.json` extension bundle `[4.0.0, 5.0.0)`.

Timer výraz je **NCRONTAB v UTC** — `TZ` ani `WEBSITE_TIME_ZONE` na Flexu nefungují.
Pro demo stačí každých pět minut; v provozu je rozumnější interval delší:

```json
{
  "bindings": [
    {
      "name": "Timer",
      "type": "timerTrigger",
      "direction": "in",
      "schedule": "0 */5 * * * *"
    }
  ]
}
```

Tělo funkce je pak jen připojení a jedno volání:

```powershell
param($Timer)

. "$PSScriptRoot/Grant-RequestedAccess.ps1"

Connect-PnPOnline -Url $env:SITE_URL -ManagedIdentity

Invoke-AccessRequestQueue `
  -RequestListTitle    $env:REQUEST_LIST `
  -AuditListTitle      $env:AUDIT_LIST `
  -AllowedLibraryTitle $env:ALLOWED_LIBRARY
```

## Krok 5 — První běh vždy s `-WhatIf`

```powershell
Invoke-AccessRequestQueue -RequestListTitle 'Zadosti o pristup' `
  -AuditListTitle 'Audit pristupu' -AllowedLibraryTitle 'Dokumenty' -WhatIf
```

Vypíše, co by se stalo, a nezapíše nic. U operace, která rozbíjí dědění oprávnění, je to
minimum slušnosti k cizímu tenantu.

## Ověření

- [ ] Žádost, kterou žadatel založil sám na povolenou knihovnu, skončí `Granted`
      a uživatel dokument opravdu vidí.
- [ ] Žádost s `RequesterEmail` jiným než `Author` skončí `Rejected` — a **v auditu je
      řádek**, ne prázdno.
- [ ] Žádost na knihovnu mimo `AllowedLibraryTitle` skončí `Rejected`, i když aplikace
      na ten web technicky právo má.
- [ ] Žádost s `RequestedRole` = `Full Control` se nepřidělí.
- [ ] Druhý běh nad stejnými daty neudělá nic (žádný řádek už není `Pending`).
- [ ] `-WhatIf` neprovede ani jeden zápis.
- [ ] V audit seznamu nemá skupina Members právo zápisu.

Prvních šest bodů odpovídá testům v
[`solution/Grant-RequestedAccess.Tests.ps1`](solution/Grant-RequestedAccess.Tests.ps1) —
17 testů, žádný nechodí na síť, takže se dají spustit i před nasazením.

## Fallback

- **`Sites.Selected` grant selže nebo se cmdlet jmenuje jinak**: názvy PnP cmdletů pro
  per-site grant se mezi verzemi měnily — ověřit
  `Get-Command -Module PnP.PowerShell *SitePermission*`. Alternativa je Graph
  `POST /sites/{siteId}/permissions`.
- **Nasazení Function na Flexu se nepovede před skupinou**: demo jde odvykládat lokálně —
  dot-source skript, připojit se interaktivně a spustit `Invoke-AccessRequestQueue`
  s `-WhatIf`. Pointa (identita, autorizační brána, audit) se neztratí, hosting je
  vedlejší.
- **Není čas na živé demo**: pustit jen Pester testy. `zamitne zadost za nekoho jineho`
  a `s -WhatIf neprovede ani jeden zapis` sdělí celou myšlenku za třicet sekund.

## Zdroje (Microsoft a PnP)

- [Set-PnPListItemPermission](https://pnp.github.io/powershell/cmdlets/Set-PnPListItemPermission.html) — `-User`, `-AddRole`, `-SystemUpdate` (mění položku bez verzování a bez spuštění flow)
- [Connect-PnPOnline](https://pnp.github.io/powershell/cmdlets/Connect-PnPOnline.html) — `-ManagedIdentity` funguje v Azure Functions, Automation Runbookech a Cloud Shellu; certifikát je `-Thumbprint`
- [Grant-PnPAzureADAppSitePermission](https://pnp.github.io/powershell/cmdlets/Grant-PnPAzureADAppSitePermission.html) — per-site grant pro `Sites.Selected`
- [Timer trigger for Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-timer) — NCRONTAB výrazy
- [Flex Consumption plan](https://learn.microsoft.com/en-us/azure/azure-functions/flex-consumption-plan) — nepodpora managed dependencies v PowerShellu

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Názvy PnP cmdletů pro per-site grant (`Grant-PnPAzureADAppSitePermission`) a parametry
> `Set-PnPListItemPermission` se mezi verzemi modulu měnily — ověřit proti
> [pnp.github.io/powershell](https://pnp.github.io/powershell/) před během, v labu jsou
> napsané natvrdo.
>
> **Nepodpora managed dependencies na Flex Consumption** je typ omezení, které Microsoft
> časem odstraňuje. Kdyby padlo, krok 4 se zkrátí na `requirements.psd1`.
