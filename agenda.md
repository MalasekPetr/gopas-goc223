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
> PowerShell do hloubky je na začátku dne 2.

## Den 2 — Strategie, oprávnění, PowerShell a Graph

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Strategie automatizace: nástroje, identita a oprávnění *(lab: app registrace + Sites.Selected)* | `day-2/automation-strategy` | P |
| 2 | PowerShell do hloubky *(Lab 1: certifikát, app-only, pracovní weby)* | `day-2/powershell-deep-dive` | P |
| 3 | Microsoft Graph — inženýrské základy | `day-2/graph-fundamentals` | P |

> [!NOTE] ~6,0 h povinně (105 + 135 + 120 = 360 min). Přestavěno 2026-09-07 po reálném běhu.
> Blok 1 přišel z D1, kde se na něj nedostalo, a **sloučil se s bývalým `permissions-consent`** —
> oba mluvily o least privilege a jejich laby pracovaly na téže app registraci, takže
> spojením zmizel kontextový přesun nad jedním artefaktem (a ušetřilo ~30 min).
> `staging-environments` odešlo na D4 na místo vypuštěné Clarity; bez toho by den vycházel
> na 8,2 h.
>
> Linka dne je jedna app registrace, která dospívá: blok 1 ji vytvoří a dá jí delegated
> i `Sites.Selected`, blok 2 jí přidá certifikát a přihlásí ji app-only, blok 3 nad ní staví
> odolné Graph volání. Bloky 1 a 2 si schválně protiřečí — Lab 1 potřebuje
> `Sites.FullControl.All`, protože zakládá weby, a to je ta lekce: least privilege je
> nejužší rozsah, **který úlohu splní**.
>
> Volitelné demo hardware klíče (YubiKey/PIV, +30 min) a mini-lab „tři podpisy zápisu"
> (+25 min) uvnitř bloku 2 — jen při reálné rezervě.
## Den 3 — Migrace, provisioning & lifecycle

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Skladba migrací *(Lab 2: fileshare → SPO dle JSON plánu + metadata)* | `day-3/migration-patterns` | P |
| 2 | Vzory automatizace zřizování | `day-3/provisioning-patterns` | P |
| 3 | Orchestry integrace & vlastní skripty (simulace) | `day-3/opt-orchestry-integration` | V |
| 4 | Lifecycle & compliance enforcement | `day-3/lifecycle-compliance` | P |

> [!NOTE] Orchestry je volitelný blok (simulace bez licence, leaf node — nic povinného na
> něm nezávisí; stejný model jako v GOC224) — spouští se dle času po provisioningu.

## Den 4 — Azure integrace, SIEM a staging

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Azure integrační vzory *(Lab 3: dávkový sync + plánovaný task; change notifications jako instruktorské demo)* | `day-4/azure-integration-patterns` | P |
| 2 | SIEM integrace přes Azure Blob | `day-4/siem-blob-integration` | P |
| 3 | Staging prostředí: DEV, TEST, PROD | `day-4/staging-environments` | P |

> [!NOTE] ~6,3 h (160 + 120 + 100 = 380 min) — nejhustší den kurzu, ale uprostřed týdne,
> bez onboarding/odchodových rizik. Change-notifications lab běží jako instruktorské demo
> (handshake + jedna notifikace), plné dokončení je samostudium.
>
> **Microsoft Clarity byl 2026-09-07 z kurzu vypuštěn** a jeho slot dostalo
> `staging-environments` z D2. Z celého týdne to bylo téma nejvzdálenější automatizaci
> a migraci; obecný mechanismus SPFx tenant-wide deploymentu, který demonstrovalo, zůstává
> v `day-5/app-catalog-lifecycle`.

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
