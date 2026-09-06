# Den 2 — Oprávnění, PowerShell, Graph engineering & staging

Consent a application permissions jako rozcvička, hloubkový PowerShell s prvním velkým
labem (certifikát, app-only identita, pracovní weby), robustnost nad Microsoft Graph
a rozdíly mezi prostředími s detekcí driftu. **~6,75 h povinně.**

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | Oprávnění a consent | [`permissions-consent`](permissions-consent/) | P |
| 2 | PowerShell do hloubky *(Lab 1)* | [`powershell-deep-dive`](powershell-deep-dive/) | P |
| 3 | Microsoft Graph — inženýrské základy | [`graph-fundamentals`](graph-fundamentals/) | P |
| 4 | Staging prostředí: DEV, TEST, PROD | [`staging-environments`](staging-environments/) | P |

> [!IMPORTANT] Bloky 1 a 2 patří k sobě
> [`permissions-consent`](permissions-consent/) učí sáhnout po nejužším oprávnění
> (`Sites.Selected`); Lab 1 hned nato používá `Sites.FullControl.All`, protože zakládá
> weby a vypisuje tenant. **Není to rozpor — je to upřesnění:** least privilege znamená
> nejužší rozsah, *který úlohu splní*. Ten protiklad je záměrný a je nosným bodem dne.

> [!NOTE] K bloku 2 patří dva **volitelné** doplňky — spouštět jen při reálné rezervě,
> nic na nich nezávisí:
> mini-lab „tři podpisy zápisu" ([`powershell-deep-dive/lab-write-identities.md`](powershell-deep-dive/lab-write-identities.md), 25 min)
> a demo hardware klíče ([`powershell-deep-dive/demo-yubikey.md`](powershell-deep-dive/demo-yubikey.md), 30 min).

> [!NOTE] Lab 1 dopoledne vytvoří weby `-dev/-test/-prod`, které
> [`staging-environments`](staging-environments/) odpoledne rovnou používá. Graph
> batching/retry z [`graph-fundamentals`](graph-fundamentals/) je vstupní znalost pro
> migrační exekuci hned ráno dne 3.
