# Lab · Od ručního klikání k aplikaci, která to udělá za vás — krok za krokem

> Odhad: 60 min · Režim: živý tenant

## Cíl

Přidělíte uživateli přístup k dokumentu. Nejdřív **ručně**, pak **skriptem z notebooku**,
a nakonec **skriptem, který běží v Azure a nikdo v něm není přihlášený**.

Ten poslední krok je celý smysl labu. Rozdíl mezi druhým a třetím je totiž tenhle:

| | Skript na notebooku | Skript v Azure |
|---|---|---|
| Čím se přihlašuje | **certifikátem, který držíte** | ničím, co byste mohl držet |
| Co se stane, když vám ukradnou notebook | útočník má identitu | nic |
| Co musíte hlídat | expiraci a uložení certifikátu | nic |

**A přesně tohle si od Azure kupujete.** Ne výkon, ne dostupnost — kupujete si to, že
identitu nemusíte nikde mít.

> [!NOTE] Pro koho je to napsané
> Pro člověka, který **Azure nikdy nepoužil**. Každý krok má napsané *co* děláme a *proč*,
> a kde to jde, tak **ručně** i **skriptem**. Když jste v Azure doma, jeďte skriptovou
> variantou a hotovo za dvacet minut.

## Předpoklady

- App registrace z [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/)
  se `Sites.Selected` a udělený admin consent.
- Certifikátová identita z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).
- Vlastní web s knihovnou dokumentů a alespoň jedním dokumentem.
- Vlastní Azure resource group `rg-goc223-<jmeno-prijmeni>` (viz [`../../environment.md`](../../environment.md)).

Druhý účet nepotřebujete. Vše projde z vašeho vlastního.

---

## Část 1 — Nejdřív to udělejte rukama (5 min)

### Krok 1 — Přidělte přístup k dokumentu ručně

**Co děláme:** v knihovně vyberete jeden dokument a dáte k němu přístup jednomu uživateli.

**Proč:** protože až to za chvíli budete automatizovat, musíte vědět, co přesně
automatizujete. A protože na tomhle kroku je vidět, proč to nikdo nechce dělat ručně.

**Ručně:**

1. Knihovna → vyberte dokument → **⋮** → **Manage access**
2. **Advanced** (vpravo dole) → **Stop Inheriting Permissions** → potvrdit
3. **Grant Permissions** → zadejte uživatele → zrušte „Send an email invitation"
4. **Show options** → vyberte úroveň **Read** → **Share**

**Poznamenejte si tři věci**, budete je za chvíli potřebovat:

- kolik to bylo kliknutí (typicky 8-10) — a představte si 200 žádostí za měsíc,
- museli jste na to mít **správcovská práva na tu knihovnu**, tedy víc, než má žadatel,
- **nikde nezůstalo, kdo o to požádal a proč.** Za půl roku to nedohledáte.

Zbytek labu tyhle tři věci postupně odstraní.

---

## Část 2 — Terén: kde se žádosti sbírají (10 min)

### Krok 2 — Seznam žádostí

**Co děláme:** seznam, do kterého uživatelé zapisují, o co žádají.

**Proč:** aby žádost byla **záznam**, ne e-mail nebo zpráva v Teams. Záznam se dá
zpracovat automatem a zůstane po něm stopa.

**Ručně:** nový seznam `Zadosti o pristup`, sloupce podle tabulky. Pozor na **interní**
názvy — vytvořte sloupec jako `RequestStatus`, ne „Request Status" (z toho by byl interní
název `Request_x0020_Status` a skript ho nenajde).

| Interní název | Typ | K čemu |
|---|---|---|
| `RequestStatus` | Choice: `Pending`, `Granted`, `Rejected`, `Failed` | default `Pending` — podle toho skript pozná, co má zpracovat |
| `RequesterEmail` | Text | komu se přístup přidělí |
| `TargetLibrary` | Text | do které knihovny |
| `TargetItemId` | Number | ke které položce |
| `RequestedRole` | Choice: `Read`, `Contribute` | jaká úroveň |
| `DecisionNote` | Note | sem zapíše skript, jak rozhodl |

**Skriptem:**

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" `
  -ClientId <client-id> -Interactive

New-PnPList -Title "Zadosti o pristup" -Template GenericList

Add-PnPField -List "Zadosti o pristup" -DisplayName "RequestStatus" -InternalName "RequestStatus" `
  -Type Choice -Choices "Pending","Granted","Rejected","Failed" -AddToDefaultView
Add-PnPField -List "Zadosti o pristup" -DisplayName "RequesterEmail" -InternalName "RequesterEmail" `
  -Type Text -AddToDefaultView
Add-PnPField -List "Zadosti o pristup" -DisplayName "TargetLibrary" -InternalName "TargetLibrary" `
  -Type Text -AddToDefaultView
Add-PnPField -List "Zadosti o pristup" -DisplayName "TargetItemId" -InternalName "TargetItemId" `
  -Type Number -AddToDefaultView
Add-PnPField -List "Zadosti o pristup" -DisplayName "RequestedRole" -InternalName "RequestedRole" `
  -Type Choice -Choices "Read","Contribute" -AddToDefaultView
Add-PnPField -List "Zadosti o pristup" -DisplayName "DecisionNote" -InternalName "DecisionNote" `
  -Type Note
```

**Ověřte si interní názvy**, ať vás to nezradí až v kroku 7:

```powershell
Get-PnPField -List "Zadosti o pristup" | Select-Object Title, InternalName
```

### Krok 3 — Seznam auditu, do kterého nikdo nesmí zapisovat

**Co děláme:** druhý seznam, kam skript zapíše, co provedl. A odebereme uživatelům
právo do něj zapisovat.

**Proč:** tohle je ta třetí věc z kroku 1 — chybějící stopa. Audit, do kterého smí
zapisovat ten, koho auditujete, není audit.

**Ručně:** nový seznam `Audit pristupu` se sloupci `Requester`, `Outcome`, `Detail`,
`ProcessedU` (vše Text). Pak **List settings → Permissions for this list → Stop
Inheriting Permissions** a skupině **Members** změňte úroveň na **Read**.

**Skriptem:**

```powershell
New-PnPList -Title "Audit pristupu" -Template GenericList

Add-PnPField -List "Audit pristupu" -DisplayName "Requester"  -InternalName "Requester"  -Type Text -AddToDefaultView
Add-PnPField -List "Audit pristupu" -DisplayName "Outcome"    -InternalName "Outcome"    -Type Text -AddToDefaultView
Add-PnPField -List "Audit pristupu" -DisplayName "Detail"     -InternalName "Detail"     -Type Note
Add-PnPField -List "Audit pristupu" -DisplayName "ProcessedU" -InternalName "ProcessedU" -Type Text -AddToDefaultView

# Rozbit dedeni a nechat clenum jen cteni
Set-PnPList -Identity "Audit pristupu" -BreakRoleInheritance -CopyRoleAssignments
$members = Get-PnPGroup | Where-Object { $_.Title -like "*Members*" }
Set-PnPListPermission -Identity "Audit pristupu" -Group $members.Title -RemoveRole "Edit"
Set-PnPListPermission -Identity "Audit pristupu" -Group $members.Title -AddRole "Read"
```

---

## Část 3 — Identita, která není člověk (15 min)

### Krok 4 — Podívejte se, co vaše aplikace umí

**Co děláme:** ověříme, co má app registrace z D2 přidělené.

**Proč:** protože za chvíli pod ní pustíte operaci, kterou žadatel sám nesmí. Musíte
vědět, co přesně jí dovolujete — a `Sites.Selected` je záměrně to nejužší, co úlohu splní.

**Ručně:** Entra → App registrations → vaše aplikace → **API permissions**. Uvidíte
`Sites.Selected` jako **Application** permission se zeleným consentem.

**Skriptem:**

```powershell
Connect-MgGraph -Scopes "Application.Read.All"
$sp = Get-MgServicePrincipal -Filter "appId eq '<client-id>'"
Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id |
    Select-Object AppRoleId, ResourceDisplayName
```

### Krok 5 — Dát aplikaci jeden jediný web

**Co děláme:** povýšíme per-site grant z D2 z `Read` na `Write`.

**Proč:** `Sites.Selected` po consentu **nedává přístup nikam** — to je celý její smysl.
Teprve tímto krokem aplikace dostane jeden konkrétní web. A `Write` je minimum, které
úlohu splní: přidělení role na položce je zápisová operace. `Read` nestačí,
`FullControl` je zbytečný.

> [!IMPORTANT] Ručně to nejde — a to je samo o sobě informace
> Per-site grant pro `Sites.Selected` **nemá v portálu žádné UI**. Není to opomenutí
> Microsoftu: je to hranice mezi tím, co člověk naklikává, a tím, co se **uděluje
> aplikaci**. Právě proto se to dělá skriptem nebo Graph API.

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" `
  -ClientId <client-id> -Interactive

Grant-PnPAzureADAppSitePermission -AppId <client-id> `
  -DisplayName "<jmeno-prijmeni>-course-app" `
  -Site "https://<tenant>.sharepoint.com/sites/<web>" `
  -Permissions Write

# Overit
Get-PnPAzureADAppSitePermission
```

---

## Část 4 — Skript na notebooku: funguje, ale držíte certifikát (10 min)

### Krok 6 — Přihlásit se jako aplikace

**Co děláme:** připojíme se app-only, certifikátem, bez jakéhokoli promptu.

**Proč:** tohle je první moment, kdy operaci provádí **aplikace, ne vy**. Všimněte si,
že se neotevře žádné okno s přihlášením.

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" `
  -ClientId $env:CLIENT_ID -Tenant "<tenant>.onmicrosoft.com" `
  -Thumbprint $env:CERT_THUMBPRINT
```

Parametr je `-Thumbprint`, **ne** `-CertificateThumbprint`. Ověřte, že opravdu nejste vy:

```powershell
Get-PnPProperty -ClientObject (Get-PnPWeb) -Property CurrentUser
```

### Krok 7 — Nechat skript udělat to, co jste v kroku 1 klikali

**Co děláme:** založíme jednu žádost a pustíme skript — nejdřív nasucho, pak naostro.

**Proč:** `-WhatIf` u operace, která rozbíjí dědění oprávnění, není formalita. Překlep
v `TargetItemId` znamená rozbité oprávnění na cizí položce.

Založte řádek: `RequesterEmail` = váš e-mail, `TargetLibrary` = vaše knihovna,
`TargetItemId` = ID dokumentu, `RequestedRole` = `Read`.

**Nejdřív si připravte pracovní složku** podle konvence z
[`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md)
a zkopírujte si do ní oba soubory řešení:

```powershell
# <cesta-k-repu> je misto, kam jste si repozitar naklonoval
Set-Location "<cesta-k-repu>/<jmeno-prijmeni>"

Copy-Item "<cesta-k-repu>/day-4/elevated-access/solution/Grant-RequestedAccess.ps1" .
Copy-Item "<cesta-k-repu>/day-4/elevated-access/solution/Grant-RequestedAccess.Tests.ps1" .
```

Teprve teď dot-source a spuštění — všimněte si, že cesta **neobsahuje `solution/`**,
protože skript už máte u sebe:

```powershell
. ./Grant-RequestedAccess.ps1

# Nasucho - vypise, co by se stalo, a nezapise nic
Invoke-AccessRequestQueue -RequestListTitle 'Zadosti o pristup' `
  -AuditListTitle 'Audit pristupu' -AllowedLibraryTitle 'Dokumenty' -WhatIf

# Naostro
Invoke-AccessRequestQueue -RequestListTitle 'Zadosti o pristup' `
  -AuditListTitle 'Audit pristupu' -AllowedLibraryTitle 'Dokumenty'
```

> [!IMPORTANT] Tečka v `. ./skript.ps1` neznamená „vedle skriptu", ale „v aktuální složce"
> `./` se vyhodnocuje proti **aktuálnímu pracovnímu adresáři** (`Get-Location`), ne proti
> umístění souboru. Když tedy dot-source spustíte odjinud, než kde soubor leží, dostanete
> `The term '.\Grant-RequestedAccess.ps1' is not recognized` — a to i když ten soubor
> v repu prokazatelně je.
>
> **Uvnitř skriptu** se tenhle problém řeší `$PSScriptRoot` (cesta ke složce toho skriptu) —
> přesně tak to dělá `Grant-RequestedAccess.Tests.ps1`, který si své řešení najde jako
> `. $PSScriptRoot/Grant-RequestedAccess.ps1`. Proto testy fungují odkudkoli, ale interaktivní
> dot-source ne: **v konzoli `$PSScriptRoot` neexistuje.**
>
> Když si nejste jistí, kde stojíte: `Get-Location`. A `Resolve-Path ./Grant-RequestedAccess.ps1`
> vám řekne, jestli tam ten soubor podle PowerShellu je.

Zkontrolujte **v SharePointu**, ne jen ve výstupu: uživatel má u dokumentu roli, řádek
je `Granted` a v auditu je záznam.

> [!IMPORTANT] Zastavte se tu na chvíli a podívejte se, co držíte v ruce
> Právě jste odstranili dvě ze tří věcí z kroku 1: **žádné klikání** a **stopa v auditu**.
> Ale ta operace pořád stojí na **certifikátu ve vašem úložišti**. Ten certifikát:
>
> - musíte někam uložit a chránit,
> - jednou vyprší a někdo ho musí vyměnit,
> - když se dostane jinam, dostane se s ním i identita,
> - a **na serveru, kde to má běžet každou noc, ho musíte mít taky.**
>
> To je ten problém, který řeší Azure. Jdeme na to.

---

## Část 5 — Přenést to do Azure: identita, kterou nemáte kde nechat (20 min)

### Krok 8 — Automation account

**Co děláme:** vytvoříme v Azure službu, která umí spouštět PowerShell podle rozvrhu.

**Proč:** potřebujeme místo, kde skript poběží, když u toho nikdo nesedí. Automation
account je nejjednodušší taková služba — má editor v prohlížeči, takže na nasazení
nepotřebujete na svém stroji vůbec nic.

**Ručně:** portál → **+ Create a resource** → **Categories** → **IT & Management Tools**
→ **Automation**. V **Resource group** vyberte **svou existující** `rg-goc223-<jmeno>` —
**ne** „Create new", na to nemáte práva. Zbytek nechte a **Review + create**.

**Skriptem:**

```powershell
Connect-AzAccount

New-AzAutomationAccount -ResourceGroupName "rg-goc223-<jmeno-prijmeni>" `
  -Name "aa-goc223-<jmeno-prijmeni>" -Location "westeurope"
```

**Ověřte, že má identitu:** portál → váš Automation account → **Identity** →
**System assigned** musí být **On**. Při zakládání z portálu je zapnutá defaultně
(dokumentace: *„By default, a system-assigned managed identity is enabled for the
Automation account"*). Když tam není, přepněte ji tady a uložte.

> [!NOTE] Co se právě stalo, i když to není vidět
> Vznikl vám v Entra nový **service principal** — identita, která patří té Azure službě.
> Nemá heslo, nemá certifikát, nemá kde se přihlásit. Existuje jen dokud existuje ten
> Automation account.

### Krok 9 — Dostat PnP.PowerShell dovnitř

**Co děláme:** naimportujeme modul, aby ho runbook mohl použít.

**Proč:** Azure neví nic o modulech, které máte na notebooku. Runbook běží v cizím
prostředí a všechno, co potřebuje, tam musí být.

**Ručně:** Automation account → **Shared Resources** → **Modules** → **Add a module** →
**Browse from Gallery** → `PnP.PowerShell` → **Select** → **Runtime version: 7.2** →
**Import**. **Trvá to minuty**, ne sekundy — pusťte to a čtěte dál.

**Skriptem:**

```powershell
New-AzAutomationModule -ResourceGroupName "rg-goc223-<jmeno-prijmeni>" `
  -AutomationAccountName "aa-goc223-<jmeno-prijmeni>" `
  -Name "PnP.PowerShell" -RuntimeVersion "7.2" `
  -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/PnP.PowerShell/<verze>"
```

> [!WARNING] Dvě věci, které tady zaskočí i zkušené
> - **Runtime version modulu musí souhlasit s runbookem.** Modul pro 5.1 runbook na 7.2
>   nevidí a hláška bude „cmdlet not recognized" — na modul neukáže vůbec.
> - **Nevidíte blazenu Modules?** Účet používá novou *Runtime environment* zkušenost, kde
>   se moduly spravují jinde. Dokumentace: *„In the new experience, Modules and Packages
>   blades are not available."*

### Krok 10 — Dát té nové identitě přístup k SharePointu

**Co děláme:** managed identitě přiřadíme aplikační roli `Sites.Selected` a pak jí dáme
ten jeden web.

**Proč:** je to **nová, jiná identita** než vaše app registrace z části 4. To, že jste
grant udělal v kroku 5, pro ni neplatí.

> [!IMPORTANT] Tohle je nejčastější místo, kde lab spadne
> V labu teď existují **dvě identity**, které sahají na SharePoint:
>
> | Identita | Používá se | Čím se hlásí |
> |---|---|---|
> | vaše app registrace z D2 | část 4, na notebooku | certifikátem |
> | managed identity Automation accountu | část 5, v Azure | ničím |
>
> Jsou to dva různé service principaly a **každý potřebuje svůj vlastní per-site grant.**
> Kdo v části 5 spoléhá na grant z kroku 5, dostane `Access denied` — a ta hláška na
> příčinu neukáže.

**Ručně to nejde** (stejný důvod jako v kroku 5), takže skriptem. **GUID rolí nikde
neopisujte** — dohledejte si je:

```powershell
Connect-MgGraph -Scopes "AppRoleAssignment.ReadWrite.All","Application.Read.All"

# Service principal SharePointu - nazev je stabilnejsi nez GUID z pameti
$spo = Get-MgServicePrincipal -Filter "displayName eq 'Office 365 SharePoint Online'"
$spo.AppRoles | Where-Object { $_.Value -eq 'Sites.Selected' } |
    Select-Object Value, Id, DisplayName

# Service principal vasi managed identity (jmenuje se jako Automation account)
$mi = Get-MgServicePrincipal -Filter "displayName eq 'aa-goc223-<jmeno-prijmeni>'"
```

Roli pak přiřadíte přes `New-MgServicePrincipalAppRoleAssignment` na `$mi.Id`,
s `ResourceId` = `$spo.Id` a `AppRoleId` z výpisu výše. Nakonec **druhý per-site grant**,
tentokrát na `AppId` managed identity:

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" `
  -ClientId <client-id> -Interactive

Grant-PnPAzureADAppSitePermission -AppId $mi.AppId `
  -DisplayName "aa-goc223-<jmeno-prijmeni>" `
  -Site "https://<tenant>.sharepoint.com/sites/<web>" -Permissions Write
```

### Krok 11 — Runbook a první běh v Azure

**Co děláme:** vložíme skript do runbooku a spustíme ho.

**Proč:** runbook **nemá disk**, takže se nedá dot-sourcovat soubor jako v kroku 7.
Funkce ze `solution/Grant-RequestedAccess.ps1` musí být v runbooku obsažené.

**Ručně:** Automation account → **Process Automation** → **Runbooks** →
**Create a runbook** → jméno `Grant-Access`, typ **PowerShell**, **Runtime version 7.2**.
Do editoru vložte **celý obsah** `solution/Grant-RequestedAccess.ps1` a pod něj tohle
(pro skriptovou variantu si to uložte jako `runbook-body.ps1`):

```powershell
param(
    [Parameter(Mandatory = $true)] [string] $SiteUrl,
    [Parameter(Mandatory = $true)] [string] $RequestList,
    [Parameter(Mandatory = $true)] [string] $AuditList,
    [Parameter(Mandatory = $true)] [string] $AllowedLibrary
)

$ErrorActionPreference = 'Stop'

# Zadny certifikat, zadne heslo, zadny ClientId. Plaforma rekne, kdo jsme.
Connect-PnPOnline -Url $SiteUrl -ManagedIdentity

Invoke-AccessRequestQueue -RequestListTitle $RequestList `
    -AuditListTitle $AuditList -AllowedLibraryTitle $AllowedLibrary
```

Pak **Save** a **Test pane** → vyplňte parametry → **Start**.

**Skriptem** (sestaví runbook ze dvou souborů a nahraje ho):

```powershell
$rg = "rg-goc223-<jmeno-prijmeni>"
$aa = "aa-goc223-<jmeno-prijmeni>"

Get-Content ./Grant-RequestedAccess.ps1, ./runbook-body.ps1 |
    Set-Content ./Grant-Access.ps1

Import-AzAutomationRunbook -ResourceGroupName $rg -AutomationAccountName $aa `
  -Name "Grant-Access" -Type PowerShell -Path ./Grant-Access.ps1 -Force

Publish-AzAutomationRunbook -ResourceGroupName $rg -AutomationAccountName $aa `
  -Name "Grant-Access"

$job = Start-AzAutomationRunbook -ResourceGroupName $rg -AutomationAccountName $aa `
  -Name "Grant-Access" -Parameters @{
      SiteUrl = "https://<tenant>.sharepoint.com/sites/<web>"
      RequestList = "Zadosti o pristup"
      AuditList = "Audit pristupu"
      AllowedLibrary = "Dokumenty"
  }

Get-AzAutomationJobOutput -ResourceGroupName $rg -AutomationAccountName $aa `
  -Id $job.JobId -Stream Output
```

> [!IMPORTANT] `Test pane` běží nad draftem, `Start` nad publikovanou verzí
> Kdo si odladí runbook v Test pane a zapomene dát **Publish**, dostane při dalším běhu
> starý kód — a z výstupu to nepozná. Nejčastější zdroj „ale mně to fungovalo".

### Krok 12 — Rozvrh: a od teď to jede samo

**Co děláme:** navěsíme na runbook rozvrh.

**Proč:** tím je hotová ta věc, o které mluví celý den — **plánovaný běh bez
interaktivního přihlášení.**

**Ručně:** runbook → **Schedules** → **Add a schedule** → **Create a new schedule**,
nastavte opakování a v **Parameters** vyplňte hodnoty.

**Skriptem:**

```powershell
New-AzAutomationSchedule -ResourceGroupName $rg -AutomationAccountName $aa `
  -Name "kazdych-15-minut" -StartTime (Get-Date).AddMinutes(10) `
  -HourInterval 1

Register-AzAutomationScheduledRunbook -ResourceGroupName $rg -AutomationAccountName $aa `
  -RunbookName "Grant-Access" -ScheduleName "kazdych-15-minut" -Parameters @{ }
```

Rozvrh v Automation má **vlastní časovou zónu**, kterou zvolíte — na rozdíl od NCRONTAB
u Azure Functions timeru, který je vždycky v UTC.

> [!IMPORTANT] Tady je pointa celého labu — přečtěte si to nahlas
> Podívejte se na tělo runbooku. **Není v něm certifikát, heslo, ClientId ani thumbprint.**
> Jen `Connect-PnPOnline -ManagedIdentity`. A přesto právě provedl operaci, kterou žadatel
> sám provést nesmí.
>
> **Nezmizel principál — zmizel secret.** Ta identita pořád existuje v Entra, pořád má
> přiřazenou roli a per-site grant, a kdo má Contributor na téhle resource group, ten pod
> ní umí runbook spustit. Co zmizelo, je **cokoli, co se dá zkopírovat, vyexportovat nebo
> poslat mailem.**
>
> A to je celá odpověď na otázku, k čemu je Azure jako platforma pro app-only skripty.

---

## Část 6 — Aplikace teď smí víc než člověk (5 min)

### Krok 13 — Jedna podmínka v kódu

**Co děláme:** ověříme, že skript odmítne žádost, která nepřišla od toho, pro koho je.

**Proč:** aplikace má právo zápisu na **celý web** — víc, než má kdokoli, kdo do seznamu
žádostí zapisuje. Kdyby brala řádky bez kontroly, uměl by si každý přidělit cokoli, nebo
přidělit přístup někomu, kdo o nic nepožádal. Ta jedna podmínka je cena za to, že
identita má víc práv než lidé.

Založte řádek, kde do `RequesterEmail` napíšete **cizí adresu** — `Author` budete vy.
Spusťte runbook. Řádek musí skončit `Rejected`, přístup se nepřidělit a **v auditu musí
být záznam** (zamítnutí, které nikde nezůstane, je pro auditora totéž jako kdyby žádost
nepřišla).

Další dvě podmínky — role mimo povolenou sadu a knihovna mimo rozsah — jsou dokázané
testy, není potřeba je proklikávat:

```powershell
Invoke-Pester ./Grant-RequestedAccess.Tests.ps1
```

---

## Ověření

- [ ] Krok 1: umíte popsat, kolik kliknutí ruční přidělení stálo a co po něm nezůstalo.
- [ ] Skript na notebooku přidělí přístup **bez interaktivního přihlášení** (krok 6-7).
- [ ] `-WhatIf` neprovede ani jeden zápis.
- [ ] Runbook v Azure udělá **totéž**, a v jeho těle **není žádný secret** (krok 11).
- [ ] Managed identity má **vlastní** per-site grant — `Get-PnPAzureADAppSitePermission`
      vrací dvě aplikace, ne jednu (krok 10).
- [ ] Rozvrh existuje a runbook je **publikovaný** (krok 12).
- [ ] Žádost s cizí adresou v `RequesterEmail` skončí `Rejected` a je v auditu (krok 13).
- [ ] V audit seznamu nemá skupina Members právo zápisu.

## Fallback

- **Nedostanete se do Azure** (část 5): části 1-4 stojí samy a mají vlastní pointu —
  ruční operace, pak aplikační identita s certifikátem. Rozdíl proti Azure se pak dá
  odvyprávět nad tabulkou v úvodu labu, ale je to slabší: neuvidí se, že v runbooku
  opravdu žádný secret není.
- **Import modulu nedobíhá** (krok 9): pokračujte krokem 10, import běží na pozadí.
  Když nedoběhne vůbec, spusťte runbook alespoň s `Write-Output` místo PnP volání —
  ověříte tím celou cestu kromě SharePointu.
- **App role assignment selže** (krok 10): potřebuje GA nebo Privileged Role Administrator.
  Bez něj Azure část nedoběhne — nechte studenty spárovat s tím, komu to prošlo, ať to
  aspoň vidí.
- **Není čas na celý lab**: části 1, 4 a 5 jsou jádro (ručně → certifikát → nic).
  Části 2 a 3 se dají dodat hotové skriptem výše.

## Zdroje (Microsoft a PnP)

- [Create an Automation account using the portal](https://learn.microsoft.com/en-us/azure/automation/quickstarts/create-azure-automation-account-portal) — postup i managed identity zapnutá defaultně
- [Manage modules in Azure Automation](https://learn.microsoft.com/en-us/azure/automation/shared-resources/modules) — Browse from Gallery, runtime version, Runtime environment
- [Az.Automation](https://learn.microsoft.com/en-us/powershell/module/az.automation/) — `New-AzAutomationAccount`, `New-AzAutomationModule`, `Import-AzAutomationRunbook`, `Publish-AzAutomationRunbook`, `Start-AzAutomationRunbook`, `Get-AzAutomationJobOutput`, `New-AzAutomationSchedule`, `Register-AzAutomationScheduledRunbook`
- [Connect-PnPOnline](https://pnp.github.io/powershell/cmdlets/Connect-PnPOnline.html) — `-ManagedIdentity` funguje v Automation Runbookech; certifikát je `-Thumbprint`
- [Set-PnPListItemPermission](https://pnp.github.io/powershell/cmdlets/Set-PnPListItemPermission.html) — cmdlet, kterým se elevovaná operace provádí
- [Grant-PnPAzureADAppSitePermission](https://pnp.github.io/powershell/cmdlets/Grant-PnPAzureADAppSitePermission.html) — per-site grant pro `Sites.Selected`

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> **Klikací postupy stárnou rychleji než cmdlety.** Portálové cesty v krocích 8, 9, 11
> a 12 projít nanečisto před **každým** během. Totéž pro runtime versions runbooků
> (dnes 5.1 a 7.2) a pro *Runtime environment* zkušenost, která schovává blazenu Modules.
>
> `New-AzAutomationModule` chce v `-ContentLinkUri` konkrétní verzi z PowerShell Gallery —
> doplnit aktuální před během.
>
> Názvy PnP cmdletů pro per-site grant se mezi verzemi měnily; ověřit proti
> [pnp.github.io/powershell](https://pnp.github.io/powershell/).
