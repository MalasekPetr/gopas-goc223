# Comparison · Power Automate flow vs vlastní app-only skript

Doplněk k [`README.md`](README.md). Srovnání hostingů v
[`comparison-scheduled-runtimes.md`](comparison-scheduled-runtimes.md) řeší, **kde** skript
běží. Tenhle soubor řeší otázku, která na kurzu padne skoro vždycky: **„a proč to nenapsat
v Power Automate?"**

Je to legitimní dotaz. Power Automate má většina zákazníků nasazený, umí SharePoint bez
jediné řádky kódu a pro spoustu úloh je správnou odpovědí. Rozhodovací hranice ale existuje
a leží jinde, než se obvykle čeká — ne v tom, co ta která platforma umí, ale **pod čí
identitou to běží**.

## Pozitivní výběr: podle toho, co chcete

| Chci… | Volba |
|---|---|
| **schvalování s UI**, notifikace do Teams, formulářový vstup | **Power Automate** — Approvals a konektory jsou hotové, tohle nepřepisujte |
| **propojit služby, kde nemáte API znalosti** (Outlook, Planner, třetí strany) | **Power Automate** — konektorů je 1 000+ a udržuje je Microsoft |
| **automatizaci, kterou vlastní tým, ne člověk** — přežije odchod autora, běží pod aplikační identitou | **app-only skript** |
| **operaci nad tisíci weby nebo položkami** s throttling-aware retry a měřitelnou propustností | **app-only skript** |
| **auditní stopu, kterou vidí i zadavatel** a která leží ve vašem seznamu, ne v běhové historii flow | **app-only skript** |
| **elevaci oprávnění s kontrolou, kdo o ni smí požádat** | **app-only skript** ([`guide-elevated-op.md`](guide-elevated-op.md)) |

Pointa není „Power Automate je špatný". Pointa je, že **první dvě řádky jsou pro flow
a zbytek ne** — a rozhodující je ta třetí.

## Jak Power Automate dělá elevaci

Tohle je klíčové pochopit, protože je to přesně ta funkce, kterou tady nahrazujeme.

Power Automate nemá „run with elevated privileges" jako přepínač. Elevace se dělá
**sdílením flow s run-only uživateli**, kde konektory zůstanou na vlastníkovi. Microsoft to
popisuje takto:

> „If the flow uses the owner's connection always, the run-only user might not need any
> special role in Dataverse — **they're pressing a button and the flow uses the owner's
> privilege**."

Uživatel tedy zmáčkne tlačítko a operace se provede **pod oprávněním vlastníka flow**.
Funguje to, je to jednoduché a má to tři důsledky, které se projeví až za pár měsíců.

### 1. Automatizaci vlastní člověk, ne tým

Connection patří konkrétnímu uživateli. Elevovaná automatizace tedy visí na osobním účtu
a odchod toho člověka ji zabije — a v tu chvíli nikdo neví, co přesně dělala, protože
run-only uživatelé do ní nevidí.

Obrana existuje a **doporučuje ji sám Microsoft**:

> „Possibly, a dedicated service account or service principal is actually the owner of flows
> for stability, with the two owners as co-owners for maintenance. **Using a service principal
> as primary owner improves governance for critical flows**."

Přečtěte si to ještě jednou. U kritických flow je doporučená architektura **service
principal jako vlastník** — tedy přesně ta aplikační identita, kterou tenhle kurz staví
od druhého dne. Rozdíl je jen v tom, že u flow k ní přidáte navíc vrstvu Power Platform
a její licencování; logika zůstane v designeru, mimo repo a mimo code review.

### 2. Kdo akci vyvolal, nevidí, co se stalo

Run-only uživatel podle dokumentace **nevidí běhovou historii**:

> „Can't display the flow's run history or details of past executions."

U elevované operace je to nepříjemné: zadavatel neví, jestli a co přesně se provedlo, a při
sporu není co doložit. Vlastní skript proti tomu zapisuje audit **do seznamu**, který
zadavatel i auditor vidí (viz [`../lifecycle-compliance/`](../lifecycle-compliance/) k retenci
a neměnnosti audit logů).

### 3. Continuity vs kontrola nad elevací

Aby automatizace přežila dovolenou, přidáte co-ownera. Ten má ale podle dokumentace
**plnou kontrolu** — „full control is given to any co-owner" — takže může elevovanou
operaci libovolně přepsat. Volba je tedy mezi *bus faktorem jedna* a *rozdáním editačních
práv k elevaci*. U app-only skriptu tuhle volbu neděláte: kód je v repu, mění se přes PR,
identita je oddělená od lidí.

## Rozhodovací tabulka

| | **Power Automate flow** | **app-only PowerShell skript** |
|---|---|---|
| Identita, pod kterou to běží | connection **konkrétního uživatele** (nebo service principal, viz výše) | **app registrace** s certifikátem nebo managed identity |
| Co se stane, když autor odejde | connection padne, flow přestane fungovat | nic |
| Kde žije logika | v designeru, mimo repo | v repu, prochází PR a code review |
| Autorizace zadavatele | „kdo je run-only user" | **vaše, explicitní v kódu** |
| Rozsah oprávnění | rozsah konektoru = práva vlastníka | **`Sites.Selected` na jeden web** |
| Auditní stopa | běhová historie flow, zadavatel ji nevidí | **řádek v seznamu**, viditelný a retenčně řízený |
| Testovatelnost | manuální proklikání | **Pester testy**, viz [`solution/Grant-RequestedAccess.Tests.ps1`](solution/Grant-RequestedAccess.Tests.ps1) |
| Throttling a retry | konektor si dělá své | **vaše, měřitelné** ([`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/)) |
| Náklad | licence Power Automate, u části konektorů premium | hosting, u noční dávky **0** ([kalkulátor](../../day-5/performance-cost-capstone/solution/Get-HostingCost.ps1)) |
| Kdy je to lepší volba | **schvalování, notifikace, formuláře, integrace bez API znalostí** | **elevace, dávky, cokoli, co má přežít lidi** |

> [!NOTE] Nesnažte se to postavit proti sobě
> V reálném zákazníkovi běží obojí a je to správně. Rozumná hranice: **flow dělá interakci
> s člověkem** (formulář, schválení, notifikace), **skript dělá privilegovanou operaci**.
> Flow může skript zavolat — pak má člověk UI a operace má aplikační identitu a audit.

## Klíčové rozlišení

- **Osobní connection vs aplikační identita** — první je vázaná na člověka a jeho odchod,
  druhá na tenant. U elevace je to rozdíl mezi dočasným a trvalým řešením.
- **Run-only sharing vs autorizace v kódu** — run-only říká *kdo smí zmáčknout tlačítko*,
  ale rozsah elevace je vždy plné oprávnění vlastníka. Ve vlastním skriptu je autorizace
  i rozsah explicitní a testovatelný.
- **Běhová historie vs auditní seznam** — historii flow vidí vlastník, audit seznam vidí
  i zadavatel a podléhá retenci.
- **Low-code rychlost vs verzovatelnost** — flow postavíte za odpoledne, ale nedostanete ho
  do PR. U elevovaných operací je code review to, co chcete.

## Zdroje (Microsoft)

- [Guide to cloud flow sharing and permissions](https://learn.microsoft.com/en-us/power-automate/guide-to-cloud-flow-sharing-permissions) — run-only vs co-owner, „the flow uses the owner's privilege", service principal jako vlastník kritických flow
- [Share a cloud flow](https://learn.microsoft.com/en-us/power-automate/create-team-flows) — přidání co-ownera a run-only uživatele
- [Manage owners and users in your Microsoft list flows](https://learn.microsoft.com/en-us/sharepoint/dev/business-apps/power-automate/guidance/manage-list-flows) — SharePoint-specifická správa flow
- [Set-PnPListItemPermission](https://pnp.github.io/powershell/cmdlets/Set-PnPListItemPermission.html) — cmdlet, kterým elevovanou operaci provádíme

## Stav produktu / delta

> [!WARNING] Licencování Power Automate neuvádět z hlavy — stav k 2026-09
> Členění na standardní a **premium konektory**, licenční modely (per-user, per-flow,
> Power Automate Premium) a limity počtu běhů se mění nejčastěji z celého tohoto materiálu.
> Tenhle soubor proto **žádná licenční čísla neuvádí** a v tabulce má jen kvalitativní
> „licence Power Automate, u části konektorů premium". Před během ověřit na aktuální
> licenční stránce Power Platform, jestli argument o nákladech pořád platí ve tvaru,
> v jakém ho chcete říct.

> [!WARNING] Ověřit k datu běhu
> Mechanismus run-only sharing a chování connection **provided by flow owner** vs
> **provided by run-only user** ověřit proti
> [guide-to-cloud-flow-sharing-permissions](https://learn.microsoft.com/en-us/power-automate/guide-to-cloud-flow-sharing-permissions).
> Je to nosný argument celého srovnání — kdyby Microsoft zavedl skutečnou elevaci bez
> vazby na vlastníka, tři důsledky výše se mění.
