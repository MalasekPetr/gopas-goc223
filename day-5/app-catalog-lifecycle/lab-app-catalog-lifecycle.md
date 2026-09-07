# Lab · Životní cyklus řešení v App Catalogu skriptem

> Odhad: 45 min · Režim: živý tenant

## Cíl

Student odskriptuje celý životní cyklus dodaného řešení — nasazení, instalaci, upgrade,
audit oprávnění a odebrání — a má výstup, který se dá pustit proti seznamu webů, ne jen
proti jednomu.

> [!NOTE] Balíček dodává instruktor
> `.sppkg` je v tomto labu **black box od dodavatele** — přesně jako v reálném provozu.
> Nesestavujete ho, posuzujete ho. Vývoj SPFx v tomto kurzu není.

## Předpoklady

- PnP PowerShell a připojení k tenantu s `-ClientId` (viz
  [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/)).
- Dva `.sppkg` balíčky od instruktora: **verze 1.0.0 a 1.1.0 téhož řešení**.
- Site collection app catalog povolený na vlastním sandbox webu (viz `instructor-notes.md`).

## Kroky

### Část A — nasazení a instalace

1. Zjistit, co v katalogu už je, **než něco přidáte**:

   ```powershell
   Get-PnPApp -Scope Tenant | Select-Object Title, AppCatalogVersion, InstalledVersion, Deployed
   ```

   Poznamenat si výstup — na konci labu ho porovnáte.

2. Nahrát verzi 1.0.0 do **site collection app catalogu vlastního webu** a publikovat.
3. Nainstalovat řešení na svůj web a ověřit, že je dostupné.

### Část B — upgrade

4. Nahrát verzi 1.1.0 do stejného katalogu.
5. **Před** `Update-PnPApp` spustit `Get-PnPApp` znovu a odpovědět: co ukazuje
   `AppCatalogVersion` a co `InstalledVersion`? Proč se liší, když je nová verze nahraná?
6. Spustit upgrade na svém webu a ověřit, že se `InstalledVersion` srovnala.

### Část C — audit oprávnění

7. Vypsat, co má tenant schválené a co čeká na schválení:

   ```powershell
   Get-PnPTenantServicePrincipalPermissionGrants
   Get-PnPTenantServicePrincipalPermissionRequests
   ```

8. Odpovědět písemně (dvě věty, jde do commit message): kdyby vaše řešení dostalo
   `Sites.Read.All`, **které jiné řešení v tenantu by ho mohlo použít** a proč.

### Část D — skript, ne klikání

9. Napsat `scripts/Get-AppInventory.ps1`, který pro **seznam webů** (parametr, ne natvrdo)
   vrátí objekty s `SiteUrl`, `Title`, `AppCatalogVersion`, `InstalledVersion`
   a spočítaným `NeedsUpdate`. Požadavky:
   - `param()` blok, žádné hardcoded URL ani ClientId;
   - vrací **objekty**, ne `Write-Host` — aby šel výstup poslat do `Export-Csv`;
   - web, ke kterému se nelze připojit, nesmí skript shodit — zaznamenat a pokračovat.

10. Exportovat výstup do CSV pro Excel s českou diakritikou
    (`-Encoding utf8BOM -UseCulture`, viz
    [`../../day-2/powershell-deep-dive/explainer-formats-encoding.md`](../../day-2/powershell-deep-dive/explainer-formats-encoding.md)).

### Část E — úklid

11. Odebrat řešení ze svého webu a odstranit ho z katalogu. Spustit `Get-PnPApp` z kroku 1
    a ověřit, že se výstup shoduje se stavem před labem.

## Ověření

- [ ] Verze 1.0.0 byla nasazená, publikovaná a nainstalovaná na vlastním webu.
- [ ] Student umí vysvětlit rozdíl `AppCatalogVersion` vs `InstalledVersion` z kroku 5
      a proč nahrání do katalogu samo weby neupgraduje.
- [ ] Po `Update-PnPApp` se obě verze shodují na `1.1.0`.
- [ ] `Get-AppInventory.ps1` běží proti alespoň dvěma webům, vrací objekty a **nespadne**
      na webu, ke kterému se nelze připojit (ověřit záměrně chybnou URL v seznamu).
- [ ] CSV export se v Excelu otevře se správnou diakritikou a rozdělený do sloupců.
- [ ] Odpověď z kroku 8 je v commit message a jmenuje sdílený service principal.
- [ ] Po části E je stav katalogu shodný se stavem před labem.

> [!NOTE] Referenční řešení
> [`solution/Get-AppInventory.ps1`](solution/Get-AppInventory.ps1) + **12 testů**.
> Otevřete až po vlastním pokusu. Jeden test tvrdí, že skript **nic nemění** — kdyby ho
> někdo „vylepšil" o automatický upgrade, spadne. Jiný fixuje, že `1.10.0` je vyšší než
> `1.9.0`; textové porovnání by tvrdilo opak a upgrade na verzi 1.10 by nikdo neviděl.

## Fallback

- **Site collection app catalog nejde na některém webu zapnout**: student nahraje balíček
  do tenant App Catalogu pod názvem dle naming konvence (`<jmeno-prijmeni>-<reseni>`)
  a v části E ho odstraní. Instruktor na to musí dohlédnout — 25 lidí ve sdíleném tenant
  katalogu je zdroj kolizí.
- **Instruktor nemá dvě verze balíčku**: část B lze odjet jako demo na plátně; části C a D
  jsou na verzích nezávislé a jsou to ty, které nesou výukovou hodnotu.
- **Časový skluz**: vypustit část D kroky 9-10 a zadat je jako samostudium — ale části C
  (audit oprávnění) se nevzdávat, ta se váže na
  [`../security-hardening/`](../security-hardening/) hned v následujícím bloku.
