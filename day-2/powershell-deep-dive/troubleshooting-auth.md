# Tahák · Troubleshooting připojení: „jsem připojený? a kdo vlastně jsem?"

Postup pro chvíli, kdy `Connect-PnPOnline` „projde", ale nic nefunguje — nebo neprojde
vůbec. Klíčová mentální kotva: **authn != authz** — *připojil jsem se* (autentizace)
ještě neznamená *smím něco* (autorizace). Každá vrstva má vlastní diagnostiku.

## Krok 1 — ověření připojení (tři úrovně důkazu)

```powershell
# a) Stav v pameti - kam a jako kdo si PowerShell MYSLI, ze je pripojeny
Get-PnPConnection | Select-Object Url, ConnectionType, ClientId, Tenant

# b) Co je v tokenu - koho/co token skutecne reprezentuje
$t = Get-PnPAccessToken -ResourceTypeName SharePoint -Decoded
$t.Audiences                                    # pro SPO musi byt https://<tenant>.sharepoint.com
$t.Claims | Where-Object Type -in 'roles','scp','upn','appid','app_displayname' |
  Select-Object Type, Value

# c) Realne volani - jediny skutecny dukaz
Get-PnPWeb | Select-Object Title, Url
Get-PnPTenantSite | Select-Object -First 3     # jen na -admin URL
```

(a) je jen objekt v paměti — existuje i s nefunkčním tokenem. (b) říká, co token
opravdu nese: **app-only má `roles` a nemá `upn`; delegated má `upn` + `scp` a nemá
`roles`** — nejrychlejší způsob, jak rozlišit, „kdo jsem". (c) je teprve důkaz.

> [!IMPORTANT] Past diagnostiky
> **`$t.Payload.aud` nefunguje.** Objekt z `-Decoded` (v PnP 3.x typ
> `Microsoft.IdentityModel.JsonWebTokens.JsonWebToken`) **nemá vlastnost `Payload`** —
> dotaz na ni tiše vrátí prázdno, bez chyby. Používat `.Audiences` a `.Claims`, nebo
> ruční dekódování payloadu, nezávislé na verzi modulu:
>
> ```powershell
> $raw = Get-PnPAccessToken -ResourceTypeName SharePoint
> $p = $raw.Split('.')[1].Replace('-','+').Replace('_','/')
> $p = $p.PadRight($p.Length + (4 - $p.Length % 4) % 4, '=')
> [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($p)) | ConvertFrom-Json |
>   Select-Object aud, roles, upn, appid, app_displayname
> ```
>
> Je to zároveň učební moment: **tichý prázdný výstup je horší než chyba** — návyk
> „ověřuj, že příkaz opravdu něco vrátil" platí i na diagnostické příkazy.

Token je jen JSON v base64url: tři části oddělené tečkou (hlavička, payload, podpis),
payload je obyčejný JSON. Proto do tokenu nikdy nepatří tajemství — **kdokoli, kdo token
drží, si ho přečte**; podpis brání změnám, ne čtení.

## Krok 2 — tabulka symptomů

| Symptom | Příčina | Oprava |
|---|---|---|
| `AADSTS700016` (no application found) | `Connect-PnPOnline` bez `-ClientId` — PnP od 9/2024 nemá výchozí | doplnit `-ClientId` vlastní app registrace |
| `AADSTS7000218` (must contain client_assertion or client_secret) | device code / flow bez redirect URI a vypnutý fallback *Allow public client flows* | app registrace → *Authentication → Settings* → přepnout na *Yes* (viz [`README.md`](README.md), public vs confidential client) |
| „The provided certificate is not of type **RSA**" | ECC certifikát — MSAL/Entra podporuje pro certifikátové app-only přihlášení RSA podpisy | vygenerovat RSA 2048 klíč + cert, vyměnit `.cer` na app registraci (**nový thumbprint!**) |
| Připojení projde, ale **`Unauthorized`** s prázdnou odpovědí na první cmdlet | token bez rolí — typicky oprávnění přidané jako **Delegated** místo **Application** (app-only delegated oprávnění ignoruje), nebo chybí admin consent | *API permissions* → SharePoint → **Application** → potřebné oprávnění → **Grant admin consent**; pak **nové připojení** (starý token roli nedostane) |
| Totéž — a Application permission „tam je" | consent udělen **po** připojení; token v paměti je starý | `Disconnect-PnPOnline` / nová konzole a připojit znovu; počítat s 1–2 min propagace |
| `403 Forbidden` (ne 401) | token role má, ale nestačí na operaci (čtecí role vs zápis) | porovnat `roles` v tokenu s potřebou cmdletu; rozšíření zdůvodnit — najde ho audit v [`../../day-5/security-hardening/`](../../day-5/security-hardening/) |
| Cert v `Cert:\CurrentUser\My` je, ale `HasPrivateKey` = `False` | ve store je jen veřejná část (import `.cer` místo párování s klíčem), nebo cert z čipové karty bez spárování | přegenerovat pár (`New-SelfSignedCertificate`), u smart card / HSM ověřit minidriver a propagaci certifikátu |
| „**Access was denied because of a security violation**" (žádný `AADSTS…`) | **lokální** krypto chyba — podpis privátním klíčem neproběhl, požadavek nikdy neodešel: klíč na čipové kartě čekal na dotyk/PIN a vypršel, nebo se PIN dialog nemá kde zobrazit (integrovaný terminál editoru) | spustit v samostatné konzoli, potvrdit PIN/dotyk, a izolovat podpis od MSAL (test níže) |

### Izolace podpisu — funguje vůbec klíč?

Obejde PnP i MSAL a testuje jen privátní klíč — nejrychlejší diagnóza „security violation":

```powershell
$c = Get-Item Cert:\CurrentUser\My\<thumbprint>
$c.HasPrivateKey          # musi byt True
$rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($c)
$rsa.SignData([byte[]](1..32), 'SHA256', 'Pkcs1') | Out-Null   # u HW klice: PIN dialog + dotyk
```

- **Projde** → klíč je v pořádku; problém je v kontextu volání (terminál, načasování)
  nebo v konfiguraci app registrace.
- **Spadne** → problém je mezi OS a klíčem, ne v Entra: chybí privátní klíč, nebo
  (u čipových karet) minidriver a propagace certifikátu do store.

## Dvě pasti na závěr

- **Stejná slova, dvě API**: SharePoint delegated oprávnění se jmenuje
  `AllSites.FullControl`, SharePoint application `Sites.FullControl.All` — a Graph má
  taky `Sites.FullControl.All`, které ale pro SPO REST volání (`Get-PnPWeb`,
  `Get-PnPTenantSite`) nepomůže. Vždy kontrolovat **API + Type + Status** (zelená
  fajfka), ne jen jméno.
- **Token žije v paměti připojení**: každá změna oprávnění nebo consentu se projeví až
  v novém tokenu — po změně v portálu vždy odpojit a připojit znovu.

## Zdroje (Microsoft)

- [Microsoft identity platform — chybové kódy AADSTS](https://learn.microsoft.com/en-us/entra/identity-platform/reference-error-codes)
- [Granting access via Microsoft Entra ID App-Only](https://learn.microsoft.com/en-us/sharepoint/dev/solution-guidance/security-apponly-azuread)
- [Permissions and consent overview](https://learn.microsoft.com/en-us/entra/identity-platform/permissions-consent-overview)
- [PnP PowerShell — Get-PnPAccessToken](https://pnp.github.io/powershell/cmdlets/Get-PnPAccessToken.html)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Typ objektu vracený `Get-PnPAccessToken -Decoded` a jeho vlastnosti se mezi verzemi
> PnP.PowerShell mění (proto je ruční dekódování spolehlivější volba do skriptů);
> texty chybových hlášek Entra se rovněž mění — vázat se na kód `AADSTS…`, ne na text.
