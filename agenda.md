# Agenda — pořadí bloků

Jediný zdroj pravdy o pořadí modulů. Složky jsou slugy; pořadí drží tato tabulka.

**5 dní · 3–4 bloky/den.** P = povinný, V = volitelný.

## Den 1 — Onboarding, prostředí, mapa API a strategie

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Onboarding & pravidla práce | `day-1/onboarding` | P |
| 2 | Toolchain skriptera: PowerShell 7, Node a CLI *(lab)* | `day-1/toolchain-setup` | P |
| 3 | Mapa API nad M365 a SPO *(cvičení Graph Explorer)* | `day-1/api-landscape` | P |
| 4 | Inženýrské prostředí, VS Code a Copilot *(lab)* | `day-1/vscode-copilot-env` | P |
| 5 | Strategie automatizace & nástrojová mapa *(lab)* | `day-1/automation-strategy` | P |

> [!NOTE] **Nejhustší den kurzu (~6,3 h povinně; ~6,2 h na předinstalované učebně)** —
> součet: onboarding 120 + toolchain 45 + mapa API 45 + VS Code/Copilot 85 +
> strategie 85 min. Přestavěno 2026-09-06 podle ověřeného běhu
> KURZ-26-07-29. Účet i stroj jsou připravené hned (bloky 1-2), mapa API je rozhodovací
> rámec pro zbytek týdne a nese **první hands-on dne** (cvičení Graph Explorer).
> Kompenzace je v dni 5, který vypuštěním SPFx vývoje o blok zlehčel.
>
> Rezerva na nepředvídatelný onboarding (MFA u 25 účtů) leží v bloku 2: na předinstalované
> učebně se zkrátí z 45 na 35 min a lze ho spojit s blokem 1. Při větším skluzu se zkracuje
> výklad bloku 3, **nikdy jeho cvičení** — je to jediný hands-on moment před blokem 5.
> PowerShell do hloubky je na začátku dne 2.

## Den 2 — Oprávnění, PowerShell, Graph engineering & staging

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Oprávnění a consent *(lab: Sites.Selected)* | `day-2/permissions-consent` | P |
| 2 | PowerShell do hloubky *(Lab 1: certifikát, app-only, pracovní weby)* | `day-2/powershell-deep-dive` | P |
| 3 | Microsoft Graph — inženýrské základy | `day-2/graph-fundamentals` | P |
| 4 | Staging prostředí: DEV, TEST, PROD | `day-2/staging-environments` | P |

> [!NOTE] ~6,75 h povinně. Blok 1 (nový 2026-09-06) je krátká rozcvička **těsně před
> prvním app-only přihlášením** v Labu 1 — bez něj si skupina udělí `Sites.FullControl.All`
> a považuje to za normální. Lab 1 dopoledne vytvoří weby `-dev/-test/-prod`, které staging
> odpoledne rovnou používá — žádná mezera přes noc.
>
> Volitelné demo hardware klíče (YubiKey/PIV, +30 min) uvnitř bloku 2 — spouštět jen při
> reálné rezervě.

## Den 3 — Migrace, provisioning & lifecycle

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Skladba migrací *(Lab 2: fileshare → SPO dle JSON plánu + metadata)* | `day-3/migration-patterns` | P |
| 2 | Vzory automatizace zřizování | `day-3/provisioning-patterns` | P |
| 3 | Orchestry integrace & vlastní skripty (simulace) | `day-3/opt-orchestry-integration` | V |
| 4 | Lifecycle & compliance enforcement | `day-3/lifecycle-compliance` | P |

> [!NOTE] Orchestry je volitelný blok (simulace bez licence, leaf node — nic povinného na
> něm nezávisí; stejný model jako v GOC224) — spouští se dle času po provisioningu.

## Den 4 — Azure integrace, SIEM & Clarity

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Azure integrační vzory *(Lab 3: dávkový sync + plánovaný task; change notifications jako instruktorské demo)* | `day-4/azure-integration-patterns` | P |
| 2 | SIEM integrace přes Azure Blob | `day-4/siem-blob-integration` | P |
| 3 | Microsoft Clarity — konfigurace | `day-4/clarity-configuration` | P |

> [!NOTE] Druhý nejhustší den (~6,25 h) — uprostřed týdne, bez onboarding/odchodových
> rizik. Od 2026-09-06 už není nejhustší; tím je den 1 (~6,3 h), zato s rizikem
> nepředvídatelného onboardingu. Change-notifications lab běží jako instruktorské demo (handshake + jedna notifikace),
> plné dokončení je samostudium.

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
