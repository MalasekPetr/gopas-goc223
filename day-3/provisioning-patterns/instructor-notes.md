# Instructor notes — Vzory automatizace zřizování

## Timing

- 40 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- `Invoke-PnPTenantTemplate` vyžaduje Global Administrator roli — rozhodnout předem, jak toto
  v kurzovém tenantu vyřešit: (a) dočasná role per student jen na dobu labu (riziko: Global
  Admin je nejvyšší role v tenantu, odebrat hned po labu), nebo (b) instruktor aplikuje šablony
  na projektoru pod jednou instruktorskou identitou, studenti jen sestavují a validují šablonu.
  Doporučení: (b) je bezpečnější výchozí volba pro skupinu, kterou neznáte.
- Připravit "zlatý" vzorový web s reprezentativní konfigurací předem, ne nechat studenty
  budovat vzor od nuly — cíl labu je práce se šablonou, ne návrh webu.

## Tripwires

- Zdůraznit napětí Global Admin požadavku vs. least-privilege téma z [`../../day-1/automation-strategy/`](../../day-1/automation-strategy/)/[`../../day-5/security-hardening/`](../../day-5/security-hardening/) — je to
  záměrný teaching point, ne opomenutí kurikula.
- `-Handlers All` aplikuje kompletně vše ze šablony včetně věcí, co student nechtěl — trvat na
  explicitním omezení rozsahu.

## Vazby

- Dopředu: navazuje `orchestry-integration` jako alternativní/doplňkový přístup ke
  stejnému problému (žádanky, metadata, governance).
- Zpět: baseline/diff koncept z [`../../day-2/staging-environments/`](../../day-2/staging-environments/) se zde používá jako zdroj šablony i jako ověření výsledku.
