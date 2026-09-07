# Den 2 — Strategie, oprávnění, PowerShell a Graph

Nástrojová mapa, identita automatizace a oprávnění jako otvírák, pak hloubkový PowerShell
s prvním velkým labem (certifikát, app-only identita, pracovní weby) a robustnost nad
Microsoft Graph. **~6,0 h povinně.**

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Strategie automatizace: nástroje, identita a oprávnění | [`automation-strategy`](automation-strategy/) | P |
| 2 | PowerShell do hloubky *(Lab 1)* | [`powershell-deep-dive`](powershell-deep-dive/) | P |
| 3 | Microsoft Graph — inženýrské základy | [`graph-fundamentals`](graph-fundamentals/) | P |

Linka dne je jedna app registrace, která postupně dospívá: blok 1 ji vytvoří a dá jí
delegated i `Sites.Selected`, blok 2 jí přidá certifikát a přihlásí ji app-only, blok 3
nad ní staví odolné Graph volání. V D5 tatáž aplikace projde auditem.

> [!IMPORTANT] Bloky 1 a 2 patří k sobě a schválně si protiřečí
> Blok 1 učí sáhnout po nejužším oprávnění (`Sites.Selected`); Lab 1 hned nato používá
> `Sites.FullControl.All`, protože zakládá weby a vypisuje tenant. **Není to rozpor — je
> to upřesnění:** least privilege znamená nejužší rozsah, *který úlohu splní*. Ten
> protiklad je záměrný a je nosným bodem dne.

> [!NOTE] K bloku 2 patří dva **volitelné** doplňky — spouštět jen při reálné rezervě,
> nic na nich nezávisí:
> mini-lab „tři podpisy zápisu" ([`powershell-deep-dive/lab-write-identities.md`](powershell-deep-dive/lab-write-identities.md), 25 min)
> a demo hardware klíče ([`powershell-deep-dive/demo-yubikey.md`](powershell-deep-dive/demo-yubikey.md), 30 min).

> [!NOTE] Přestavba 2026-09-07
> Den prošel dvěma změnami. `automation-strategy` přišel z D1, kde se na něj v reálném
> běhu nedostalo, a **sloučil se s bývalým blokem `permissions-consent`** — oba mluvily
> o least privilege a jejich laby pracovaly na téže app registraci.
> `staging-environments` odešlo na D4 na místo vypuštěné Clarity, protože jinak by den
> vycházel na 8,2 h. Weby `-dev/-test/-prod` z Labu 1 tedy staging používá až ve čtvrtek;
> Graph batching/retry z bloku 3 je vstupní znalost pro migrační exekuci ráno dne 3.
