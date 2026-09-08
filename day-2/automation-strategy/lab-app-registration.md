# Lab · App registrace, consent a Sites.Selected

> Odhad: 55 min · Režim: živý tenant

## Cíl

Student má vlastní app registraci s **delegated i application** oprávněním, umí zdůvodnit
každé z nich, na vlastní oči vidí, že `Sites.Selected` po consentu nedává přístup nikam,
a umí skriptem ověřit, co má aplikace v tenantu **skutečně** udělené.

Tahle app registrace je vaše identita pro celý zbytek týdne — v následujícím bloku
dostane certifikát, v D5 projde auditem.

## Předpoklady

- Účet z onboardingu ([`../../day-1/onboarding/`](../../day-1/onboarding/)) — role Global administrator,
  takže registrace i admin consent probíhají pod vlastním účtem.
- Naming konvence z [`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md).
- PnP PowerShell a `Microsoft.Graph` z [`../../day-1/toolchain-setup/`](../../day-1/toolchain-setup/).

## Kroky

### Část A — registrace a delegated přístup

1. Zaregistrovat novou aplikaci v Entra ID (App registrations → New registration) —
   pojmenovanou dle konvence `<jmeno.prijmeni>-course-app`.

2. Nastavit aplikaci jako **public client** pro delegated přihlašování (prokazuje se
   uživatel, viz [`../powershell-deep-dive/`](../powershell-deep-dive/)) —
   pozor, jsou to podle flow **dvě samostatná nastavení**:
   - pro `-Interactive`: platforma **Mobile and desktop applications** s redirect URI
     `http://localhost` (*Authentication → Add a platform*),
   - pro `-UseDeviceLogin`: přepínač **Allow public client flows = Yes**
     (*Authentication → Settings*) — device code nemá redirect URI, takže Entra typ
     klienta pozná právě z tohoto fallbacku; bez něj skončí `AADSTS7000218`.

   Certificate credential pro app-only scénář (**confidential client** — prokazuje se
   aplikace) přidá až lab v následujícím bloku. Definice obou pojmů:
   [`../../GLOSSARY.md`](../../GLOSSARY.md).

3. Přidat baseline **delegated** permission: `Sites.Read.All` (Graph) pro čtecí operace nad
   SharePointem, bez zápisových oprávnění v tomto kroku.

4. Zapsat si zdůvodnění každého přiřazeného permission (lokální poznámka, ne commit do
   repa) — proč je potřeba, proč ne širší varianta.

5. Provést admin consent a ověřit přihlášení skrz `Connect-*` cmdlet libovolného ze tří
   modulů z [`../powershell-deep-dive/`](../powershell-deep-dive/).

   > Tady consent uděláte jedním kliknutím, protože jste GA ve vlastním tenantu. V cizím
   > tenantu se spouští **odkazem, který si musíte složit sami** — portál ho nikde nenabízí.
   > Tvar URL, povinné parametry v2.0 endpointu a tři věci, které to shodí:
   > [`explainer-app-registrations-enterprise-apps.md`](explainer-app-registrations-enterprise-apps.md).

6. Najít tutéž aplikaci v **obou** portálových pohledech — App registrations (šablona,
   credentials, požadované permissions) i Enterprise applications (service principal,
   udělený consent) — a pojmenovat, co je v každém z nich jiného (viz
   [`explainer-app-registrations-enterprise-apps.md`](explainer-app-registrations-enterprise-apps.md)).
   Zkontrolovat, že `signInAudience` je `AzureADMyOrg` (single-tenant).

### Část B — application oprávnění a Sites.Selected

7. **Zjistit, co aplikace má teď.** Najít Object ID **service principalu** své aplikace
   (Enterprise applications, ne App registrations — jsou to různá ID) a vypsat udělená
   oprávnění:

   ```powershell
   Connect-MgGraph -ClientId <client-id> -TenantId <tenant-id> -Scopes "Application.Read.All"
   Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId <sp-object-id>
   ```

   Poznamenat si výstup — na konci ho porovnáte.

8. **Přidat `Sites.Selected` jako Application permission.** Entra → App registrations →
   vaše aplikace → API permissions → Add a permission → **SharePoint** →
   **Application permissions** → `Sites.Selected`.

   > Pozor na záložku. Delegated a Application jsou dvě různé sady; app-only přihlášení
   > delegovaná oprávnění ignoruje.

9. **Grant admin consent** a znovu spustit dotaz z kroku 7. Oprávnění teď v seznamu je.

10. **Ověřit, že aplikace nevidí nic.** Vypsat weby, ke kterým má aplikace přístup:

    ```powershell
    Get-PnPAzureADAppSitePermission -AppIdentity <client-id>
    ```

    Výstup je prázdný. **To je správné chování, ne chyba** — a je to celý smysl
    `Sites.Selected`. Zapsat si vlastními slovy, proč.

11. **Přidělit aplikaci jeden web** — svůj sandbox web, s právem `Read`:

    ```powershell
    Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<vas-web>" `
      -ClientId <client-id> -Interactive
    Grant-PnPAzureADAppSitePermission -AppId <client-id> `
      -DisplayName "<jmeno-prijmeni>-course-app" -Site "https://<tenant>.sharepoint.com/sites/<vas-web>" `
      -Permissions Read
    ```

12. **Ověřit rozdíl.** Znovu `Get-PnPAzureADAppSitePermission` — teď je tam jeden web.
    Aplikace má stále přesně jedno application oprávnění, ale rozsah se změnil z „nic"
    na „tenhle jeden web".

13. **Zdůvodnění do commit message.** Dvě věty: proč `Sites.Selected` a ne
    `Sites.ReadWrite.All`, a co konkrétně by druhá varianta znamenala, kdyby certifikát
    vaší aplikace unikl.

## Ověření

- [ ] App registrace existuje a má přiřazený přesně jeden **delegated** permission (`Sites.Read.All`).
- [ ] Student umí vysvětlit rozdíl mezi tímto permission a jeho „write" ekvivalentem.
- [ ] Přihlášení přes ClientId této aplikace proběhne úspěšně.
- [ ] Student umí ukázat aplikaci v App registrations i Enterprise applications a říct,
      který objekt drží credentials a který udělený consent.
- [ ] `signInAudience` = `AzureADMyOrg`.
- [ ] Student umí říct, které nastavení odpovídá kterému flow (platforma + `http://localhost`
      pro `-Interactive`, *Allow public client flows* pro device code).
- [ ] `Get-MgServicePrincipalAppRoleAssignment` vrací `Sites.Selected` jako udělené
      **application** oprávnění.
- [ ] Student umí ukázat, že mezi krokem 9 a 10 přibylo oprávnění, ale **nepřibyl přístup**,
      a vysvětlit proč.
- [ ] `Get-PnPAzureADAppSitePermission` po kroku 11 vrací právě jeden web.
- [ ] Student umí říct, ve které záložce (Delegated vs Application) oprávnění přidal
      a co by se stalo, kdyby ho přidal do té druhé.
- [ ] Zdůvodnění z kroku 13 je v commit message.

## Fallback

- Pokud studentovi nefunguje vlastní účet (MFA/licence nedořešené z onboardingu), pracuje ve
  dvojici se sousedem nad jeho app registrací a vlastní si založí po vyřešení účtu o přestávce.
- **`Grant-PnPAzureADAppSitePermission` neexistuje nebo má jiné parametry**: názvy PnP
  cmdletů pro per-site grant se mezi verzemi měnily — ověřit
  `Get-Command -Module PnP.PowerShell *SitePermission*`. Alternativa je Graph:
  `POST /sites/{siteId}/permissions`.
- **Chybí oprávnění ke čtení service principalů**: kroky 7 a 9 lze nahradit portálovým
  pohledem (Enterprise applications → Permissions). Pointa je porovnat stav před a po,
  ne konkrétní cmdlet.
- **Časový skluz**: vypustit kroky 4 a 13 (písemná zdůvodnění, dají se dopsat doma).
  Kroky 10-12 ne — jsou to ty, kvůli kterým část B existuje.
