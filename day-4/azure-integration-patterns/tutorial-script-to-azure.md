# Tutorial · Dostat skript do Azure a spustit ho tam — krok za krokem

Praktický průchod, na konci kterého **váš PowerShell skript běží v Azure** a zřizuje weby
v SharePointu. Žádná teorie, žádná rozhodovací tabulka — ta je vedle
v [`comparison-scheduled-runtimes.md`](comparison-scheduled-runtimes.md) a přečtete si ji,
až budete vědět, jak to vypadá zvnějšku.

> [!IMPORTANT] Dvě části, a první z nich musí projít vždycky
> **Část A (10 min)** dostane do Azure skript, který nedělá nic zajímavého — a spustí ho.
> Tím je dokázaná celá cesta: účet, editor, běh, výstup, rozvrh.
> **Část B (15 min)** ten samý runbook napojí na SharePoint a nechá ho zřídit web ze šablony.
>
> Tohle pořadí je záměrné. Když se Část B zadrhne na oprávněních — a to je nejčastější místo,
> kde se to zadrhne — máte pořád odučenou pointu: **skript běží v Azure a nikdo se
> nepřihlašuje.** Nedělejte to naopak.

## Proč Automation Runbook a ne Azure Function

Function je správná odpověď na *„reaguj na event"*. Na *„dostaň můj skript do Azure"* je
špatný učební nástroj, protože ta nejtěžší část nasazení nesouvisí se skriptem:

| | Automation Runbook | Azure Function (Flex Consumption) |
|---|---|---|
| Kam se napíše kód | **editor v portálu** | lokální projekt + deployment package |
| Jak se dovnitř dostane PnP.PowerShell | **import z galerie, klikací** | **musí se přiložit do `Modules/`** v packagi — Flex managed dependencies nepodporuje |
| Co potřebujete na svém stroji | **nic** | Azure Functions Core Tools, správná verze runtime |
| První úspěšný běh | **minuty** | desítky minut, když se něco nepovede |

Ten druhý řádek je ten podstatný. `PnP.PowerShell` je velký modul a na Flexu ho nedostanete
přes `requirements.psd1` — nese se v obsahu aplikace. To je legitimní produkční postup
(popsaný v [`../elevated-access/lab-elevated-access.md`](../elevated-access/lab-elevated-access.md) a
[`guide-copy-metadata.md`](guide-copy-metadata.md)), ale jako **první** kontakt s hostingem
v Azure je to past.

---

# Část A — skript v Azure za deset minut

## A1. Automation account

Portál → **+ Create a resource** → **Categories** → **IT & Management Tools** →
**Automation**.

Vyplňte Subscription, Resource group (**vlastní**, viz [`../../environment.md`](../../environment.md)),
jméno a Region. Ostatní taby nechte, jak jsou, a dejte **Review + create**.

> [!NOTE] Managed identity dostanete zdarma a rovnou
> Dokumentace: *„By default, a system-assigned managed identity is enabled for the
> Automation account."* Nemusíte tedy nic zapínat — a hlavně: **nikde v tomhle tutoriálu
> nebude heslo ani secret.** To je celý smysl.

## A2. První runbook

V Automation accountu → **Process Automation** → **Runbooks** → **Create a runbook**.

- **Name**: `Provision-Site` (ať ho v části B nemusíte zakládat znovu)
- **Runbook type**: **PowerShell**
- **Runtime version**: **7.2**

Do editoru vložte tohle a dejte **Save**:

```powershell
param(
    [Parameter(Mandatory = $true)]
    [string] $SiteUrl
)

Write-Output "Start: $(Get-Date -Format o)"
Write-Output "Bezim v Azure, nikdo se neprihlasil."
Write-Output "Dostal jsem parametr SiteUrl: $SiteUrl"
Write-Output "Konec."
```

## A3. Spustit a vidět výstup

Dvě cesty a obě chcete znát:

**Test pane** (nepublikuje se, ideální na ladění): tlačítko **Test pane** → vyplňte
`SITEURL` → **Start**. Výstup se objeví přímo v okně.

**Publish + Start** (takhle to poběží v provozu): **Publish** → pak **Start** → vyplňte
parametr → OK. Otevře se stránka jobu, výstup je na tabu **Output**, chyby na **Errors**
a **Warnings**.

> [!IMPORTANT] Nepublikovaný runbook rozvrh nespustí
> `Test pane` běží nad **draftem**, `Start` a rozvrh nad **publikovanou** verzí. Kdo si
> odladí skript v Test pane a zapomene dát Publish, dostane při dalším běhu starý kód —
> a nejde to poznat z výstupu. Je to nejčastější zdroj „ale mně to fungovalo".

## A4. Rozvrh (volitelně, 1 minuta)

**Schedules** → **Add a schedule** → **Link a schedule to your runbook** → **Create a new
schedule**. Recurrence nastavte a v **Parameters** vyplňte `SiteUrl`.

Tím máte hotovou tu věc, o které mluví celý den 4: **plánovaný běh bez interaktivního
přihlášení.** Čas je v časové zóně, kterou u rozvrhu zvolíte — na rozdíl od NCRONTAB
u Function timeru, který je vždy v UTC.

**Část A je hotová.** Skript je v Azure, běží, bere parametry, má rozvrh a výstup. Teď ať
dělá něco užitečného.

---

# Část B — ať sáhne na SharePoint

## B1. Naimportovat PnP.PowerShell

Automation account → **Shared Resources** → **Modules** → **Add a module** →
**Browse from Gallery** → najděte `PnP.PowerShell` → **Select** → **Runtime version: 7.2**
→ **Import**.

> [!WARNING] Import trvá minuty, ne sekundy. A dvě věci vás můžou zaskočit
> - **Nevidíte blazenu Modules?** Účet používá novou *Runtime environment* zkušenost —
>   dokumentace: *„In the new experience, Modules and Packages blades are not available."*
>   Moduly se pak spravují v **Runtime environments**. Ověřte to **před během**, ne v sále.
> - **Runtime version musí souhlasit s runbookem.** Modul naimportovaný pro 5.1 runbook
>   na 7.2 nevidí. Hláška bude „cmdlet not recognized" a na modul neukáže.

## B2. Šablona webu — kde ji vzít, když runbook nemá disk

Runbook nemá souborový systém, kam byste položili `template.xml`. Řešení, které
`Invoke-PnPSiteTemplate` přímo podporuje: **šablona leží v knihovně SharePointu**
a čte se jako stream.

Šablonu vyrobíte ze vzorového webu (lokálně, jednou) — tentýž `Get-PnPSiteTemplate`
jako v [`../../day-3/provisioning-patterns/`](../../day-3/provisioning-patterns/):

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<vzor>" `
  -ClientId <client-id> -Interactive

Get-PnPSiteTemplate -Out .\baseline.xml -Handlers Lists,Fields
```

Ten soubor nahrajte do knihovny na správním webu — odtud si ho runbook vezme.

## B3. Dát managed identitě právo na SharePoint

Tady se to zadrhává, tak pomalu. Managed identita po vzniku **nemá žádná práva** — a to je
správně. Potřebuje dvě věci:

**1. Aplikační roli `Sites.Selected`** na SharePointu. Přiřazuje se service principalu té
identity přes Microsoft Graph. **Nevypisujte GUID z hlavy** — najděte si ho:

```powershell
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All","Application.Read.All"

# Service principal SharePointu (nazev je stabilnejsi nez GUID z pameti)
$spo = Get-MgServicePrincipal -Filter "displayName eq 'Office 365 SharePoint Online'"

# Overte, jak se role jmenuje a jake ma id, a az pak prirazujte
$spo.AppRoles | Where-Object { $_.Value -eq 'Sites.Selected' } |
    Select-Object Value, Id, DisplayName
```

Objekt ID vaší managed identity najdete v Automation accountu pod **Identity**. Přiřazení
je pak `New-MgServicePrincipalAppRoleAssignment` na service principal té identity
s `ResourceId` = `$spo.Id` a `AppRoleId` = id z výpisu výše.

**2. Per-site grant** — `Sites.Selected` sama nedává přístup nikam, to je celý její smysl.
Postup je identický jako v [`../elevated-access/lab-elevated-access.md`](../elevated-access/lab-elevated-access.md), krok 2, jen
`-AppId` je **Application (client) ID managed identity**, ne vaší app registrace.

> [!TIP] Když B3 nevyjde, nezastavujte se
> Fallback: nechte runbook v Části A a Část B **odveďte lokálně** s certifikátovou identitou
> z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/). Studenti pak
> viděli obojí — běh v Azure i skutečné zřízení webu — jen ne v jednom procesu. To je pořád
> nekonečně víc než výklad o tom, že by to šlo.

## B4. Přepsat runbook na skutečnou práci

Vraťte se do `Provision-Site`, přepište tělo a dejte **Save** + **Publish**:

```powershell
param(
    [Parameter(Mandatory = $true)] [string] $SiteUrl,
    [Parameter(Mandatory = $true)] [string] $TemplateUrl,
    [string] $ListTitle = "Projekty"
)

$ErrorActionPreference = 'Stop'

Write-Output "Pripojuji se jako managed identity, bez tajemstvi na disku."
Connect-PnPOnline -Url $SiteUrl -ManagedIdentity

# Sablona lezi v knihovne, ne na disku - runbook zadny disk nema.
Write-Output "Ctu sablonu: $TemplateUrl"
$stream = Get-PnPFile -Url $TemplateUrl -AsMemoryStream

Write-Output "Aplikuji sablonu na $SiteUrl"
Invoke-PnPSiteTemplate -Stream $stream -Parameters @{ ListTitle = $ListTitle }

Write-Output "Hotovo: $(Get-Date -Format o)"
```

Spusťte **Test pane** s vyplněnými parametry. Když projde, jste doma: **skript běží v Azure,
zřizuje weby a nikde v něm není heslo.**

## B5. Ověření

- [ ] Runbook v Části A vypsal parametr a skončil bez chyby.
- [ ] `Test pane` a `Start` dávají stejný výsledek — tj. **nezapomněli jste Publish**.
- [ ] `Connect-PnPOnline -ManagedIdentity` projde **bez jakéhokoli hesla nebo certifikátu**.
- [ ] Cílový web má po běhu listy ze šablony.
- [ ] Druhý běh nad stejným webem neskončí chybou (šablony jsou idempotentní pro `Lists`).
- [ ] V runbooku ani v jeho parametrech **není žádný secret**.

## Na co narazíte (a co s tím)

> [!WARNING] Automation sandbox není plný PowerShell
> Dokumentace: *„Cloud sandbox supports a maximum of 48 system calls, and restricts all
> other calls for security reasons"* a *„we have seen issues with cmdlets which require
> elevated access, require a credential as a parameter, or cmdlets related to networking."*
> Jmenovitě neprojde `Resolve-DnsName`. Doporučené východisko je **Hybrid Runbook Worker
> nebo Azure Functions** — a tím se dostáváte přesně k té rozhodovací tabulce
> v [`comparison-scheduled-runtimes.md`](comparison-scheduled-runtimes.md), tentokrát
> s vlastní zkušeností.

| Symptom | Příčina |
|---|---|
| `The term 'Connect-PnPOnline' is not recognized` | modul se doimportovává, nebo je pro jinou **Runtime version** než runbook |
| Běh vrací starý výstup | runbook není **publikovaný** — ladili jste v Test pane |
| `Access denied` na `Invoke-PnPSiteTemplate` | chybí **per-site grant**; `Sites.Selected` sama nedává nic |
| `Connect-PnPOnline -ManagedIdentity` selže | identita nemá přiřazenou aplikační roli (B3, krok 1) |
| Job visí v `Queued` | fair share / sdílený sandbox; u dlouhých úloh viz strop **3 h** v srovnání |

## Zdroje (Microsoft a PnP)

- [Create an Automation account using the portal](https://learn.microsoft.com/en-us/azure/automation/quickstarts/create-azure-automation-account-portal) — postup i věta o managed identitě zapnuté defaultně
- [Manage modules in Azure Automation](https://learn.microsoft.com/en-us/azure/automation/shared-resources/modules) — Browse from Gallery, runtime version, limity sandboxu, poznámka o Runtime environment
- [Invoke-PnPSiteTemplate](https://pnp.github.io/powershell/cmdlets/Invoke-PnPSiteTemplate.html) — `-Stream`, `-Parameters`, `-Handlers`
- [Get-PnPFile](https://pnp.github.io/powershell/cmdlets/Get-PnPFile.html) — `-AsMemoryStream`
- [Connect-PnPOnline](https://pnp.github.io/powershell/cmdlets/Connect-PnPOnline.html) — `-ManagedIdentity` funguje v Automation Runbookech

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> **Runtime versions Automation runbooků** (dnes 5.1 a 7.2) a **Runtime environment
> zkušenost**, která schovává blazenu Modules, jsou nejrychleji se měnící části tohohle
> postupu — projít portál nanečisto **před každým během**. Klikací postupy stárnou rychleji
> než cmdlety.
>
> Přiřazení aplikační role managed identitě přes Microsoft Graph PowerShell ověřit
> proti aktuální dokumentaci; **GUID rolí v tomhle souboru schválně nejsou** a mají se
> dohledávat příkazem v B3.
