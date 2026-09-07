# Instructor notes — Toolchain skriptera

## Timing

- 15 min výklad + 30 min lab. **Na předinstalované učebně 15 + 20 min** (části A–C
  odpadají, ověřovací skript v části D zůstává — to je jádro, ne instalace).
- Tohle je blok, který se **nesmí protáhnout na úkor ostatních**. Kdo v 30 minutách
  nedojede, dojede o pauze; zbytek skupiny nečeká. Instalace je mechanická, ověřovací
  skript je to, co se učí.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Nejlevnější řešení celého bloku je předinstalovaný image.** Domluvit s učebnou
  PowerShell 7.4+, Git, fnm + Node 22, VS Code s PowerShell rozšířením a čtyři moduly.
  Ušetří 25× stahování a odstraní většinu tripwires níže. Ověřovací skript se pak stává
  jádrem bloku, což je pedagogicky lepší než 25 lidí čekajících na `winget`.
- **Projet celý lab na čistém stroji den předem** a zapsat si skutečné verze —
  minimální verze v labu (PowerShell 7.4.0, Node 18) jsou k datu psaní a posouvají se.
  Na go/no-go stačí pustit [`solution/verify-toolchain.ps1`](solution/verify-toolchain.ps1) —
  je to zároveň nejrychlejší kontrola připravenosti učebního image a podklad pro fallback
  „instruktor rozdá předpřipravený repozitář".
- **Ověřit síť z učebny na všechny čtyři cíle**: `winget` (`cdn.winget.microsoft.com`),
  VS Code Marketplace, PowerShell Gallery (`www.powershellgallery.com`), npm registry
  (`registry.npmjs.org`). Firewall v učebnách často pouští jen část — zjistit **předem**,
  který fallback bude potřeba, ne v 9:15 ráno.
- **Ověřit, že studentské účty smí instalovat do uživatelského profilu.** Všechny kroky
  labu jsou user-scope právě proto, ale politika stroje to umí zakázat i tak.
- **Mít připravené offline artefakty** pro každý fallback z labu: instalátory, moduly
  jako `.zip`, `.vsix` PowerShell rozšíření. Na USB nebo ve sdílené složce.
- **`winget` nemusí existovat** — na starším Windows 10 image chybí App Installer.
  Zkontrolovat `winget --version` na jednom stroji.

## Tripwires

- **Nové okno terminálu po instalaci.** Nejčastější „nefunguje to" celého bloku:
  `winget` doinstaluje, ale běžící session má starý `PATH`. Říct to nahlas dřív, než
  se první ruka zvedne, ne potom.
- **fnm bez řádku v profilu nedělá nic viditelného.** `fnm install 22` projde, ale
  `node --version` hlásí, že příkaz neexistuje. Krok 2 labu se nesmí přeskočit a je to
  jediný krok, kde se edituje profil — proto to není jednořádkový příkaz, ale test
  existence souboru plus `Add-Content`.
- **`$PROFILE` v PowerShell 7 je jiný soubor než ve Windows PowerShell 5.1.** Kdo řádek
  vloží v 5.1 a pak spustí `pwsh`, diví se. Trvat na tom, že se celý lab dělá v `pwsh`.
- **Pester 5 vs vestavěná Pester 3.4.0.** Windows má předinstalovanou starou Pester
  podepsanou Microsoftem — `Install-Module Pester` bez `-SkipPublisherCheck` selže na
  neshodě vydavatele. Proto je ten přepínač v labu; počítat s dotazem „proč zrovna tady".
  **Pozor na tichou variantu téhož problému:** kontrola „je modul k dispozici?" na
  předinstalované 3.4.0 projde jako OK, ačkoli `Should -Invoke` z
  [`../vscode-copilot-env/explainer-quality-gates.md`](../vscode-copilot-env/explainer-quality-gates.md)
  v ní neexistuje. Referenční řešení proto u Pesteru **pinuje minimum 5.0.0** a u ostatních
  modulů ne — je to dobrá otázka do diskuze: *kdy verzi pinovat a kdy ne?*
- **VS Code se umí přilepit na Windows PowerShell 5.1** jako výchozí session, i když je
  7.4 nainstalovaná. Krok 7 (Session Menu) není kosmetika — bez něj student celý týden
  ladí v 5.1 a diví se, proč se PnP modul nenačte.
- **`Microsoft.Graph` je velký meta-modul** a instaluje se dlouho (desítky sub-modulů).
  Na pomalé síti to je nejdelší příkaz labu. Pustit ho jako první a mluvit přes to.
- **SPO Management Shell v PowerShell 7** může při importu vyžadovat `-UseWindowsPowerShell`.
  Instalace projde vždy, problém se projeví až při prvním `Connect-SPOService` v D2. Ověřit
  na demo stroji předem a mít po ruce jednořádkovou odpověď — je to nejčastější „ten modul
  je rozbitý" celého kurzu, přitom jde jen o kompatibilitní shim.
- Dotaz „proč ne prostě Node z instalátoru" padne skoro jistě. Odpověď je provozní, ne
  technická, a je v README — netvrdit, že instalátor je špatně, protože pro jeden projekt
  není.
- Dotaz „proč potřebuju Node, když píšu PowerShell" padne taky. Odpověď: **jen kvůli CLI
  for Microsoft 365**, které je distribuované jako npm balíček. Nic v kurzu se v Node
  nevyvíjí. Neslibovat víc.

## Vazby

- Dopředu: bez tohoto bloku nepojede **nic** — [`../vscode-copilot-env/`](../vscode-copilot-env/)
  hned navazuje repozitářem a `tasks.json` nad PSScriptAnalyzer/Pester, D2 Lab 1 staví na
  PnP PowerShell a certifikátu.
- **Repozitář vzniká tady** (`git init`, lokálně), ne až v dalším bloku — `verify-toolchain.ps1`
  je jeho první obsah. Vzdálený repozitář a push přidává
  [`../vscode-copilot-env/`](../vscode-copilot-env/); pokud lab přeteče, stačí, že skript
  existuje ve `scripts/`, commit se dožene později.
- Zpět: navazuje na účet a pravidla z [`../onboarding/`](../onboarding/); stroj a účet
  jsou dvě půlky téže připravenosti.
