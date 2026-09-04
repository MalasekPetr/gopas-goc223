# Pravidla způsobu práce (ways of working)

Governance ground-rules kurzu. Zavádí se tady a pozdější moduly se na ně odkazují (nit
celého kurzu). **V tomto kurzu mají všichni studenti roli Global administrator ve sdíleném
tenantu `cloudedu.cz`** — pravidla níže nahrazují technické zábrany, které v produkci
zajišťují role. Porušení pravidla typicky rozbije práci ostatním 24 lidem.

## Tvrdá pravidla (bez výjimky)

1. **Žádné tenant-wide `Set-*` bez instruktora.** `Set-SPOTenant`, sharing policy na úrovni
   organizace, Entra tenant nastavení — jen na pokyn instruktora, nikdy "na zkoušku".
2. **Sahej jen na svoje artefakty.** Cizí weby, app registrace, resource groups a skripty
   jsou tabu — i když na ně jako GA technicky dosáhneš.
3. **Nemazat a needitovat nic, co jsi nevytvořil.** Včetně "úklidu" věcí, které vypadají
   opuštěně — mohou patřit jinému studentovi nebo minulému běhu.

## Naming konvence (izolace přes pojmenování)

Protože nás neizolují role, izolují nás jména. Všechno, co vytvoříš, nese tvůj login prefix —
a od **druhého artefaktu stejného typu a účelu** i dvouciferné pořadové číslo:

| Artefakt | Vzor | Příklad |
|---|---|---|
| SharePoint web | `/sites/<jmeno-prijmeni>-<účel>[-NN]` | `/sites/jan-novak-dev`, druhý pokus `/sites/jan-novak-dev-02` |
| App registrace | `<jmeno.prijmeni>-<účel>[-NN]` | `jan.novak-course-app`, druhá `jan.novak-course-app-02` |
| Azure resource group | `rg-goc223-<jmeno-prijmeni>[-NN]` | `rg-goc223-jan-novak` |
| Skripty/soubory v repu | složka `<jmeno-prijmeni>/` | `jan-novak/connect-wrapper.ps1` |

Pravidla pro číslování:

- **První kus bez čísla** — laby odkazují na kanonická jména (`-dev`, `-course-app`);
  číslo se přidává až od druhého kusu (`-02`, `-03`…).
- **Vždy dvouciferně** (`-02`, ne `-2`) — správně se řadí v seznamech i ve skriptech.
- **Nepřepoužívat jméno smazaného artefaktu** pro něco jiného — smazaný web drží URL
  v koši a smazaná app registrace zůstává v *Deleted applications*; nový pokus = nové číslo.

## Přístupový princip

- **Licence vs. permissions vs. role** — E5 licence dává přístup k funkcím, SharePoint
  permissions řídí obsah, Entra role (GA) řídí administraci. Tři různé vrstvy, viz
  [`../../GLOSSARY.md`](../../GLOSSARY.md).
- To, že něco *můžeš* (GA), neznamená, že to *smíš* (pravidla kurzu) — přesně tak zní
  least-privilege argument v [`../automation-strategy/`](../automation-strategy/).

## Zodpovědná AI a data

- Do tenantu nenahrávat reálná firemní/osobní data — jen kurzovní a fiktivní obsah.
  Fiktivní testovací data (weby, položky, dokumenty, cesty ze zdrojového fileshare) si nechte
  vygenerovat Copilot Chatem — recepty na prompty:
  [`../vscode-copilot-env/guide-dummy-data.md`](../vscode-copilot-env/guide-dummy-data.md).
- Do promptů (Copilot Chat i jakýkoli jiný AI asistent) nikdy nevkládat tenant ID, ClientId, secrety,
  cert thumbprinty (viz [`../vscode-copilot-env/`](../vscode-copilot-env/)).
- Výstupy AI ověřovat před použitím — platí pro kód, fakta i vygenerovaná dummy data
  (kontrola, že neobsahují reálná jména a firmy).
