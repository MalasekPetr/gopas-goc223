# Lab · HelloWorld deploy přes App Catalog

> Odhad: 75 min · Režim: živý tenant

## Cíl

Student má vlastní HelloWorld SPFx webpart, sestavený aktuálním (Heft) toolchainem,
zabalený jako `.sppkg`, nahraný a nasazený přes App Catalog a přidaný na moderní stránku.

## Předpoklady

- Node LTS verze kompatibilní s aktuální verzí `@microsoft/generator-sharepoint`.
- Přístup do App Catalogu kurzového tenantu (tenant, nebo site collection app catalog —
  viz `instructor-notes.md`).

## Kroky

1. `npm install @microsoft/generator-sharepoint@latest --global`, `yo @microsoft/sharepoint`
   — zvolit webpart, TypeScript, žádný framework (React volitelně).
2. Ověřit lokální běh (`heft start` — nebo `gulp serve`, pokud instruktor rozhodl o starším
   toolchainu, viz go/no-go).
3. Build a balíček: vytvořit `.sppkg` (`heft build` → `heft package` dle scaffoldu, nebo
   ekvivalentní gulp task).
4. Nahrát `.sppkg` do App Catalogu, potvrdit "make this solution available to all sites".
5. Přidat webpart na moderní stránku vlastního sandbox webu, ověřit zobrazení.
6. Zvýšit verzi v `package-solution.json`, znovu nahrát a ověřit, že SharePoint nabídne update.

## Ověření

- [ ] `.sppkg` je úspěšně nahraný a "trusted" v App Catalogu.
- [ ] Webpart se zobrazuje na moderní stránce se správným obsahem.
- [ ] Druhé nahrání s vyšší verzí je rozpoznáno jako update, ne jako nové řešení.

## Fallback

Primární cesta je **site collection app catalog na vlastním webu** (izolace ve sdíleném
tenantu — viz `instructor-notes.md`); pokud jeho aktivace na některém webu selže, student
nahraje `.sppkg` do tenant App Catalogu s názvem řešení dle naming konvence
(`<jmeno-prijmeni>-helloworld`) a po ověření ho zase odebere.
