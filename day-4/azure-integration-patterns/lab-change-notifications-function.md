# Lab · Funkce pro change notifications (skeleton)

> Odhad: 60 min · Režim: živý tenant

## Cíl

Student má Azure Function jako endpoint pro Graph change notification subscription, včetně
zpracování validačního tokenu při vytvoření a alespoň skeleton pro obnovu subscription
před expirací.

## Předpoklady

- Azure resource group per student (`environment.md`), Function App.
- App registrace s Graph permission pro sledovaný resource (např. `Sites.Read.All`).

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
