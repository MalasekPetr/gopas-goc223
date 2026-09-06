# Explainer · Certifikáty a klíče: CER/PEM/PFX, úložiště, žebříček credentialů

Deep-dive k [`README.md`](README.md) a k [`lab-cert-auth-sites.md`](lab-cert-auth-sites.md),
který certifikát vyrábí. Odpovídá na tři otázky, které se v praxi pletou: **co je v tom
souboru**, **kde certifikát bydlí** a **kdy už software certifikát nestačí**.

## Pár klíčů — jediné, o co jde

Certifikátová autentizace stojí na dvojici klíčů: **privátní** (prokazuji se jím, nesmí
opustit stroj) a **veřejný** (ověřuje mě protistrana, může ho mít kdokoli). Certifikát
je veřejný klíč + metadata (subject, platnost, thumbprint). App registrace v Entra
dostane **jen veřejnou část** — proto se nahrává `.cer` a nikdy `.pfx`.

## Formáty souborů — co je uvnitř

| Soubor | Obsah | Smí opustit stroj? |
|---|---|---|
| `.cer` / `.crt` (DER binárně, nebo Base64) | jen veřejný klíč + metadata | ano — tohle se nahrává do Entra |
| `.pem` | textová obálka `-----BEGIN…-----`; může nést certifikát, privátní klíč, nebo obojí | podle obsahu! `BEGIN PRIVATE KEY` = nikdy |
| `.pfx` / `.p12` (PKCS#12) | certifikát **včetně privátního klíče**, chráněný heslem | jen řízený přenos (import na server), nikdy mailem, chatem ani do repa |

PEM je jen Base64 zápis s hlavičkou — tentýž certifikát může existovat jako `.cer`
i `.pem`. Na Windows převažuje DER/PFX + úložiště certifikátů, na Linuxu, macOS
a v kontejnerech se pracuje se soubory PEM (`Cert:` provider na Linuxu neexistuje —
viz [`../../day-4/azure-integration-patterns/explainer-azure-orientation.md`](../../day-4/azure-integration-patterns/explainer-azure-orientation.md)).
PowerShell 7 je multiplatformní, takže je potřeba znát obojí.

## Windows úložiště certifikátů

Dvě oddělené soustavy — a záměna je častá příčina „na mém stroji to jede, pod taskem ne":

| Scope | GUI | PowerShell | Kdy |
|---|---|---|---|
| Uživatel | `certmgr.msc` | `Cert:\CurrentUser\My` | interaktivní práce, laby |
| Počítač | `certlm.msc` (vyžaduje admina) | `Cert:\LocalMachine\My` | scheduled task pod servisním účtem |

Jazyková past: složka, které české GUI říká **Osobní**, se v PowerShellu jmenuje **`My`**.
Struktura je vždy *scope → store*: vedle `My` existují `Root` (důvěryhodné kořenové CA —
nesahat) a `CA` (zprostředkující). Úložiště je v PowerShellu obyčejný „disk":

```powershell
Get-ChildItem Cert:\CurrentUser\My |
  Where-Object Subject -like "*course-app*" |
  Select-Object Subject, Thumbprint, NotAfter, HasPrivateKey
```

**NonExportable** (atribut z labu) znamená, že Windows odmítne privátní klíč exportovat —
v `certmgr.msc` je volba „exportovat privátní klíč" zašedlá. První stupeň ochrany proti
zkopírování; ne pojistka proti adminovi stroje.

## Žebříček credentialů — čím dál míň tajemství na discích

| Stupeň | Kde klíč bydlí | Typické použití |
|---|---|---|
| Client secret | řetězec v konfiguraci/skriptu | jen dočasně; ze všech variant nejhorší |
| Software certifikát (NonExportable) | cert store stroje | scheduled task on-prem, vývojová stanice |
| Hardware klíč (čipová karta / PIV, HSM) | vyhrazený čip, klíč z něj nejde dostat | credential s vysokými právy používaný **člověkem** (admin, konzultant napříč tenanty) |
| Azure Key Vault | HSM jako služba | automatizace běžící v Azure, sdílené credentialy s auditem |
| Managed identity | žádný spravovaný credential | automatizace na Azure resource — cílový stav |

Pravidlo: **hardware klíč patří k člověku, bezobslužná automatizace patří na managed
identity.** Hardwarový klíč vyžadující dotyk je pro noční scheduled task chyba nasazení,
ne bezpečnostní vylepšení.

Certifikát je z podstaty lepší než secret: podepisuje se jím výzva, samotný klíč po síti
nikdy neputuje — na rozdíl od secretu, který se posílá při každém přihlášení.

## Hardware klíč — NonExportable dotažený do konce

`NonExportable` je **softwarová** pojistka: je to příznak, který respektuje Windows.
Administrátor stroje ho umí obejít a útočník s dostatečnými právy taky. Hardware klíč
tuhle vlastnost mění z dohody na fyzikální fakt.

**YubiKey v režimu PIV** (a stejně tak čipová karta, HSM nebo Azure Key Vault) funguje takto:

1. Klíčový pár se **vygeneruje přímo na čipu**. Privátní klíč se nikdy neobjeví
   v paměti počítače.
2. **Neexistuje operace, která by ho z čipu dostala ven.** Není to zakázané — čip to
   neumí. To je celý rozdíl proti `NonExportable`.
3. Podpis se provádí **uvnitř čipu**: aplikace pošle data k podpisu, čip vrátí podpis.
   Volitelně až po zadání PIN a **fyzickém dotyku** klíče.
4. Windows minidriver certifikát z čipu promítne do cert store, takže
   `Connect-PnPOnline -Thumbprint <thumb>` funguje **beze změny jediného znaku** —
   jen podpis proběhne v hardwaru místo v softwaru.

Bod 4 je pointa pro skriptera: **hardware klíč není jiné API, je to jiné úložiště klíče.**
Skript se nemění.

**PIV** (Personal Identity Verification) je protokol čipových karet — YubiKey se pod ním
tváří jako smart card. Tentýž princip, jen jiný formfaktor, mají HSM a v cloudu
**Azure Key Vault** (HSM jako služba pro automatizaci, která neběží na vašem stolku).

### Kdy to má smysl a kdy je to chyba nasazení

| Situace | Správná volba |
|---|---|
| Credential s vysokými právy používaný **člověkem** (admin, konzultant napříč tenanty) | hardware klíč |
| Bezobslužná automatizace **v Azure** | managed identity, případně Key Vault |
| Noční scheduled task on-prem | software cert v `LocalMachine` s NonExportable |

**Hardware klíč vyžadující dotyk je pro noční scheduled task chyba nasazení, ne
bezpečnostní vylepšení** — v 03:00 u něj nikdo nestojí. Pravidlo: *hardware klíč patří
k člověku, bezobslužná automatizace patří na managed identity.*

### MFA token vs PIV credential — tentýž klíč, dvě různé role

YubiKey jste v [`../../day-1/onboarding/mfa-setup.md`](../../day-1/onboarding/mfa-setup.md)
mohli potkat jako **druhý faktor při přihlášení člověka**. Tady drží **credential
aplikace**. Je to stejný kus hardwaru ve dvou nesouvisejících rolích:

| | Přihlášení člověka | Credential aplikace |
|---|---|---|
| Protokol | FIDO2 / WebAuthn (passkey) | PIV (smart card) |
| Co prokazuje | že u klávesnice je konkrétní člověk | že volající je konkrétní aplikace |
| Kde se registruje | Entra → Authentication methods uživatele | app registrace → Certificates |
| Nahrazuje | heslo | client secret |

Záměna těchto dvou je častý zdroj zmatku v diskuzi „máme YubiKeys, tak jsme
bezpeční" — bezpečné je to, k čemu je klíč skutečně nasazený.

Živé demo celého postupu (klíč → self-signed certifikát → upload `.cer` na app registraci
z labu → přihlášení s dotykem): [`demo-yubikey.md`](demo-yubikey.md).

## Praktické důsledky pro skripty

- Na app registraci nahrávat **výhradně `.cer`**; `.pfx` vzniká jen tam, kde se cert
  musí přenést na jiný stroj — a pak se maže.
- `.gitignore` musí obsahovat `*.pfx`, `*.p12`, `*.pem` — tajemství, které se jednou
  dostane do gitu, zůstává v historii.
- Certifikát má **platnost**; rotace se plánuje dřív, než vyprší — `keyCredentials`
  na app registraci je multi-hodnotové pole, takže nový cert lze nahrát vedle starého
  a teprve pak starý smazat (rotace bez výpadku, detail v
  [`../../day-5/security-hardening/`](../../day-5/security-hardening/)).
- Thumbprint je identifikátor konkrétního certifikátu — po rotaci se **mění** a skripty
  ho musí brát z konfigurace, ne mít natvrdo.

## Klíčové rozlišení

- **Privátní vs veřejný klíč** — privátní se prokazuje a nikam nechodí; veřejný ověřuje
  a smí kamkoli. Všechna pravidla výše jsou důsledkem této jediné věty.
- **`.cer` vs `.pfx`** — bez privátního klíče vs s ním; do Entra jde vždy jen `.cer`.
- **DER/CER vs PEM** — binární Windows svět vs textový soubor pro Linux a kontejnery;
  tentýž obsah, jiný obal.
- **CurrentUser vs LocalMachine store** — profil člověka vs stroj; scheduled task pod
  servisním účtem do uživatelského store nevidí.
- **NonExportable (softwarová pojistka) vs hardware klíč (fyzická nemožnost)** —
  mezistupně nejsou selhání, jsou to úrovně podle hodnoty credentialu.
- **MFA token (FIDO2/passkey, prokazuje člověka) vs PIV credential (prokazuje aplikaci)** —
  tentýž YubiKey ve dvou nesouvisejících rolích; „máme YubiKeys" samo o sobě neříká nic
  o tom, co je zabezpečené.
- **Hardware klíč vs managed identity** — první patří k člověku, druhá k bezobslužné
  automatizaci. Klíč s dotykem u nočního tasku je chyba nasazení.

## Zdroje (Microsoft)

- [Certificate credentials for application authentication](https://learn.microsoft.com/en-us/entra/identity-platform/certificate-credentials)
- [about_Certificate_Provider (PowerShell)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/about/about_certificate_provider)
- [New-SelfSignedCertificate](https://learn.microsoft.com/en-us/powershell/module/pki/new-selfsignedcertificate)
- [Azure Key Vault keys overview](https://learn.microsoft.com/en-us/azure/key-vault/keys/about-keys)
- [Passwordless authentication s FIDO2 / passkeys (Entra)](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-authentication-passwordless)
- [YubiKey Manager (`ykman`) — Yubico](https://developers.yubico.com/yubikey-manager/)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Podporované algoritmy a délky klíčů pro certifikátové app-only přihlášení (dnes RSA),
> stejně jako doporučená doba platnosti certifikátu, se mění — ověřit v dokumentaci
> certificate credentials před během.
