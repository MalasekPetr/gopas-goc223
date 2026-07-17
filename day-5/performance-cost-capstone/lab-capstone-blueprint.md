# Lab · Capstone: provoz & konsolidace blueprintu

> Modul: M5.3 · Odhad: 90 min · Režim: simulace | živý tenant

## Cíl

Student konsoliduje artefakty celého týdne do jednoho end-to-end blueprintu migrace a
provisioningu, s explicitním rollback plánem a předávacím runbookem.

## Předpoklady

- Wave plán (M2.3), provisioning artefakt (M3.1), Azure integrační/SIEM blueprint
  (M4.1-M4.2), hardened app registrace (M5.2) — vlastní artefakty z celého týdne.

## Kroky

1. Sepsat jednostránkový přehled: jak spolu artefakty souvisí (diagram + krátký popis toku
   od provisioningu přes migraci po monitoring).
2. Ke každé fázi blueprintu doplnit `$select`/batching optimalizaci tam, kde chybí
   (revize z pohledu efektivity API).
3. Napsat rollback plán — co přesně dělat, pokud vlna migrace (M2.3) selže v polovině.
4. Napsat předávací runbook — vlastník po kurzu, kde je dokumentace, jak se hlásí incident.
5. Krátká prezentace blueprintu (5 min/student nebo ve dvojicích) — rizika, náklady, další
   kroky (certifikační cesta dle zájmu — viz `README.md` currency marker k AZ-204/AI-200).

## Ověření

- [ ] Blueprint explicitně propojuje alespoň 3 artefakty z různých dnů týdne.
- [ ] Rollback plán je konkrétní (kroky, ne jen "vrátíme to zpět").
- [ ] Předávací runbook obsahuje vlastníka a eskalační cestu.

## Fallback

Pokud studentovi chybí některý dřívější artefakt (nedokončený lab), capstone pokračuje s
tím, co je k dispozici, a chybějící část se nahradí návrhem "co by tam mělo být" — cíl je
demonstrovat schopnost konsolidace, ne dohánět nedokončenou práci z dřívějších dnů.
