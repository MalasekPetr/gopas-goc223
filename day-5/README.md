# Den 5 — App Catalog, security hardening & capstone

App Catalog uzavírá kruh s Clarity injekcí z D4 — tam jste tenant-wide deployment viděli
na jednom případu, tady je obecný mechanismus a jeho správa. Security hardening shrnuje least-privilege
vlákno celého týdne — a předchází mu reporting oprávnění, protože nelze zpřísňovat to,
o čem nevíte. Capstone spojuje migraci, provisioning a integrace do jednoho
end-to-end blueprintu. **~5,7–6,7 h.**

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | App Catalog: nasazení, upgrady a audit | [`app-catalog-lifecycle`](app-catalog-lifecycle/) | P |
| 2 | Kdo má k čemu přístup: reporting oprávnění | [`permission-discovery`](permission-discovery/) | P |
| 3 | Security hardening & least privilege | [`security-hardening`](security-hardening/) | P |
| 4 | Výkon, náklady & capstone | [`performance-cost-capstone`](performance-cost-capstone/) | P |

> [!NOTE] Blok 2 je vstupem do bloku 3 — hardening začíná tím, že víte, kdo co má.
> Jeho SAM část je **instruktorské demo** (report běží 1× za 30 dní, tenant jich unese 5),
> a pokud kurzovní tenant nemá SAM licenci, jede ze screenshotů.

> [!NOTE] Capstone je poslední blok kurzu — vyžaduje dokončené artefakty z D2 (migrace),
> D3 (provisioning) a D4 (integrace). Ověřit před během, že všechny navazující laby mají
> uložené výstupy dostupné pro capstone.
