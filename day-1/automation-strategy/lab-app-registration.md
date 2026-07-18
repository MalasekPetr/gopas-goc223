# Lab · Registrace app & baseline oprávnění

> Odhad: 45 min · Režim: živý tenant

## Cíl

Student má vlastní app registraci v kurzovém tenantu s minimální sadou oprávnění potřebných
pro zbytek týdne, umí zdůvodnit každé přiřazené permission a rozumí rozdílu delegated/application.

## Předpoklady

- Přístup do Entra ID kurzového tenantu s právem registrovat aplikace (Application Developer role
  nebo dočasně přidělená vyšší role — viz `instructor-notes.md`).

## Kroky

1. Zaregistrovat novou aplikaci v Entra ID (App registrations → New registration).
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

Pokud studenti nemají v kurzovém tenantu právo registrovat aplikace, instruktor předem
zaregistruje jednu sdílenou aplikaci pro celou skupinu (dočasně, smazat po kurzu) a lab
pokračuje od kroku 3 nad sdíleným ClientId.
