# Demo · Hardware klíč (YubiKey PIV) jako credential aplikace

> Odhad: 30 min · Režim: **volitelné instruktorské demo** · Publikum: celá skupina se dívá

Volitelný doplněk k [`explainer-certificates-keys.md`](explainer-certificates-keys.md).
Hands-on část dne běží nad **softwarovými** certifikáty z [`lab-cert-auth-sites.md`](lab-cert-auth-sites.md);
tohle demo ukazuje poslední stupeň žebříčku credentialů na reálném hardwaru. Klíč koluje
po místnosti k osahání.

**Pointa dema:** skript se nezmění. Změní se jen to, kde privátní klíč bydlí — a to je
rozdíl mezi „Windows slíbil, že klíč neexportuje" a „klíč z čipu nejde dostat ven".

## Předpoklady

- Vlastní **YubiKey 5** (instruktorský) — starší modely PIV nemusí podporovat.
- `ykman` nainstalovaný na demo stroji — viz [`setup-ykman.md`](setup-ykman.md).
- App registrace z [`../automation-strategy/lab-app-registration.md`](../automation-strategy/lab-app-registration.md),
  do které se nahraje veřejná část certifikátu.
- **Otestováno den předem na stejném stroji.** Viz `instructor-notes.md`.

## Kroky

### 1. Ukázat, co na klíči je

```powershell
ykman piv info
```

Vypíše sloty a certifikáty. Slot **9a** (PIV Authentication) je ten, který se používá
pro přihlašování. Pokud je obsazený z dřívějška, demo pokračuje na jiném slotu
(9c/9d/9e) — nepřepisovat cizí obsah bez rozmyslu.

### 2. Vygenerovat klíčový pár PŘÍMO NA ČIPU

```powershell
ykman piv keys generate --algorithm RSA2048 9a public-key.pem
```

Tohle je celé demo v jednom příkazu. Řekněte nahlas, co se právě stalo:
**privátní klíč vznikl uvnitř čipu a nikdy nebyl v paměti počítače.** Soubor
`public-key.pem`, který zbyl na disku, je jen veřejná část — může kolovat, komu chcete.

### 3. Vyrobit self-signed certifikát nad tím klíčem

```powershell
ykman piv certificates generate --subject "CN=course-hw-demo" 9a public-key.pem
ykman piv certificates export 9a course-hw-demo.cer
```

Podpis certifikátu proběhl **v čipu**. Exportuje se jen `.cer` — veřejná část.
Ukázat, že `.pfx` tu nikde nevzniká a vzniknout nemůže.

### 4. Nahrát veřejnou část do app registrace

Entra admin center → App registrations → vaše aplikace → **Certificates & secrets →
Certificates → Upload certificate** → `course-hw-demo.cer`.

Poznamenat si **thumbprint**, který Entra zobrazí.

### 5. Přihlásit se — a nechat je vidět dotyk

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" `
  -ClientId <client-id> -Tenant <tenant>.onmicrosoft.com -Thumbprint <thumbprint>
Get-PnPWeb
```

Klíč zabliká, instruktor se ho dotkne, přihlášení projde.

**Tady se demo vyplácí.** Ukažte, že příkaz je **znak po znaku stejný** jako v labu se
softwarovým certifikátem. Windows minidriver promítl certifikát z čipu do cert store,
takže PnP o hardwaru vůbec neví — jen požádá o podpis a čip ho vrátí.

### 6. Zkusit klíč exportovat (a neuspět)

```powershell
Get-ChildItem Cert:\CurrentUser\My |
  Where-Object Subject -eq "CN=course-hw-demo" |
  Select-Object Subject, Thumbprint, HasPrivateKey
```

`HasPrivateKey` je `True` — ale v `certmgr.msc` je volba *Export private key* zašedlá
a žádný nástroj klíč nedostane ven. Rozdíl proti `NonExportable`: tam Windows
**odmítá**, tady čip **neumí**.

### 7. Úklid

```powershell
ykman piv keys delete 9a
ykman piv certificates delete 9a
```

A odebrat certifikát z app registrace. Nechat na klíči demo certifikát do dalšího běhu
je nepořádek, ne úspora času.

## Co si mají odnést

- **Hardware klíč není jiné API, je to jiné úložiště klíče** — skript se nemění.
- **Privátní klíč se rodí v čipu** a neexistuje operace, která ho dostane ven.
- **Dotyk je feature pro člověka, ne pro automatizaci** — noční scheduled task s klíčem,
  u kterého nikdo nestojí, je chyba nasazení.
- Tentýž YubiKey umí být **token pro vícefaktorové ověření (MFA)** (FIDO2) i **credential aplikace** (PIV);
  jsou to dvě nesouvisející role.

## Fallback

- **Klíč není k dispozici / `ykman` nefunguje**: projít kroky 2-3 jako slidy s výstupy
  zachycenými předem a soustředit se na krok 5 — že se příkaz nemění. Pointa dema je
  koncepční, ne manuální.
- **Demo přeteče čas**: vypustit kroky 6-7 a říct závěr slovy. Kroky 2 a 5 jsou jádro.
- **Skupina nemá zájem o hardware**: demo je volitelné, přeskočit celé a odkázat na
  [`explainer-certificates-keys.md`](explainer-certificates-keys.md).

## Zdroje

- [YubiKey Manager CLI (`ykman`) — Yubico](https://developers.yubico.com/yubikey-manager/)
- [PIV (Personal Identity Verification) — Yubico](https://developers.yubico.com/PIV/)
- [Certificate credentials for application authentication](https://learn.microsoft.com/en-us/entra/identity-platform/certificate-credentials)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Syntaxe `ykman piv` se mezi hlavními verzemi YubiKey Manageru **měnila** (dřívější
> `ykman piv generate-key` / `generate-certificate` vs dnešní
> `ykman piv keys generate` / `certificates generate`). Před KAŽDÝM během ověřit
> `ykman --version` a projet celé demo na demo stroji — příkazy výše jsou k datu psaní.
