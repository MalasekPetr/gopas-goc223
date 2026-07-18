# Lab · Certifikát, app-only přihlášení & pracovní weby

> Odhad: 90 min · Režim: živý tenant

## Cíl

První velký lab kurzu. Student vezme app registraci z [`../automation-strategy/`](../automation-strategy/),
vybaví ji certifikátem (bezpečně vygenerovaným a uloženým), přihlásí se app-only bez
jakéhokoli promptu a skriptem si vytvoří pracovní weby (DEV/TEST/PROD), na kterých staví
zbytek týdne.

## Předpoklady

- App registrace `<jmeno.prijmeni>-course-app` z labu [`../automation-strategy/lab-app-registration.md`](../automation-strategy/lab-app-registration.md).
- PnP.PowerShell nainstalovaný s pinovanou verzí (viz [`explainer-module-management.md`](explainer-module-management.md)).
- Naming konvence z [`../onboarding/ways-of-working.md`](../onboarding/ways-of-working.md).

## Kroky

1. **Rozšířit oprávnění aplikace pro app-only**: přidat application permission
   `Sites.FullControl.All` (SharePoint) + admin consent. Zapsat si do poznámky zdůvodnění —
   přesně tohle rozšíření bude předmětem auditu v [`../../day-5/security-hardening/`](../../day-5/security-hardening/).
2. **Vygenerovat self-signed certifikát** do uživatelského úložiště — private key nikdy
   neopustí stroj:

   ```powershell
   $cert = New-SelfSignedCertificate -Subject "CN=<jmeno.prijmeni>-course-app" `
     -CertStoreLocation "Cert:\CurrentUser\My" `
     -KeyExportPolicy NonExportable -KeySpec Signature `
     -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 `
     -NotAfter (Get-Date).AddMonths(6)
   Export-Certificate -Cert $cert -FilePath .\course-app.cer   # JEN verejna cast
   ```

3. **Nahrát veřejnou část** (`.cer`) na app registraci (Certificates & secrets →
   Certificates → Upload). Soubor `.cer` je jediné, co stroj opouští — žádný `.pfx`,
   žádný private key, nic do repa (ověř `.gitignore`).
4. **App-only přihlášení** bez promptu:

   ```powershell
   Connect-PnPOnline -Url "https://<tenant>-admin.sharepoint.com" `
     -ClientId $clientId -Tenant "<tenant>.onmicrosoft.com" `
     -Thumbprint $cert.Thumbprint
   ```

5. **Skriptem vytvořit tři pracovní weby** dle naming konvence — parametrizovaně, ne
   copy-paste třikrát:

   ```powershell
   foreach ($stage in 'dev','test','prod') {
     New-PnPSite -Type CommunicationSite `
       -Title "<jmeno-prijmeni> $stage" `
       -Url "https://<tenant>.sharepoint.com/sites/<jmeno-prijmeni>-$stage"
   }
   ```

6. **Zabalit do `Connect-CourseTarget` wrapperu**: funkce s parametry
   `-Module (PnP|Graph|SPO)` a `-AuthMode (Interactive|DeviceCode|Certificate)`, uvnitř
   mapování na správný `Connect-*` cmdlet, strukturovaný log každého připojení (timestamp,
   modul, auth mode, výsledek — objekt/JSON, ne `Write-Host`). Certificate větev právě
   ověřena kroky 4-5; Interactive/DeviceCode doplnit a otestovat.

## Ověření

- [ ] Certifikát existuje v `Cert:\CurrentUser\My` s `NonExportable` klíčem; v pracovní
      složce ani repu není žádný `.pfx`/private key.
- [ ] App registrace má nahranou veřejnou část certifikátu a přihlášení kroku 4 proběhne
      **bez jakéhokoli interaktivního promptu**.
- [ ] Existují weby `-dev`, `-test`, `-prod` dle naming konvence, vytvořené skriptem
      (ne ručně v UI).
- [ ] `Connect-CourseTarget` funguje minimálně pro kombinace PnP+Certificate a
      PnP+Interactive a loguje strukturovaně.
- [ ] Import modulů jde přes `-RequiredVersion` (pin z předpokladů).

## Fallback

- Pokud `New-PnPSite` v app-only režimu selže (tenant policy), vytvořit weby pod delegated
  přihlášením (`-Interactive`) a app-only certifikátovou cestu ověřit na čtecí operaci
  (`Get-PnPSite`) — cíl labu (cert bez promptu) zůstává splněn.
- Pokud se týž den nestihne krok 6, Interactive/DeviceCode větve wrapperu se doplní jako
  domácí rozcvička před D2 — D2 laby wrapper předpokládají.
