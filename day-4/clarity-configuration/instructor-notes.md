# Instructor notes — Microsoft Clarity — konfigurace

## Timing

- 35 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, zda studenti (nebo instruktor) mají v kurzovém tenantu oprávnění k App Catalogu —
  typicky vyžaduje SharePoint Administrator/Global Admin, stejné rozhodnutí jako u jiných
  admin-scope labů v týdnu (viz M3.1 go/no-go).
- Připravit vlastní/testovací Clarity projekt s Project ID předem, ne zakládat na místě.
- Ověřit aktuální dobu aktivace (dokumentovaných "až 20 minut") — pokud je delší, naplánovat
  aktivaci na začátek bloku a ověřovat výsledek až ke konci.

## Tripwires

- Zdůraznit, že Microsoft dokumentuje jen organization-wide instalaci jako podporovanou —
  nenechat studenty navrhnout řešení "jen na jeden web" jako primární variantu.
- Cookie/souhlas krok musí být v rollout plánu **před** technickou aktivací — v ověření
  labu na to explicitně dávat pozor.

## Vazby

- Dopředu: SPFx tenant-wide deployment mechanismus (Tenant Wide Extensions list,
  `skipFeatureDeployment`) se dokončuje v `spfx-fundamentals` (M5.1) na vlastním HelloWorld
  webpartu.
- Zpět: —
