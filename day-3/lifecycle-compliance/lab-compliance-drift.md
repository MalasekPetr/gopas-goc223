# Lab · Compliance drift report + remediation

> Odhad: 60 min · Režim: simulace | živý tenant

## Cíl

Student rozšíří diff/baseline skript z [`../../day-2/staging-environments/`](../../day-2/staging-environments/) o kontrolu sharing policy driftu a napíše
report rozlišující report-only nález od navrhované (ne automaticky provedené) remediation akce.

## Předpoklady

- Diff/baseline skript z [`../../day-2/staging-environments/`](../../day-2/staging-environments/).
- Sandbox web s úmyslně nastaveným sharing driftem (web-level volnější než org policy by měl
  dovolit, nebo naopak zbytečně restriktivní oproti očekávání).

## Kroky

1. Rozšířit baseline z [`../../day-2/staging-environments/`](../../day-2/staging-environments/) o očekávanou hodnotu external sharing pro daný web.
2. Načíst aktuální sharing nastavení webu a porovnat s baseline i s org-level policy.
3. Report jasně rozlišuje: web odpovídá baseline / web je restriktivnější (OK, jen info) /
   web je otevřenější než dovoluje org policy (violation, nutná akce).
4. Navrhnout (ne provést) remediation krok pro nalezenou violaci — psaný jako by-schválení
   akce, ne automatické provedení.

## Ověření

- [ ] Report rozlišuje tři stavy (odpovídá / restriktivnější OK / porušuje org policy),
      ne jen ano/ne.
- [ ] Remediation krok je navržený ke schválení, skript ho neprovede automaticky bez potvrzení.

## Fallback

Pokud sandbox web s driftem není dostupný, instruktor poskytne statický export dvou
konfigurací (baseline JSON + "aktuální stav" JSON) a lab pokračuje nad těmito soubory.
