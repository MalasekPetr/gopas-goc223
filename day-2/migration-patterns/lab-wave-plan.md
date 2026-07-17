# Lab · Wave plán & throttle-aware exekuce

> Modul: M2.3 · Odhad: 75 min · Režim: simulace

## Cíl

Student navrhne wave plán pro fiktivní sadu webů/listů dle rizika/velikosti/závislostí a
implementuje throttle-aware exekuci jedné vlny s korektním zpracováním 429/5xx (viz M2.1).

## Předpoklady

- Retry/throttle klasifikace z M2.1, `Get-AllGraphResults`/connect wrapper.
- Demo migrační zdrojová data (fiktivní sada 15-20 webů s různou velikostí/rizikem).

## Kroky

1. Ke každému fiktivnímu webu přiřadit velikost, riziko (nízké/střední/vysoké — dle
   viditelnosti/počtu uživatelů) a závislosti na jiných webech.
2. Sestavit wave plán: pilotní vlna (1-2 nízkorizikové weby), hlavní vlny, kritická vlna
   (nejvyšší riziko) s explicitním rollback krokem.
3. Implementovat throttle-aware exekuci migrace jedné vlny — paralelní zpracování více webů
   s respektováním throttling limitů z M2.1 (ne fire-and-forget bez kontroly chyb).
4. Zdůvodnit pořadí vln v krátkém textovém shrnutí (proč tento web až v poslední vlně).

## Ověření

- [ ] Wave plán řadí weby podle rizika/velikosti/závislostí, ne abecedně.
- [ ] Kritická vlna má definovaný rollback krok.
- [ ] Exekuce jedné vlny korektně zpracuje throttling (429) bez pádu celého běhu.

## Fallback

Pokud čas nestačí na implementaci exekuce, student odevzdá jen wave plán (písemně/tabulkou)
se zdůvodněním a pseudokódem throttle-aware smyčky — plán samotný je hodnotící jádro labu.
