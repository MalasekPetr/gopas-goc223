# GOC223 — Microsoft 365: Pokročilá automatizace a migrace SharePoint

Zdrojové materiály kurzu **GOC223** (GOPAS). Vše je psané v Markdownu s Mermaid diagramy, renderovatelné přímo na GitHubu.

> [!NOTE]
> Cílová skupina: inženýři migrací a automatizace, pokročilí administrátoři M365/SharePoint Online, DevOps/platformní inženýři pro governance, konzultanti navrhující škálovatelný provisioning a migrační rámce. Předpoklady: základy PowerShellu, zkušenost se správou SharePoint Online, základy Azure (resource groups, identity); vítána znalost JSON/REST a zkušenost s migračními nástroji.

## Jak repo číst

- **Pořadí modulů** je definované v [`agenda.md`](agenda.md) — složky jsou pojmenované **slugy**, ne čísly, aby vkládání dalších modulů nerozhazovalo číslování.
- **Závazné názvosloví** (nástroje, API, PowerShell moduly, Azure služby) je v [`GLOSSARY.md`](GLOSSARY.md) — jediný zdroj pravdy.
- **Konvence** (MD styl, Mermaid, currency-markery, číslování modulů) jsou v [`CONVENTIONS.md`](CONVENTIONS.md).
- **Šablony** modulu a labu jsou v [`_templates/`](_templates/).
- **Prostředí kurzu** (pracovní tenant, na který se laby odkazují) je v [`environment.md`](environment.md).
- **Provozní skripty** kurzu (lifecycle studentů, app registrace, Azure prostředky) jsou v [`scripts/`](scripts/).

## Struktura

```text
goc223/
├─ README.md          # tento soubor
├─ CONVENTIONS.md      # jak psát materiály
├─ GLOSSARY.md         # závazné názvosloví
├─ agenda.md           # 5denní pořadí bloků (single source of order)
├─ environment.md      # pracovní tenant kurzu
├─ _templates/         # module.md, lab.md
├─ scripts/            # lifecycle a provisioning automatizace kurzu
├─ day-1/ … day-5/     # obsah po dnech; každý modul = složka se slugem
```

## Legenda

- **Povinný** modul — součást každého běhu.
- **Volitelný** modul (slug s prefixem `opt-`) — spouští se dle času / potřeb skupiny; nikdy na něm nesmí záviset povinný modul ani capstone.
- Čísla v nadpisech modulů (`M<den>.<pořadí>`, např. `M2.3`) jsou jen čitelný odkaz na pořadí — **jediný zdroj pravdy o pořadí je `agenda.md`**.
- Currency-markery v textu:
  - `> [!WARNING] Ověřit k datu běhu` — fast-moving fakt (ceny, preview, throttling limity, verze modulů).
  - `> [!IMPORTANT]` — lineage / přejmenování / API breaking change, na které studenty upozornit.

## Stav

Scaffold. Struktura všech 5 dnů a 15 modulů založená jako kostry (README/lab/instructor-notes skeleton). Obsah doplňujeme postupně, den po dni.
