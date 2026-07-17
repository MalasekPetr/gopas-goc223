# Lab · Hardening app registration & úprava scope

> Modul: M5.2 · Odhad: 60 min · Režim: živý tenant

## Cíl

Student provede audit permissions app registrace z M1.2, odebere nadbytečná oprávnění a
provede migraci ze client secret na certifikát bez výpadku (overlap starý/nový).

## Předpoklady

- App registrace z M1.2 s historií použití napříč celým týdnem.
- Oprávnění spravovat tuto app registraci (student by ji měl vlastnit od M1.2).

## Kroky

1. Vypsat všechny permissions aktuálně přiřazené app registraci.
2. Ke každému permission napsat, kde přesně (který modul/lab) bylo reálně použito.
3. Odebrat permissions, které nebyly použité, nebo mají užší dostupnou alternativu.
4. Vygenerovat nový certifikát, nahrát ho vedle stávajícího client secret (`keyCredentials`
   multi-hodnotové pole) — otestovat připojení s novým certifikátem, teprve pak odebrat
   client secret.

## Ověření

- [ ] Seznam permissions po auditu je kratší (nebo zdůvodněně stejný) oproti seznamu před
      auditem, s explicitním zdůvodněním u každé ponechané položky.
- [ ] Připojení certifikátem funguje před odebráním client secretu (ověřený overlap,
      ne "nejdřív smazat, pak zkusit").
- [ ] Client secret je po úspěšném ověření certifikátu odebrán.

## Fallback

Pokud generování/nahrání vlastního certifikátu selže kvůli omezením prostředí, student
provede jen audit a odebrání permissions (kroky 1-3) a certifikátovou rotaci popíše jako
plán (kroky, v jakém pořadí, jak ověřit) bez reálné exekuce.
