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

Dvě věci, které stojí za zdůraznění před začátkem dne:

- **Blok 3 nepotřebuje nic ze dne 3.** Lab
  [`lifecycle-compliance/lab-compliance-drift.md`](lifecycle-compliance/lab-compliance-drift.md)
  si baseline zapíše jako pár řádků JSON (očekávaná sharing hodnota pro web) — to je
  všechno, co potřebuje. Kdo má diff skript z [`../day-3/staging-environments/`](../day-3/staging-environments/),
  nabalí to na něj a ušetří si strukturu reportu. Je to **výhoda, ne podmínka**.
- **Blok 1 a blok 2 na sebe navazují technicky, ne jen tematicky.** Function App, kterou
  nasadí demo v bloku 1, přebírá blok 2 pro Blob trigger. A zápis přes `SystemUpdate`
  z bloku 1 nechá pole `Modified` nedotčené — detekce driftu postavená na `Modified` ho
  proto neuvidí. Blok 1 tu slepou skvrnu pojmenuje, blok 3 na ni narazí.

## Před během (lektor)

Azure resource group per student ([`../environment.md`](../environment.md)) se poprvé
reálně používá v tomto dni — ověřit provisioning předem. Log Analytics workspace a Data
Collection Rule (DCR) pro blok 2 musí existovat před začátkem.

Historie přestavby dne je v [`../CHANGELOG.md`](../CHANGELOG.md).
