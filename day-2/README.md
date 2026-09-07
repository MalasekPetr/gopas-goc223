# Den 2 — Strategie, oprávnění, PowerShell & Graph engineering

Nástrojová mapa a app registrace, consent a application permissions, hloubkový PowerShell
s prvním velkým labem (certifikát, app-only identita, pracovní weby), robustnost nad
Microsoft Graph a rozdíly mezi prostředími s detekcí driftu.

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Strategie automatizace & nástrojová mapa | [`automation-strategy`](automation-strategy/) | P |
| 2 | Oprávnění a consent | [`permissions-consent`](permissions-consent/) | P |
| 3 | PowerShell do hloubky *(Lab 1)* | [`powershell-deep-dive`](powershell-deep-dive/) | P |
| 4 | Microsoft Graph — inženýrské základy | [`graph-fundamentals`](graph-fundamentals/) | P |
| 5 | Staging prostředí: DEV, TEST, PROD | [`staging-environments`](staging-environments/) | P |

> [!WARNING] Den je v tomto rozvržení PŘETÍŽENÝ — 8,2 h povinně
> Přesun `automation-strategy` z D1 (2026-09-07, po reálném běhu) je logicky správný:
> app registrace z jeho labu je vstup pro blok 2 i pro certifikát v Labu 1. Časově ale
> D2 vychází na **490 min = 8,2 h**, což je neodjezditelné.
>
> Sečteno: 85 + 50 + 135 + 120 + 100 min. Ani jeden další den nemá 100 min volných
> (D1 4,9 h · D3 5,8 h · D4 6,3 h · D5 5,7–6,7 h), takže samotné přesunutí problém
> jen přemístilo. **Rozhodnutí o tom, co z D2 odejde nebo se zkrátí, je otevřené** —
> viz `agenda.md`.

> [!IMPORTANT] Bloky 2 a 3 patří k sobě
> [`permissions-consent`](permissions-consent/) učí sáhnout po nejužším oprávnění
> (`Sites.Selected`); Lab 1 hned nato používá `Sites.FullControl.All`, protože zakládá
> weby a vypisuje tenant. **Není to rozpor — je to upřesnění:** least privilege znamená
> nejužší rozsah, *který úlohu splní*. Ten protiklad je záměrný a je nosným bodem dne.

> [!NOTE] K bloku 3 patří dva **volitelné** doplňky — spouštět jen při reálné rezervě,
> nic na nich nezávisí:
> mini-lab „tři podpisy zápisu" ([`powershell-deep-dive/lab-write-identities.md`](powershell-deep-dive/lab-write-identities.md), 25 min)
> a demo hardware klíče ([`powershell-deep-dive/demo-yubikey.md`](powershell-deep-dive/demo-yubikey.md), 30 min).

> [!NOTE] Lab 1 dopoledne vytvoří weby `-dev/-test/-prod`, které
> [`staging-environments`](staging-environments/) odpoledne rovnou používá. Graph
> batching/retry z [`graph-fundamentals`](graph-fundamentals/) je vstupní znalost pro
> migrační exekuci hned ráno dne 3.
