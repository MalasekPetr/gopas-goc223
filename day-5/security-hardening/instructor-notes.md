# Instructor notes — Security hardening & least privilege

## Timing

- 40 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Připravit přehled permissions přiřazených app registraci z [`../../day-1/automation-strategy/`](../../day-1/automation-strategy/) v průběhu týdne (pokud
  studenti sami neevidovali) — pomůže s auditem, když si student na začátek týdne
  nepamatuje přesně.
- Ověřit, že vygenerování self-signed certifikátu a jeho nahrání na app registraci funguje
  v kurzovém prostředí bez blokace (firewall/policy).

## Tripwires

- Trvat na pořadí "nahrát nový cert → ověřit → teprve pak smazat secret", ne obráceně —
  to je přesně bod labu (zero-downtime rotace).
- Nezaměňovat Conditional Access na service principal (musí být přiřazená přímo, ne přes
  skupinu) s CA na uživatele (skupiny fungují běžně) — časté nedorozumění.

## Vazby

- Dopředu: hardening app registrace je vstup do `performance-cost-capstone`
  blueprintu.
- Zpět: navazuje na auth módy z [`../../day-1/powershell-deep-dive/`](../../day-1/powershell-deep-dive/) a app registration strategii z [`../../day-1/automation-strategy/`](../../day-1/automation-strategy/) — uzavírá
  least-privilege vlákno celého týdne.
