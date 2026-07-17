# Agenda — pořadí bloků

Jediný zdroj pravdy o pořadí modulů. Složky jsou slugy; pořadí drží tato tabulka.

**5 dní · 3 bloky/den.** P = povinný, V = volitelný.

## Den 1 — Inženýrské prostředí a strategie automatizace

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Inženýrské prostředí, VS Code a Copilot | `day-1/vscode-copilot-env` | P |
| 2 | Strategie automatizace & nástrojová mapa | `day-1/automation-strategy` | P |
| 3 | PowerShell do hloubky | `day-1/powershell-deep-dive` | P |

> [!NOTE] Den 1 buduje inženýrské základy: prostředí a návyky (VS Code, Git, Copilot), rozhodovací rámec „který nástroj kdy" a hloubkový PowerShell — vše, na čem stojí zbytek týdne.

## Den 2 — Graph engineering, staging & migrace

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Microsoft Graph — inženýrské základy | `day-2/graph-fundamentals` | P |
| 2 | Staging prostředí: DEV, TEST, PROD | `day-2/staging-environments` | P |
| 3 | Skladba migrací | `day-2/migration-patterns` | P |

> [!NOTE] Graph robustnost (batching/delta/throttling) hned po PowerShell základech z D1 — je to vstupní znalost pro staging diff skripty i migrační exekuci dál v tomtéž dni.

## Den 3 — Provisioning, Orchestry & lifecycle

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Vzory automatizace zřizování | `day-3/provisioning-patterns` | P |
| 2 | Orchestry integrace & vlastní skripty (simulace) | `day-3/orchestry-integration` | P |
| 3 | Lifecycle & compliance enforcement | `day-3/lifecycle-compliance` | P |

> [!NOTE] Provisioning → governance nástroj (Orchestry, simulace) → lifecycle/compliance — přirozený oblouk „jak weby vznikají, jak se řídí, jak zanikají/archivují".

## Den 4 — Azure integrace, SIEM & Clarity

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Azure integrační vzory | `day-4/azure-integration-patterns` | P |
| 2 | SIEM integrace přes Azure Blob | `day-4/siem-blob-integration` | P |
| 3 | Microsoft Clarity — konfigurace | `day-4/clarity-configuration` | P |

> [!NOTE] Azure integrační vzory (Logic Apps/Functions/Event Grid) jsou vstupní znalost pro SIEM pipeline; Clarity je odlehčenější odpolední blok se stejným SPFx injection motivem, který se vrátí v D5.

## Den 5 — SPFx, security hardening & capstone

| # | Blok | Slug | Typ |
|---|---|---|---|
| 1 | SPFx základy & App Catalog | `day-5/spfx-fundamentals` | P |
| 2 | Security hardening & least privilege | `day-5/security-hardening` | P |
| 3 | Výkon, náklady & capstone | `day-5/performance-cost-capstone` | P |

> [!NOTE] SPFx uzavírá kruh s Clarity injection z D4 (App Customizer). Security hardening shrnuje least-privilege vlákno celého týdne (app registrace z D1 → produkční cert-based auth). Capstone spojuje migraci (D2) + provisioning (D3) + integrace (D4) do jednoho end-to-end blueprintu.
