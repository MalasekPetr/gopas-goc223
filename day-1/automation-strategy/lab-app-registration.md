# Lab · Registrace app & baseline oprávnění

> Odhad: 45 min · Režim: živý tenant

## Cíl

Student má vlastní app registraci v kurzovém tenantu s minimální sadou oprávnění potřebných
pro zbytek týdne, umí zdůvodnit každé přiřazené permission a rozumí rozdílu delegated/application.

## Předpoklady

- Účet z onboardingu ([`../onboarding/`](../onboarding/)) — role Global administrator,
  takže registrace i admin consent probíhají pod vlastním účtem.
- Naming konvence z [`../onboarding/ways-of-working.md`](../onboarding/ways-of-working.md).

## Kroky

1. Zaregistrovat novou aplikaci v Entra ID (App registrations → New registration) —
   pojmenovanou dle konvence `<jmeno.prijmeni>-course-app`.
2. Zvolit typ klienta podle plánovaného použití v [`../powershell-deep-dive/`](../powershell-deep-dive/) (public client pro interactive/device
   code, případně přidat certificate credential pro app-only scénář).
3. Přidat baseline API permissions: `Sites.Read.All` (Graph, delegated) pro čtecí operace nad
   SharePointem, bez zápisových oprávnění v tomto kroku.
4. Zapsat do `README.md` labu (lokální poznámka, ne commit do repa) zdůvodnění každého
   přiřazeného permission — proč je potřeba, proč ne širší varianta.
5. Provést admin consent (pokud je vyžadován) a ověřit přihlášení skrz `Connect-*` cmdlet
   libovolného ze tří modulů z [`../powershell-deep-dive/`](../powershell-deep-dive/).

## Ověření

- [ ] App registrace existuje a má přiřazený přesně jeden delegated permission (`Sites.Read.All`).
- [ ] Student umí vysvětlit rozdíl mezi tímto permission a jeho "write" ekvivalentem.
- [ ] Přihlášení přes ClientId této aplikace proběhne úspěšně.

## Fallback

Pokud studentovi nefunguje vlastní účet (MFA/licence nedořešené z onboardingu), pracuje ve
dvojici se sousedem nad jeho app registrací a vlastní si založí po vyřešení účtu o přestávce.
