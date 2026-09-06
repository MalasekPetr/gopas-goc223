# Provozní skripty kurzu GOC223

Automatizace životního cyklu kurzového tenantu a Azure prostředí: provisioning studentů → laby → offboarding.
Všechny skripty budou idempotentní (bezpečné spustit opakovaně) a podporovat `-WhatIf` (dry-run) — stejná disciplína jako u GOC224.

> [!IMPORTANT] Identifikátory
> Repo je public. **Žádný skript nebude mít zabudované identifikátory** — tenant GUID, ClientId
> aplikací, cert thumbprint a Azure subscription ID se budou předávat výhradně parametry na
> příkazové řádce. Nikdy je sem nedoplňujte ani necommitujte výstupy s hesly
> (`student-credentials.csv` je gitignored).

> [!NOTE] Stav
> Toto je scaffold — skripty níže jsou plánované (`[PLÁNOVANÉ]`), plné znění vzniká postupně
> během rozpracování dne, ke kterému se vážou (Phase 2 dle `agenda.md`).

## Životní cyklus kurzu (plán)

Cílový tenant: M365 Developer tenant `cloudedu.cz` (viz [`../environment.md`](../environment.md)).
Účty `jmeno.prijmeni@cloudedu.cz` (bez diakritiky, max. 25), licence E5 Developer, role
Global administrator. Jmenný seznam účastníků se skriptům předává jako CSV parametr
z instruktorského kanálu — nikdy není součástí repa.

| Fáze | Skript | API | Váže se k |
|---|---|---|---|
| 1. Účty studentů (vytvoření/reaktivace, E5 licence, role GA) | `New-CourseStudents.ps1` `[PLÁNOVANÉ]` | Graph | `day-1/onboarding` |
| 2. Studentské weby — **jen fallback** (studenti si `-dev/-test/-prod` weby vytváří sami v D1 labu) + seedování úmyslného driftu a demo obsahu do nich | `New-CourseStudentSites.ps1` `[PLÁNOVANÉ]` | PnP | `day-2/powershell-deep-dive`, `day-2/staging-environments` |
| 3. Demo migrační zdrojová data (velké listy, verze, metadata) | `New-MigrationSeedData.ps1` `[PLÁNOVANÉ]` | PnP | `day-3/migration-patterns` |
| 4. Azure prostředky per student (Storage/Blob **gen-purpose v2**, Function App, Event Grid) + **DCR per student** proti sdílenému Log Analytics workspace | `New-CourseStudentAzureResources.ps1` `[PLÁNOVANÉ]` | Az/ARM | `day-4/siem-blob-integration` |
| 5. Offboarding — smazání obsahu a artefaktů studentů (weby, app registrace, Tenant Wide Extensions záznamy) | `Remove-CourseStudentData.ps1` `[PLÁNOVANÉ]` | Graph + PnP | — |
| 6. Offboarding — Azure resource group cleanup | `Remove-CourseStudentAzureResources.ps1` `[PLÁNOVANÉ]` | Az/ARM | — |
| 7. Offboarding — disable sign-in + uvolnění licencí | `Disable-CourseStudents.ps1` `[PLÁNOVANÉ]` | Graph | — |

> [!NOTE] App registrace pro laby si studenti zakládají sami (všichni jsou Global
> administrator — lab v `day-1/automation-strategy`), samostatný provisioning skript pro ně
> není potřeba. O to důležitější je offboarding fáze 5: posbírat a smazat vše, co studenti
> pod GA rolí vytvořili (dle naming konvence z `day-1/onboarding/ways-of-working.md`).

Pořadí offboardingu: **nejdřív 5, pak 6, pak 7** — mazání obsahu vyžaduje ještě licencované
účty a existující resource groups.

## Přihlašování — tři režimy (všechny skripty)

1. **Interactive** (default) — browser/WAM popup. Pozor: popup jde do default browseru;
   pokud v něm běží jiná identita než admin cílového tenantu, auth tiše selže.
2. **`-UseDeviceCode`** — kód zadáte v libovolném browseru/profilu. Řeší problém č. 1.
3. **`-CertificateThumbprint` + `-ClientId` + `-TenantId` (GUID)** — app-only, bez
   jakéhokoli promptu. Doporučeno pro dávkové operace (offboarding = 20+ připojení).

Detailní návod na app registraci a přiřazení permissions je součástí `day-1/automation-strategy`
(lab: registrace app & baseline oprávnění) a `day-5/security-hardening` (rotace secretu →
cert-based auth).

## Demo data

`migration-seed/*` (vzniká s `day-3/migration-patterns`) — **výhradně fiktivní data** pro
migrační a provisioning scénáře. Nikdy sem nenahrávejte reálná zákaznická/personální data.
