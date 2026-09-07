# Explainer · Copilot Chat, agenti a pay-as-you-go: co je zdarma a co se účtuje

Kurz používá **Microsoft Copilot Chat** jako asistenta pro přípravu a testování skriptů —
bez samostatné vývojářské AI licence. Tenhle explainer vysvětluje, **co v Copilot Chatu
nic nestojí, kde začíná měřená spotřeba** a jak se pay-as-you-go zapíná a hlídá. Pro
cílovou skupinu kurzu je to zároveň provozní téma: rozhodnutí, které budete doma
obhajovat před rozpočtem.

## Tři úrovně, které se pletou

| Úroveň | Co to je | Náklad |
|---|---|---|
| **Copilot Chat** | chat s modelem v rámci firemního přihlášení, s ochranou firemních dat | součást stávajícího M365 předplatného |
| **Agenti nad firemními daty** (deklarativní agenti, SharePoint agents) pro uživatele **bez** Copilot licence | agent s vlastními instrukcemi a zdroji v tenantu | **měřená spotřeba** — pay-as-you-go přes Azure subscription |
| **Microsoft 365 Copilot (plná licence)** | Copilot v Office aplikacích, agenti bez měření | měsíční licence na uživatele |

Nosná věta: **chat je součástí toho, co už máte; agent nad firemními daty pro
nelicencovaného uživatele je měřená služba.** Kurz staví na první úrovni, druhou používá
vědomě a v malém.

## Ochrana dat — argument, který padne jako první

Copilot Chat běží s ochranou firemních dat: prompty a odpovědi zůstávají v hranicích
služby Microsoft 365 a **netrénují modely**. To je licenčně i datově „přijde s tím, co už
máte" — a zároveň důvod, proč se v kurzu smí používat na pracovní úlohy. Pravidla
z [`../onboarding/ways-of-working.md`](../onboarding/ways-of-working.md) platí beze
změny: **žádné tenant ID, ClientId, thumbprinty ani reálná osobní data v promptu.**

## Jak se pay-as-you-go zapíná (a proč to admin musí vědět)

Pay-as-you-go je **ve výchozím stavu vypnuté**. Zapnutí má dva kroky a dělá se
v Microsoft 365 admin centru:

1. **Billing policy** — spojí **Azure subscription** s množinou uživatelů; policy je
   nositelem nákladové odpovědnosti (lze ji přiřadit oddělení) a lze na ni nastavit
   **rozpočet s notifikacemi** při dosažení procentních milníků.
2. **Připojení policy ke službě** — teprve tím uživatelé pokrytí policy získají přístup
   k měřeným agentům v dané službě (Copilot Chat, SharePoint agents). Odpojením přístup
   zase ztratí.

Role, které to smí spravovat: Global administrator, Billing administrator, **AI
administrator**, Global reader (jen čtení). Pro least-privilege je správná volba **AI
administrator nebo Billing administrator**, ne GA — přesně ta úvaha, kterou kurz vede
u app registrací ([`../../day-2/automation-strategy/`](../../day-2/automation-strategy/)).

Spotřeba se účtuje **přes Azure meter na připojené subscription**; sledovat se dá
v M365 admin centru na stránce Cost Management i v Azure Cost Management.

## Praktická nákladová hygiena

- **Rozpočet nastavit hned při zapnutí**, ne až po prvním vyúčtování; notifikace jsou
  součástí billing policy.
- **Billing policy na skupinu, ne „all users"** — jinak měřenou službu dostane celý
  tenant a nákladová odpovědnost se rozplyne.
- **Vypnutí je odpojení policy**, ne mazání agentů — rychlá brzda, když spotřeba
  vyskočí.
- Náklady sledovat **před** rozhodnutím o plných licencích: typický důvod, proč PAYG
  zapnout, je zjistit reálný vzorec využití.

## Klíčové rozlišení

- **Chat vs agent** — konverzace v rámci předplatného vs pojmenovaná konfigurace
  s instrukcemi a zdroji, která u nelicencovaného uživatele spotřebovává kredity.
- **Licence vs billing policy** — licence je předplacené právo na uživatele, policy je
  měřená spotřeba účtovaná přes Azure; obojí se dá kombinovat.
- **Ochrana dat vs veřejný chatbot** — Copilot Chat s firemním účtem nepatří do stejné
  kategorie jako veřejná AI služba; to je věta, kterou budete doma potřebovat.

## Zdroje (Microsoft)

- [Microsoft Copilot pay-as-you-go service overview](https://learn.microsoft.com/en-us/microsoft-365/copilot/pay-as-you-go/overview)
- [Set up Microsoft Copilot pay-as-you-go services](https://learn.microsoft.com/en-us/microsoft-365/copilot/pay-as-you-go/setup)
- [Meters for Microsoft Copilot pay-as-you-go services](https://learn.microsoft.com/en-us/microsoft-365/copilot/pay-as-you-go/meters)
- [Usage-based billing and cost management for Copilot Credits](https://learn.microsoft.com/en-us/microsoft-365/copilot/usage-based-billing-overview-copilot-credits)
- [Agents for Microsoft Copilot Chat](https://learn.microsoft.com/en-us/copilot/agents)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> **Nejrychleji se měnící fakt v tomto modulu.** Názvy služeb, sazby meterů, seznam
> služeb dostupných v pay-as-you-go i rozsah toho, co je zdarma v Copilot Chatu, se mění
> po měsících. Před KAŽDÝM během ověřit odkazy výše a projít nastavení billing policy
> v kurzovním tenantu.
