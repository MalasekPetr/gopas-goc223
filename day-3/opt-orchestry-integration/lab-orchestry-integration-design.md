# Lab · Návrh integrace skriptů (simulace PnP)

> Odhad: 60 min · Režim: simulace

## Cíl

Student navrhne kontrakt pre-provision/post-provision hooků a napojí post-provision hook na
existující PnP provisioning artefakt z [`../provisioning-patterns/`](../provisioning-patterns/) — bez živé Orchestry licence, na pseudokódu/kontraktu.

## Předpoklady

- PnP provisioning artefakt (parametrizovaná šablona) z [`../provisioning-patterns/`](../provisioning-patterns/).

## Kroky

1. Navrhnout datový kontrakt pre-provision hooku — jaká data hook dostane (žadatel, název,
   šablona, metadata) a co může vrátit (schválit/zamítnout/požádat o doplnění).
2. Navrhnout datový kontrakt post-provision hooku — jaká data dostane o nově vzniklém prostoru
   (ID webu, URL, přiřazená šablona) a jak z něj zavolá existující PnP skript z [`../provisioning-patterns/`](../provisioning-patterns/).
3. Napojit post-provision hook (pseudokód) na `Invoke-PnPTenantTemplate` volání z [`../provisioning-patterns/`](../provisioning-patterns/) s
   parametry odvozenými z dat hooku.
4. Krátce srovnat: co by dělalo IT oddělení, kdyby tento hook neexistoval (manuální krok) —
   zdůvodnit hodnotu automatizace.

## Ověření

- [ ] Kontrakt obou hooků je zapsaný strukturovaně (vstup/výstup), ne jen volným textem.
- [ ] Post-provision hook prokazatelně předává data do existujícího PnP skriptu z [`../provisioning-patterns/`](../provisioning-patterns/)
      (konkrétní mapování polí, ne jen "zavolá se skript").

## Fallback

Bez ohledu na dostupnost živého tenantu je toto čistě návrhový lab (simulace) — fallback
není potřeba mimo prodloužení času na diskuzi ve dvojicích místo samostatné práce.
