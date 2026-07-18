# Jak zaregistrovat vícefaktorové ověřování (MFA)

> Prostředí: [`../../environment.md`](../../environment.md)

> Účet `jmeno.prijmeni@cloudedu.cz` je po celou dobu kurzu váš **pracovní účet na počítači
> v učebně** — přihlaste se jím do profilu prohlížeče (Edge) a používejte ho celý týden.
> Při prvním přihlášení je nutné zaregistrovat MFA; bez něj se ke zdrojům tenantu nedostanete
> (a jako Global administrator ho mít **musíte** — účet bez MFA s touto rolí je nepřijatelné riziko).

## Postup

1. Přihlaste se na `https://portal.office.com` účtem `jmeno.prijmeni@cloudedu.cz` a heslem
   od instruktora. Systém vyzve ke změně hesla.
2. Po změně hesla se objeví výzva **"More information required"** — pokračujte tlačítkem Next.
3. Doporučená metoda: **Microsoft Authenticator** na vlastním telefonu.
   - Nainstalujte aplikaci (App Store / Google Play).
   - V aplikaci: Add account → Work or school account → Scan QR code.
   - Naskenujte QR kód z obrazovky a potvrďte testovací notifikaci.
4. Alternativa bez chytrého telefonu: telefonní číslo + SMS kód (volba "I want to set up a
   different method" → Phone).
5. Dokončete průvodce. Ověření: `https://aka.ms/mysecurityinfo` ukazuje alespoň jednu metodu.

## Časté problémy

- **QR kód nejde naskenovat** — v Authenticatoru zvolte "Enter code manually" a přepište
  kód + URL z obrazovky.
- **Nepřišla SMS** — zkontrolujte předvolbu (+420), zkuste "Resend"; když nepomůže, řeší
  instruktor.
- **Smyčka "More information required" po dokončení** — odhlásit, zavřít prohlížeč, přihlásit
  znovu ve stejném profilu Edge.
- **Vlastní telefon není k dispozici** — řeší instruktor individuálně (dočasná výjimka nebo
  hardwarový token).
