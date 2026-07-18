# Instructor notes — SPFx základy & App Catalog

## Timing

- 45 min výklad + 75 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit kompatibilní verzi Node LTS s aktuální verzí `@microsoft/generator-sharepoint` den
  předem na všech studentských strojích — nesoulad verzí je nejčastější zdroj scaffolding
  chyb a je time-consuming řešit na místě.
- Rozhodnout: nový Heft toolchain (default od SPFx 1.22), nebo `--use-gulp` kvůli konzistenci
  s jiným materiálem/staršími zvyklostmi skupiny — sladit slidy a přesné příkazy předem,
  neimprovizovat mezi `heft`/`gulp` příkazy za běhu výkladu.
- Předem povolit Site Collection App Catalog na sandbox webech, pokud studenti nemají
  tenant-wide admin oprávnění (viz Fallback v labu).

## Tripwires

- SPFx build systém je přísně verzově provázaný — pokud něco nesedí (Node/SPFx/TypeScript),
  chybové hlášky bývají neintuitivní; mít připravený working combo jako referenci.
- Nezapomenout na "trust" krok (make available to all sites) — nahrání bez tohoto potvrzení
  vypadá jako úspěch, ale řešení nejde použít.

## Vazby

- Dopředu: SPFx app registrace/permissions (pokud webpart volá Graph/SPO) se řeší v
  `security-hardening`.
- Zpět: navazuje na tenant-wide deployment mechanismus (Tenant Wide Extensions) poprvé
  viděný v `clarity-configuration` — zde se staví od nuly vlastní řešení.
