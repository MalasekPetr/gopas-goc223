# Instructor notes — Kdo má k čemu přístup

## Timing

- 35 min výklad + 40 min lab. Před [`../security-hardening/`](../security-hardening/) —
  reporting přístupů je vstup do auditu, ne naopak.
- SAM část je **10 min uvnitř výkladu**, ne samostatný blok. Demo na plátně.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Zjistit, jestli kurzovní tenant vůbec má SAM.** Podmínka je alespoň jedna přiřazená
  licence **Microsoft Copilot** v tenantu (uživatel nemusí být admin), nebo SAM Plan 1
  add-on. **Copilot Chat na pay-as-you-go tuhle podmínku nesplňuje** — kurzovní tenant
  tedy SAM nejspíš nemá a SAM část jede ze screenshotů. Ověřit, ne předpokládat; pokud
  screenshoty, pořídit je z tenantu, kde SAM je, a **začernit tenant identifikátory**.
- **Pokud SAM je**: nechat org-wide report *Site permissions* proběhnout **předem** — bez
  něj report pro uživatele nejde vytvořit. A počítat s tím, že se dá spustit
  **1× za 30 dní**; když ho vyplýtváte na zkoušku týden před během, na kurzu ho nemáte.
- **Projet celý lab den předem** včetně části A (Entra skupina vložená do SharePoint
  skupiny) a ověřit, že krok 3 skutečně vrací prázdno. Bez toho kontrastu lab nemá pointu.
- Ověřit oprávnění pro `Get-MgUserTransitiveMemberOf` (`GroupMember.Read.All` nebo
  `Directory.Read.All`) a udělat consent předem.
- Ověřit, že studenti smí zakládat bezpečnostní skupiny v Entra (jsou GA, takže ano —
  ale politika tenantu to umí omezit).

## Tripwires

- **Krok 3 musí selhat.** Studenti budou hlásit „nefunguje mi skript". Je to zamýšlené
  a je to jediný okamžik, kdy si zapamatují, proč `transitiveMemberOf`. Nespěchat
  s vysvětlením — nechat je nejdřív říct hypotézu.
- **`Get-PnPGroupMember` vrací i principály typu skupina**, ne jen uživatele. Studenti
  filtrují na `LoginName -like "*upn*"` a skupinu tím zahodí. To je přesně ta chyba,
  kterou dělá většina reálných skriptů na internetu.
- **`memberOf` vs `transitiveMemberOf`** — kdo sáhne po prvním, mine vnořené skupiny.
  U dvouúrovňového vnoření to v labu ještě „skoro" funguje, u reálného tenantu ne.
- **Nesklouznout do výuky oprávnění SharePointu.** Cílovka kurzu ví, co je dědičnost
  a permission level. Blok je o **reportingu**, ne o modelu oprávnění — když se debata
  stočí k „a jak se vlastně dědí", utnout a vrátit se ke skriptu.
- **Dotaz na výkon nad velkým tenantem padne jistě.** Odpověď: reverzní dotaz nemá index,
  je to O(počet webů) na uživatele — a právě proto existuje SAM. Je to dobrý most k SAM
  části, ne odbočka.
- **Nezaměňovat s auditem aplikací.** Tenhle blok je o **lidech**; oprávnění aplikací
  řeší [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/) a
  [`../security-hardening/`](../security-hardening/).

## Vazby

- Dopředu: výstup labu je artefakt do capstone blueprintu
  ([`../performance-cost-capstone/`](../performance-cost-capstone/)) a přímý vstup do
  [`../security-hardening/`](../security-hardening/) — hardening začíná tím, že víte,
  kdo co má.
- Zpět: stránkování a throttling z [`../../day-3/graph-fundamentals/`](../../day-3/graph-fundamentals/),
  UTF-8/CSV z [`../../day-2/powershell-deep-dive/explainer-formats-encoding.md`](../../day-2/powershell-deep-dive/explainer-formats-encoding.md),
  weby `-dev/-test/-prod` z Labu 1. SAM se v kurzu poprvé objevil u Site Attestation
  v [`../../day-3/lifecycle-compliance/`](../../day-3/lifecycle-compliance/) — odkázat
  na to, ať studenti vidí, že je to tentýž produkt.

> [!NOTE] Nový blok (2026-09-06)
> Zaveden na základě zpětné vazby z běhů: „k čemu má tenhle člověk přístup" je nejčastější
> dotaz, který admin dostane, a portál na něj přímou odpověď nedává. Technika vychází
> z produkčního reportingu, ne z dokumentace — proto je důraz na slepá místa, ne na
> vyjmenování cmdletů.
