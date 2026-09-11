# Den 2 — Strategie, oprávnění a PowerShell

Nástrojová mapa, identita automatizace a oprávnění jako otvírák, volitelně základy jazyka
pro ty, kdo je nemají, a pak hloubkový PowerShell s prvním velkým labem (certifikát,
app-only identita, pracovní weby). **~4,0 h povinně, 5,0 h s volitelným blokem 2.**

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Strategie automatizace: nástroje, identita a oprávnění | [`automation-strategy`](automation-strategy/) | P |
| 2 | PowerShell — základy pro ty, kdo je nemají | [`opt-powershell-basics`](opt-powershell-basics/) | V |
| 3 | PowerShell do hloubky *(Lab 1)* | [`powershell-deep-dive`](powershell-deep-dive/) | P |

Linka dne je jedna app registrace, která postupně dospívá: blok 1 ji vytvoří a dá jí
delegated i `Sites.Selected`, blok 3 jí přidá certifikát a přihlásí ji app-only. Odolné
Graph volání nad tou samou aplikací otevírá ráno dne 3
([`../day-3/graph-fundamentals/`](../day-3/graph-fundamentals/)). V D5 tatáž aplikace
projde auditem.

> [!IMPORTANT] Bloky 1 a 3 patří k sobě a schválně si protiřečí
> Blok 1 učí sáhnout po nejužším oprávnění (`Sites.Selected`); Lab 1 hned nato používá
> `Sites.FullControl.All`, protože zakládá weby a vypisuje tenant. **Není to rozpor — je
> to upřesnění:** least privilege znamená nejužší rozsah, *který úlohu splní*. Ten
> protiklad je záměrný a je nosným bodem dne.

> [!NOTE] Blok 2 je záchranná síť, ne plnohodnotný blok
> Spouští se **jen tehdy, když je skupina slabá v základech PowerShellu**. Pozná se to už
> u labu bloku 1: kdo neumí přečíst, co mu cmdlet vrátil, neprojde Labem 1 ani ničím
> dalším v týdnu. Rozhodnutí patří na dopoledne druhého dne, ne do přípravy — a den se
> tím prodlouží o hodinu a pořád zůstane pod stropem.

> [!NOTE] K bloku 3 patří dva **volitelné** doplňky — spouštět jen při reálné rezervě,
> nic na nich nezávisí:
> mini-lab „tři podpisy zápisu" ([`powershell-deep-dive/lab-write-identities.md`](powershell-deep-dive/lab-write-identities.md), 25 min)
> a demo hardware klíče ([`powershell-deep-dive/demo-yubikey.md`](powershell-deep-dive/demo-yubikey.md), 30 min).

