# Den 3 — Graph, staging, migrace & provisioning

Odolné volání Microsoft Graphu jako vstupní znalost dne, model tří prostředí s detekcí
driftu (jehož baseline skript pak používají dva další laby), migrace jako inženýrská
disciplína s druhým velkým labem (fileshare → SPO dle JSON plánu), automatizace zřizování
a volitelně governance nástroj (Orchestry, simulace).

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Microsoft Graph — inženýrské základy | [`graph-fundamentals`](graph-fundamentals/) | P |
| 2 | Staging prostředí: DEV, TEST, PROD | [`staging-environments`](staging-environments/) | P |
| 3 | Skladba migrací *(Lab 2)* | [`migration-patterns`](migration-patterns/) | P |
| 4 | Vzory automatizace zřizování | [`provisioning-patterns`](provisioning-patterns/) | P |
| 5 | Orchestry integrace & vlastní skripty (simulace) | [`opt-orchestry-integration`](opt-orchestry-integration/) | V |

> [!IMPORTANT] Pořadí bloků 1 a 2 není tematické — plyne z předpokladů labů
>
> - **Graph je blok 1**, protože [`migration-patterns/lab-fileshare-migration.md`](migration-patterns/lab-fileshare-migration.md)
>   má jeho retry vzory ve svých Předpokladech.
> - **Staging je blok 2**, protože jeho **diff/baseline skript** je vstupem pro
>   [`provisioning-patterns/lab-pnp-provisioning.md`](provisioning-patterns/lab-pnp-provisioning.md)
>   (krok 5 i položka v Ověření), pro předmigrační kontrolu v `migration-patterns`
>   a pro lab v [`../day-4/lifecycle-compliance/`](../day-4/lifecycle-compliance/).
>
> Baseline skript z bloku 2 je nejvíc znovupoužitý artefakt celého kurzu. Když se blok 2
> vypustí nebo přesune, přestanou fungovat tři laby, ne jeden.

> [!NOTE] Orchestry blok je volitelná simulace/koncept (bez živé licence) — integrační body
> se navrhují proti PnP.PowerShell/Graph rozhraní, viz `GLOSSARY.md`; nic povinného na něm
> nezávisí a spouští se dle času. Běží po provisioningu, jehož artefakt používá jako cíl.

> [!WARNING] Den je nad stropem: ~7,8 h povinně (470 min)
> `graph-fundamentals` sem přišel 2026-09-08 z D2 (120 min), protože se na něj ve dni 2
> nedostalo. **Zatím vědomě nevyřešeno** — a nejde to vyřešit přesunem: dvojice D3 + D4
> drží dohromady **850 min** povinné látky, takže i při ideálním rozdělení vychází
> **7,1 h na den**. Rezerva v týdnu existuje jen v D1 a D2 a tam se přesouvat nesmí.
>
> Reálné odlehčení znamená **ubrat 70 min**, aby se oba dny dostaly pod 6,5 h. Kandidáti
> jsou v `CLAUDE.md` v otevřených otázkách; rozhodne se podle prvního reálného běhu D3.

> [!NOTE] Přestavba 2026-09-08 po reálném běhu
> Den prošel dvěma změnami. `graph-fundamentals` přišel z D2, kde se na něj nedostalo.
> `staging-environments` se vrátil ze D4 sem, před bloky, které jeho baseline skript
> potřebují — přesun na D4 (2026-09-07, na místo vypuštěné Clarity) rozbil předpoklady
> tří labů. Výměnou za něj odešel `lifecycle-compliance` na D4, kde navazuje na SIEM
> a kde je staging z předchozího dne hotový.
