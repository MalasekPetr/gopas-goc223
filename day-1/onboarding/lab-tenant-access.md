# Lab · Přístup do tenantu & ověření

> Odhad: 45 min · Režim: živý tenant · Prostředí: [`../../environment.md`](../../environment.md)

## Cíl

Student se přihlásí, zaregistruje MFA, ověří přiřazenou licenci i roli Global administrator
a potvrdí, že rozumí pravidlům práce ve sdíleném tenantu.

## Předpoklady

- Účet `jmeno.prijmeni@cloudedu.cz` + heslo (rozdané na začátku).
- Vlastní telefon (Microsoft Authenticator) nebo mobilní číslo pro SMS — nutné pro MFA.
- Přiřazená licence Microsoft 365 E5 Developer + role Global administrator.

## Kroky

1. Přihlas se na `https://portal.office.com` účtem `jmeno.prijmeni@cloudedu.cz` — a stejným
   účtem do profilu prohlížeče (Edge); účet používáš celý týden jako pracovní.
2. Dokonči reset hesla a **registraci MFA** — postup: [`mfa-setup.md`](mfa-setup.md).
3. Otevři `https://admin.microsoft.com` — jako Global administrator vidíš admin center.
   Najdi svůj účet (Users → Active users) a ověř přiřazenou E5 licenci a roli.
4. Otevři SharePoint a vytvoř si vlastní web podle naming konvence z
   [`ways-of-working.md`](ways-of-working.md) (`/sites/<jmeno-prijmeni>-dev`).
5. Přečti si [`ways-of-working.md`](ways-of-working.md) celý — pravidla se vymáhají od
   tohoto okamžiku.

## Ověření

- [ ] MFA zaregistrováno — `https://aka.ms/mysecurityinfo` ukazuje alespoň jednu metodu.
- [ ] Student vidí M365 admin center a svou roli Global administrator.
- [ ] Existuje web `/sites/<jmeno-prijmeni>-dev` pojmenovaný dle konvence.
- [ ] Student umí říct tři tvrdá pravidla z `ways-of-working.md` (kontrola instruktorem
      namátkou u 3-4 studentů).

## Fallback

- Problémy s MFA (QR kód, SMS, zablokovaný účet): viz "Časté problémy" v
  [`mfa-setup.md`](mfa-setup.md); když nepomůže, řeší instruktor.
- Pokud studentovi chybí licence/role (nedoběhlé přiřazení), instruktor opraví v admin
  centru na místě — proto je go/no-go kontrola den předem kritická (viz `instructor-notes.md`).
