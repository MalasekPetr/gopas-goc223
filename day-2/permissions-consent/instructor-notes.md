# Instructor notes — Oprávnění a consent

## Timing

- 25 min výklad + 25 min lab. Otvírák dne 2, bezprostředně před
  [`../powershell-deep-dive/`](../powershell-deep-dive/), kde aplikace poprvé dostane
  certifikát a přihlásí se app-only.
- **Krátký blok schválně.** Není to přednáška o identitě — je to rozcvička, která má
  zabránit tomu, aby si za hodinu 25 lidí udělilo `Sites.FullControl.All` a považovalo
  to za normální.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Projet celý lab na testovacím účtu den předem** a poznamenat si přesné názvy PnP
  cmdletů pro per-site grant. `Grant-PnPAzureADAppSitePermission` /
  `Get-PnPAzureADAppSitePermission` se mezi verzemi PnP **přejmenovávaly** —
  `Get-Command -Module PnP.PowerShell *SitePermission*` je první věc, kterou udělejte.
- **Ověřit, že `Sites.Selected` je v tenantu vidět** v seznamu SharePoint Application
  permissions. Pokud ne, celý lab padá a je nutný fallback přes Graph.
- Ověřit Object ID service principalu vs App registrace — studenti je zaručeně zamění.
  Mít připravený jednořádkový návod, kde se které bere.

## Tripwires

- **Delegated vs Application záložka.** Nejčastější chyba bloku a příčina `Unauthorized`
  s prázdnou odpovědí v následujícím labu. Ukázat obě záložky vedle sebe na plátně dřív,
  než začnou.
- **Nepřepálit to na „Sites.Selected vždycky".** Hned následující Lab 1 ho použít nemůže
  a skupina si toho všimne. Pointa je *nejužší rozsah, který úlohu splní*, ne jméno
  oprávnění — viz sekce v README.
- **„Dal jsem consent a nic nefunguje" je u `Sites.Selected` správná odpověď.** Krok 4
  labu je na to nastražený schválně — nechat je narazit a teprve pak vysvětlit. Kdo to
  zažije, nezapomene; kdo to jen slyší, zapomene do oběda.
- **Všichni jsou GA, takže consent past neuvidí.** Vyslovit to nahlas jako varování do
  praxe: *test pod adminem neprokáže nic*. Je to jediná věc z tohoto bloku, kterou si
  v kurzovním tenantu nemohou vyzkoušet — o to důrazněji ji říct.
- Debata „proč nemůžu prostě dát FullControl, je to rychlejší" padne skoro jistě.
  Odpověď je věcná: může, a pak je celý zbytek týdne o governance k ničemu, protože
  aplikace obchází dědičnost, sdílení i labely. Neargumentovat morálkou, argumentovat
  tím, co se stane při úniku certifikátu.
- Nesklouznout do Conditional Access ani do obsahových oprávnění (skupiny, dědičnost) —
  tenhle blok je **o aplikacích**, ne o lidech. Reporting přístupů lidí je
  [`../../day-5/permission-discovery/`](../../day-5/permission-discovery/).

## Vazby

- Dopředu: [`../powershell-deep-dive/`](../powershell-deep-dive/) hned navazuje
  certifikátem a app-only přihlášením. **Lab 1 tam vědomě používá `Sites.FullControl.All`** —
  zakládá site collections a vypisuje tenant, což `Sites.Selected` neumí. Je to
  protipříklad, ne rozpor: nejdřív se naučí nejužší oprávnění, hned nato úloha, kde
  nestačí. Nechat je na to přijít samostatně, otázka „a proč tady ne Sites.Selected?"
  je nejlepší možný začátek Labu 1. Audit uděleného consentu se vrací v
  [`../../day-5/security-hardening/`](../../day-5/security-hardening/) a v
  [`../../day-5/app-catalog-lifecycle/`](../../day-5/app-catalog-lifecycle/)
  (API access u SPFx je tentýž problém na jiném objektu).
- Zpět: staví na app registraci z
  [`../automation-strategy/`](../automation-strategy/) — ta byla
  záměrně jen delegated, aby tenhle blok měl co přidat.

> [!NOTE] Nový blok (2026-09-06)
> Zaveden proto, že kurz kázal least privilege a jeho první app-only lab přitom uděloval
> `Sites.FullControl.All`. Lab 1 v [`../powershell-deep-dive/`](../powershell-deep-dive/)
> byl současně opraven na `Sites.Selected`.
