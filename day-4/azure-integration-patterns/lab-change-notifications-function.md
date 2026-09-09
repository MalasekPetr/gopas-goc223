# Lab · Funkce pro change notifications (skeleton)

> Odhad: 60 min · Režim: živý tenant

## Cíl

Student má Azure Function jako endpoint pro Graph change notification subscription, včetně
zpracování validačního tokenu při vytvoření a alespoň skeleton pro obnovu subscription
před expirací.

> [!IMPORTANT] Od 2026-09-09 je tenhle lab **celé samostudium** — a to mění, kudy se dělá
> Dřív handshake odvykládal instruktor jako demo a samostudium byl jen renewal. Demo bylo
> vyměněné za [`guide-copy-metadata.md`](guide-copy-metadata.md), takže je teď na
> studentovi celý lab. Dvě věci, které z toho plynou:
>
> - **Kroky 1-3 potřebují kurzovní prostředí**: Function App v resource group studenta
>   a **veřejně dostupný endpoint** (Graph si na něj musí zavolat s validačním tokenem).
>   Po skončení kurzu ta resource group nemusí existovat. Kdo chce lab v téhle podobě,
>   ať ho udělá **během týdne v rezervě**, ne až doma.
> - **Mimo kurzovní prostředí berte jako hlavní cestu Fallback** (nahraný payload) —
>   není to náhradní varianta, je to jediná, která bez veřejného endpointu projde.
>   Renewal skeleton, tedy krok 4, je stejně ta část s trvalou hodnotou: naváže se na
>   `subscriptionExpirationDateTime` z payloadu úplně stejně jako z živé notifikace.

## Předpoklady

- Azure resource group per student (`environment.md`), Function App — **jen pro kroky 1-3
  a jen v kurzovním prostředí**, viz poznámka výše.
- **Veřejně dostupný endpoint** funkce; bez něj validační handshake projít nemůže.
- App registrace s Graph permission pro sledovaný resource (např. `Sites.Read.All`).

> Volání Graphu ve funkci pište přes `Invoke-RestMethod`, ne přes modul `Microsoft.Graph`.
> **Flex Consumption nepodporuje managed dependencies v PowerShellu**, takže modul by se
> musel nést v deployment package -- u dvou HTTP volání (`POST` subscription, `PATCH`
> renewal) je to zbytečná zátěž. Detaily:
> [`comparison-scheduled-runtimes.md`](comparison-scheduled-runtimes.md).

## Kroky

1. Vytvořit HTTP-triggered Function jako notification endpoint — zpracovat validační
   handshake (Graph při vytvoření subscription pošle validation token, endpoint ho musí
   vrátit v plain-textu jako potvrzení).
2. Vytvořit subscription na testovaný resource (např. list položek na sandbox webu) s
   `expirationDateTime` blízko minimu (45 min) — kvůli reálnému pozorování expirace v rámci
   labu.
3. Zalogovat příchozí notifikace strukturovaně, včetně `subscriptionExpirationDateTime`.
4. Napsat skeleton pro obnovu subscription (`PATCH`) spouštěný na základě blížící se expirace.

## Ověření

- [ ] Function úspěšně projde validační handshake při vytvoření subscription.
- [ ] Function přijme alespoň jednu reálnou change notifikaci z testovaného resource.
- [ ] Skeleton obnovy subscription existuje a je navázaný na `subscriptionExpirationDateTime`
      z přijaté notifikace, ne na pevně vypočítaný čas.

## Fallback

Pokud vytvoření Graph subscription na testovaný resource selže (chybějící oprávnění,
firewall), instruktor poskytne nahraný ukázkový payload notifikace a student implementuje
zpracování a renewal skeleton nad tímto simulovaným vstupem.
