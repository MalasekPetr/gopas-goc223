# Lab · Resilientní ingest & stránkování Graph

> Odhad: 75 min · Režim: živý tenant

## Cíl

Student má PowerShell/Graph skript, který korektně stránkuje výsledky, respektuje throttling
(`Retry-After`) a rozlišuje transientní chyby (retry) od permanentních (fail-fast).

## Předpoklady

- `Connect-CourseTarget` wrapper z [`../../day-1/powershell-deep-dive/`](../../day-1/powershell-deep-dive/), app registrace s `Sites.Read.All` (Graph, delegated).
- Kurzový tenant obsahuje dostatek uživatelů/webů, aby dotaz reálně vyžadoval stránkování.

## Kroky

1. Napsat funkci `Get-AllGraphResults`, která projde `@odata.nextLink` až do konce a vrátí
   kompletní kolekci (žádná tichá ztráta dat po první stránce).
2. Přidat klasifikaci chyb: 429 → počkat `Retry-After`, pak retry; 5xx → exponenciální
   backoff (max. N pokusů); jiné 4xx → vyhodit chybu okamžitě, bez retry.
3. Uměle vyvolat throttling (vysoký počet rychlých requestů) a ověřit, že skript korektně čeká.
4. Zalogovat každý pokus strukturovaně (viz logging scaffolding z [`../../day-1/powershell-deep-dive/`](../../day-1/powershell-deep-dive/)) včetně `client-request-id`.

## Ověření

- [ ] Skript vrátí kompletní dataset i při datasetu větším než jedna stránka Graph odpovědi.
- [ ] Při vyvolaném 429 skript počká přesně dobu z `Retry-After`, ne pevnou hodnotu.
- [ ] Log obsahuje rozlišení retry (429/5xx) vs fail-fast (jiné 4xx) pro každý pokus.

## Fallback

Pokud se throttling v kurzovém tenantu nepodaří spolehlivě vyvolat (nedostatek dat/rychlosti),
instruktor poskytne nahraný ukázkový response log s 429 odpovědí a student implementuje a
testuje retry logiku nad tímto simulovaným vstupem.
