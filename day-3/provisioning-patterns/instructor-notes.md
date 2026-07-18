# Instructor notes — Vzory automatizace zřizování

## Timing

- 40 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- `Invoke-PnPTenantTemplate` vyžaduje Global Administrator roli — v tomto kurzu ji studenti
  **mají** (viz `environment.md`), takže aplikují šablony sami pod vlastním účtem. O to víc
  hlídat rozsah: šablona se aplikuje výhradně na vlastní web dle naming konvence
  ([`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md)),
  nikdy na cizí nebo tenant-wide.
- Připravit "zlatý" vzorový web s reprezentativní konfigurací předem, ne nechat studenty
  budovat vzor od nuly — cíl labu je práce se šablonou, ne návrh webu.

## Tripwires

- Zdůraznit napětí Global Admin požadavku vs. least-privilege téma z [`../../day-1/automation-strategy/`](../../day-1/automation-strategy/)/[`../../day-5/security-hardening/`](../../day-5/security-hardening/) — je to
  záměrný teaching point, ne opomenutí kurikula.
- `-Handlers All` aplikuje kompletně vše ze šablony včetně věcí, co student nechtěl — trvat na
  explicitním omezení rozsahu.

## Vazby

- Dopředu: navazuje `opt-orchestry-integration` jako alternativní/doplňkový přístup ke
  stejnému problému (žádanky, metadata, governance).
- Zpět: baseline/diff koncept z [`../../day-2/staging-environments/`](../../day-2/staging-environments/) se zde používá jako zdroj šablony i jako ověření výsledku.
