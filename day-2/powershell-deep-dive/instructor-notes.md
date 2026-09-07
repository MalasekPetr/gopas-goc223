# Instructor notes — PowerShell do hloubky

## Timing

- 45 min výklad + 90 min lab (první velký lab kurzu — otvírák dne 2, počítat s rezervou;
  instalace tří modulů může zabrat 10-15 minut na pomalejší síti, pustit na pozadí hned
  na začátku bloku).
- Volitelný mini-lab [`lab-write-identities.md`](lab-write-identities.md) (+25 min) spouštět
  **jen při reálné rezervě**; jinak zadat jako samostudium. Nic na něm nezávisí.

## Go/no-go — KLÍČOVÉ, otestovat před během

- Ověřit, že app registrace z [`../../day-1/automation-strategy/`](../../day-1/automation-strategy/) má `-ClientId` funkční pro PnP interaktivní přihlášení —
  od 9. 9. 2024 PnP.PowerShell vyžaduje vlastní ClientId, sdílené výchozí už nefunguje.
- **Projít celý flow labu na testovacím účtu den předem**: `New-SelfSignedCertificate` na
  učebním stroji (práva k CurrentUser store jsou standard, ale ověřit image učebny), upload
  `.cer` na app registraci, app-only `Connect-PnPOnline -Thumbprint`, a hlavně
  **`New-PnPSite` v app-only režimu** — tenant policy umí app-only vytváření webů blokovat;
  pokud blokuje, aktivovat Fallback variantu (delegated vytvoření) rovnou ve výkladu.
- Admin consent pro `Sites.FullControl.All` si studenti dávají sami (GA) — připomenout
  pravidla z [`../../day-1/onboarding/ways-of-working.md`](../../day-1/onboarding/ways-of-working.md), je to druhá tenant-wide akce dne.
- Pokud v učebně není druhé zařízení pro device code test, mít připravený telefon/tablet
  jako záložní "druhé zařízení" pro demo.

## Referenční řešení

- [`solution/Connect-CourseTarget.ps1`](solution/Connect-CourseTarget.ps1) + 18 testů.
  `Invoke-Pester ./solution` projde bez tenantu i bez certifikátu — dá se pustit jako
  součást go/no-go i na stroji, kde ještě není nic nastavené.
- **Dva testy jsou tam kvůli chybám, které odhalily.** Stojí za zmínku ve výkladu, protože
  obojí je poučení, ne kuriozita: `throw` po emitování objektu zahodí návratovou hodnotu
  (proto je ve wrapperu `Write-Error`), a nepodporovaná kombinace je chyba **zadání**,
  takže patří k validaci, ne do chybové větve připojení.

## Tripwires

- Studenti si pletou `-ClientId` aplikace s `-TenantId` — zdůraznit rozdíl hned na začátku.
- **Nenechat nikoho exportovat `.pfx` "pro zálohu"** — celý bod labu je, že private key
  neopouští stroj/store; `.cer` (veřejná část) je jediný soubor, který se přenáší.
- Weby vytvářet skriptem (smyčka přes dev/test/prod), ne 3× ručně v UI — jde o návyk
  parametrizace; UI-cesta neprojde ověřením.
- SPO modul v PowerShell 7 potřebuje `-UseWindowsPowerShell` při importu na některých verzích —
  mít na slidu jako rychlou opravu, pokud `Import-Module` selže.
- **Certifikát musí být RSA.** ECC klíč (`-KeyAlgorithm ECDSA_nistP256`) projde generováním
  i uploadem, ale `Connect-PnPOnline` skončí „The provided certificate is not of type RSA".
  Kdo si příkaz upraví po svém, spadne — a chyba nezní jako problém certifikátu.
- **`$t.Payload.aud` tiše vrátí prázdno** (objekt z `-Decoded` vlastnost `Payload` nemá) —
  studenti pak hlásí „token je prázdný". Používat `.Audiences` / `.Claims` nebo ruční
  dekódování; tichý prázdný výstup je vděčný učební moment.
- **Po každé změně consentu je nutné nové připojení** — token v paměti roli nedostane
  zpětně. Typický scénář: „permission tam přece je" a přitom 401. Plus 1–2 min propagace.
- Delegated vs Application permission u app-only: přidané jako *Delegated* se v app-only
  režimu **ignoruje** — 401 s prázdnou odpovědí. Tabulka symptomů:
  [`troubleshooting-auth.md`](troubleshooting-auth.md).

## Vazby

- Dopředu: weby `-dev/-test/-prod` z tohoto labu jsou přímý vstup do
  [`../../day-2/staging-environments/`](../../day-2/staging-environments/) (diff/baseline) a
  [`../../day-3/migration-patterns/`](../../day-3/migration-patterns/) (migrační cíle);
  `Connect-CourseTarget` wrapper se znovupoužívá po celý zbytek kurzu; certifikátová identita
  je základ pro plánovaný sync task v [`../../day-4/azure-integration-patterns/`](../../day-4/azure-integration-patterns/)
  a pro rotační cvičení v [`../../day-5/security-hardening/`](../../day-5/security-hardening/).
- Zpět: navazuje na app registraci a auth strategii z [`../../day-1/automation-strategy/`](../../day-1/automation-strategy/).
