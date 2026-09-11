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

> [!NOTE] **~4,9 h povinně** (295 min: onboarding 120 + toolchain 45 + mapa API 45 +
> VS Code/Copilot 85). Původně 6,3 h včetně bloku `automation-strategy` — ten se
> **2026-09-07 po reálném běhu přesunul na začátek D2**, protože se na něj v D1
> nedostalo. Den je tím zpátky na záměrně volnější podobě, kterou návrh chtěl:
> rezerva kryje nepředvídatelný onboarding s MFA u 25 účtů. Přestavěno podle ověřeného běhu
> KURZ-26-07-29. Účet i stroj jsou připravené hned (bloky 1-2), mapa API je rozhodovací
> rámec pro zbytek týdne a nese **první hands-on dne** (cvičení Graph Explorer).
> Kompenzace je v dni 5, který vypuštěním SPFx vývoje o blok zlehčel.
>
> Rezerva na nepředvídatelný onboarding (MFA u 25 účtů) leží v bloku 2: na předinstalované
> učebně se zkrátí z 45 na 35 min a lze ho spojit s blokem 1. Při větším skluzu se zkracuje
> výklad bloku 3, **nikdy jeho cvičení** — je to jediný hands-on moment před blokem 5.
> PowerShell do hloubky přichází ve dni 2 (blok 3), po strategii a oprávněních.

## Den 2 — Strategie, oprávnění a PowerShell

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Strategie automatizace: nástroje, identita a oprávnění *(lab: app registrace + Sites.Selected)* | `day-2/automation-strategy` | P |
| 2 | PowerShell — základy pro ty, kdo je nemají | `day-2/opt-powershell-basics` | V |
| 3 | PowerShell do hloubky *(Lab 1: certifikát, app-only, pracovní weby)* | `day-2/powershell-deep-dive` | P |

> [!NOTE] ~4,0 h povinně (105 + 135 = 240 min), **5,0 h s volitelným blokem 2**.
> Přestavěno 2026-09-08 po reálném běhu: `graph-fundamentals` odešel na D3, protože se na
> něj ve dni 2 nedostalo. Blok 1 přišel z D1 (2026-09-07) a **sloučil se s bývalým
> `permissions-consent`** — oba mluvily o least privilege a jejich laby pracovaly na téže
> app registraci. `staging-environments` odešlo na D4 na místo vypuštěné Clarity.
>
> Linka dne je jedna app registrace, která dospívá: blok 1 ji vytvoří a dá jí delegated
> i `Sites.Selected`, blok 3 jí přidá certifikát a přihlásí ji app-only. Odolné Graph
> volání nad tou samou aplikací otevírá ráno dne 3. Bloky 1 a 3 si schválně protiřečí —
> Lab 1 potřebuje `Sites.FullControl.All`, protože zakládá weby, a to je ta lekce: least
> privilege je nejužší rozsah, **který úlohu splní**.
>
> **Blok 2 je záchranná síť, ne plnohodnotný blok.** Spouští se jen tehdy, když je skupina
> slabá v základech PowerShellu — což se pozná už u labu bloku 1. Pustit ho je rozhodnutí
> dopoledne druhého dne, ne dopředu; den se tím prodlouží o hodinu a pořád zůstane pod
> stropem. Bez něj se blok 3 pro takovou skupinu nedá odučit.
>
> Volitelné demo hardware klíče (YubiKey/PIV, +30 min) a mini-lab „tři podpisy zápisu"
> (+25 min) uvnitř bloku 3 — jen při reálné rezervě.

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

> [!NOTE] Korektura 2026-09-09: diff/baseline skript nebyl tím, čím ho repo tvrdilo
> Do 2026-09-09 tu stálo, že **diff/baseline skript** ze `staging-environments` je vstupem
> tří labů a že je to „nejvíc znovupoužitý artefakt kurzu". Na tom argumentu se 2026-09-08
> staging vrátil z D4 na D3. **Reálný běh tu vazbu nikdy nevyzkoušel:** staging se odučil
> bez labu, takže skript nevznikl — a provisioning se přesto odučil, jen se ten krok obešel.
>
> Byla to skrytá křehkost: závislost existovala **jen jako studentský výstup**, takže
> vypuštění jednoho volitelného labu tiše bralo vstup dvěma dalším. Oba konzumenti jsou
> proto přeformulovaní tak, že skript **uvítají, ale nevyžadují**. Přesun stagingu na D3
> tím zpětně ztrácí své odůvodnění; **zůstává tam ale i tak**, protože D3 je po rekalibraci
> na 5,1 h a přesun na D4 by ho po jeho přestavbě 2026-09-10 vytáhl na 7,2 h.

> [!NOTE] Den 3: **~5,1 h povinně** (120 + 40 + 45 + 100 = 305 min) + dva volitelné laby
> Rekalibrováno 2026-09-09 podle reálného běhu, který den odučil **podle plánu**, přestože
> repo na něj tehdy počítalo 470 min. Co se skutečně stalo: **staging bez labu** (jen
> výklad) a **Lab 2 vypadl celý** (výklad zkrácen). Oba laby jsou proto od té doby
> **volitelné** a povinné jádro dne je 305 min.
>
> `graph-fundamentals` (120) a `provisioning-patterns` (100) **změřené nejsou** — nesou
> pořád původní odhady, o kterých instruktor řekl, že jsou nafouknuté. Reálné číslo dne
> tedy bude spíš nižší než 5,1 h.
>
> **Položka „ubrat 70 min" tím padá.** D3 je na 5,1 h; D4 se po přestavbě 2026-09-10 drží na 6,5 h.
> Nebyla to kapacita, byly to nafouknuté odhady plus dva laby, které se nestíhají učit.
> Rezerva pod stropem je naopak tak velká, že se do dne vejde zkrácený Lab 2 (~75 min →
> 6,3 h) — je proto **první v řadě**, když čas je.

> [!WARNING] Den 3 nemá v povinné podobě vlastní lab kromě provisioningu
> Cena rekalibrace. Staging lab i Lab 2 jsou volitelné, takže hands-on dne stojí na labu
> `provisioning-patterns`. Na kurzu pro inženýry je to slabina — proto ta rezerva pod
> stropem existuje a proto se Lab 2 (byť volitelný) drží v repu.

## Den 4 — Azure integrace, SIEM a lifecycle

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Azure integrační vzory *(výklad + tutorial nasazení do Azure; Lab 3 dávkový sync 45 min)* | `day-4/azure-integration-patterns` | P |
| 2 | **Elevovaný přístup: self-service žádost o oprávnění** *(step-by-step lab, 13 kroků)* | `day-4/elevated-access` | P |
| 3 | SIEM integrace přes Azure Blob | `day-4/siem-blob-integration` | P |
| 4 | Lifecycle & compliance enforcement | `day-4/lifecycle-compliance` | P |

> [!NOTE] ~6,5 h povinně (80 + 90 + 120 + 100 = 390 min) — **ověřeno reálným během 2026-09-10**
> **Den vyšel podle plánu.** Je to zatím **jediný den, u kterého odhad sedl** — D1, D2 i D3
> se po reálném běhu musely přepočítávat. Přestavba téhož rána (níž) se tedy potvrdila
> i časově, nejen obsahově.
>
> Den 4 byl do té doby **příliš akademický**: mluvil o Azure hostingu a identitách
> a studenti si nic nepostavili. Přestavba to řeší a **vejde se do stropu**:
>
> **Přišel blok 2** [`day-4/elevated-access`](day-4/elevated-access/) (30 výklad + 60 lab)
> — plnohodnotný modul s step-by-step labem, který postaví elevovanou operaci
> a nasadí ji do Azure. Do té doby to bylo 15min demo uvnitř bloku 1.
> **A přišel tutorial** `tutorial-script-to-azure.md` v bloku 1 — krok za krokem, jak
> dostat skript do Azure a spustit ho tam. Nic takového v repu nebylo, přitom o tom byl
> celý den.
>
> **Zaplaceno 70 min z bloku 1** (150 → 80): Lab 3 zkrácen 90 → 45 min (registrace do
> Task Scheduleru odešla do bloku 2, kde se dělá v Azure), demo kopie s metadaty vyjmuto
> z povinného odhadu (README ho už označovalo „mimo agendu" a přitom se počítalo — rozpor),
> výklad 40 → 35 min (srovnání Runbook vs Function je teď v tutoriálu).

> [!NOTE] Change-notifications lab je **celé samostudium**; subscription lifecycle
> zůstává ve výkladu bloku 1.
>
> **Přestavba 2026-09-09:** ~30min instruktorské demo change notifications nahradilo
> **20min demo kopie s metadaty** (`guide-copy-metadata.md`). Z obou je to jediné, které
> reálně zapíše do SharePointu z Functiony běžící v Azure — celý den přitom mluví o Azure
> hostingu. Den se tím zkrátil o 10 min. Nebyl to kapacitní krok — položka „ubrat 70 min"
> padla téhož dne rekalibrací D3 (viz den 3 výše).
>
> **Přestavba 2026-09-08:** třetím blokem byl `staging-environments`; ten se vrátil na D3,
> tehdy kvůli labům, které jeho baseline skript měly potřebovat (odůvodnění 2026-09-09 padlo,
> viz korektura u dne 3). Výměnou sem přišel `lifecycle-compliance`
> z D3. Den se časově nezměnil (oba bloky 100 min) a vazba na staging teď míří správným
> směrem, do předchozího dne. Tematicky to sedí lépe: blok 2 postaví telemetrickou
> pipeline, blok 3 na ní staví governance pravidla.
>
> **Microsoft Clarity byl 2026-09-07 z kurzu vypuštěn.** Z celého týdne to bylo téma
> nejvzdálenější automatizaci a migraci; obecný mechanismus SPFx tenant-wide deploymentu,
> který demonstrovalo, zůstává v `day-5/app-catalog-lifecycle`.

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
