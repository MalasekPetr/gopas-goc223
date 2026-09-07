# Lab · Report „k čemu má uživatel přístup"

> Odhad: 40 min · Režim: živý tenant

## Cíl

Student má skript, který pro zadaný UPN vrátí seznam webů s **cestou, kterou přístup
vede** — a na vlastní oči vidí rozdíl mezi verzí, která rozbaluje Entra skupiny, a verzí,
která je míjí.

## Předpoklady

- App registrace a app-only přihlášení z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).
- `Microsoft.Graph` a PnP PowerShell z [`../../day-1/toolchain-setup/`](../../day-1/toolchain-setup/).
- Weby `-dev/-test/-prod` z Labu 1 a **jedna Entra bezpečnostní skupina**, kterou si
  založíte v kroku 1.

## Kroky

### Část A — připravit případ, který naivní report mine

1. Založit bezpečnostní skupinu v Entra (`<jmeno-prijmeni>-access-test`), přidat do ní
   **souseda**, a **skupinu** (ne souseda přímo) přidat do SharePoint skupiny *Members*
   na svém `-dev` webu.

   Tím vznikl přesně ten případ z README: soused má na web přístup, ale v členech
   SharePoint skupiny je vidět **skupina**, ne on.

### Část B — naivní verze

2. Napsat `scripts/Get-UserAccess.ps1` s parametry `-UserPrincipalName` a `-SiteUrl`
   (pole, ne natvrdo). Pro každý web zjistit:
   - je uživatel **site collection admin**? (`Get-PnPSiteCollectionAdmin`)
   - je **přímo** členem některé SharePoint skupiny? (`Get-PnPGroup` + `Get-PnPGroupMember`)

   Vracet objekty s `SiteUrl`, `AccessVia` (`SiteAdmin` / `SharePointGroup:<název>`),
   `GroupName`. Žádný `Write-Host`.

3. Spustit skript **na souseda** proti svým třem webům. Výsledek: **žádný přístup** —
   ačkoli soused web reálně vidí. Zapsat si, proč.

### Část C — doplnit tranzitivní členství

4. Rozšířit skript: pro zadaného uživatele načíst všechna členství včetně vnořených

   ```powershell
   $userGroupIds = (Get-MgUserTransitiveMemberOf -UserId $UserPrincipalName -All).Id
   ```

   a při procházení členů SharePoint skupin porovnávat **i proti tomuto seznamu** —
   člen skupiny může být principál typu skupina, ne jen uživatel.

5. Doplnit `AccessVia` o hodnotu `EntraGroup:<název>`, aby výstup říkal **kudy** přístup
   vede, ne jen že existuje.

6. Spustit znovu na souseda. Teď se `-dev` web objeví s cestou přes Entra skupinu.
   **Rozdíl mezi krokem 3 a krokem 6 je celý smysl labu.**

### Část D — odolnost a výstup

7. Přidat do seznamu webů jednu **záměrně chybnou URL** a ověřit, že skript ji zaznamená
   a pokračuje, místo aby spadl.

8. Exportovat do CSV pro zadavatele:

   ```powershell
   $result | Export-Csv -Path .\user-access.csv -NoTypeInformation `
     -Encoding utf8BOM -UseCulture
   ```

9. Do hlavičky skriptu (`.NOTES`) zapsat **slepá místa** vlastními slovy: co tenhle report
   nevidí. Minimálně: přímá oprávnění na položkách při porušené dědičnosti a sharing links.

## Ověření

- [ ] Krok 3 vrací pro souseda prázdný výsledek, krok 6 vrací `-dev` web.
- [ ] `AccessVia` rozlišuje `SiteAdmin`, `SharePointGroup:*` a `EntraGroup:*`.
- [ ] Skript nespadne na chybné URL a nepřístupný web je ve výstupu zaznamenaný.
- [ ] CSV se v Excelu otevře se správnou diakritikou a rozdělené do sloupců.
- [ ] `.NOTES` jmenuje alespoň dvě slepá místa reportu.
- [ ] Student umí říct, proč nelze mít index „uživatel → weby" a co z toho plyne pro
      dobu běhu nad velkým tenantem.

> [!NOTE] Referenční řešení
> [`solution/Get-UserAccess.ps1`](solution/Get-UserAccess.ps1) + **11 testů**
> v [`solution/Get-UserAccess.Tests.ps1`](solution/Get-UserAccess.Tests.ps1).
> Otevřete až po vlastním pokusu. Dva testy fixují přesně ten kontrast, který v labu
> zažijete mezi krokem 3 a 6 — *naivní verze přístup nenajde*, *verze s `transitiveMemberOf`
> ano* — takže kdyby někdo při refaktoru sáhl po `memberOf`, testy to zachytí.
>
> Skript **nebyl testovaný proti živému tenantu**; ověřená je rozhodovací logika,
> ne skutečná volání.

## Fallback

- **`Get-MgUserTransitiveMemberOf` selže na oprávnění**: potřebuje `GroupMember.Read.All`
  nebo `Directory.Read.All`. Pokud consent nelze udělit, nahradit Graph voláním
  `GET /users/{id}/transitiveMemberOf` s tokenem app registrace z D2 — pointa je
  tranzitivita, ne konkrétní cmdlet.
- **Není soused / práce v páru nevychází**: použít vlastní účet a druhou Entra skupinu,
  do které se student přidá sám. Efekt je stejný, jen méně názorný.
- **Časový skluz**: vypustit část D (kroky 7-8). Části B a C ne — kontrast mezi krokem 3
  a 6 je jediný důvod, proč lab existuje.

> [!NOTE] SAM část je demo, ne lab
> Report *Site permissions for users* běží **1× za 30 dní** a tenant jich unese 5 —
> 25 studentů ho spustit nemůže. Instruktor ho ukáže na plátně (nebo ze screenshotů,
> pokud kurzovní tenant SAM nemá) a porovná jeho výstup s výstupem vašeho skriptu.
