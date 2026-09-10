# Den 3 — Graph, staging, migrace & provisioning

Odolné volání Microsoft Graphu jako vstupní znalost dne, model tří prostředí s detekcí
driftu, migrace jako inženýrská disciplína, automatizace zřizování a volitelně governance
nástroj (Orchestry, simulace). Hands-on jádro dne je **lab provisioningu**; laby stagingu
a migrace (Lab 2) jsou od rekalibrace 2026-09-09 **volitelné** — viz čísla níž.

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Microsoft Graph — inženýrské základy | [`graph-fundamentals`](graph-fundamentals/) | P |
| 2 | Staging prostředí: DEV, TEST, PROD *(výklad; lab volitelný)* | [`staging-environments`](staging-environments/) | P |
| 3 | Skladba migrací *(výklad; Lab 2 volitelný)* | [`migration-patterns`](migration-patterns/) | P |
| 4 | Vzory automatizace zřizování | [`provisioning-patterns`](provisioning-patterns/) | P |
| 5 | Orchestry integrace & vlastní skripty (simulace) | [`opt-orchestry-integration`](opt-orchestry-integration/) | V |

> [!IMPORTANT] Pořadí bloků 1 a 2 není tematické — plyne z předpokladů
>
> - **Graph je blok 1**, protože [`migration-patterns/lab-fileshare-migration.md`](migration-patterns/lab-fileshare-migration.md)
>   má jeho retry vzory ve svých Předpokladech.
> - **Staging je blok 2**, protože jeho **koncept** baseline vs drift se vrací
>   v [`provisioning-patterns/`](provisioning-patterns/) i v
>   [`../day-4/lifecycle-compliance/`](../day-4/lifecycle-compliance/). Jde o výklad, ne
>   o artefakt — jeho lab je volitelný a nic na jeho výstupu nestojí (viz korektura níž).

> [!NOTE] Orchestry blok je volitelná simulace/koncept (bez živé licence) — integrační body
> se navrhují proti PnP.PowerShell/Graph rozhraní, viz `GLOSSARY.md`; nic povinného na něm
> nezávisí a spouští se dle času. Běží po provisioningu, jehož artefakt používá jako cíl.

> [!NOTE] ~5,1 h povinně (120 + 40 + 45 + 100 = 305 min) + dva volitelné laby
> Rekalibrováno 2026-09-09. Reálný běh den odučil **podle plánu**, přestože repo na něj
> tehdy počítalo 470 min. Co se skutečně stalo: **staging bez labu** (jen výklad)
> a **Lab 2 vypadl celý** (výklad zkrácen). Oba laby jsou proto **volitelné**.
>
> `graph-fundamentals` (120) a `provisioning-patterns` (100) **změřené nejsou** — nesou
> pořád původní odhady, o kterých instruktor řekl, že jsou nafouknuté.
>
> **Položka „ubrat 70 min" padá:** D3 5,1 h, D4 6,5 h, oba do stropu 6,5 h. Nebyla to
> kapacita, byly to nafouknuté odhady plus dva laby, které se nestíhají učit.

> [!WARNING] V povinné podobě nemá den vlastní lab kromě provisioningu
> Cena rekalibrace: hands-on dne stojí na labu [`provisioning-patterns`](provisioning-patterns/).
> Rezerva pod stropem je ale dost velká na zkrácený Lab 2 (~75 min → 6,3 h), takže je
> **první v řadě**, když čas je.

> [!NOTE] Korektura 2026-09-09: baseline skript nebyl tím, čím ho repo tvrdilo
> Do 2026-09-09 tu stálo, že diff/baseline skript ze [`staging-environments`](staging-environments/)
> je vstupem tří labů — a na tom argumentu se staging 2026-09-08 vrátil z D4 sem. **Reálný
> běh tu vazbu nikdy nevyzkoušel:** staging se odučil bez labu, skript nevznikl, a
> provisioning se přesto odučil — jen se ten krok obešel.
>
> Závislost existovala **jen jako studentský výstup**, takže vypuštění jednoho labu tiše
> bralo vstup dvěma dalším. Oba konzumenti jsou proto přeformulovaní tak, že skript
> **uvítají, ale nevyžadují**. Staging na D3 přesto zůstává — přesun na D4 by ho po jeho
> přestavbě 2026-09-10 vytáhl na 7,2 h a ničemu by neposloužil.

> [!NOTE] Přestavba 2026-09-08 po reálném běhu
> Den prošel dvěma změnami. `graph-fundamentals` přišel z D2, kde se na něj nedostalo.
> `staging-environments` se vrátil ze D4 sem — tehdy s odůvodněním, že jeho baseline
> skript potřebují tři laby; **to odůvodnění o den později padlo** (viz korektura výše),
> ale blok tu zůstává, protože kapacitně to tak vychází lépe. Výměnou za něj odešel
> `lifecycle-compliance` na D4, kde navazuje na SIEM.
