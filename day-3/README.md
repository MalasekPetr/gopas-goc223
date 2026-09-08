# Den 3 — Graph, migrace, provisioning & lifecycle

Odolné volání Microsoft Graphu jako vstupní znalost dne, migrace jako inženýrská disciplína
s druhým velkým labem (fileshare → SPO dle JSON plánu), jak weby vznikají (provisioning),
volitelně governance nástroj (Orchestry, simulace) a jak se obsah řídí v čase
(lifecycle & compliance).

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Microsoft Graph — inženýrské základy | [`graph-fundamentals`](graph-fundamentals/) | P |
| 2 | Skladba migrací *(Lab 2)* | [`migration-patterns`](migration-patterns/) | P |
| 3 | Vzory automatizace zřizování | [`provisioning-patterns`](provisioning-patterns/) | P |
| 4 | Orchestry integrace & vlastní skripty (simulace) | [`opt-orchestry-integration`](opt-orchestry-integration/) | V |
| 5 | Lifecycle & compliance enforcement | [`lifecycle-compliance`](lifecycle-compliance/) | P |

> [!IMPORTANT] Graph je blok 1, protože to vyžaduje Lab 2
> [`migration-patterns/lab-fileshare-migration.md`](migration-patterns/lab-fileshare-migration.md)
> má retry vzory z `graph-fundamentals` ve svých **Předpokladech**. Není to tematická
> preference — obrácené pořadí nechá Lab 2 bez vstupní znalosti, na které stojí.

> [!NOTE] Orchestry blok je volitelná simulace/koncept (bez živé licence) — integrační body
> se navrhují proti PnP.PowerShell/Graph rozhraní, viz `GLOSSARY.md`; nic povinného na něm
> nezávisí a spouští se dle času.

> [!WARNING] Den je nad stropem: ~7,8 h povinně (470 min)
> `graph-fundamentals` sem přišel 2026-09-08 z D2 (120 min), protože se na něj ve dni 2
> nedostalo. **Zatím vědomě nevyřešeno.** Platí pravidlo, že moduly se smí posouvat jen
> dozadu v týdnu, nikdy dopředu, takže odlehčení přesunem zpátky do D2 není ve hře;
> legální kandidáti jsou přesun něčeho na D4/D5 (oba dny jsou dnes plné) nebo zkrácení
> uvnitř dne.
>
> Do prvního reálného běhu D3 se s tím nedělá nic — rozhodne se podle toho, kde se den
> reálně zadrhne. Prakticky odpadá jako první blok 4, který je už dnes volitelný.

> [!IMPORTANT] Otevřená vazba: blok 5 potřebuje artefakt ze dne 4
> [`lifecycle-compliance/lab-compliance-drift.md`](lifecycle-compliance/lab-compliance-drift.md)
> má ve Předpokladech diff/baseline skript z
> [`../day-4/staging-environments/`](../day-4/staging-environments/) — tedy z **následujícího**
> dne. Vzniklo to přesunem stagingu z D2 na D4 (2026-09-07). Do vyřešení musí instruktor
> baseline skript pro tento lab dodat hotový, nebo nechat studenty napsat minimální
> vlastní; nelze se spoléhat na to, že ho mají z předchozího bloku.
