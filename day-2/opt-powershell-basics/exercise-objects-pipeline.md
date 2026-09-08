# Cvičení · Co mi to vlastně vrátilo

> Odhad: 20 min · Režim: lokálně, bez tenantu, bez psaní kódu

## Cíl

Student na vlastní oči vidí, že pipeline nese objekty, umí si zjistit vlastnosti
neznámého výstupu a nechá si třemi příkazy předvést tři pasti, které by ho jinak
v labech stály hodinu hledání.

## Předpoklady

- PowerShell 7.4+ z [`../../day-1/toolchain-setup/`](../../day-1/toolchain-setup/).
- **Nic dalšího.** Cvičení běží na lokálních cmdletech, nepotřebuje přihlášení, tenant
  ani síť — schválně, aby ho nemohl zablokovat účet.

## Kroky

### Objekt, ne text

1. Vypište běžící procesy a všimněte si, kolik sloupců výpis ukázal:

   ```powershell
   Get-Process
   ```

2. Teď se zeptejte, co ten příkaz **skutečně** vrátil:

   ```powershell
   Get-Process | Get-Member
   ```

   Přečtěte si první řádek (`TypeName:`) a spočítejte, kolik je tam vlastností. Je jich
   výrazně víc než sloupců v kroku 1.

   A teď to zajímavější: **najděte v tom výpisu `PM(K)` nebo `CPU(s)`** — sloupce, které
   krok 1 ukázal. Nenajdete je. Jsou to *počítané* vlastnosti a jejich skutečná jména jsou
   jiná (`PagedMemorySize64`, `CPU`). Výpis na obrazovce tedy není jen zúžený — je i
   **přeznačený**. Proto se skutečná jména dají zjistit jedině přes `Get-Member`.

3. Vytáhněte vlastnost, kterou výpis v kroku 1 **neukázal**:

   ```powershell
   Get-Process | Select-Object -Property Name, Id, Path -First 5
   ```

   Pointa: `Path` v původním výpisu nebyl, ale v datech byl celou dobu.

### Past 1 — `Format-*` ukončuje pipeline

4. Porovnejte, co dostane další cmdlet v řadě:

   ```powershell
   Get-Process | Select-Object Name, Id | Get-Member
   Get-Process | Format-Table Name, Id | Get-Member
   ```

   První `TypeName` je pořád rozumný objekt. Druhý je něco z
   `Microsoft.PowerShell.Commands.Internal.Format` — **formátovací** objekt, ne vaše data.
   Proto `Format-*` patří jen na konec řádku.

### Past 2 — filtrujte vlevo, a ve správném pořadí

5. Tento příkaz **nevrátí nic**. Než ho spustíte, zkuste říct proč:

   ```powershell
   Get-Service | Select-Object DisplayName, Status | Where-Object CanPauseAndContinue
   ```

6. Otočte pořadí a porovnejte výsledek:

   ```powershell
   Get-Service | Where-Object CanPauseAndContinue | Select-Object DisplayName, Status
   ```

   `Select-Object` v kroku 5 vlastnost `CanPauseAndContinue` z pipeline vyhodil, takže
   nebylo podle čeho filtrovat. Chyba se nikde neohlásila — jen přišel prázdný výsledek.

### Past 3 — pole a `$null`

7. Nechte si předvést, že index mimo rozsah nic neohlásí:

   ```powershell
   $data = 'nula','jedna','dve'
   $null -eq $data[9000]
   ```

8. A že `-eq` nad polem nevrací pravdivostní hodnotu, ale prvky:

   ```powershell
   $data -eq 'jedna'
   $data -ne 'jedna'
   ```

9. Porovnejte se správným zápisem, kde je `$null` vlevo:

   ```powershell
   $prazdne = @()
   $null -eq $prazdne
   $prazdne.Count
   ```

### Orientace v neznámém modulu

10. Bez čtení dokumentace zjistěte, co existuje pro práci s procesy a jak se to volá:

    ```powershell
    Get-Command -Noun Process
    Get-Help Stop-Process -Parameter WhatIf
    ```

    Poslední příkaz je ta pojistka pro celý týden: `-WhatIf` existuje, dá se zjistit
    z helpu, a `Stop-Process` ho má.

## Ověření

- [ ] Student umí říct, kolik vlastností má objekt z `Get-Process` a proč jich výpis
      ukázal méně — a najde sloupec z výpisu, který v `Get-Member` pod tím jménem není.
- [ ] Student ukáže vlastnost, která ve výchozím výpisu nebyla, a vytáhne ji.
- [ ] Student vysvětlí, čím se liší `TypeName` za `Select-Object` a za `Format-Table`,
      a řekne, kam `Format-*` v řádku patří.
- [ ] Student dokáže **před spuštěním** kroku 5 vysvětlit, proč nevrátí nic.
- [ ] Student umí říct, co vrátí `$data -eq 'jedna'`, a proč se `$null` píše vlevo.
- [ ] Student si sám najde, jestli daný cmdlet podporuje `-WhatIf`.

## Fallback

- **Časový skluz**: vypustit kroky 7-9 (pole a `$null`) — vrátí se k nim blok 3 u prvního
  reálného skriptu, kde ta past skutečně nastane. Kroky 1-6 ne; objekt v pipeline
  a pořadí filtrů jsou to, kvůli čemu cvičení existuje.
- **Skupina je na tom lépe, než se zdálo**: přeskočit na krok 4 a celé cvičení stáhnout
  na deset minut jako společné demo u projektoru, ne samostatnou práci.
- `Get-Service` je na Windows; na jiné platformě nahradit kroky 5-6 za
  `Get-ChildItem | Select-Object Name | Where-Object Length` — pointa (vyhozená vlastnost)
  je identická.
