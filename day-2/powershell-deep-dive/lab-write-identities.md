# Mini-lab (volitelný) · Tři podpisy zápisu: UI vs delegated vs app-only

> Odhad: 25 min · Režim: živý tenant, zápis **jen na vlastní `-dev` web**
> Typ: **volitelný** — spouští se jen při reálné rezervě po Labu 1; jinak zadat
> jako samostudium na večer. Nic povinného na něm nezávisí.

## Cíl

Zapsat do téhož SharePoint seznamu třemi cestami — ručně přes UI, skriptem
s **delegated** přihlášením a skriptem **app-only** — a na sloupci „Vytvořil"
na vlastní oči vidět, jak se každá cesta podepisuje. Vizuální důkaz identity osy
celého kurzu: kdo zapsal, je v SharePoint Online (SPO) navždy vidět (a je to argument pro auditovatelnost
automatizace, který se hodí i mimo učebnu).

## Předpoklady

- Dokončený Lab 1 ([`lab-cert-auth-sites.md`](lab-cert-auth-sites.md)): web `-dev`,
  certifikát, funkční app-only připojení.
- App registrace z [`../automation-strategy/lab-app-registration.md`](../automation-strategy/lab-app-registration.md)
  s application permission `Sites.FullControl.All` (SharePoint) přidaným v Labu 1.

## Kroky

1. **Připravit seznam**: na vlastním webu `-dev` založit seznam `Zapisy`
   (stačí UI: *New → List*, jen výchozí sloupec Title).
2. **Zápis přes UI**: v prohlížeči přidat položku s Title `Zapis pres UI`.
3. **Delegated oprávnění pro aplikaci**: app registrace zatím umí za uživatele jen číst
   (`Sites.Read.All`) — přidat *API permissions → SharePoint → **Delegated** →
   `AllSites.Write`* + admin consent, se zapsaným zdůvodněním (přesně tohle najde audit
   v [`../../day-5/security-hardening/`](../../day-5/security-hardening/)). Všimnout si
   názvosloví: delegated se jmenuje `AllSites.Write`, application `Sites.FullControl.All` —
   dvě dlaždice, dvě jména (viz [`troubleshooting-auth.md`](troubleshooting-auth.md)).
4. **Zápis delegated** — přihlášený je člověk, aplikace jedná jeho jménem:

   ```powershell
   Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<jmeno-prijmeni>-dev" `
     -ClientId $clientId -Interactive
   (Get-PnPAccessToken -ResourceTypeName SharePoint -Decoded).Claims |
     Where-Object Type -eq 'upn' | Select-Object -ExpandProperty Value    # = prihlaseny uzivatel
   Add-PnPListItem -List "Zapisy" -Values @{ Title = "Zapis delegated" }
   ```

5. **Zápis app-only** — jedná aplikace sama za sebe:

   ```powershell
   Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<jmeno-prijmeni>-dev" `
     -ClientId $clientId -Tenant "<tenant>.onmicrosoft.com" -Thumbprint $thumbprint
   (Get-PnPAccessToken -ResourceTypeName SharePoint -Decoded).Claims |
     Where-Object Type -in 'roles','upn' | Select-Object Type, Value   # role ano, upn ne
   Add-PnPListItem -List "Zapisy" -Values @{ Title = "Zapis app-only" }
   ```

6. **Porovnat podpisy** — v UI přidat do zobrazení sloupec **Vytvořil** (Created By),
   nebo skriptem:

   ```powershell
   Get-PnPListItem -List "Zapisy" -Fields Title, Author | ForEach-Object {
     [pscustomobject]@{
       Title    = $_.FieldValues.Title
       Vytvoril = $_.FieldValues.Author.LookupValue
     }
   }
   ```

   Očekávaný výsledek:

   | Title | Vytvořil |
   |---|---|
   | Zapis pres UI | jméno studenta |
   | Zapis delegated | jméno studenta |
   | Zapis app-only | **`<jmeno.prijmeni>-course-app`** |

7. **Vyvodit**: UI i delegated nesou **jméno člověka** (delegated = aplikace jedná jeho
   jménem a s jeho právy — proto byl v kroku 4 v tokenu `upn`); app-only nese **jméno
   aplikace** (v tokenu `roles`, žádný uživatel). Automatizace tedy v SPO zanechává
   vlastní, odlišitelnou a auditovatelnou stopu — a v migračních scénářích to má přímý
   důsledek: obsah přenesený app-only identitou je v metadatech podepsaný aplikací,
   ne původním autorem (proto migrační nástroje řeší zachování `Author`/`Editor` zvlášť,
   viz [`../../day-3/migration-patterns/`](../../day-3/migration-patterns/)).

## Ověření

- [ ] Seznam `Zapisy` obsahuje tři položky se třemi podpisy dle tabulky (dvě se jménem
      studenta, jedna se jménem aplikace).
- [ ] Student umí u delegated i app-only zápisu ukázat odpovídající důkaz v tokenu
      (`upn` vs `roles`).
- [ ] Delegated `AllSites.Write` má zapsané zdůvodnění pro audit v D5.

## Fallback

Pokud delegated consent nebo `-Interactive` přihlášení selže (public client platforma,
viz [`troubleshooting-auth.md`](troubleshooting-auth.md)), provést jen UI + app-only
větev — hlavní kontrast (člověk vs aplikace ve sloupci Vytvořil) zůstává zachován.
