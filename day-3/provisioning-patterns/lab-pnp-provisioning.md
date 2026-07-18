# Lab · Dynamický PnP provisioning artefakt

> Odhad: 60 min · Režim: simulace | živý tenant

## Cíl

Student má parametrizovanou PnP šablonu, kterou lze aplikovat na nový web s metadaty
dodanými za běhu (simulace žádanky), a rozumí, proč provisioning běží pod vyhrazenou
app-only identitou, ne pod osobním Global Admin účtem.

## Předpoklady

- Web sloužící jako "zlatý" vzor (baseline) — může být sandbox z [`../../day-2/staging-environments/`](../../day-2/staging-environments/).
- Vlastní účet (Global administrator, viz [`../../environment.md`](../../environment.md)) —
  `Invoke-PnPTenantTemplate` tuto roli vyžaduje; aplikovat výhradně na vlastní web dle
  naming konvence.

## Kroky

1. `Get-PnPTenantTemplate` — exportovat konfiguraci vzorového webu jako výchozí šablonu.
2. Upravit šablonu — nahradit pevné hodnoty (název listu, popis) tokeny `{parameter:...}`.
3. Omezit rozsah aplikace přes `-Handlers` na relevantní část (např. jen `Lists,Fields`).
4. `Invoke-PnPTenantTemplate` s `-Parameters` simulujícími metadata žádanky (název, vlastník).
5. Ověřit výsledný web proti diff skriptu z [`../../day-2/staging-environments/`](../../day-2/staging-environments/) — má odpovídat zadané baseline.

## Ověření

- [ ] Šablona obsahuje alespoň dva parametrizované tokeny nahrazené za běhu.
- [ ] Aplikace šablony s `-Handlers` omezením neprovede nic mimo zadaný rozsah.
- [ ] Diff skript z [`../../day-2/staging-environments/`](../../day-2/staging-environments/) nehlásí drift mezi výsledným webem a očekávanou baseline.

## Fallback

Pokud aplikace šablony selhává (verze PnP.PowerShell, throttling při 25 souběžných bězích),
student šablonu sestaví a ověří bez reálné aplikace; instruktor aplikaci demonstruje na
projektoru a studenti spouští postupně po menších skupinách místo všichni najednou.
