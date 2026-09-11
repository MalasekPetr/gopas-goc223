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

Lab je napsaný pro člověka, který **Azure nikdy nepoužil**. Každý krok říká *co* děláme
a *proč*, a kde to jde, má ruční i skriptovou variantu. Kdo je v Azure doma, jede
skriptovou variantou a je hotový za dvacet minut.

## Předpoklady

> [!IMPORTANT] Všechno v JEDNOM tenantu — a je to ten, ke kterému je připojená Azure subscription
> Web, seznamy, app registrace i Automation account musí být **v témže tenantu**. Není to
> pohodlí, je to tvrdá podmínka části 5:
>
> **Automation account v sobě vytvoří managed identitu, a ta vznikne jako service principál
> v tenantu té subscription.** Nedá se „nakonsentovat" jinam. Když tedy seznamy založíte
> v jiném tenantu, než kde máte Azure, **nebude komu dát `Sites.Selected`** a část 5
> se nedá dokončit.
>
> Pro kurz to platí samo — subscription je připojená k témuž tenantu jako účty studentů
> (viz [`../../environment.md`](../../environment.md)). **Kdo si to zkouší doma přes víc
> tenantů, ať si to ověří dřív, než založí první seznam.**

- App registrace z [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/)
  se `Sites.Selected` a udělený admin consent.
- Certifikátová identita z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).
- Vlastní web s knihovnou dokumentů a alespoň jedním dokumentem — **v tenantu Azure
  subscription**, viz výše.
- Vlastní Azure resource group `rg-goc223-<jmeno-prijmeni>` (viz [`../../environment.md`](../../environment.md)).

Druhý účet nepotřebujete. Vše projde z vašeho vlastního.

Ta podmínka vypadá jako úřednický detail, ale je to důsledek jedné vlastnosti, kterou
uvidíte v části 4 i 5 — jen z opačné strany:

| | Certifikát (část 4) | Managed identita (část 5) |
|---|---|---|
| Dostane se do cizího tenantu? | **ano**, když je aplikace multitenantní, má tam admin consent a per-site grant | **ne** |
| Proč | certifikát je **secret** — a secret se dá vzít s sebou | **nemá secret**, není co vzít |

**To, co dělá managed identitu bezpečnou, ji dělá nepřenosnou.** Přečtěte si to teď; v části
5 na to narazíte v praxi. Plné srovnání včetně obou cest ven (certifikát v Azure Key Vaultu,
workload identity federation) je v
[`../azure-integration-patterns/comparison-scheduled-runtimes.md`](../azure-integration-patterns/comparison-scheduled-runtimes.md).

## Nastavte si tohle jednou a pak už jen kopírujte

Všechny příkazy v labu používají tyhle proměnné. Nastavte je **na začátku** a do konce
labu se k nim nevracejte — tím zmizí nejčastější zdroj chyb, kdy se člověk v jednom kroku
připojí jako jedna aplikace a grant udělá jiné:

```powershell
$siteUrl    = "https://<tenant>.sharepoint.com/sites/<web>"
$clientId   = "<client-id vasi app registrace z D2>"
$thumbprint = "<thumbprint certifikatu z D2>"
$tenantName = "<tenant>.onmicrosoft.com"

# Nazvy seznamu, ktere zalozite v casti 2
$requestList   = "Zadosti o pristup"
$auditList     = "Audit pristupu"
$targetLibrary = "Dokumenty"
```

Thumbprint (odtisk certifikátu) si nevypisujte z hlavy — vypíše ho tenhle příkaz, včetně
data expirace:

```powershell
Get-ChildItem Cert:\CurrentUser\My |
    Select-Object Subject, Thumbprint, NotAfter
```

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
Connect-PnPOnline -Url $siteUrl `
  -ClientId $clientId -Interactive

New-PnPList -Title $requestList -Template GenericList

Add-PnPField -List $requestList -DisplayName "RequestStatus" -InternalName "RequestStatus" `
  -Type Choice -Choices "Pending","Granted","Rejected","Failed" -AddToDefaultView
Add-PnPField -List $requestList -DisplayName "RequesterEmail" -InternalName "RequesterEmail" `
  -Type Text -AddToDefaultView
Add-PnPField -List $requestList -DisplayName "TargetLibrary" -InternalName "TargetLibrary" `
  -Type Text -AddToDefaultView
Add-PnPField -List $requestList -DisplayName "TargetItemId" -InternalName "TargetItemId" `
  -Type Number -AddToDefaultView
Add-PnPField -List $requestList -DisplayName "RequestedRole" -InternalName "RequestedRole" `
  -Type Choice -Choices "Read","Contribute" -AddToDefaultView
Add-PnPField -List $requestList -DisplayName "DecisionNote" -InternalName "DecisionNote" `
  -Type Note
```

**Ověřte si interní názvy**, ať vás to nezradí až v kroku 7:

```powershell
Get-PnPField -List $requestList | Select-Object Title, InternalName
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
New-PnPList -Title $auditList -Template GenericList

Add-PnPField -List $auditList -DisplayName "Requester"  -InternalName "Requester"  -Type Text -AddToDefaultView
Add-PnPField -List $auditList -DisplayName "Outcome"    -InternalName "Outcome"    -Type Text -AddToDefaultView
Add-PnPField -List $auditList -DisplayName "Detail"     -InternalName "Detail"     -Type Note
Add-PnPField -List $auditList -DisplayName "ProcessedU" -InternalName "ProcessedU" -Type Text -AddToDefaultView

# Rozbit dedeni a nechat clenum jen cteni
Set-PnPList -Identity $auditList -BreakRoleInheritance -CopyRoleAssignments
$members = Get-PnPGroup | Where-Object { $_.Title -like "*Members*" }
Set-PnPListPermission -Identity $auditList -Group $members.Title -RemoveRole "Edit"
Set-PnPListPermission -Identity $auditList -Group $members.Title -AddRole "Read"
```

---

## Část 3 — Identita, která není člověk (15 min)

### Krok 4 — Podívejte se, co vaše aplikace umí

**Co děláme:** zjistíme, **na které weby** vaše aplikace z D2 opravdu má přístup.

**Proč:** protože za chvíli pod ní pustíte operaci, kterou žadatel sám nesmí. A protože
tohle je nejlepší moment na to, aby vám došlo, co `Sites.Selected` znamená: aplikace má
to oprávnění nakonsentované od D2, ale **přístup má jen tam, kde jí ho někdo výslovně dal.**

**Skriptem (PnP):**

```powershell
Connect-PnPOnline -Url $siteUrl `
  -ClientId $clientId -Interactive

# Kdo vsechno ma pristup na TENTO web
Get-PnPEntraIDAppSitePermission

# Nebo naopak: co ma tahle konkretni aplikace
Get-PnPEntraIDAppSitePermission -AppIdentity $clientId
```

Měl by tam být jeden záznam s právem **`Read`** — ten, který jste si udělal v D2. Krok 5
ho povýší na `Write`, takže si ten výpis **schovejte pro porovnání**.

Všimněte si, že se tady připojujeme jako **člověk** (`-Interactive`), ne certifikátem
aplikace. Není to nedůslednost: vypsat, kdo má na web grant, je administrátorská operace
a dokumentace u ní uvádí `Sites.FullControl.All`. Vaše aplikace má jen `Sites.Selected`,
takže **sama sebe vypsat neumí**. Je to první ukázka toho, že *spravovat* oprávnění
a *používat* je jsou dvě různé role.

**Ručně:** Entra → App registrations → vaše aplikace → **API permissions**. Uvidíte
`Sites.Selected` jako **Application** permission se zeleným consentem.

A teď to podstatné: ty dva pohledy, které jste právě viděl, **neříkají totéž**.

| Kde se koukáte | Co uvidíte |
|---|---|
| **Entra → API permissions** | že aplikace **smí** `Sites.Selected`, nakonsentované |
| **`Get-PnPEntraIDAppSitePermission`** | na které weby to **reálně platí** |

Po samotném consentu je první seznam plný a druhý **prázdný**. Aplikace tedy smí pracovat
s vybranými weby, ale vybraný nemá žádný — přesně proto se tomu oprávnění říká *Selected*,
a přesně proto je krok 5 samostatný krok.

Poznámka pro toho, kdo si bude chtít ověřit i první tabulku skriptem: PnP na ni cmdlet
**nemá**, na app role assignments v Entra je portál nebo
`Get-MgServicePrincipalAppRoleAssignment` z modulu Microsoft.Graph. V tomhle labu stačí
portál — consent jste dělal v D2 a jen ho potvrzujete.

### Krok 5 — Dát aplikaci jeden jediný web

**Co děláme:** povýšíme per-site grant z D2 z `Read` na `Write`.

**Proč:** `Sites.Selected` po consentu **nedává přístup nikam** — to je celý její smysl.
Teprve tímto krokem aplikace dostane jeden konkrétní web.

**A proč `Write` a ne hned něco vyššího:** protože least privilege se dělá odspodu.
Začnete na nejužší úrovni, o které si myslíte, že by mohla stačit, a **necháte se vyvrátit**.
Dokumentace popisuje čtyři úrovně takhle:

| Role | Co podle dokumentace dává |
|---|---|
| `Read` | čtení metadat a obsahu |
| `Write` | čtení a **změnu** metadat a obsahu |
| `Manage` | čtení a změnu metadat a obsahu **a správu webu** |
| `FullControl` | plnou kontrolu nad webem a jeho obsahem |

Přidělení přístupu k položce vypadá jako „změna obsahu", takže `Write` je rozumný první
odhad. **V kroku 7 uvidíte, jestli byl správný.** Nepřeskakujte to — právě ten náraz je
na tomhle labu to, co si odnesete.

Tenhle krok **nemá ruční variantu** a nehledejte ji — per-site grant pro `Sites.Selected`
v portálu žádné rozhraní nemá. Není to opomenutí Microsoftu: je to hranice mezi tím, co
člověk naklikává, a tím, co se **uděluje aplikaci**. Proto se to dělá skriptem nebo přes
Graph API.

```powershell
Connect-PnPOnline -Url $siteUrl `
  -ClientId $clientId -Interactive

Grant-PnPEntraIDAppSitePermission -AppId $clientId `
  -DisplayName "<jmeno-prijmeni>-course-app" `
  -Site $siteUrl `
  -Permissions Write

# Overit
Get-PnPEntraIDAppSitePermission
```

---

## Část 4 — Skript na notebooku: funguje, ale držíte certifikát (10 min)

### Krok 6 — Přihlásit se jako aplikace

**Co děláme:** připojíme se app-only, certifikátem, bez jakéhokoli promptu.

**Proč:** tohle je první moment, kdy operaci provádí **aplikace, ne vy**. Všimněte si,
že se neotevře žádné okno s přihlášením.

```powershell
Connect-PnPOnline -Url $siteUrl `
  -ClientId $clientId -Tenant $tenantName `
  -Thumbprint $thumbprint
```

Parametr je `-Thumbprint`, **ne** `-CertificateThumbprint`.

**Teď to ověřte, než pustíte cokoli dalšího.** Tři řádky, které vám ušetří půl hodiny
hádání v kroku 7:

```powershell
# 1. Nejsem to ja? (app-only nema CurrentUser jako clovek)
Get-PnPProperty -ClientObject (Get-PnPWeb) -Property CurrentUser

# 2. Pripojen jako KTERA aplikace a na KTERY web?
Get-PnPConnection | Select-Object Url, ClientId

# 3. Ma prave TENHLE ClientId grant na prave TENHLE web?
Get-PnPEntraIDAppSitePermission
```

> [!WARNING] `Unauthorized` v kroku 7 má skoro vždy jednu ze tří příčin
> A všechny tři odhalí ty tři příkazy výše — proto tu jsou.
>
> | Symptom | Příčina | Kde to opravit |
> |---|---|---|
> | `Unauthorized` už na **čtení** seznamu žádostí | **připojen jako jiná aplikace**, než která má grant — `ClientId` z bodu 2 nesouhlasí s tím z kroku 5 | krok 6 |
> | `Unauthorized`, `ClientId` souhlasí, grant existuje | aplikace **nemá v Entra nakonsentovanou app roli** `Sites.Selected` — per-site grant sám o sobě token neopravňuje | krok 4, ručně v portálu |
> | `Unauthorized`, vše souhlasí, ale jiná URL | grant je na **jiném webu**, než na který jste připojen | krok 5 |
>
> **`Unauthorized` není totéž jako `Access denied`.** *Unauthorized* znamená, že token
> to právo nenese **vůbec** — špatná aplikace nebo chybějící app role. *Access denied*
> znamená správnou identitu s **nedostatečnou úrovní** — to je krok 7b. Když má aplikace
> na web `FullControl` a přesto dostáváte `Unauthorized`, problém je **o vrstvu výš** než
> per-site grant a zvyšování role ho nevyřeší.

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
Invoke-AccessRequestQueue -RequestListTitle $requestList `
  -AuditListTitle $auditList -AllowedLibraryTitle $targetLibrary -WhatIf

# Naostro
Invoke-AccessRequestQueue -RequestListTitle $requestList `
  -AuditListTitle $auditList -AllowedLibraryTitle $targetLibrary
```

Ten první řádek, `. ./Grant-RequestedAccess.ps1`, obsahuje **dvě tečky, které spolu nemají
nic společného** — a stojí za to je rozlišit, protože každá umí selhat jinak.

První tečka je **operátor dot-source**. Znamená „spusť ten skript ve *mém* prostředí, ne ve
svém vlastním". Druhá tečka je součást **cesty** a znamená „aktuální složka".

Proč je ten operátor nutný: bez něj se skript spustí ve vlastním, odděleném prostředí
(child scope), které se po jeho skončení zahodí — a s ním i všechny funkce, které skript
nadefinoval. Na dalším řádku byste pak dostal `Invoke-AccessRequestQueue : The term ... is
not recognized`, přestože skript zjevně proběhl bez chyby. `Grant-RequestedAccess.ps1` je
totiž **knihovna funkcí bez vlastního těla**; dot-source je to, co z ní dělá něco
použitelného. Podrobně, včetně rozdílu proti `&` a `./`:
[`../../day-2/opt-powershell-basics/`](../../day-2/opt-powershell-basics/).

A u té druhé tečky je past, na kterou se v reálném běhu naráží:

> [!WARNING] `./` znamená „v aktuální složce", ne „vedle skriptu" — a chybová hláška to zamlčí
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

### Krok 7b — Narazíte, a to je záměr

`-WhatIf` prošel bez chyby — a to je falešný klid, protože **nic nezapsal**. Naostro
dostanete na `Set-PnPListItemPermission` chybu o přístupu (`Access denied`,
`UnauthorizedAccessException`) a řádek žádosti skončí jako `Failed`.

**Potvrzeno reálným během 2026-09-10: `Write` skutečně nestačí.** Náraz je tedy jistý, ne
hypotéza — plánujte s ním.

**Co se stalo:** přidělení role na položce **rozbíjí dědění oprávnění** a zakládá na ní
nové role assignment. To není „změna obsahu" — to je **správa oprávnění**. A `Write` podle
tabulky v kroku 5 dává jen čtení a změnu metadat a obsahu.

**Jak to opravit — a hlavně jak najít nejužší úroveň, která to splní.** Nezvyšujte hned
na maximum. Vezměte `PermissionId` z výpisu, který jste si schoval v kroku 4, a **zvyšujte
po jednom stupni**:

```powershell
Connect-PnPOnline -Url $siteUrl `
  -ClientId $clientId -Interactive

# PermissionId je v tom vypisu z kroku 4
$perm = Get-PnPEntraIDAppSitePermission -AppIdentity $clientId

# Zkusit Manage
Set-PnPEntraIDAppSitePermission -PermissionId $perm.Id -Permissions Manage
```

Pusťte skript znovu. **Pokud to pořád neprojde, zvyšte na `FullControl`** a zkuste ještě
raz. Do `Ověření` si poznamenejte, **která úroveň to nakonec byla** — to je odpověď, kterou
z labu odnášíte, ne ta, kterou jsem vám napsal dopředu.

Ten krok je nepříjemný a právě proto je v labu. U operace, která přiděluje oprávnění,
skončí hledání **vysoko** — pravděpodobně až na `FullControl`, protože správa oprávnění je
přesně to, co „plná kontrola" znamená.

A tady je věc, kterou si nesmíte splést. To, co jste právě získal, není nízká **úroveň**
oprávnění, ale **úzký rozsah**. `FullControl` na *jeden web* je nesrovnatelně lepší než
`Sites.FullControl.All` na *celý tenant* — a to druhé je přesně to, čemu se tenhle blok
vyhýbá. Vítězství je v tom `Sites.Selected`, ne v té roli.

V [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/) jste si napsal, že
least privilege je nejužší rozsah, **který úlohu splní**, ne nejužší název. Teď víte, proč
tam to slovo *splní* je.

Teprve když projde, zkontrolujte **v SharePointu**, ne jen ve výstupu: uživatel má
u dokumentu roli, řádek je `Granted` a v auditu je záznam.

Zastavte se tu na chvíli a podívejte se, co držíte v ruce. Právě jste odstranil dvě ze tří
věcí z kroku 1: **žádné klikání** a **stopa v auditu**. Ta operace ale pořád stojí na
certifikátu ve vašem úložišti — a ten certifikát:

- musíte někam uložit a chránit,
- jednou vyprší a někdo ho musí vyměnit,
- když se dostane jinam, dostane se s ním i identita,
- a **na serveru, kde to má běžet každou noc, ho musíte mít taky.**

To je ten problém, který řeší Azure. Jdeme na to.

---

## Část 5 — Přenést to do Azure: identita, kterou nemáte kde nechat (20 min)

Než začnete, ověřte tu podmínku z `Předpokladů` — že Azure a SharePoint jsou v témže
tenantu. Když nesedí, poznáte to až v kroku 10 hláškou o nenalezeném service principálu,
a do té doby budete mít hotovou půlku části 5:

```powershell
Connect-AzAccount
(Get-AzContext).Tenant.Id                # tenant Azure subscription
Get-PnPConnection | Select-Object Url    # web, na kterem jste delal casti 1-4
```

Tenant ID SharePointu zjistíte v Entra → **Overview**, nebo z libovolného
`Connect-MgGraph` výpisu. Musí se rovnat.

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

Tím se stalo něco, co na obrazovce nevidíte: vznikl vám v Entra nový **service principal**,
tedy identita patřící té Azure službě. Nemá heslo, nemá certifikát, nemá kde se přihlásit —
a existuje jen tak dlouho, dokud existuje ten Automation account.

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
Connect-PnPOnline -Url $siteUrl `
  -ClientId $clientId -Interactive

Grant-PnPEntraIDAppSitePermission -AppId $mi.AppId `
  -DisplayName "aa-goc223-<jmeno-prijmeni>" `
  -Site $siteUrl -Permissions Write
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
      SiteUrl = $siteUrl
      RequestList = $requestList
      AuditList = $auditList
      AllowedLibrary = $targetLibrary
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

A tady je pointa celého labu. Podívejte se na tělo runbooku: **není v něm certifikát, heslo,
ClientId ani thumbprint.** Jen `Connect-PnPOnline -ManagedIdentity`. A přesto právě provedl
operaci, kterou žadatel sám provést nesmí.

Důležité je pojmenovat to přesně: **nezmizel principál, zmizel secret.** Ta identita pořád
existuje v Entra, pořád má přiřazenou roli i per-site grant, a kdo má Contributor na téhle
resource group, ten pod ní umí runbook spustit. Co zmizelo, je **cokoli, co se dá
zkopírovat, vyexportovat nebo poslat mailem.**

To je celá odpověď na otázku, k čemu je Azure jako platforma pro app-only skripty.

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
- [ ] **Umíte říct, která per-site úroveň to nakonec splnila** a proč `Write` nestačila
      (krok 7b). Tohle je nejdůležitější věta, kterou si z části 3-4 odnášíte.
- [ ] `-WhatIf` neprovede ani jeden zápis.
- [ ] Runbook v Azure udělá **totéž**, a v jeho těle **není žádný secret** (krok 11).
- [ ] Managed identity má **vlastní** per-site grant — `Get-PnPEntraIDAppSitePermission`
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
- **App role assignment selže** (krok 10): potřebuje Global administrator nebo Privileged Role Administrator.
  Bez něj Azure část nedoběhne — nechte studenty spárovat s tím, komu to prošlo, ať to
  aspoň vidí.
- **Není čas na celý lab**: části 1, 4 a 5 jsou jádro (ručně → certifikát → nic).
  Části 2 a 3 se dají dodat hotové skriptem výše.

## Zdroje (Microsoft a PnP)

- [Create an Automation account using the portal](https://learn.microsoft.com/en-us/azure/automation/quickstarts/create-azure-automation-account-portal) — postup i managed identity zapnutá defaultně
- [Manage modules in Azure Automation](https://learn.microsoft.com/en-us/azure/automation/shared-resources/modules) — Browse from Gallery, runtime version, Runtime environment
- [Az.Automation](https://learn.microsoft.com/en-us/powershell/module/az.automation/) — `New-AzAutomationAccount`, `New-AzAutomationModule`, `Import-AzAutomationRunbook`, `Publish-AzAutomationRunbook`, `Start-AzAutomationRunbook`, `Get-AzAutomationJobOutput`, `New-AzAutomationSchedule`, `Register-AzAutomationScheduledRunbook`
- [Connect-PnPOnline](https://pnp.github.io/powershell/cmdlets/Connect-PnPOnline.html) — `-ManagedIdentity` funguje v Automation Runbookech; certifikát je `-Thumbprint`
- [Set-PnPListItemPermission](https://pnp.github.io/powershell/cmdlets/Set-PnPListItemPermission.html) — cmdlet, kterým se elevovaná operace provádí; má **switch** `-SystemUpdate`
- [Set-PnPListItem](https://pnp.github.io/powershell/cmdlets/Set-PnPListItem.html) — pozor, tady `-SystemUpdate` **jako switch neexistuje**, jen `-UpdateType SystemUpdate`
- [Grant-PnPEntraIDAppSitePermission](https://pnp.github.io/powershell/cmdlets/Grant-PnPEntraIDAppSitePermission.html) — per-site grant pro `Sites.Selected`

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
