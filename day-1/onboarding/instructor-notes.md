# Instructor notes — Onboarding & pravidla práce

## Timing

- AM blok, ale kratší než celé dopoledne (účty jsou předpřipravené, žádné žonglování
  s rolemi — všichni GA). Největší žrout času je MFA registrace u 25 účtů: rezerva
  minimálně 30 minut jen na ni. Po onboardingu následuje volitelný architektonický
  přehled ([`../opt-architecture-overview/`](../opt-architecture-overview/)) — pokud
  MFA proběhne rychle, je z čeho brát.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Ověřit, že M365 Developer tenant `cloudedu.cz` žije a je obnovený** — Developer Program
  byl v 2024 omezen a obnova sandboxu závisí na aktivitě; kontrola minimálně týden předem,
  ne den před kurzem (obnova/náhrada tenantu se nedá stihnout přes noc).
- Spustit `New-CourseStudents.ps1` (viz [`../../scripts/`](../../scripts/)) s reálným
  seznamem účastníků: účty `jmeno.prijmeni@cloudedu.cz`, E5 licence, role Global
  administrator. Jmenný seznam drží instruktorský kanál, nikdy repo.
- Ověřit MFA enforcement (Conditional Access / security defaults) — musí vynutit registraci
  při prvním přihlášení, ne až někdy později.
- Zkontrolovat zbytky z minulého běhu: weby, app registrace a Tenant Wide Extensions
  záznamy od minulé kohorty mate studenty při hledání vlastních artefaktů.

## Tripwires

- **Neodkládat ways-of-working na později.** Pravidla vyhlásit dřív, než má první student
  otevřené admin centrum — první "zkusím Set-SPOTenant, co to udělá" přijde do 10 minut.
- Diakritika v loginech: `jmeno.prijmeni` je bez diakritiky (jan.novak, ne jan.novák) —
  říct explicitně, studenti to jinak zkouší s diakritikou a hlásí "nefunkční účet".
- Nenechat studenty "opravovat" cizí nedoběhlé MFA — GA role to technicky umožňuje,
  pravidla to zakazují; je to první reálný test pravidel.

## Vazby

- Dopředu: ways-of-working pravidla se vymáhají celý týden; kontrast "všichni GA" vs
  least privilege se vrací v [`../automation-strategy/`](../automation-strategy/) a uzavírá
  v [`../../day-5/security-hardening/`](../../day-5/security-hardening/).
- Zpět: —
