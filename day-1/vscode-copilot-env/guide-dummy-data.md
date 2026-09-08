# Návod · Testovací data z Copilot Chatu

Pravidlo kurzu zní: **do tenantu ani do promptů žádná reálná firemní ani osobní data**
([`../onboarding/ways-of-working.md`](../onboarding/ways-of-working.md)). Testovací obsah
je ale potřeba pořád — seznamy webů pro inventuru, položky pro dávkový zápis, soubory
pro migrační lab. Copilot Chat je na fiktivní data dobrý generátor: rychlý, česky
a formát si řeknete.

## Recept na prompt

Čtyři věci, které v promptu vždy jsou — **formát, schéma, počet, čeština**:

```text
Vygeneruj JSON pole 15 fiktivnich SharePoint webu. Kazdy objekt ma pole:
name (string), owner (string, smyslene ceske jmeno s diakritikou),
docCount (int 0-5000), lastActivity (datum ISO 8601 v poslednich 2 letech).
Jmena musi byt smyslena - zadne realne osoby ani firmy. Alespon 3 weby at
maji nulovou aktivitu pres 180 dni a 2 weby diakritiku i v nazvu webu.
Vystup jen cisty JSON bez komentaru.
```

Varianty téhož receptu:

- **CSV** — „výstup jako CSV se středníkem jako oddělovačem, první řádek hlavička";
  uložit jako UTF-8 (viz [`../../day-2/powershell-deep-dive/explainer-formats-encoding.md`](../../day-2/powershell-deep-dive/explainer-formats-encoding.md)).
- **Položky SPO seznamu** — schéma opsat z reálného seznamu (interní názvy polí a choice
  hodnoty zjistíte tahákem [`../../day-3/graph-fundamentals/tips-spo-api.md`](../../day-3/graph-fundamentals/tips-spo-api.md)),
  ale do promptu dát jen **strukturu**, žádná reálná data.
- **Fileshare pro migrační lab** — „vygeneruj strom 30 cest k souborům včetně názvů
  s diakritikou, mezerami, dlouhými cestami a znaky, které SharePoint nepovoluje";
  přesně na tom se testuje sanitizace v [`../../day-3/migration-patterns/`](../../day-3/migration-patterns/).
- **Dokumenty** — „vygeneruj 5 odstavců fiktivní interní směrnice" jako obsah k nahrání
  do knihovny pro testy vyhledávání a metadat.

## Na co nezapomenout

- **Vyžádat si okrajové případy** — prázdné hodnoty, extrémně dlouhý název, znak `&`,
  datum na přelomu roku, položka přes 5000 v seznamu. Dummy data, na kterých nic
  nespadne, nic netestují.
- **Diakritiku vyžádat explicitně** — jinak model rád generuje ASCII a UTF-8 round-trip
  nemáte čím ověřit.
- **Zkontrolovat, že data jsou opravdu smyšlená** — projít očima, jestli se
  nevygenerovalo reálné jméno nebo firma. Výstup AI se ověřuje vždy, i tenhle.
- **Objem řešit opakováním, ne jedním promptem** — délka odpovědi je omezená; 200 položek
  = několikrát „pokračuj dalšími 50, naváž na předchozí".
- **Hromadné nahrání dělat skriptem** a dávkově (`Invoke-PnPBatch`) — a jsme zpět
  u workflow kurzu: prompt → přečíst → otestovat → spustit.

## Kde se to v kurzu hodí

Lab tohoto bloku (vstupní JSON), obsah pracovních webů `-dev/-test/-prod`, testovací
fileshare pro migrační lab, vstup pro dávkový sync task a data pro capstone.
