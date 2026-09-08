# Den 4 — Azure integrace, SIEM a lifecycle

Azure integrační vzory jako vstupní znalost pro SIEM logging pipeline a na ně navázaný
lifecycle & compliance enforcement — den, který uzavírá provozní a governance linku
týdne. **~6,3 h povinně.**

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Azure integrační vzory *(Lab 3)* | [`azure-integration-patterns`](azure-integration-patterns/) | P |
| 2 | SIEM integrace přes Azure Blob | [`siem-blob-integration`](siem-blob-integration/) | P |
| 3 | Lifecycle & compliance enforcement | [`lifecycle-compliance`](lifecycle-compliance/) | P |

> [!NOTE] Azure resource group per student (`environment.md`) se poprvé reálně používá
> v tomto dni — ověřit provisioning před během. Log Analytics workspace a DCR pro blok 2
> musí existovat předem.

> [!IMPORTANT] Blok 3 staví na baseline skriptu ze dne 3
> [`lifecycle-compliance/lab-compliance-drift.md`](lifecycle-compliance/lab-compliance-drift.md)
> rozšiřuje diff/baseline skript z [`../day-3/staging-environments/`](../day-3/staging-environments/)
> o kontrolu sharing policy driftu. Studenti ho tedy mají z předchozího dne — v úvodu bloku
> se vyplatí nechat je ověřit, že jim skript pořád běží, než na něj začnou nabalovat
> compliance pravidla.

> [!NOTE] Přestavba 2026-09-08
> Blok 3 byl `staging-environments`; ten se vrátil na **D3**, před laby, které jeho baseline
> skript potřebují. Výměnou sem přišel `lifecycle-compliance` z D3 — den se tím časově
> nezměnil (oba bloky jsou 100 min) a vazba na staging je teď správným směrem, tedy
> do předchozího dne.
>
> Tematicky to sedí lépe než dřív: blok 2 staví telemetrickou pipeline a blok 3 nad ní
> navazuje governance pravidly. Retenci logů (blok 2) a retenci obsahu (blok 3) je přitom
> potřeba držet oddělené — jsou to jiné compliance požadavky.

> [!NOTE] Starší přestavba 2026-09-07
> Den měl třetím blokem **Microsoft Clarity**. Ten byl z kurzu **vypuštěn** — z celého
> týdne to bylo téma nejvzdálenější automatizaci a migraci. Obecný mechanismus SPFx
> tenant-wide deploymentu, který Clarity demonstrovala, zůstává v kurzu zachovaný —
> řeší ho [`../day-5/app-catalog-lifecycle/`](../day-5/app-catalog-lifecycle/).
