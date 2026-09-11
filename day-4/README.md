# Den 4 — Azure integrace, SIEM a lifecycle

Azure integrační vzory jako vstupní znalost, na ni navázaná **elevovaná operace nad
SharePointem, kterou si studenti postaví a nasadí**, SIEM logging pipeline a lifecycle
& compliance enforcement — den, který uzavírá provozní a governance linku týdne.
**~6,5 h povinně** — ověřeno reálným během 2026-09-10, den vyšel podle plánu.

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Azure integrační vzory *(výklad + tutorial nasazení; Lab 3, 45 min)* | [`azure-integration-patterns`](azure-integration-patterns/) | P |
| 2 | **Elevovaný přístup: self-service žádost o oprávnění** *(lab)* | [`elevated-access`](elevated-access/) | P |
| 3 | SIEM integrace přes Azure Blob | [`siem-blob-integration`](siem-blob-integration/) | P |
| 4 | Lifecycle & compliance enforcement | [`lifecycle-compliance`](lifecycle-compliance/) | P |

> [!IMPORTANT] Přestavba 2026-09-10 — den přestal být akademický a vejde se do stropu
> **Důvod:** den 4 mluvil o Azure hostingu a identitách celý den, ale studenti si nic
> nepostavili — a v celém repu nebyl **jediný postup, jak skript do Azure dostat**.
>
> **Co přišlo:**
> - **Blok 2** [`elevated-access/`](elevated-access/) (30 výklad + 60 lab) — plnohodnotný
>   modul se step-by-step labem o **13 krocích v šesti částech** (ručně -> certifikát -> nic).
>   Do té doby to bylo 15min demo uvnitř bloku 1.
> - **Tutorial** [`azure-integration-patterns/tutorial-script-to-azure.md`](azure-integration-patterns/tutorial-script-to-azure.md)
>   — krok za krokem přes Automation Runbook na neutrálním skriptu. Lab bloku 2 jede tutéž cestu v části 5.
>
> **Čím se zaplatilo — 70 min z bloku 1 (150 → 80):**
> - **Lab 3: 90 → 45 min.** Registrace do Task Scheduleru odešla do bloku 2, kde se táž
>   věc dělá **v Azure**. Task Scheduler na učebním image bývá blokovaný policy, takže
>   to byl krok s nejvyšší mírou selhání. Zůstalo jádro: delta přes business klíč
>   a idempotence.
> - **Demo kopie s metadaty: -20 min z povinného odhadu.** README ho označovalo za „mimo
>   agendu" a přitom se počítalo do 150 — to byl rozpor, ne rozhodnutí. Demo zůstává,
>   spouští se na dotaz.
> - **Výklad: 40 → 35 min.** Srovnání Runbook vs Function je teď v tutoriálu.
>
> **Výsledek: 80 + 90 + 120 + 100 = 390 min = 6,5 h**, přesně na stropu.

> [!NOTE] Přestavba 2026-09-09 — blok 1
> ~30min instruktorské demo change notifications nahradilo **20min demo kopie dat se
> zachováním metadat**
> ([`azure-integration-patterns/guide-copy-metadata.md`](azure-integration-patterns/guide-copy-metadata.md)).
> Z obou dem je to jediné, které **reálně zapíše do SharePointu z Functiony běžící
> v Azure** — a den je přitom celý o Azure integraci. Function App, kterou demo nasadí,
> si navíc přebírá blok 2 pro Blob trigger.
>
> Bonus je vazba na blok 3: zápis přes `SystemUpdate` nechá `Modified` nedotčené, takže
> detekce driftu postavená na `Modified` ho neuvidí. Blok 1 tu slepou skvrnu pojmenuje,
> blok 3 na ni narazí. Zadání labu change notifications zůstává jako samostudium.

> [!NOTE] Azure resource group per student (`environment.md`) se poprvé reálně používá
> v tomto dni — ověřit provisioning před během. Log Analytics workspace a DCR pro blok 2
> musí existovat předem.

> [!IMPORTANT] Blok 3 na baseline skriptu ze dne 3 **nestojí** — korektura 2026-09-09
> Do 2026-09-09 tu stálo, že [`lifecycle-compliance/lab-compliance-drift.md`](lifecycle-compliance/lab-compliance-drift.md)
> rozšiřuje diff/baseline skript ze [`../day-3/staging-environments/`](../day-3/staging-environments/)
> a že ho studenti mají z předchozího dne. **Nemají.** Lab stagingu je volitelný a v reálném
> běhu se neodučil, takže ten skript nikdy nevznikl.
>
> Lab bloku 3 je proto přeformulovaný: baseline si zapíše jako pár řádků JSON (očekávaná
> sharing hodnota pro web), což je stejně všechno, co potřebuje. Kdo skript z D3 má, nabalí
> to na něj a ušetří si strukturu reportu — je to **výhoda, ne podmínka**.

> [!NOTE] Přestavba 2026-09-08
> Blok 3 byl `staging-environments`; ten se vrátil na **D3** (tehdy kvůli labům, které jeho baseline
> skript měly potřebovat — to odůvodnění 2026-09-09 padlo, viz výše). Výměnou sem přišel `lifecycle-compliance` z D3 — den se tím časově
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
