# Demo · Od ingestu k incidentu: Sentinel nad vlastní tabulkou

> Odhad: 20 min · Režim: **instruktorské demo** uvnitř labu · Navazuje na [`lab-siem-ingest-blueprint.md`](lab-siem-ingest-blueprint.md)

Lab končí u „data dorazila, KQL to potvrdil". To je **ingest, ne SIEM**. SIEM začíná
o krok dál: pravidlo, které v datech samo najde vzorec, z něj udělá **incident** a nabídne
vyšetřování. Tohle demo ten krok ukáže — nad tabulkou, kterou studenti právě naplnili.

## Proč to stojí za 20 minut

Rozdíl mezi **logováním** a **SIEM** je otázka, kterou dostanete od vedení i od auditora:
„máme přece logy, na co ještě platit SIEM?" Odpověď je konkrétní: log odpovídá na otázku,
kterou si položíte. SIEM se ptá sám, průběžně, i když se zrovna nedíváte — a výsledek
předá jako incident s vlastníkem a stavem, ne jako řádek v tabulce.

## Předpoklady

- Log Analytics workspace z labu s daty ve vlastní tabulce.
- **Sentinel zapnutý nad tímto workspacem** — viz `instructor-notes.md`, sekce go/no-go
  (je to jeden přepínač, ale má časové a nákladové podmínky).

## Postup

1. **Ukázat, kde lab skončil.** Spustit KQL dotaz z labu — data jsou v tabulce, ale nikdo
   se na ně nedívá. Vyslovit otázku: *„a kdo si toho všimne v neděli ve tři ráno?"*

2. **Vytvořit analytics rule** (scheduled query rule) nad toutéž tabulkou. Dotaz je
   prakticky týž KQL, jen doplněný o podmínku, která popisuje **nežádoucí vzorec** —
   například víc než N událostí od jednoho aktéra v krátkém okně:

   ```kusto
   <NazevTabulky>_CL
   | where TimeGenerated > ago(15m)
   | summarize Pocet = count() by Aktor = ActorUpn_s
   | where Pocet > 5
   ```

   Nastavit **nejkratší interval spouštění, který portál dovolí**, a namapovat
   `Aktor` jako **entitu** — to je krok, kvůli kterému z nálezu vznikne vyšetřovatelný
   incident, a ne jen e-mail.

3. **Vyvolat vzorec.** Nahrát do Blobu testovací dávku, která podmínku splní. Pipeline
   z labu ji donese do tabulky během minut.

4. **Ukázat incident.** Sentinel → Incidents: severity, stav, vlastník, entity.
   Otevřít vyšetřování a projít timeline.

5. **Vyslovit pointu.** Mezi krokem 1 a krokem 4 se nezměnila data ani dotaz — změnilo se,
   že se **někdo ptá průběžně** a výsledek má životní cyklus (nový → přiřazený → uzavřený).
   To je celý rozdíl mezi logováním a SIEM.

## Volitelně: nad reálnou SharePoint aktivitou

Sentinel má **Microsoft 365 konektor** a `OfficeActivity` (SharePoint, Exchange, Teams)
je v něm **bezplatný datový zdroj** — dá se tedy postavit pravidlo nad skutečnou aktivitou
tenantu, například nad vytvořením anonymního sdíleného odkazu (vazba na governance sdílení
v [`../../day-4/lifecycle-compliance/`](../lifecycle-compliance/)).

> [!WARNING] Živě to nevyjde — je to o latenci, ne o konfiguraci
> Audit logy Microsoftu 365 mají latenci **typicky 60–90 minut a bez SLA** (Microsoft
> upřednostňuje úplnost dat před rychlostí), první nasazení konektoru trvá **2–3 hodiny**,
> než se cokoli objeví. Akce udělaná v učebně se v `OfficeActivity` do konce bloku
> **neobjeví**.
>
> Jediná varianta, která funguje: nechat studenty tu akci udělat **už ve dni 3** u bloku
> o governance sdílení. Ve čtvrtek odpoledne je v `OfficeActivity` a incident je **jejich
> vlastní**. Vyžaduje to připojit konektor na začátku kurzu — viz go/no-go.

## Co si mají odnést

- **Log odpovídá na otázku, kterou položíte. SIEM se ptá sám.** To je ta věta do rozpočtové
  debaty.
- **Entity mapping není kosmetika** — bez něj vznikne upozornění, s ním vyšetřovatelný
  incident s vazbami na účet, soubor a IP.
- **Latence je vlastnost, ne chyba.** U audit logů je to kompromis ve prospěch úplnosti;
  kdo staví detekci na M365 audit datech, nestaví real-time obranu, ale forenzní stopu.
- Transformace v DCR (z [`README.md`](README.md)) je ta samá myšlenka o vrstvu níž:
  filtrovat a maskovat **před** uložením, ne až v dotazu.

## Fallback

- **Sentinel není zapnutý / trial vyčerpaný**: projít kroky 2–4 ze screenshotů a nechat
  studenty napsat jen ten KQL dotaz pravidla. Pointa (log vs SIEM) se dá předat i bez
  živého incidentu.
- **Pravidlo se nespustí včas**: mít připravený incident z předchozího běhu a ukázat
  rovnou krok 4. Čekání u projektoru na naplánované spuštění je nejhorší možné využití
  dvaceti minut.
- **Demo přeteče**: vypustit krok 3 a ukázat existující incident. Kroky 2 a 5 jsou jádro.

## Zdroje (Microsoft)

- [Plan costs and understand pricing and billing — Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/billing)
- [Microsoft 365 connector for Microsoft Sentinel](https://learn.microsoft.com/en-us/azure/sentinel/data-connectors/microsoft-365)
- [OfficeActivity table reference](https://learn.microsoft.com/en-us/azure/azure-monitor/reference/tables/officeactivity)
- [Troubleshooting the Office 365 Management Activity API](https://learn.microsoft.com/en-us/office/office-365-management-api/troubleshooting-the-office-365-management-activity-api)

## Stav produktu / delta

> [!WARNING] Tvrdé datum: 31. 3. 2027
> **Po 31. 3. 2027 Microsoft Sentinel v Azure portálu končí** a bude dostupný jen
> v Microsoft Defender portálu. Klikací cesta v tomto demu i všechny screenshoty tedy mají
> daný konec životnosti. Kurz poběží i po tomhle datu — před každým během ověřit, ve kterém
> portálu demo jede, a včas ho přepsat na Defender portál.

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Podmínky trialu (dnes 10 GB/den zdarma po 31 dní, limit 20 workspaců na tenant), rozsah
> bezplatných datových zdrojů a nejkratší povolený interval scheduled rule se mění —
> ověřit na [billing](https://learn.microsoft.com/en-us/azure/sentinel/billing) před během.
