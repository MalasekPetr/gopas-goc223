# Instructor notes — Security hardening & least privilege

## Timing

- 40 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Připravit přehled permissions přiřazených app registraci z M1.2 v průběhu týdne (pokud
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

- Dopředu: hardening app registrace je vstup do `performance-cost-capstone` (M5.3)
  blueprintu.
- Zpět: navazuje na auth módy z M1.3 a app registration strategii z M1.2 — uzavírá
  least-privilege vlákno celého týdne.
