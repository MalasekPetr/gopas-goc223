# Instructor notes — Lifecycle & compliance enforcement

## Timing

- 40 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Připravit v sandboxu úmyslný sharing drift (web-level nastavení odchýlené od org policy)
  pro demonstraci — ověřit den předem, že drift je skutečně přítomný a rozpoznatelný.
- Ověřit, zda kurzový tenant má SharePoint Advanced Management licenci pro živou ukázku Site
  Attestation — pokud ne, připravit screenshoty/nahrávku jako náhradu.

## Tripwires

- Zdůraznit rozdíl report-only vs auto-remediation — auto-remediation bez review je riziko
  (může "opravit" záměrnou výjimku); v ověření labu kontrolovat, že student remediation
  jen navrhuje, neprovádí automaticky.
- Připomenout, že web-level sharing setting nemůže obejít restriktivnější org-level policy —
  časté nepochopení u administrátorů, kteří zkouší "povolit to jen na tomto webu".

## Vazby

- Dopředu: compliance drift koncept se vrací v D4 (SIEM logging pro audit trail) a v capstone
  (M5.3).
- Zpět: navazuje na baseline/diff z M2.2 a governance artefakty (attestace, sprawl) z M3.2 —
  Site Attestation je zde nativní Microsoft ekvivalent k Orchestry simulaci.
