# Agenda — pořadí bloků

Jediný zdroj pravdy o pořadí modulů. Složky jsou slugy; pořadí drží tato tabulka.

**5 dní · 3–4 bloky/den.** P = povinný, V = volitelný.

## Den 1 — Onboarding, prostředí a strategie automatizace

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Onboarding & pravidla práce | `day-1/onboarding` | P |
| 2 | Architektonický přehled: Azure, Entra ID, M365, Graph, SPO REST | `day-1/opt-architecture-overview` | V |
| 3 | Inženýrské prostředí, VS Code a Copilot | `day-1/vscode-copilot-env` | P |
| 4 | Strategie automatizace & nástrojová mapa | `day-1/automation-strategy` | P |

> [!NOTE] Záměrně volnější den (~5,2 h povinně): onboarding s MFA u 25 účtů je časově
> nepředvídatelný a jeho přetečení absorbuje rezerva + volitelný blok 2 (první, co při
> skluzu padá). PowerShell do hloubky se přesunul na začátek dne 2.

## Den 2 — PowerShell, Graph engineering & staging

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | PowerShell do hloubky *(Lab 1: certifikát, app-only, pracovní weby)* | `day-2/powershell-deep-dive` | P |
| 2 | Microsoft Graph — inženýrské základy | `day-2/graph-fundamentals` | P |
| 3 | Staging prostředí: DEV, TEST, PROD | `day-2/staging-environments` | P |

> [!NOTE] Lab 1 dopoledne vytvoří weby `-dev/-test/-prod`, které staging odpoledne rovnou
> používá — žádná mezera přes noc.

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

> [!NOTE] Vědomě nejhustší den kurzu (~6,25 h) — uprostřed týdne, bez onboarding/odchodových
> rizik. Change-notifications lab běží jako instruktorské demo (handshake + jedna notifikace),
> plné dokončení je samostudium.

## Den 5 — SPFx, security hardening & capstone

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | SPFx základy & App Catalog | `day-5/spfx-fundamentals` | P |
| 2 | Security hardening & least privilege | `day-5/security-hardening` | P |
| 3 | Výkon, náklady & capstone *(elastický blok 60–120 min)* | `day-5/performance-cost-capstone` | P |

> [!NOTE] Záměrně volnější závěr (~4,7–5,7 h): studenti občas odcházejí o 1–2 h dřív.
> Capstone je elastický — při zkrácení se prezentace mění na pair-share a konsolidace na
> jednostránkový blueprint; jádro (propojení artefaktů + rollback plán) zůstává vždy.
