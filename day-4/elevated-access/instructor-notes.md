# Instructor notes — Elevovaný přístup

## Timing

- **30 min výklad + 60 min lab = 90 min.** Blok 2 dne 4, hned za výkladovým Azure blokem.
- **Nový modul od 2026-09-10.** Do té doby to bylo 15min instruktorské demo uvnitř bloku 1
  (`guide-elevated-op.md`). Důvod přestavby: den 4 byl v reálném nasazení **příliš
  akademický** — mluvil o hostingu a identitách a studenti si nic nepostavili. Tohle je
  nejkonkrétnější věc celého dne, tak dostala vlastní blok a poctivý step-by-step lab.
- Lab **nekrátit pod krok 7** (zamítnutí). Kroky 1-6 postaví funkční přidělení, ale teprve
  krok 7 dokáže, že to není generální klíč — a to je celá pointa bloku.

> [!NOTE] Kapacita dne je vyřešená — zaplatil to blok 1
> D4 = 80 + **90** + 120 + 100 = **390 min / 6,5 h**, přesně na stropu. Těch 90 minut se
> vzalo z bloku 1: **Lab 3 zkrácen 90 → 45 min**, protože jeho registrace do Task
> Scheduleru se s **krokem 8** tohohle labu překrývala — a tady se táž věc dělá v Azure,
> kam plánovaný běh v tomhle kurzu patří. Zbytek úspory je demo kopie s metadaty vyjmuté
> z povinného odhadu a 5 min výkladu.
>
> Praktický důsledek pro tebe: **studenti přijdou z bloku 1 se sync skriptem, který nikde
> neběží.** Krok 8 je pro ně první nasazení do Azure vůbec, takže si na něj nechej čas
> a nezkracuj ho — je to ta věc, kvůli které celá přestavba dne vznikla.

## Go/no-go — KLÍČOVÉ, otestovat před během

- **Projít celý lab jednou nanečisto.** Rozbití dědění oprávnění na položce se před
  skupinou improvizovat nedá.
- **Založit oba seznamy na demo webu** a zkontrolovat **interní** názvy polí
  (`Get-PnPField -List ... | Select Title, InternalName`) — sloupec vytvořený jako
  „Request Status" má interní název `Request_x0020_Status` a skript ho nenajde. Je to
  nejčastější důvod, proč lab studentovi nejede, a chybová hláška na to neukáže.
- **Udělit `Sites.Selected` per-site grant** a ověřit ho `Get-PnPAzureADAppSitePermission`.
- **Lab si vystačí s jedním účtem** — nic nepárovat do dvojic, nic nezřizovat. Krok 7
  vyrábí neshodu `RequesterEmail` vs `Author` tím, že student napíše do pole cizí adresu.
  (Do 2026-09-10 lab druhý účet vyžadoval; vyhozeno záměrně — na první seznámení
  s technologií to zesložiťovalo něco, co jde ukázat jedním řádkem.)
- **Ověřit, že audit seznam má Members jen čtení.** Studenti to přeskakují a pak nechápou,
  proč je to v `Ověření`.
- Pro krok 8 platí go/no-go z
  [`../azure-integration-patterns/tutorial-script-to-azure.md`](../azure-integration-patterns/tutorial-script-to-azure.md) —
  hlavně že v Automation accountu je vidět blazena **Modules** (jinak účet používá Runtime
  environments) a že import `PnP.PowerShell` je hotový **před** blokem, ne během něj.

## Tripwires

- **Nejsilnější moment je zamítnutá žádost, ne úspěšná.** Nechte studenty nejdřív uvidět,
  jak jim to přidělí přístup — a pak je pošlete na krok 7. Ten kontrast dělá tu lekci.
- **U Power Automate nesklouznout do hanění.** Studenti tam mají postavené věci, které
  fungují. Materiál to říká výslovně: flow dělá interakci s člověkem, skript dělá
  privilegovanou operaci. Kdo z bloku odejde s dojmem „Power Automate je špatný", odnesl
  si opak toho, co je v [`comparison-power-automate.md`](comparison-power-automate.md).
  Pomáhá zmínit, že **service principal jako vlastník kritických flow doporučuje sám
  Microsoft** — je to tatáž aplikační identita, jen s vrstvou Power Platform navíc.
- **Dvoustupňová brána: nenechat je postavit jen jeden stupeň.** Typická odevzdávka má
  kontrolu v kódu a otevřený seznam, nebo zamčený seznam a žádnou kontrolu. Ptejte se
  „a co se stane, když ti řádek založí někdo jiný z tenantu?"
- **`-WhatIf` není formalita.** Kdo ho přeskočí a má překlep v `TargetItemId`, rozbije
  dědění oprávnění na cizí položce. V labu je to krok 5 schválně před krokem 6.
- Studenti si pletou **zobrazovaný a interní název pole** — viz go/no-go výše.

## Vazby

- Zpět: app registrace a `Sites.Selected` z
  [`../../day-2/automation-strategy/`](../../day-2/automation-strategy/), certifikátová
  identita z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/).
- Zpět: nasazení do Azure řeší
  [`../azure-integration-patterns/tutorial-script-to-azure.md`](../azure-integration-patterns/tutorial-script-to-azure.md)
  z bloku 1 — tenhle blok ho jen použije, neopakuje ho.
- Dopředu: disciplína audit seznamu (retence, neměnnost, Members jen čtení) se dotahuje
  v [`../lifecycle-compliance/`](../lifecycle-compliance/).
- Dopředu: `-SystemUpdate`, kterým skript zapisuje stav žádosti, nechá `Modified`
  nedotčené — a to je slepá skvrna detekce driftu, viz
  [`../azure-integration-patterns/guide-copy-metadata.md`](../azure-integration-patterns/guide-copy-metadata.md).
