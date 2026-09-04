# Den 2 — PowerShell, Graph engineering & staging

Hloubkový PowerShell s prvním velkým labem (certifikát, app-only identita, pracovní weby),
robustnost nad Microsoft Graph a rozdíly mezi prostředími s detekcí driftu.

| Pořadí | Blok | Slug | Typ |
|---|---|---|---|
| 1 | PowerShell do hloubky *(Lab 1)* | [`powershell-deep-dive`](powershell-deep-dive/) | P |
| 2 | Microsoft Graph — inženýrské základy | [`graph-fundamentals`](graph-fundamentals/) | P |
| 3 | Staging prostředí: DEV, TEST, PROD | [`staging-environments`](staging-environments/) | P |

> [!NOTE] K bloku 1 patří **volitelný** mini-lab „tři podpisy zápisu"
> ([`powershell-deep-dive/lab-write-identities.md`](powershell-deep-dive/lab-write-identities.md),
> 25 min) — spouští se jen při reálné rezervě, jinak jde na samostudium; nic na něm nezávisí.

> [!NOTE] Lab 1 dopoledne vytvoří weby `-dev/-test/-prod`, které
> [`staging-environments`](staging-environments/) odpoledne rovnou používá. Graph
> batching/retry z [`graph-fundamentals`](graph-fundamentals/) je vstupní znalost pro
> migrační exekuci hned ráno dne 3.
