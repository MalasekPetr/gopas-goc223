# Lab · Sites.Selected místo generálního klíče

> Odhad: 25 min · Režim: živý tenant

## Cíl

Student rozšíří svou app registraci z D1 o **application** permission `Sites.Selected`,
na vlastní oči uvidí, že consent sám o sobě nedává přístup nikam, přidělí aplikaci
konkrétní web a umí skriptem ověřit, co má aplikace skutečně udělené.

## Předpoklady

- App registrace z [`../../day-1/automation-strategy/lab-app-registration.md`](../../day-1/automation-strategy/lab-app-registration.md)
  (zatím jen delegated `Sites.Read.All`).
- PnP PowerShell a `Microsoft.Graph` z [`../../day-1/toolchain-setup/`](../../day-1/toolchain-setup/).
- Certifikát ještě **nemáte** — ten vzniká v následujícím bloku. Tento lab pracuje
  s delegovaným přihlášením; app-only přihlášení certifikátem přijde hned potom.

## Kroky

1. **Zjistit, co aplikace má teď.** Najít Object ID service principalu své aplikace
   (Enterprise applications, ne App registrations — jsou to různá ID) a vypsat udělená
   oprávnění:

   ```powershell
   Connect-MgGraph -ClientId <client-id> -TenantId <tenant-id> -Scopes "Application.Read.All"
   Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId <sp-object-id>
   ```

   Poznamenat si výstup — na konci ho porovnáte.

2. **Přidat `Sites.Selected` jako Application permission.** Entra → App registrations →
   vaše aplikace → API permissions → Add a permission → **SharePoint** →
   **Application permissions** → `Sites.Selected`.

   > Pozor na záložku. Delegated a Application jsou dvě různé sady; app-only přihlášení
   > delegovaná oprávnění ignoruje.

3. **Grant admin consent** a znovu spustit dotaz z kroku 1. Oprávnění teď v seznamu je.

4. **Ověřit, že aplikace nevidí nic.** Vypsat weby, ke kterým má aplikace přístup:

   ```powershell
   Get-PnPAzureADAppSitePermission -AppIdentity <client-id>
   ```

   Výstup je prázdný. **To je správné chování, ne chyba** — a je to celý smysl
   `Sites.Selected`. Zapsat si vlastními slovy, proč.

5. **Přidělit aplikaci jeden web** — svůj sandbox web, s právem `Read`:

   ```powershell
   Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<vas-web>" `
     -ClientId <client-id> -Interactive
   Grant-PnPAzureADAppSitePermission -AppId <client-id> `
     -DisplayName "<jmeno-prijmeni>-course-app" -Site "https://<tenant>.sharepoint.com/sites/<vas-web>" `
     -Permissions Read
   ```

6. **Ověřit rozdíl.** Znovu `Get-PnPAzureADAppSitePermission` — teď je tam jeden web.
   Aplikace má stále přesně jedno oprávnění, ale rozsah se změnil z „nic" na „tenhle
   jeden web".

7. **Zdůvodnění do commit message.** Dvě věty: proč `Sites.Selected` a ne
   `Sites.ReadWrite.All`, a co konkrétně by druhá varianta znamenala, kdyby certifikát
   vaší aplikace unikl.

## Ověření

- [ ] `Get-MgServicePrincipalAppRoleAssignment` vrací `Sites.Selected` jako udělené
      **application** oprávnění.
- [ ] Student umí ukázat, že mezi krokem 3 a 4 přibylo oprávnění, ale **nepřibyl přístup**,
      a vysvětlit proč.
- [ ] `Get-PnPAzureADAppSitePermission` po kroku 5 vrací právě jeden web.
- [ ] Student umí říct, ve které záložce (Delegated vs Application) oprávnění přidal
      a co by se stalo, kdyby ho přidal do té druhé.
- [ ] Zdůvodnění z kroku 7 je v commit message.

## Fallback

- **`Grant-PnPAzureADAppSitePermission` neexistuje nebo má jiné parametry**: názvy PnP
  cmdletů pro per-site grant se mezi verzemi měnily — ověřit
  `Get-Command -Module PnP.PowerShell *SitePermission*`. Alternativa je Graph:
  `POST /sites/{siteId}/permissions`.
- **Chybí oprávnění ke čtení service principalů**: krok 1 a 3 lze nahradit portálovým
  pohledem (Enterprise applications → Permissions). Pointa je porovnat stav před a po,
  ne konkrétní cmdlet.
- **Časový skluz**: kroky 1 a 7 lze vypustit. Kroky 4-6 ne — jsou to ty, kvůli kterým
  lab existuje.
