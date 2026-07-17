# Instructor notes — PowerShell do hloubky

## Timing

- 45 min výklad + 60 min lab. Instalace tří modulů může zabrat 10-15 minut na pomalejší síti —
  pustit instalaci na pozadí hned na začátku bloku.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že app registrace z M1.2 má `-ClientId` funkční pro PnP interaktivní přihlášení —
  od 9. 9. 2024 PnP.PowerShell vyžaduje vlastní ClientId, sdílené výchozí už nefunguje.
- Připravit jeden certifikát (self-signed stačí) předem pro demonstraci certificate auth flow —
  generování na místě zabírá čas a je zdroj chyb.
- Pokud v učebně není druhé zařízení pro device code test, mít připravený telefon/tablet jako
  záložní "druhé zařízení" pro demo.

## Tripwires

- Studenti si pletou `-ClientId` aplikace s `-TenantId` — zdůraznit rozdíl hned na začátku.
- Nenechat studenty ukládat certifikát/private key do repozitáře — i v labu, i "jen na chvíli".
- SPO modul v PowerShell 7 potřebuje `-UseWindowsPowerShell` při importu na některých verzích —
  mít na slidu jako rychlou opravu, pokud `Import-Module` selže.

## Vazby

- Dopředu: `Connect-CourseTarget` wrapper z tohoto labu se znovupoužívá po celý zbytek kurzu
  (D2 Graph ingest, D3 provisioning, D4 Azure integrace).
- Zpět: navazuje na app registraci a auth strategii z M1.2.
