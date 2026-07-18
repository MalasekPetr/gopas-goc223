# Instructor notes — Architektonický přehled

## Timing

- 30-45 min, bez labu. Spouští se hned po onboardingu, **jen pokud** MFA registrace
  nesežrala rezervu — jinak přeskočit a odkázat studenty na README k samostudiu.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Rozhodnout podle složení skupiny (registrace/předdotazník): skupina samých SPO adminů
  s Azure zkušeností tento blok nepotřebuje; smíšená skupina (konzultanti, DevOps bez M365
  historie) z něj těží nejvíc.

## Tripwires

- Nesklouznout do hloubky auth flows — to je [`../powershell-deep-dive/`](../powershell-deep-dive/);
  tady jen "všechny cesty nesou Entra token".
- Nesklouznout do Graph batching/throttling — to je [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/).
- Držet leaf-node charakter: nic, co tu zazní, nesmí být prerekvizita — pokud se přistihneš,
  že říkáš "tohle budete zítra potřebovat", patří to do povinného modulu, ne sem.

## Vazby

- Dopředu: mapa podkládá [`../automation-strategy/`](../automation-strategy/) (nástrojová
  rozhodovací osa) a [`../powershell-deep-dive/`](../powershell-deep-dive/) (auth) — ale jen
  jako kontext, ne jako závislost.
- Zpět: navazuje na onboarding (tenant vs subscription rozlišení z `environment.md`).
