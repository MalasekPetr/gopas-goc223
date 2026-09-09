# Lab · Compliance drift report + remediation

> Odhad: 60 min · Režim: simulace | živý tenant

## Cíl

Student napíše kontrolu driftu sharing policy a report, který rozlišuje report-only nález
od navrhované (ne automaticky provedené) remediation akce. Koncept baseline a driftu je
z výkladu [`../../day-3/staging-environments/`](../../day-3/staging-environments/); kdo má
z jeho **volitelného** labu hotový diff skript, nabalí to na něj a ušetří si strukturu
reportu.

## Předpoklady

- Koncept baseline vs drift z výkladu [`../../day-3/staging-environments/`](../../day-3/staging-environments/).
  Hotový diff skript z jeho volitelného labu je **výhoda, ne podmínka** — bez něj se
  baseline pro tenhle lab zapíše jako pár řádků JSON (očekávaná sharing hodnota pro web),
  což je stejně všechno, co kroky níž potřebují.
- Sandbox web s úmyslně nastaveným sharing driftem (web-level volnější než org policy by měl
  dovolit, nebo naopak zbytečně restriktivní oproti očekávání).

## Kroky

1. Zapsat baseline: očekávaná hodnota external sharing pro daný web (JSON). Kdo má diff
   skript z [`../../day-3/staging-environments/`](../../day-3/staging-environments/),
   rozšíří jeho baseline o tuhle hodnotu místo psaní nové.
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
