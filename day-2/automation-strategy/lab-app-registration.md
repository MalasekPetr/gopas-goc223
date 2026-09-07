# Lab · Registrace app & baseline oprávnění

> Odhad: 45 min · Režim: živý tenant

## Cíl

Student má vlastní app registraci v kurzovém tenantu s minimální sadou oprávnění potřebných
pro zbytek týdne, umí zdůvodnit každé přiřazené permission a rozumí rozdílu delegated/application.

## Předpoklady

- Účet z onboardingu ([`../../day-1/onboarding/`](../../day-1/onboarding/)) — role Global administrator,
  takže registrace i admin consent probíhají pod vlastním účtem.
- Naming konvence z [`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md).

## Kroky

1. Zaregistrovat novou aplikaci v Entra ID (App registrations → New registration) —
   pojmenovanou dle konvence `<jmeno.prijmeni>-course-app`.
2. Nastavit aplikaci jako **public client** pro delegated přihlašování (prokazuje se
   uživatel, viz [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/)) —
   pozor, jsou to podle flow **dvě samostatná nastavení**:
   - pro `-Interactive`: platforma **Mobile and desktop applications** s redirect URI
     `http://localhost` (*Authentication → Add a platform*),
   - pro `-UseDeviceLogin`: přepínač **Allow public client flows = Yes**
     (*Authentication → Settings*) — device code nemá redirect URI, takže Entra typ
     klienta pozná právě z tohoto fallbacku; bez něj skončí `AADSTS7000218`.

   Certificate credential pro app-only scénář (**confidential client** — prokazuje se
   aplikace) přidá až lab v D2. Definice obou pojmů: [`../../GLOSSARY.md`](../../GLOSSARY.md).
3. Přidat baseline API permissions: `Sites.Read.All` (Graph, delegated) pro čtecí operace nad
   SharePointem, bez zápisových oprávnění v tomto kroku.
4. Zapsat do `README.md` labu (lokální poznámka, ne commit do repa) zdůvodnění každého
   přiřazeného permission — proč je potřeba, proč ne širší varianta.
5. Provést admin consent (pokud je vyžadován) a ověřit přihlášení skrz `Connect-*` cmdlet
   libovolného ze tří modulů z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).
6. Najít tutéž aplikaci v **obou** portálových pohledech — App registrations (šablona,
   credentials, požadované permissions) i Enterprise applications (service principal,
   udělený consent) — a pojmenovat, co je v každém z nich jiného (viz
   [`explainer-app-registrations-enterprise-apps.md`](explainer-app-registrations-enterprise-apps.md)).
   Zkontrolovat, že `signInAudience` je `AzureADMyOrg` (single-tenant).

## Ověření

- [ ] App registrace existuje a má přiřazený přesně jeden delegated permission (`Sites.Read.All`).
- [ ] Student umí vysvětlit rozdíl mezi tímto permission a jeho "write" ekvivalentem.
- [ ] Přihlášení přes ClientId této aplikace proběhne úspěšně.
- [ ] Student umí ukázat aplikaci v App registrations i Enterprise applications a říct,
      který objekt drží credentials a který udělený consent.
- [ ] `signInAudience` = `AzureADMyOrg`.
- [ ] Student umí říct, které nastavení odpovídá kterému flow (platforma + `http://localhost`
      pro `-Interactive`, *Allow public client flows* pro device code).

## Fallback

Pokud studentovi nefunguje vlastní účet (MFA/licence nedořešené z onboardingu), pracuje ve
dvojici se sousedem nad jeho app registrací a vlastní si založí po vyřešení účtu o přestávce.
