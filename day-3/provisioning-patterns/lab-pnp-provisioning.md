# Lab · Dynamický PnP provisioning artefakt

> Modul: M3.1 · Odhad: 60 min · Režim: simulace | živý tenant

## Cíl

Student má parametrizovanou PnP šablonu, kterou lze aplikovat na nový web s metadaty
dodanými za běhu (simulace žádanky), a rozumí, proč provisioning běží pod vyhrazenou
app-only identitou, ne pod osobním Global Admin účtem.

## Předpoklady

- Web sloužící jako "zlatý" vzor (baseline) — může být sandbox z M2.2.
- App registrace s dočasně přiřazenou rolí nutnou pro `Invoke-PnPTenantTemplate` (viz
  `instructor-notes.md` — řešit stejně jako go/no-go v M1.2).

## Kroky

1. `Get-PnPTenantTemplate` — exportovat konfiguraci vzorového webu jako výchozí šablonu.
2. Upravit šablonu — nahradit pevné hodnoty (název listu, popis) tokeny `{parameter:...}`.
3. Omezit rozsah aplikace přes `-Handlers` na relevantní část (např. jen `Lists,Fields`).
4. `Invoke-PnPTenantTemplate` s `-Parameters` simulujícími metadata žádanky (název, vlastník).
5. Ověřit výsledný web proti diff skriptu z M2.2 — má odpovídat zadané baseline.

## Ověření

- [ ] Šablona obsahuje alespoň dva parametrizované tokeny nahrazené za běhu.
- [ ] Aplikace šablony s `-Handlers` omezením neprovede nic mimo zadaný rozsah.
- [ ] Diff skript z M2.2 nehlásí drift mezi výsledným webem a očekávanou baseline.

## Fallback

Pokud role pro `Invoke-PnPTenantTemplate` není v kurzovém tenantu dostupná ani dočasně,
student šablonu sestaví a ověří syntakticky (`Test-PnPTenantTemplate`, pokud dostupné) bez
reálné aplikace; instruktor aplikaci demonstruje na projektoru pod instruktorskou identitou.
