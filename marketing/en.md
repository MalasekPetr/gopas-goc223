# GOC223 — website content (gopas.eu)

> [!NOTE] Editor note
> Each "##" heading below corresponds to one field on the course page; the text under it is the content for that field. "Editor note" blocks themselves are not page content — do not copy them to the website.
>
> Compared to the currently live page: the title now includes "PowerShell"; the outline is now structured by day (the live page is a flat numbered list 1–15 with no day grouping); the missing opening module "Onboarding & working rules" has been added (entirely absent from the live page); the "Orchestry integration" module is now marked optional (on the live page it appears as a plain numbered item with no marker, and on the current EN page it is additionally mistranslated as "Orchestration integration" — dropping the Orchestry product name entirely); the SPFx module's dev-toolchain description is updated to Heft (the default since SPFx 1.22) instead of the outdated Gulp still shown on the live page; the AZ-204 certification recommendation as a next step has been dropped — the course material itself flags its retirement on 2026-07-31 in favor of the new AI-200.

## URL

`microsoft-365-advanced-automation-and-sharepoint-migration_goc223`

> [!NOTE] Editor note
> Slug unchanged — no redirect needed, preserves existing SEO (search engine optimization) history.

## Course title

Microsoft 365: PowerShell, Advanced Automation, and SharePoint Migration

## Short description (meta description / teaser)

A hands-on five-day course on advanced SharePoint Online automation and migration — PowerShell, Microsoft Graph, and PnP in depth, three large hands-on labs (app-only identity, provisioning, batch sync), governance, Azure integration, and automation identity security, capped off with a capstone blueprint.

## Course overview

This course takes migration and automation engineers through the full cycle of advanced SharePoint Online automation and migration. The week opens with the tooling strategy decision (PowerShell, Microsoft Graph, PnP, REST) and secure automation identity, followed by PowerShell in depth across three production-grade modules, four authentication modes, and the first large lab (certificate, app-only sign-in, scripted work sites). Day three opens with engineering skills on Microsoft Graph - batching, delta query, throttling, and error classification for resilient scripts - and then covers the course's two pillars: migration composition (pre-migration checks, wave planning, cutover tactics) and provisioning automation via the PnP provisioning engine, rounded out with the DEV/TEST/PROD three-environment model and drift detection. Day four connects SharePoint with Azure integration patterns (Logic Apps, Functions, Runbooks, Graph change notifications), a SIEM pipeline from Azure Blob into Log Analytics, and lifecycle and compliance enforcement. The final day covers App Catalog lifecycle management for supplied solutions, permission reporting ("which sites can this person reach"), and security hardening for automation identities, and closes with a capstone blueprint tying migration, provisioning, and Azure integration into a single end-to-end plan with a rollback plan and an operational handoff.

## Who this course is for

- Migration and automation engineers
- Advanced SharePoint Online / Microsoft 365 administrators
- DevOps / platform engineers for governance
- Consultants designing scalable provisioning and migration frameworks

## Prerequisites

- PowerShell basics — if you are unsure, the course levels these up at the start of day two when the group needs it
- Experience administering SharePoint Online
- Azure fundamentals (resource groups, identity)
- Beneficial: JSON/REST literacy, experience with migration tools (SharePoint Migration Tool, ShareGate, and similar)

## Format and duration

- 5 days, instructor-led, with hands-on labs in a test tenant
- Level: advanced

> [!NOTE] Editor note
> Price intentionally omitted — GOPAS sales fills it in directly in the content management system (CMS) and price list.

## Course outline

### Day 1 — Onboarding, Environment & API Map

- **Onboarding & working rules** — entry into the shared training tenant, multi-factor authentication (MFA) registration, and rules for safely collaborating with a larger group of administrators in one environment.
- **The scripter's toolchain** *(lab)* — PowerShell 7, Node, and the CLI for Microsoft 365 command-line tool, VS Code extensions, and version management; the deliverable is your own verification script that reports what the machine is missing.
- **API map across Microsoft 365 (M365) and SharePoint Online (SPO)** *(exercise)* — Azure, Entra ID, Microsoft Graph, and SPO REST on one map, dead layers and their replacements; every participant makes their own first Graph calls in Graph Explorer.
- **Engineering environment, VS Code, and Copilot** *(lab)* — VS Code as the working tool for automation, Git repository hygiene, and responsible use of Microsoft Copilot Chat when writing scripts.

### Day 2 — Strategy, Permissions & PowerShell

- **Automation strategy: tools, identity, and permissions** *(lab)* — choosing between PowerShell, Microsoft Graph, PnP, and REST, designing an automation identity (app registration), delegated vs. application permissions, and `Sites.Selected` instead of a master key.

- **PowerShell in depth** *(large lab)* — the three PowerShell modules (PnP, Graph, SPO) and four authentication modes; lab: certificate, app-only sign-in, scripted creation of work sites.

> Optional, depending on the group's starting level: a **PowerShell fundamentals levelling block** (objects in the pipeline, filtering left, reading cmdlet output) — the instructor runs it when the group needs it, so nobody falls behind on the scripting work that follows.

### Day 3 — Graph, Staging, Migration & Provisioning

- **Microsoft Graph — engineering basics** — batching, delta query, throttling, and error classification for resilient automation scripts.
- **Staging environments: DEV, TEST, PROD** — baseline as a declarative artifact and drift detection between environments. The baseline-versus-drift concept returns in provisioning and in lifecycle and compliance enforcement.
- **Migration composition** — pre-migration checks, wave planning, cutover tactics, large lists and throttling.
- **Provisioning automation patterns** — the PnP provisioning engine, tenant templates, and parameterizing site requests.

> Optional, time permitting: Orchestry integration and custom scripts (unlicensed simulation, designing governance hooks against the PnP/Graph interface).

### Day 4 — Azure Integration, SIEM & Lifecycle

- **Azure integration patterns** *(large lab)* — Logic Apps vs. Functions vs. Runbooks, the Graph change notifications subscription lifecycle; lab: an idempotent batch sync under an application identity, plus a step-by-step walkthrough of getting a script into Azure and running it there.
- **Elevated access: self-service permission requests** *(lab)* — the most commonly built SharePoint automation of all: a user requests access and an application identity grants it. A two-stage authorization gate, `Sites.Selected` narrowed to a single site, audited rejections - and deployment to Azure without a single password.
- **SIEM integration via Azure Blob** — the app → Blob → Event Grid → Function → SIEM logging pipeline, KQL (Kusto Query Language) basics for validation and dashboards.
- **Lifecycle & compliance enforcement** — automating retention and sensitivity, sharing governance, Site Attestation.

### Day 5 — App Catalog, Security Hardening & Capstone

- **App Catalog: deployment, upgrades, and audit** *(lab)* — the administrator's lifecycle for a supplied solution, driven by script: deployment, installation, upgrades across sites, API permission audit, and removal. No SPFx development — the package is a black box from the supplier.
- **Who can access what: permission reporting** *(lab)* — the reverse question "which sites can this person reach, and how was access granted", including access through nested groups; when a script is enough and when SharePoint Advanced Management earns its licence.
- **Security hardening & least privilege** — minimizing scope, Conditional Access for service principals, certificate rotation.
- **Performance, cost & capstone** — API efficiency, logging costs, asynchronous fan-out patterns; a closing blueprint tying migration, provisioning, and Azure integration together with a rollback plan.

## Course outcome

Participants leave with their own end-to-end blueprint for migrating and provisioning SharePoint Online in their organization — including a wave plan, a provisioning artifact, Azure/SIEM integration, a hardened automation identity, and an explicit rollback and operational handoff plan.

## Pre-publish checklist for the editor

- [ ] Fill in the course price (GOPAS sales).
- [ ] Verify current Azure pay-as-you-go (PAYG) and Flex Consumption costs for the Day 4 labs and the availability/lifespan of the M365 Developer Program tenant.
- [ ] Verify the current status of the AZ-204 certification (planned retirement 2026-07-31) and its AI-200 replacement before mentioning next-step study paths in promotional material.
- [ ] Verify the minimum toolchain versions (PowerShell for PnP, Node for CLI for Microsoft 365) before they go into the text.
- [ ] Check that no "Editor note" block was left copied into the published text.
