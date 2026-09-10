# Instructor notes — Elevovaný přístup

## Timing

- **30 min výklad + 60 min lab = 90 min.** Blok 2 dne 4, hned za výkladovým Azure blokem.
- Lab má **13 kroků v šesti částech**, každý s *co* a *proč* a s ruční i skriptovou
  variantou. Části a jejich rozpočet: 1) ručně 5 · 2) seznamy 10 · 3) identita 15 ·
  4) notebook 10 · 5) **Azure 20** · 6) brána 5.
- **Nový modul od 2026-09-10.** Do té doby to bylo 15min instruktorské demo uvnitř bloku 1.
  Den 4 byl v reálném nasazení **příliš akademický** — mluvil o hostingu a identitách
  a studenti si nic nepostavili.

> [!IMPORTANT] Co je v tomhle labu nejdůležitější — nesplést si to
> **Není to autorizační brána.** Je to **rozdíl mezi částí 4 a částí 5**: na notebooku
> se skript hlásí certifikátem, který musíš uložit, chránit a vyměňovat; v Azure se hlásí
> `-ManagedIdentity` a v celém runbooku není žádný secret. A provede tutéž operaci.
>
> Věta, se kterou má skupina odejít: **nezmizel principál, zmizel secret** — a s ním
> všechno, co se dá zkopírovat, vyexportovat nebo poslat mailem.
>
> Brána je až část 6 a je to **důsledek**, ne pointa: aplikace teď smí víc než člověk,
> který ji spustil, tak tam musí být jedna podmínka. Jeden krok, ne climax. (Do 2026-09-10
> byla brána označená za „nejdůležitější krok celého labu" — to bylo špatně a bylo to
> opravené právě proto, že modul má vysvětlit Azure lidem, kteří ho nikdy nepoužili.)

- **Když se krátí, drž části 1, 4 a 5** — ruční operace, certifikát, nic. To je ta linie.
  Části 2 a 3 se dají dodat hotové skriptem, který je v labu.
- **Část 5 nikdy nekrátit.** Studenti přijdou z bloku 1 se sync skriptem, který nikde
  neběží; tohle je pro většinu **první nasazení do Azure vůbec**.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Projít celý lab jednou nanečisto**, včetně Azure části. Rozbití dědění oprávnění na
  položce ani portálové cesty se před skupinou improvizovat nedají.
- **ZMĚŘIT, která per-site úroveň stačí na `Set-PnPListItemPermission`.** Krok 7b je
  **plánovaný náraz**: lab dá aplikaci `Write`, ono to spadne na `Access denied`, a student
  pak zvyšuje `Manage` → `FullControl`, dokud to neprojde. Ta didaktika je správná — least
  privilege se hledá odspodu — ale **ty nesmíš být ten, kdo to v sále zjišťuje poprvé.**
  25 lidí bisektujících oprávnění naživo je katastrofa. Projdi to předem a **poznamenej si
  výsledek**. Očekávání: `Write` nestačí (dává jen čtení a změnu obsahu), `FullControl`
  stačí. **Jestli projde už `Manage`, je to lepší odpověď a patří do labu jako fakt** —
  dopiš ji tam.

> [!NOTE] Proč to v labu není napsané dopředu
> Protože mapování rolí `Sites.Selected` na SharePoint permission levels dokumentace
> neuvádí dost přesně a **nedá se poctivě tvrdit bez měření**. Lab proto nechává studenta,
> aby to zjistil — a je to zároveň nejlepší lekce o least privilege, jakou ten blok má.
>
> Do 2026-09-10 tam stálo „`Write` je minimum, které úlohu splní". To byl **nepodložený
> odhad autora** a je opravený. Poučení pro celý repo: u oprávnění nepsat „stačí X", dokud
> to někdo nespustil.

- **Interní názvy polí.** Sloupec vytvořený jako „Request Status" má interní název
  `Request_x0020_Status` a skript ho nenajde. Je to nejčastější důvod, proč lab nejede,
  a chybová hláška na to neukáže. V labu je proto `Get-PnPField ... | Select InternalName`
  jako ověřovací krok — trvej na něm.
- **Dva per-site granty, dvě identity.** Nejpravděpodobnější místo, kde lab spadne:
  část 4 jede pod **app registrací s certifikátem**, část 5 pod **managed identitou
  Automation accountu**. Jsou to dva service principaly a **každý potřebuje svůj vlastní
  grant**. Kdo v části 5 spoléhá na grant z kroku 5, dostane `Access denied` a hláška na
  příčinu neukáže. V labu to je jako `[!IMPORTANT]` u kroku 10 — projdi to s nimi nahlas.
- **Automation account není v provisioning rozsahu** (`../../environment.md` vyjmenovává
  Storage, Function App, Event Grid, Log Analytics + DCR). Student si ho pod rolí
  Contributor na vlastní RG vytvořit umí — a v labu je to krok 8 — ale rozhodni se předem,
  jestli to necháš na nich, nebo doplníš do `New-CourseStudentAzureResources.ps1`.
- **Contributor na resource group nesmí zakládat resource groups.** V portálu musí
  v „Create a resource" vybrat **existující** `rg-goc223-<jmeno>`, ne „Create new".
  Klasické místo, kde se 25 lidí zasekne naráz.
- **Import PnP.PowerShell trvá minuty.** Ideálně ho nech spustit hned na začátku části 5
  a mezitím vykládej krok 10 — jinak se čeká.
- **Ověřit, že v Automation accountu je vidět blazena Modules.** Když ne, účet používá
  *Runtime environment* zkušenost a moduly se spravují jinde.
- **App role assignment managed identitě** potřebuje GA nebo Privileged Role Administrator.
  Studenti jsou GA (viz `../../environment.md`), takže projde — ale ověř to na jednom účtu.
- **Ověřit, že audit seznam má Members jen čtení.** Studenti to přeskakují a pak nechápou,
  proč je to v `Ověření`.
- **Lab si vystačí s jedním účtem** — nic nepárovat do dvojic, nic nezřizovat.

## Tripwires

- **Nezačínej cmdlety, začni krokem 1.** Nech je přidělit přístup rukama a spočítat
  kliknutí. Bez toho je celý zbytek odpověď na otázku, kterou si nikdo nepoložil.
- **Po části 4 se zastav a nech otázku dozrát.** „Funguje to — a co teď držíte v ruce?"
  Odpověď je certifikát. Teprve pak jdi do Azure. Kdo části 4 a 5 slepí, zabije pointu.
- **Někdo se zeptá, jestli to není jen heslo uložené u Microsoftu.** Je to dobrá otázka
  a odpověď je v labu: principál nezmizel, zmizel secret. Neuhýbej — přiznej, že kdo má
  Contributor na tu resource group, ten pod tou identitou runbook spustit umí. Právě proto
  se Azure RBAC na resource group řeší jako oprávnění.
- **`Test pane` vs `Publish`.** Kdo ladí v Test pane a zapomene publikovat, dostane při
  dalším běhu starý kód a z výstupu to nepozná.
- **U Power Automate nesklouznout do hanění.** Studenti tam mají postavené věci, které
  fungují: flow dělá interakci s člověkem, skript dělá privilegovanou operaci. Pomáhá
  zmínit, že **service principal jako vlastník kritických flow doporučuje sám Microsoft** —
  je to tatáž aplikační identita, jen s vrstvou Power Platform navíc. Viz
  [`comparison-power-automate.md`](comparison-power-automate.md).

## Vazby

- Zpět: app registrace a `Sites.Selected` z
  [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/), certifikátová
  identita z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).
  **Část 4 labu na obojím přímo stojí** — kdo je nemá, nedojde dál než do části 3.
- Zpět: [`../azure-integration-patterns/tutorial-script-to-azure.md`](../azure-integration-patterns/tutorial-script-to-azure.md)
  z bloku 1 je stejná Azure cesta na neutrálním skriptu. Kdo ho odučil, má část 5
  za deset minut.
- Dopředu: disciplína audit seznamu (retence, neměnnost, Members jen čtení) se dotahuje
  v [`../lifecycle-compliance/`](../lifecycle-compliance/).
- Dopředu: `-SystemUpdate`, kterým skript zapisuje stav žádosti, nechá `Modified`
  nedotčené — slepá skvrna detekce driftu, viz
  [`../azure-integration-patterns/guide-copy-metadata.md`](../azure-integration-patterns/guide-copy-metadata.md).
