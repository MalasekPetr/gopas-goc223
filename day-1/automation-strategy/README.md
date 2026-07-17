# M1.2 · Strategie automatizace & nástrojová mapa

> Typ: povinný · Den: 1 · Odhad: <min>

## Cíle
- PowerShell vs Graph vs PnP vs REST — kdy který.
- App registration & identity strategie.
- Bezpečnostní postoj a least privilege jako výchozí návyk.

## Výklad

### PowerShell vs Graph vs PnP vs REST
Tři PowerShell moduly z GLOSSARY.md (PnP.PowerShell, Microsoft.Graph, SPO Management Shell) jsou
wrappery nad dvěma REST rozhraními — Microsoft Graph a SharePoint REST/CSOM. Rozhodovací otázka
není "PowerShell nebo REST", ale "wrapper, nebo přímé volání": moduly šetří boilerplate
(auth, paging, serializace), přímé REST volání dává plnou kontrolu tam, kde modul nemá cmdlet
pro potřebnou operaci nebo kde je nutná jemná kontrola nad chybovými stavy (viz M2.1).

### App registration & identity strategie
Každá automatizace potřebuje identitu, pod kterou běží. Rozhodnutí padá na dvou osách:
delegated (uživatel je přítomen, přihlašuje se) vs application (běží bez přihlášeného uživatele,
jako služba) a interaktivní vs headless. Microsoft doporučuje delegated tam, kde je to možné —
aplikační oprávnění (application permissions) se udělují na úrovni celého tenantu a
rozšiřují útočnou plochu víc než permission vázaná na konkrétního uživatele.

### Bezpečnostní postoj a least privilege
Žádat jen oprávnění nezbytná pro danou akci, pravidelně auditovat přiřazená oprávnění proti
skutečně použitým a odebírat nadbytečná (např. `User.ReadWrite.All`, když stačí `User.Read.All`).
Samostatné app registrace pro samostatné účely — nesdílet jednu aplikaci mezi nesouvisejícími
automatizacemi, aby kompromitace jedné neotevřela přístup ke všem.

```mermaid
flowchart TD
  A[Potřebuji automatizovat úkol] --> B{Existuje cmdlet v PnP/Graph/SPO modulu?}
  B -->|Ano, časté operace| C[Použít modul]
  B -->|Ne, nebo potřebuji jemnou kontrolu chyb| D[Přímé REST/Graph volání]
  C --> E{Je přítomen přihlášený uživatel?}
  D --> E
  E -->|Ano| F[Delegated permissions]
  E -->|Ne, běží jako služba| G[Application permissions + least privilege audit]
```

## Klíčové rozlišení
- **Delegated vs application permissions** — delegated je vázané na přihlášeného uživatele a jeho
  oprávnění, application permission platí tenant-wide bez ohledu na to, kdo skript spustí.
- **PnP.PowerShell vs SPO Management Shell překryv** — viz `GLOSSARY.md`; preferovat PnP pro
  čitelnost, SPO modul jen tam, kde chybí PnP ekvivalent.
- **Modul (wrapper) vs přímé REST/Graph volání** — modul je rychlejší start, přímé volání je
  nutné pro jemnou kontrolu retry/error handlingu (M2.1).

## Lab
Viz [`lab-app-registration.md`](lab-app-registration.md).

## Zdroje (Microsoft)
- [Increase application security with the principle of least privilege](https://learn.microsoft.com/en-us/entra/identity-platform/secure-least-privileged-access)
- [Security best practices for application properties](https://learn.microsoft.com/en-us/entra/identity-platform/security-best-practices-for-app-registration)
- [Overview of permissions and consent in the Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/permissions-consent-overview)

## Stav produktu / delta
- Ověřit k datu běhu — doporučený least-privilege permission model se zpřesňuje (Microsoft
  postupně označuje širší oprávnění jako "reducible" ve prospěch užších ekvivalentů); před
  během zkontrolovat, zda konkrétní permissions v labu nemají nově doporučenou užší alternativu.
