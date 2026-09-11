# Scripting Advisor — kompletní zdrojový kód agenta

Zdrojový kód deklarativního agenta, kterého kurz používá jako AI asistenta pro psaní
skriptů. Je tu **celý**, ne výřez: co je v této složce, to se publikuje do tenantu.
Výklad architektury je v [`../explainer-declarative-agent.md`](../explainer-declarative-agent.md).

Agent je poskytnutý autorem kurzu (Malach IS, MCT). **Není publikovaný v Agent Store** —
běží jen v tenantu, kde ho správce schválí.

## Proč vlastní agent, a ne jen chat

Doma studenti sahají po nástrojích jako Claude Code nebo GitHub Copilot a je to správná
volba. Na kurzu se ale pracuje s tím, co je dostupné v učebně — a to je **Microsoft Copilot
Chat** v rámci firemního přihlášení. Tenhle agent ukazuje, že to není omezení, ale příležitost:
agent (Model Context Protocol, MCP) nad stejným chatem umí věci, na které obecná konverzace nedosáhne — **MCP konektivitu,
řízený grounding a guardrails, které si nese s sebou.**

## Soubory

| Soubor | Co to je |
|---|---|
| [`declarativeAgent.json`](declarativeAgent.json) | jádro — capabilities, actions, behavior overrides, disclaimer, 12 conversation starterů |
| [`instruction.txt`](instruction.txt) | systémový prompt agenta; **7 411 z 8 000 povolených znaků** |
| [`ai-plugin.json`](ai-plugin.json) | plugin manifest v2.4 — runtime `RemoteMCPServer` proti Microsoft Learn MCP |
| [`manifest.json`](manifest.json) | Microsoft 365 app manifest v1.30 — jméno, vydavatel, ikony, privacy/terms |
| [`m365agents.yml`](m365agents.yml) | projektový soubor Agents Toolkitu — kroky `provision` a `publish` |
| [`eval-questions.md`](eval-questions.md) | 20 testovacích otázek s kritérii úspěchu a známými pastmi |
| [`scoring-sheet.csv`](scoring-sheet.csv) | hodnoticí list, jeden na běh |

Chybějící soubory oproti originálu jsou vědomé: ikony (`.png`), vygenerované ID prostředí
(`env/`) a legal stránky vydavatele. `projectId` byl z `m365agents.yml` odebrán — je to
lokální identifikátor Toolkitu, ne konfigurace.

> [!IMPORTANT] Pole vydavatele
> `manifest.json` je ponechaný **verbatim** včetně `developer`, `mpnId` a `accentColor`.
> Při publikování pod vlastní organizací se tahle pole nahrazují — Microsoft Partner Network (MPN) ID a privacy/terms
> URL musí odpovídat skutečnému vydavateli, jinak validace balíčku neprojde.

## Návrhová rozhodnutí a jejich důvody

| Rozhodnutí | Proč |
|---|---|
| Deklarativní agent, ne custom engine | hostuje Microsoft — žádné Azure hosting náklady, žádný orchestrátor k údržbě |
| **Žádná capability nad daty tenantu** | nástroj na skripty nemá vidět zákaznická data; zároveň to agenta drží mimo měřenou spotřebu pro uživatele bez Copilot licence |
| Microsoft Learn MCP jako akce | normativní zdroj pro cmdlety, parametry, endpointy, oprávnění a limity — agent dokumentaci čte, ne si ji pamatuje |
| Tři WebSearch domény ze čtyř | `pnp.github.io` pokryje PnP PowerShell, CLI for Microsoft 365 i script samples jedním slotem; čtvrtý slot je rezerva |
| `learn.microsoft.com` **není** ve WebSearch | duplikovalo by MCP akci, která má lepší retrieval |
| `discourage_model_knowledge: false` | Learn nedokumentuje PnP PowerShell — zapnutí by udělalo do znalostí díru; břemeno nese instrukce |
| `default_response_mode: "Think deeper"` | tyhle otázky se vyplatí prořešit, ne odbýt rychlou odpovědí |
| Zdrojová hierarchie v instrukcích | Learn normativní pro signatury, PnP/CLI reference pro své nástroje, komunitní samply jako vzory — nikdy ne jako signatury |

## Build a publikace

**Microsoft 365 Agents Toolkit** ve VS Code, verze 6.12.0 nebo novější (starší neumí
nakonfigurovat MCP akci).

- **Provision** — vytvoří aplikaci, zabalí a zvaliduje balíček, publikuje do katalogu agentů.
- **Publish** — odešle do tenant app katalogu ke schválení správcem.

Znovupublikování už publikovaného agenta vyžaduje **zvýšit `version` v `manifest.json`**.
Katalog odmítne titul, jehož verze není striktně vyšší než živá; změna `manifestVersion`
nebo `$schema` se nepočítá.

## Evaluace

Hlavní metrika je **míra halucinací a laťka je nula**. 8 z 20 otázek míří do oblastí, pro
které agent groundovaný není — tam je přiznaná nejistota procházející odpovědí.

Výchozí evaluátory Relevance a Coherence **vymyšlený cmdlet neodhalí** — odpověď
s neexistujícím parametrem je perfektně relevantní i koherentní. Manuální hodnocení proti
rubrice je primární, automatické skóre je regresní test plynulosti.

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Verze schémat (app manifest 1.30, declarative agent v1.8, plugin manifest v2.4, Toolkit
> project file v1.12) i minimální verze Agents Toolkitu se mění po měsících. Před během
> ověřit proti [Declarative agent schema](https://learn.microsoft.com/en-us/microsoft-365/copilot/extensibility/declarative-agent-manifest-1.8)
> a zkusit build v čerstvém prostředí.
