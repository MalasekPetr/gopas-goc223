# Lab · Unified connect wrapper & logging scaffolding

> Odhad: 60 min · Režim: simulace | živý tenant

## Cíl

Student má PowerShell funkci, která sjednotí připojení napříč PnP.PowerShell, Microsoft.Graph
a SPO Management Shell pod jedním rozhraním s volitelným auth módem a strukturovaným logováním.

## Předpoklady

- App registrace z [`../automation-strategy/`](../automation-strategy/) (`ClientId`).
- Nainstalované moduly: `PnP.PowerShell`, `Microsoft.Graph.Authentication`,
  `Microsoft.Online.SharePoint.PowerShell`.

## Kroky

1. Napsat funkci `Connect-CourseTarget` s parametry `-Module (PnP|Graph|SPO)`,
   `-AuthMode (Interactive|DeviceCode|Certificate)`, `-ClientId`, volitelně
   `-CertificateThumbprint`/`-TenantId`.
2. Uvnitř funkce mapovat kombinaci `-Module`/`-AuthMode` na správný `Connect-*` cmdlet a jeho
   parametry (např. PnP interactive → `Connect-PnPOnline -Interactive -ClientId`).
3. Přidat logging scaffolding — strukturovaný log (objekt/JSON řádek s timestamp, modul,
   auth mode, výsledek), ne jen `Write-Host`.
4. Otestovat funkci se dvěma různými kombinacemi modul/auth mode.

## Ověření

- [ ] `Connect-CourseTarget -Module PnP -AuthMode Interactive -ClientId <id>` úspěšně připojí.
- [ ] Log obsahuje strukturovaný záznam s výsledkem připojení (úspěch/chyba), ne jen text na
      konzoli.
- [ ] Funkce nemá žádný natvrdo zapsaný identifikátor (tenant ID, ClientId) v těle skriptu.

## Fallback

Pokud device code / certificate flow nelze v učebně otestovat živě (chybí druhé zařízení,
cert nestihl vygenerovat), student implementuje a manuálně prochází logiku (dry-run bez
reálného volání `Connect-*`), instruktor demonstruje živé připojení na projektoru.
