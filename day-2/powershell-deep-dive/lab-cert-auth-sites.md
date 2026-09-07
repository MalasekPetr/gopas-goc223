# Lab · Certifikát, app-only přihlášení & pracovní weby

> Odhad: 90 min · Režim: živý tenant

## Cíl

První velký lab kurzu. Student vezme app registraci z [`../../day-1/automation-strategy/`](../../day-1/automation-strategy/),
vybaví ji certifikátem (bezpečně vygenerovaným a uloženým), přihlásí se app-only bez
jakéhokoli promptu a skriptem si vytvoří pracovní weby (DEV/TEST/PROD), na kterých staví
zbytek týdne.

## Předpoklady

- App registrace `<jmeno.prijmeni>-course-app` z labu [`../../day-1/automation-strategy/lab-app-registration.md`](../../day-1/automation-strategy/lab-app-registration.md).
- PnP.PowerShell nainstalovaný s pinovanou verzí (viz [`explainer-module-management.md`](explainer-module-management.md)).
- Naming konvence z [`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md).

## Kroky

1. **Rozšířit oprávnění aplikace pro app-only**: přidat application permission
   `Sites.FullControl.All` (SharePoint) + admin consent.

   > [!IMPORTANT] Proč tady `Sites.Selected` z minulého bloku nestačí
   > V [`../permissions-consent/`](../permissions-consent/) jste se naučili sáhnout po
   > nejužším oprávnění — a je to správný reflex. **Tenhle lab je výjimka, která pravidlo
   > upřesňuje.** `Sites.Selected` dává přístup k **vyjmenovaným, existujícím** webům;
   > neumí ani vypsat weby tenantu (`Get-PnPTenantSite`), ani žádný web **založit**
   > (`New-PnPSite`). Obojí jsou tenant-scoped operace a přesně to tenhle lab dělá.
   >
   > Least privilege není „vždy vyber nejužší název", ale **nejužší rozsah, který úlohu
   > skutečně splní**. Rozdíl mezi těmito dvěma větami je to, co odlišuje bezpečnostní
   > úvahu od bezpečnostního rituálu.

   Zapsat si do poznámky zdůvodnění — **včetně věty, kdy tohle oprávnění přestane být
   potřeba**. Přesně tohle rozšíření bude předmětem auditu v
   [`../../day-5/security-hardening/`](../../day-5/security-hardening/): provisioning
   skončil, oprávnění zůstalo.
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

   **Kde certifikát leží — úložiště certifikátů.** Windows má úložiště dvojí:
   **uživatele** (`certmgr.msc`, PowerShellem `Cert:\CurrentUser\...`) a **počítače**
   (`certlm.msc`, `Cert:\LocalMachine\...`, vyžaduje admina — sem patří certy pro
   scheduled tasky). Právě vygenerovaný cert leží v uživatelském úložišti ve složce
   *Osobní* — pozor, PowerShell jí říká `My`. Úložiště je v PowerShellu obyčejný „disk":

   ```powershell
   Get-ChildItem Cert:\CurrentUser\My |
     Where-Object Subject -like "*course-app*" |
     Select-Object Subject, Thumbprint, NotAfter, HasPrivateKey
   ```

   Ověřit obě cesty: v `certmgr.msc` dvojklikem na cert („Máte privátní klíč, který
   odpovídá tomuto certifikátu") a zkusit pravý klik → *Všechny úkoly → Exportovat* —
   volba „exportovat privátní klíč" je zašedlá. To je `NonExportable` v akci; souvislosti
   a formáty souborů: [`explainer-certificates-keys.md`](explainer-certificates-keys.md).

3. **Nahrát veřejnou část** (`.cer`) na app registraci (Certificates & secrets →
   Certificates → Upload). Soubor `.cer` je jediné, co stroj opouští — žádný `.pfx`,
   žádný private key, nic do repa (ověř `.gitignore`).
4. **App-only přihlášení** bez promptu:

   ```powershell
   Connect-PnPOnline -Url "https://<tenant>-admin.sharepoint.com" `
     -ClientId $clientId -Tenant "<tenant>.onmicrosoft.com" `
     -Thumbprint $cert.Thumbprint
   ```

   **Hned po připojení ověřit, že jsem připojený a kdo jsem** (návyk na celý kurz):

   ```powershell
   # 1. Detaily pripojeni
   Get-PnPConnection | Select-Object Url, ConnectionType, ClientId, Tenant

   # 2. Analyza tokenu - app-only ma roles, nema upn
   $t = Get-PnPAccessToken -ResourceTypeName SharePoint -Decoded
   $t.Audiences
   $t.Claims | Where-Object Type -in 'roles','upn','app_displayname' |
     Select-Object Type, Value

   # 3. Realne volani - teprve tohle je dukaz
   Get-PnPTenantSite | Select-Object -First 3
   ```

   Když cokoli selže (`Unauthorized`, `AADSTS…`, „not of type RSA"), postupovat podle
   [`troubleshooting-auth.md`](troubleshooting-auth.md) — pokrývá i past Delegated vs
   Application permission.

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
- [ ] Student ověřil připojení všemi třemi úrovněmi (connection → token → reálné volání)
      a umí v tokenu ukázat `roles` a vysvětlit, proč chybí `upn`.
- [ ] Existují weby `-dev`, `-test`, `-prod` dle naming konvence, vytvořené skriptem
      (ne ručně v UI).
- [ ] `Connect-CourseTarget` funguje minimálně pro kombinace PnP+Certificate a
      PnP+Interactive a loguje strukturovaně.
- [ ] Import modulů jde přes `-RequiredVersion` (pin z předpokladů).

> [!NOTE] Referenční řešení
> [`solution/Connect-CourseTarget.ps1`](solution/Connect-CourseTarget.ps1) + **18 unit testů**
> v [`solution/Connect-CourseTarget.Tests.ps1`](solution/Connect-CourseTarget.Tests.ps1).
> Otevřete až po vlastním pokusu — a pak si projděte testy, ne jen skript: jsou to
> **funkční ukázky mockování** z [`../../day-1/vscode-copilot-env/explainer-quality-gates.md`](../../day-1/vscode-copilot-env/explainer-quality-gates.md).
> Dva z nich vznikly proto, že odhalily reálnou chybu v první verzi wrapperu —
> je to v komentářích popsané.
>
> Sám wrapper **nebyl testovaný proti živému tenantu**: ověřená je validace vstupu,
> výběr cmdletu a podoba logu, ale skutečné přihlášení závisí na app registraci
> a tenant policy. Projít všechny tři auth módy je součást go/no-go.

## Fallback

- Pokud `New-PnPSite` v app-only režimu selže (tenant policy), vytvořit weby pod delegated
  přihlášením (`-Interactive`) a app-only certifikátovou cestu ověřit na čtecí operaci
  (`Get-PnPSite`) — cíl labu (cert bez promptu) zůstává splněn.
- Pokud se týž den nestihne krok 6, Interactive/DeviceCode větve wrapperu se doplní jako
  domácí rozcvička před D2 — D2 laby wrapper předpokládají.
