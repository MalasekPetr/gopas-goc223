# Instructor notes — Microsoft Clarity — konfigurace

## Timing

- 35 min výklad + 60 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Oprávnění nejsou překážka (všichni studenti GA) — ale **App Catalog i Tenant Wide
  Extensions list je v tenantu jen jeden**: instalace Clarity je kolektivní krok, který
  provede instruktor (nebo jeden vybraný student na projektoru) **jednou**, ne 25× paralelně.
  Studenti individuálně dělají rollout plán a opt-out návrh, technickou aktivaci sledují.
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
  `skipFeatureDeployment`) se dokončuje v `spfx-fundamentals` na vlastním HelloWorld
  webpartu.
- Zpět: —
