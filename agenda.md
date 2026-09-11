# Agenda — pořadí bloků

Jediný zdroj pravdy o pořadí modulů. Složky jsou slugy; pořadí drží tato tabulka.

**5 dní · 3–4 bloky/den.** P = povinný, V = volitelný.

## Den 1 — Onboarding, prostředí a mapa API

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Onboarding & pravidla práce | `day-1/onboarding` | P |
| 2 | Toolchain skriptera: PowerShell 7, Node a CLI *(lab)* | `day-1/toolchain-setup` | P |
| 3 | Mapa API nad M365 a SPO *(cvičení Graph Explorer)* | `day-1/api-landscape` | P |
| 4 | Inženýrské prostředí, VS Code a Copilot *(lab)* | `day-1/vscode-copilot-env` | P |

**~4,9 h povinně** (295 min: onboarding 120 + toolchain 45 + mapa API 45 + VS Code/Copilot
85). Den je záměrně volnější — rezerva kryje nepředvídatelný onboarding s vícefaktorovým
ověřením (MFA) u 25 účtů. Účet i stroj jsou připravené hned (bloky 1-2), mapa API je
rozhodovací rámec pro zbytek týdne a nese **první hands-on dne** (cvičení Graph Explorer).

Kde se bere čas při skluzu: rezerva leží v bloku 2, který se na předinstalované učebně
zkrátí z 45 na 35 min a lze ho spojit s blokem 1. Při větším skluzu se zkracuje výklad
bloku 3, **nikdy jeho cvičení** — je to jediný hands-on moment dne. PowerShell do hloubky
přichází až ve dni 2.

## Den 2 — Strategie, oprávnění a PowerShell

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Strategie automatizace: nástroje, identita a oprávnění *(lab: app registrace + Sites.Selected)* | `day-2/automation-strategy` | P |
| 2 | PowerShell — základy pro ty, kdo je nemají | `day-2/opt-powershell-basics` | V |
| 3 | PowerShell do hloubky *(Lab 1: certifikát, app-only, pracovní weby)* | `day-2/powershell-deep-dive` | P |

**~4,0 h povinně** (105 + 135 = 240 min), **5,0 h s volitelným blokem 2**.

Linka dne je jedna app registrace, která dospívá: blok 1 ji vytvoří a dá jí delegated
oprávnění i `Sites.Selected`, blok 3 jí přidá certifikát a přihlásí ji app-only. Odolné
Graph volání nad tou samou aplikací otevírá ráno dne 3. Bloky 1 a 3 si přitom schválně
protiřečí — Lab 1 potřebuje `Sites.FullControl.All`, protože zakládá weby, a to je ta
lekce: least privilege je nejužší rozsah, **který úlohu splní**.

**Blok 2 je záchranná síť, ne plnohodnotný blok.** Spouští se jen tehdy, když je skupina
slabá v základech PowerShellu — což se pozná už u labu bloku 1. Pustit ho je rozhodnutí
dopoledne druhého dne, ne dopředu; den se tím prodlouží o hodinu a pořád zůstane pod
stropem. Bez něj se blok 3 pro takovou skupinu odučit nedá.

Volitelné demo hardwarového klíče (YubiKey/PIV, +30 min) a mini-lab „tři podpisy zápisu"
(+25 min) uvnitř bloku 3 — jen při reálné rezervě.

## Den 3 — Graph, staging, migrace & provisioning

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Microsoft Graph — inženýrské základy | `day-3/graph-fundamentals` | P |
| 2 | Staging prostředí: DEV, TEST, PROD *(výklad; lab volitelný)* | `day-3/staging-environments` | P |
| 3 | Skladba migrací *(výklad; Lab 2 fileshare → SPO volitelný)* | `day-3/migration-patterns` | P |
| 4 | Vzory automatizace zřizování | `day-3/provisioning-patterns` | P |
| 5 | Orchestry integrace & vlastní skripty (simulace) | `day-3/opt-orchestry-integration` | V |

> [!NOTE] Orchestry je volitelný blok (simulace bez licence, leaf node — nic povinného na
> něm nezávisí; stejný model jako v GOC224) — spouští se dle času po provisioningu, jehož
> artefakt používá jako cíl.

> [!IMPORTANT] Pořadí bloků 1 a 2 plyne z předpokladů labů, ne z tématu
> [`day-3/migration-patterns/lab-fileshare-migration.md`](day-3/migration-patterns/lab-fileshare-migration.md)
> má retry vzory z `graph-fundamentals` ve **Předpokladech**, proto Graph otevírá den.
> Staging je blok 2, protože jeho **koncept** baseline vs drift se vrací v provisioningu
> i v `day-4/lifecycle-compliance` — ne kvůli artefaktu, viz níž.

**~5,1 h povinně** (120 + 40 + 45 + 100 = 305 min) plus dva volitelné laby: lab stagingu
a Lab 2 (fileshare → SPO). Rezerva pod stropem je dost velká, aby se do dne vešel zkrácený
Lab 2 (~75 min → 6,3 h) — je proto **první v řadě**, když je čas.

Čísla u `graph-fundamentals` (120) a `provisioning-patterns` (100) jsou **neměřené odhady**,
podle instruktora nafouknuté. Reálné číslo dne bude spíš nižší než 5,1 h.

> [!WARNING] Den 3 nemá v povinné podobě vlastní lab kromě provisioningu
> Staging lab i Lab 2 jsou volitelné, takže hands-on celého dne stojí na labu
> `provisioning-patterns`. Na kurzu pro inženýry je to slabina — proto ta rezerva pod
> stropem existuje a proto se Lab 2 (byť volitelný) drží v repu.

## Den 4 — Azure integrace, SIEM a lifecycle

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Azure integrační vzory *(výklad + tutorial nasazení do Azure; Lab 3 dávkový sync 45 min)* | `day-4/azure-integration-patterns` | P |
| 2 | **Elevovaný přístup: self-service žádost o oprávnění** *(step-by-step lab, 13 kroků)* | `day-4/elevated-access` | P |
| 3 | SIEM integrace přes Azure Blob | `day-4/siem-blob-integration` | P |
| 4 | Lifecycle & compliance enforcement | `day-4/lifecycle-compliance` | P |

**~6,5 h povinně** (80 + 90 + 120 + 100 = 390 min). Jediný den, u kterého odhad sedl při
reálném běhu — D1, D2 i D3 se musely přepočítávat.

Blok 1 obsahuje kromě výkladu **tutorial `tutorial-script-to-azure.md`**: krok za krokem,
jak dostat skript do Azure a spustit ho tam. Blok 2 jede tutéž cestu ve svém labu.

Lab change notifications je **celé samostudium**; subscription lifecycle zůstává ve výkladu
bloku 1. Instruktorské demo bloku 1 je kopie dat se zachováním metadat
(`guide-copy-metadata.md`) — z dostupných dem jediné, které reálně zapíše do SharePointu
z Functiony běžící v Azure.

## Den 5 — App Catalog, security hardening & capstone

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | App Catalog: nasazení, upgrady a audit *(lab)* | `day-5/app-catalog-lifecycle` | P |
| 2 | Kdo má k čemu přístup: reporting oprávnění *(lab)* | `day-5/permission-discovery` | P |
| 3 | Security hardening & least privilege | `day-5/security-hardening` | P |
| 4 | Výkon, náklady & capstone *(elastický blok 60–120 min)* | `day-5/performance-cost-capstone` | P |

> [!NOTE] **~5,7–6,7 h.** Volnější závěr zůstal jen zčásti: vypuštění vývoje SPFx ubralo
> 45 min, nový blok 2 (reporting oprávnění) přidal 75. Studenti občas odcházejí o 1–2 h dřív —
> proto je blok 2 před hardeningem, ne za ním, a capstone zůstává elastický.
> Capstone je elastický — při zkrácení se prezentace mění na pair-share a konsolidace na
> jednostránkový blueprint; jádro (propojení artefaktů + rollback plán) zůstává vždy.
