# Cvičení · První Graph dotazy a srovnání se SPO REST

> Odhad: 20 min · Režim: živý tenant, jen čtení, bez psaní kódu

První hands-on dne. Cíl není naučit Graph — to je [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/) —
ale **na živém tenantu si osahat mapu z výkladu**: že Graph a SPO REST jsou dvě cesty
ke stejným datům, každá s jiným tvarem odpovědi, a že za každým voláním stojí token
s konkrétním, zdůvodnitelným oprávněním.

## Cíl

Účastník si sám zavolá obě API nad stejným webem a umí pojmenovat, čím se odpovědi liší
a proč by v konkrétní situaci sáhl po té či oné.

## Předpoklady

- Účet z onboardingu, přihlášený v pracovním profilu Edge.
- [Graph Explorer](https://developer.microsoft.com/graph/graph-explorer) — consent
  zajišťuje lektor předem (viz `instructor-notes.md`).

## Kroky

1. **Přihlásit se** v Graph Exploreru kurzovním účtem. Bez přihlášení vrací dotazy demo
   data fiktivního tenantu; po přihlášení **vaše**.

2. **`GET /me`** — sloveso + URL + token (schovaný za přihlášením) + JSON. Tohle je celé
   API volání; všechno ostatní v kurzu je jen pohodlnější obal nad tímhle.

3. **`GET /me?$select=displayName,jobTitle`** — porovnat velikost odpovědi s krokem 2.
   `$select` není kosmetika: u dotazu přes tisíce objektů je to rozdíl mezi skriptem,
   který doběhne, a skriptem, který se utopí v throttlingu.

4. **Permissions**: záložka *Modify permissions* u dotazu. Jaké oprávnění dotaz použil,
   je delegated nebo application, a kdo ho schválil? Tuhle úvahu budete dělat za vlastní
   aplikaci v [`../automation-strategy/lab-app-registration.md`](../automation-strategy/lab-app-registration.md).

5. **`GET /sites?search=*`** — weby tenantu. Všimnout si obálky `value` a **absence**
   `@odata.nextLink` u malé odpovědi. Co se stane, až webů bude víc než se vejde,
   řeší [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/).

6. **Vybrat jeden web** z kroku 5, poznamenat si jeho `id` a zavolat
   `GET /sites/{id}/lists` — seznamy toho webu očima Graphu.

7. **Totéž přes SPO REST.** V novém panelu prohlížeče otevřít
   `https://<tenant>.sharepoint.com/sites/<web>/_api/web/lists?$select=Title,BaseTemplate`
   (přihlášení nese session cookie, token řešit nemusíte). Porovnat s krokem 6 a odpovědět:
   - Které vlastnosti seznamu vidíte v SPO REST a **nevidíte** v Graphu?
   - Který formát odpovědi se lépe zpracovává ve skriptu a proč?
   - Kdyby vás zajímal `BaseTemplate` nebo nastavení verzování, kterou cestou půjdete?

   Tohle je celá pointa modulu na jednom příkladu: **Graph first, SPO REST tam, kde Graph
   nestačí** — a „nestačí" teď není tvrzení z prezentace, ale něco, co jste viděli.

## Ověření

- [ ] Účastník spustil dotazy z kroků 2–3 pod vlastním účtem a umí říct, co `$select` změnil.
- [ ] Umí říct, jaké permission použil dotaz `/me`, zda je delegated či application,
      a kde to zjistil.
- [ ] Zavolal stejný web přes Graph (krok 6) i SPO REST (krok 7) a **umí pojmenovat
      alespoň jednu vlastnost, kterou vrací jen SPO REST**.

## Fallback

- **Přihlášení do Graph Exploreru selže** (consent, síť): kroky 2–5 fungují i nad demo
  tenantem bez přihlášení, jen nad fiktivními daty. Krok 4 ukáže instruktor na plátně.
- **SPO REST v prohlížeči vrací XML místo JSON**: to je korektní chování — bez hlavičky
  `Accept: application/json;odata=nose` odpovídá endpoint v Atom/XML. Je to samo o sobě
  dobrý teaching point (SPO REST je starší vrstva a chová se podle toho); kdo chce JSON
  hned, použije `?$select=...` v prohlížeči a JSON si vynutí až ze skriptu v D2.
- **Časový skluz**: kroky 6–7 jsou to, co se smí vypustit jako první. Kroky 2–4 ne —
  jsou to jediné hands-on minuty dne před blokem `automation-strategy`.
