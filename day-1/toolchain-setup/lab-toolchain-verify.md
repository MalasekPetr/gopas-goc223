# Lab · Instalace a ověření toolchainu

> Odhad: 30 min (20 min na předinstalované učebně) · Režim: lokální stroj

## Cíl

Student má na stroji ověřený toolchain pro celý týden a **vlastní ověřovací skript**,
který kdykoli řekne, co chybí — a dá se předat kolegovi.

## Předpoklady

- Windows stroj s `winget` (Windows 11, nebo App Installer z Microsoft Store).
- Právo instalovat do uživatelského profilu. **Administrátor není potřeba** — všechny
  kroky níže jsou user-scope.
- Síť na `winget`, VS Code Marketplace, PowerShell Gallery a npm registry (viz Fallback).

> [!NOTE] Předinstalovaná učebna
> Pokud instruktor rozdal stroje s hotovým image, přeskočte části A–C a jděte rovnou
> na část D. Ověření je stejně povinné — image bývá starší, než si myslíte.

## Kroky

### Část A — runtime

1. Nainstalovat PowerShell 7, Git a fnm. **Otevřít nové okno terminálu** po instalaci,
   jinak se změny v `PATH` neprojeví:

   ```powershell
   winget install --id Microsoft.PowerShell --source winget
   winget install --id Git.Git --source winget
   winget install --id Schniz.fnm --source winget
   ```

2. Zapnout fnm v PowerShell profilu. Řádek zajistí, že se verze Node přepne automaticky
   podle `.node-version` v repozitáři, do kterého vejdete:

   ```powershell
   if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
   Add-Content -Path $PROFILE -Value 'fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression'
   ```

   Zavřít a znovu otevřít PowerShell 7.

3. Nainstalovat Node 22 LTS a nastavit ho jako výchozí:

   ```powershell
   fnm install 22
   fnm default 22
   fnm use 22
   node --version
   ```

### Část B — nástroje

4. PowerShell moduly, vše do uživatelského profilu:

   ```powershell
   Install-Module PnP.PowerShell   -Scope CurrentUser -Force
   Install-Module Microsoft.Graph  -Scope CurrentUser -Force
   Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
   Install-Module Pester           -Scope CurrentUser -Force -SkipPublisherCheck
   Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser -Force
   ```

   Poslední řádek je **SPO Management Shell** — třetí z kurzovní trojice modulů
   (PnP / Graph / SPO). Potřebujete ho pro tenant-wide nastavení mimo rozsah PnP a pro DAG reporty
   SharePoint Advanced Management ([`../../day-5/permission-discovery/`](../../day-5/permission-discovery/)).
   V PowerShellu 7 může jeho import vyžadovat `-UseWindowsPowerShell` — detail
   v [`../../day-2/powershell-deep-dive/explainer-module-management.md`](../../day-2/powershell-deep-dive/explainer-module-management.md).

5. CLI for Microsoft 365 (proto je na stroji Node):

   ```powershell
   npm install -g @pnp/cli-microsoft365
   m365 --version
   ```

### Část C — VS Code

6. Nainstalovat PowerShell rozšíření. Přes příkazovou řádku, ať je to zopakovatelné:

   ```powershell
   code --install-extension ms-vscode.powershell
   ```

7. Ve VS Code otevřít Command Palette (`Ctrl+Shift+P`) → **PowerShell: Show Session Menu**
   a zkontrolovat, že vybraná session je **PowerShell 7**, ne Windows PowerShell.

### Část D — ověřovací skript (jádro labu)

8. Založit lokální repozitář (`git init`) se složkou `scripts/` a v ní
   `scripts/verify-toolchain.ps1`. Tenhle repozitář používáte celý týden — vzdálený
   repozitář a push k němu přidáte v bloku [`../vscode-copilot-env/`](../vscode-copilot-env/).
   Skript musí:
   - vypsat verze: `pwsh`, `git`, `node`, `npm`, `m365` a všech pěti PowerShell modulů;
   - **porovnat je proti minimálním verzím** v `param()` bloku (PowerShell `7.4.0`,
     Node `18.0.0`), ne jen vypsat;
   - u chybějící položky napsat **příkaz, kterým se doinstaluje**, ne jen „chybí";
   - skončit nenulovým exit kódem, pokud něco chybí (aby se dal použít v CI);
   - nespadnout na první chybějící položce — projít všechny a nahlásit souhrn.

9. Do repa přidat `.node-version` s obsahem `22` a `.vscode/extensions.json`
   s doporučeným rozšířením:

   ```json
   {
     "recommendations": ["ms-vscode.powershell"]
   }
   ```

10. Spustit `verify-toolchain.ps1` a **commitnout lokálně** spolu s oběma soubory z kroku 9.
    Vzdálený repozitář zatím žádný není — push přijde v bloku
    [`../vscode-copilot-env/`](../vscode-copilot-env/).

## Ověření

- [ ] `$PSVersionTable.PSVersion` vrací **7.4.0 nebo vyšší**.
- [ ] `node --version` vrací `v22.x`, `m365 --version` vrací verzi bez chyby.
- [ ] `Get-Module PnP.PowerShell -ListAvailable` vrací nainstalovanou verzi.
- [ ] `Get-Module Microsoft.Online.SharePoint.PowerShell -ListAvailable` vrací verzi —
      bez něj neodjedete SPO větev wrapperu v Labu 1 dne 2.
- [ ] Ve VS Code je aktivní PowerShell 7 session (Session Menu), ne 5.1.
- [ ] `verify-toolchain.ps1` proběhne, vypíše všechny položky a skončí exit kódem `0`.
- [ ] Skript **detekuje chybu**: dočasně zvýšit požadovanou verzi Node v `param()` na `99.0.0`,
      spustit znovu — musí ohlásit nesoulad, navrhnout příkaz a skončit nenulovým kódem.
      Pak vrátit zpět.
- [ ] `.node-version` a `.vscode/extensions.json` jsou v repu a commitnuté.

## Fallback

- **Blokovaný `winget`** — instruktor rozdá offline instalátory (PowerShell `.msi`,
  Git, Node `.msi`) ze sdílené složky. Bez fnm se pracuje s jedním globálním Node;
  `.node-version` v repu pak slouží jen jako dokumentace, což je stále lepší než nic.
- **Blokovaná PowerShell Gallery** — instruktor rozdá moduly jako `.zip` k rozbalení do
  `$env:PSModulePath`; ověřovací skript funguje beze změny.
- **Blokovaný npm registry** — CLI for Microsoft 365 vypadne. Kurz tím **není zablokovaný**:
  všechny povinné laby mají PnP PowerShell cestu, CLI je alternativa. Zaznamenat to jako
  nález (v reálném projektu je to blocker pro CI) a pokračovat.
- **Blokovaný VS Code Marketplace** — nainstalovat rozšíření z `.vsix` souboru
  (Extensions → `...` → Install from VSIX), instruktor ho má připravený.
