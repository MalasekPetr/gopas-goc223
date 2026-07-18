# Lab · Rollout plán + App Customizer injekce (simulace)

> Odhad: 60 min · Režim: simulace | živý tenant

## Cíl

Student má rollout plán (pilotní weby, souhlas/cookie krok, opt-out kritéria) a prakticky
projde nasazení Clarity App Customizeru přes Tenant Wide Extensions list v kurzovém tenantu.

## Předpoklady

- Vlastní/testovací Clarity projekt a Project ID.
- Přístup do App Catalogu kurzového tenantu (nebo instruktorská demonstrace, viz Fallback).

## Kroky

1. Navrhnout rollout plán: pořadí pilotních webů, kdy/jak informovat uživatele (cookie
   banner/souhlas), kritéria pro opt-out konkrétních citlivých webů.
2. V App Catalogu přidat aplikaci Microsoft Clarity, povolit "add it to all sites".
3. V Tenant Wide Extensions listu najít záznam Microsoft Clarity, vložit Project ID do
   Component Properties.
4. Ověřit aktivaci (může trvat až 20 minut) na testovacím webu — zkontrolovat, že tracking
   skript je přítomný.
5. Zdokumentovat, jak by šlo řešení omezit jen na podmnožinu webů (opt-out strategie).

## Ověření

- [ ] Rollout plán obsahuje explicitní krok pro souhlas/cookie banner **před** aktivací,
      ne až po ní.
- [ ] Tenant Wide Extensions záznam obsahuje platné Project ID.
- [ ] Tracking je ověřitelně přítomný alespoň na jednom testovacím webu po aktivaci.

## Fallback

Pokud studenti nemají oprávnění k App Catalogu (typicky vyžaduje SharePoint/Global Admin),
instruktor provede kroky 2-4 na projektoru a studenti připraví jen rollout plán (krok 1) a
opt-out zdokumentování (krok 5) samostatně.
