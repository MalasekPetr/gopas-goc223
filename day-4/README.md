# Den 4 — Azure integrace, SIEM a staging

Azure integrační vzory jako vstupní znalost pro SIEM logging pipeline; staging prostředí
jako odpolední blok, který uzavírá provozní linku týdne — baseline jako deklarativní
artefakt a detekce driftu. **~6,3 h povinně.**

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Azure integrační vzory *(Lab 3)* | [`azure-integration-patterns`](azure-integration-patterns/) | P |
| 2 | SIEM integrace přes Azure Blob | [`siem-blob-integration`](siem-blob-integration/) | P |
| 3 | Staging prostředí: DEV, TEST, PROD | [`staging-environments`](staging-environments/) | P |

> [!NOTE] Azure resource group per student (`environment.md`) se poprvé reálně používá
> v tomto dni — ověřit provisioning před během. Log Analytics workspace a DCR pro blok 2
> musí existovat předem.

> [!NOTE] Přestavba 2026-09-07
> Den měl třetím blokem **Microsoft Clarity**. Ten byl z kurzu **vypuštěn** — z celého
> týdne to bylo téma nejvzdálenější automatizaci a migraci, a jeho slot potřeboval
> `staging-environments`, aby den 2 nevycházel na 8,2 h. Obecný mechanismus SPFx
> tenant-wide deploymentu, který Clarity demonstrovala, zůstává v kurzu zachovaný —
> řeší ho [`../day-5/app-catalog-lifecycle/`](../day-5/app-catalog-lifecycle/).
>
> Staging používá weby `-dev/-test/-prod` z Labu 1 (den 2), takže mezi jejich vytvořením
> a použitím jsou teď dva dny. Nevadí to — jen se v úvodu bloku vyplatí nechat studenty
> ověřit, že weby pořád stojí.
