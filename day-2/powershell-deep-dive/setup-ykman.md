# Setup · YubiKey Manager (`ykman`) — pro samostudium

> Volitelné. Nepotřebujete to k ničemu v kurzu — je to pro ty, kdo mají vlastní YubiKey
> a chtějí si zopakovat [`demo-yubikey.md`](demo-yubikey.md) doma.

## Co je `ykman`

CLI od Yubica pro konfiguraci YubiKey: PIV sloty, FIDO2, OTP, PIN a PUK. Existuje
i grafický **YubiKey Manager**, ale skriptovat jde jen CLI — a v kurzu, který je
o automatizaci, dává smysl jen ta cesta.

## Instalace

```powershell
winget install --id Yubico.YubiKeyManagerCLI --source winget
ykman --version
ykman list
```

Po instalaci **otevřít nové okno terminálu**, jinak se změna `PATH` neprojeví — stejná
past jako v [`../../day-1/toolchain-setup/`](../../day-1/toolchain-setup/).

`ykman list` musí vypsat připojený klíč. Pokud nevypíše nic, klíč není v USB nebo ho
drží jiná aplikace (typicky běžící relace prohlížeče s otevřeným FIDO promptem).

## Než začnete cokoli mazat

> [!WARNING] PIV sloty mohou být obsazené firemním certifikátem
> Pokud klíč dostáváte od zaměstnavatele, může v PIV slotech mít **firemní certifikát
> pro přihlašování**. `ykman piv keys delete` je nevratné a klíč tím přijde o funkci,
> kterou vám nikdo rychle neobnoví. Nejdřív:

```powershell
ykman piv info
```

Prázdný slot 9a = můžete pracovat. Obsazený slot = použijte jiný (9c, 9d, 9e), nebo
si pořiďte druhý klíč na hraní.

## Výchozí PIN, PUK a management key

Nový YubiKey má tovární hodnoty, které jsou **veřejně známé**:

| Položka | Tovární hodnota |
|---|---|
| PIN | `123456` |
| PUK | `12345678` |
| Management key | `010203040506070801020304050607080102030405060708` |

Pro demo v učebně to stačí. **Pro cokoli, co drží reálný credential, je změňte** —
tovární PIN znamená, že kdokoli s klíčem v ruce může podepisovat vaším jménem:

```powershell
ykman piv access change-pin
ykman piv access change-puk
ykman piv access change-management-key --generate --protect
```

`--protect` uloží management key na klíč chráněný PINem, takže si ho nemusíte pamatovat.

## Blokace klíče

Několik špatných PINů klíč zablokuje; odblokuje se PUKem. Vyčerpání PUKu znamená
**nevratný reset PIV aplikace** včetně všech klíčů v ní. Pro credential aplikace
z toho plyne provozní pravidlo: **mějte plán, co se stane, když klíč selže nebo se
ztratí** — u certifikátu na app registraci to znamená mít připravenou rotaci
(`keyCredentials` je multi-hodnotové pole, viz
[`explainer-certificates-keys.md`](explainer-certificates-keys.md)).

## Zdroje

- [YubiKey Manager CLI (`ykman`) — dokumentace](https://developers.yubico.com/yubikey-manager/)
- [`ykman` command reference](https://docs.yubico.com/software/yubikey/tools/ykman/)
- [PIV — Yubico developers](https://developers.yubico.com/PIV/)

## Stav produktu / delta
> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> Název winget balíčku i syntaxe `ykman piv` se mezi verzemi mění. Ověřit
> `winget search yubikey` a `ykman piv --help` proti dokumentaci výše.
