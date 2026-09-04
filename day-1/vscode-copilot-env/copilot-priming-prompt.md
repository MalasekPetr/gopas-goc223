# Priming prompt · Krocení fantazie Copilota pro skriptování M365

**Microsoft Copilot Chat** nemá ve výchozím stavu trvalé instrukce pro vaše téma —
pravidla se nastavují tzv. **priming promptem**: blok níže se vloží jako **první zpráva
nové konverzace** a platí pro celý její zbytek. V kurzu ho použijete mnohokrát denně,
takže si ho uložte jako snippet do repa z labu tohoto bloku (je to taky kód).

Proč: bez mantinelů model ochotně **vymyslí** neexistující cmdlet, parametr nebo Graph
endpoint — vypadá to věrohodně a spadne až za běhu. Priming prompt fantazii omezuje
a hlavně ji **zviditelňuje**: nutí model přiznat nejistotu místo hádání.

Dokument je záměrně **ve dvou verzích s testem mezi nimi** — na vlastní oči uvidíte, jak
podoba promptu mění výsledek. To je hlavní lekce: prompt není jednou hotový text, ale
nástroj, který se iteruje proti chybám, které reálně dělá.

## Verze 1 — základní pravidla (kopírovat celý blok)

```text
Jsi asistent pro PowerShell skriptovani nad Microsoft 365 (SharePoint Online,
Microsoft Graph). V cele teto konverzaci se ridis temito pravidly:

1. Pouzivej vyhradne existujici cmdlety, parametry a API endpointy. Pokud si
   nejsi jisty, ze neco existuje, vyslovne to napis a uved, kde to mam overit
   (Get-Command, Get-Help, learn.microsoft.com, pnp.github.io). Nikdy nazvy
   nevymyslej.
2. Cilove prostredi: PowerShell 7. Povolene moduly: PnP.PowerShell,
   Microsoft.Graph, Microsoft.Online.SharePoint.PowerShell. Nepouzivej MSOnline
   ani AzureAD (jsou vypnute) ani jine moduly, ktere vyslovne nezminim.
3. Microsoft Graph: endpoint v1.0, ne beta, pokud nereknu jinak. U kazdeho
   Graph volani uved, jake permission vyzaduje a zda delegated nebo application.
4. Kazdy skript: param() s vychozimi hodnotami, try/catch s citelnou chybou,
   u operaci, ktere neco meni nebo mazou, podpora -WhatIf. Vystup vracej jako
   objekty, ne Write-Host. Data obsahuji ceskou diakritiku - pri cteni a zapisu
   souboru vzdy explicitne -Encoding utf8, CSV pro Excel s -Encoding utf8BOM
   -UseCulture.
5. Zadne konkretni identifikatory: tenant, ClientId, URL, thumbprint pis jako
   placeholder <takto> a na konci vyjmenuj, cim je mam nahradit.
6. Kdyz je me zadani nejednoznacne, poloz doplnujici otazku - nehadej.
7. Kdyz neco nevis, napis "nejsem si jisty" a navrhni zpusob overeni. Jistotu
   nepredstiraj.
8. Ke kazdemu skriptu pridej: co dela (max 2 vety), jaka opravneni potrebuje
   a jak ho bezpecne otestovat pred ostrym spustenim.
```

## Test verze 1 — co chytí a co spolehlivě propustí

**Test A — návnada (chytí):** *„Použij cmdlet `Get-PnPSiteHealthScore` a ukaž mi
příklad."* Cmdlet neexistuje — správná reakce je pochybnost a odkaz na ověření dle
pravidla 1. Pokud model přesto vyrobí sebevědomý příklad, vidíte fantazii v čisté podobě.

**Test B — připojení k SPO (spolehlivě selže):** *„Napiš skript, který se přihlásí k webu
přes PnP.PowerShell a vypíše všechny seznamy."* Typický návrh s verzí 1:

```powershell
Connect-PnPOnline -Url "https://<tenant>.sharepoint.com/sites/<web>" -Interactive
```

Vypadá správně — a **při spuštění spadne** (`AADSTS700016` / „Specify a valid client
id"). Proč: PnP.PowerShell od 9. 9. 2024 **vyžaduje vlastní `-ClientId`** (sdílené
výchozí bylo odebráno), jenže internet je plný let starých příkladů bez něj — a model
generuje nejčastější vzor, který zná. Pravidlo 1 tady nepomůže: cmdlet i parametry
**existují**, jen je jejich kombinace zastaralá. Druhá tvář fantazie: nejen vymyšlené
názvy, ale i **reálná, jen neaktuální praxe**. Diagnostika téhož symptomu ve skriptu:
[`../../day-2/powershell-deep-dive/troubleshooting-auth.md`](../../day-2/powershell-deep-dive/troubleshooting-auth.md).

## Verze 2 — doplněná pravidla

K bloku výše přidejte pravidla 9–11 (úplná verze 2 = verze 1 + tento blok):

```text
 9. Pripojeni k SharePoint Online: vzdy Connect-PnPOnline s explicitnim
    -ClientId <moje app registrace> (a -Tenant u app-only). Auth mody:
    -Interactive (delegated), -UseDeviceLogin, nebo -Thumbprint <thumbprint>
    (app-only, bez promptu). PnP.PowerShell od zari 2024 nema vychozi ClientId -
    nikdy negeneruj Connect-PnPOnline bez -ClientId a nepouzivej zastarale
    -UseWebLogin ani -Credentials.
10. Prace se seznamy: filtruj na serveru (-Filter, $filter, CAML <Where>), ber
    po strankach (-PageSize, -All, @odata.nextLink) a nikdy negeneruj
    Get-PnPListItem bez omezeni nasledovane Where-Object. Nazvy poli pouzivej
    presne tak, jak ti je dam - jsou to interni nazvy, nehadej je z popisku.
11. Chyby: 429 a 5xx retryuj s respektovanim hlavicky Retry-After (nikdy pevny
    Start-Sleep), ostatni 4xx nereryuj a nahlas je jako chybu k reseni.
```

**Test B podruhé** (nová konverzace, verze 2): návrh teď obsahuje
`-ClientId <client-id-app-registrace>` jako placeholder dle pravidla 5, správný auth mód
a poznámku, čím placeholder nahradit. Stejný model, stejná otázka — jiný prompt, jiný
(funkční) výsledek.

## Pointa — prompt je živý dokument

Když model **opakovaně** dělá tutéž chybu, nepřepisujte pořád jeho výstup — **přidejte
pravidlo do priming promptu**. Během kurzu vám přibudou vlastní pravidla (interní názvy
polí z [`../../day-2/graph-fundamentals/tips-spo-api.md`](../../day-2/graph-fundamentals/tips-spo-api.md),
stránkování, threshold 5000, dekorace user agenta).

**Evoluce → agent:** vkládat prompt do každé konverzace je daň za ruční přístup.
Otestovaná sada pravidel je přesně to, z čeho se dá udělat **deklarativní agent**
(„Scripting Assistant") — pravidla se stanou trvalými instrukcemi agenta a vkládání
končí. Cesta **prompt → otestovaná pravidla → agent** je hlavní AI dovednost, kterou si
z kurzu odnesete; licenční a nákladovou stránku agentů řeší
[`explainer-copilot-licensing.md`](explainer-copilot-licensing.md).

## Vazby

- Pravidla 4–5 kopírují review checklist z [`README.md`](README.md) a zákaz citlivých
  identifikátorů z [`../onboarding/ways-of-working.md`](../onboarding/ways-of-working.md).
- Pravidlo 9 odpovídá deltě v [`../../day-2/powershell-deep-dive/README.md`](../../day-2/powershell-deep-dive/README.md)
  (PnP `-ClientId` od 9/2024); Test B se hodí zopakovat živě před Labem 1 dne 2.
- Pravidla 10–11 vycházejí z [`../../day-2/graph-fundamentals/`](../../day-2/graph-fundamentals/)
  (stránkování, klasifikace chyb, velké seznamy).

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Chování modelů se mění: Test B projet den předem. Pokud už model generuje `-ClientId`
> sám od sebe, je demo slabší (a svět lepší) — pak demonstrovat na jiném spolehlivém
> failu; princip verze 1 → test → verze 2 platí dál. Pokud Copilot Chat mezitím dostane
> trvalé uživatelské instrukce, přenést obsah tam a priming prompt zkrátit.
