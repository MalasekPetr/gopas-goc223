# Instructor notes — Strategie automatizace & nástrojová mapa

## Timing

- 40 min výklad + 45 min lab.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, zda studentské účty v kurzovém tenantu smí registrovat aplikace (Entra ID → User
  settings → App registrations). Pokud ne, rozhodnout mezi (a) dočasné přidělení Application
  Developer role, nebo (b) instruktor registruje jednu sdílenou aplikaci — viz Fallback v labu.
- Připravit admin consent flow předem — pokud admin consent vyžaduje Global Admin, mít
  instruktora připraveného kliknout "Grant admin consent" hned po registraci každou skupinou.

## Tripwires

- Studenti mají tendenci rovnou přidat `Sites.FullControl.All` "pro jistotu" — trvat na
  `Sites.Read.All` v tomto kroku, širší oprávnění přijdou přirozeně v pozdějších dnech, kdy
  budou reálně potřeba (a student uvidí PROČ).
- Nezaměňovat consent dialog uživatele (delegated, per-user) s admin consent (tenant-wide) —
  časté nedorozumění u prvního zkoušení.

## Vazby

- Dopředu: tato app registrace se používá napříč celým týdnem; `security-hardening` (M5.2)
  na konci kurzu provádí audit a hardening přesně této aplikace.
- Zpět: navazuje na repo hygienu z M1.1.
