# Explainer · Runbooky z repa: source control integration vs vlastní pipeline

Odpověď na otázku, která v sále padne hned po prvním nasazení z portálu: **„a jak to dělá
inženýr, ne klikač?"** Runbook naklikaný v portálovém editoru není verzovaný, nemá code
review a nikdo nepozná, kdo ho změnil. To se dá řešit dvěma způsoby a **ten pohodlnější
má omezení, které se u tohoto kurzu trefí do nejcitlivějšího místa.**

Doplněk k [`tutorial-script-to-azure.md`](tutorial-script-to-azure.md). Určeno i k přečtení
předem.

## Pozitivní výběr: podle toho, co potřebujete

| Chci… | Volba |
|---|---|
| **runbooky v repu bez psaní pipeline**, PowerShell **5.1**, a stačí mi „co je v repu, to je v Automation" | **Source Control Integration** |
| **PowerShell 7.2** runbooky (tedy i PnP.PowerShell 7.4+) | **vlastní pipeline** — native cesta 7.2 neumí |
| **testy před nasazením** (Pester musí projít, jinak se nepublikuje) | **vlastní pipeline** |
| **sestavit runbook z víc souborů** (knihovna funkcí + volací blok) | **vlastní pipeline** |
| promovat **stejný kód mezi DEV/TEST/PROD** Automation accounty přes branche | **Source Control Integration** (na to je navržená) |
| **žádný PAT** s právy na repo hooky | **vlastní pipeline** (federated credentials) |

První a poslední řádek jsou legitimní důvody pro native cestu. Zbytek vede k pipeline —
a **u tohoto kurzu rozhoduje druhý řádek**, viz níž.

## Co Source Control Integration je

Nativní funkce Automation accountu: připojíte repozitář a runbooky se z něj synchronizují
do Automation účtu. Podporované typy jsou tři: **GitHub**, **Azure DevOps (Git)**
a **Azure DevOps (TFVC)**.

Chování se nastavuje dvěma přepínači, které dohromady dělají přesně to „publikuj na
commit":

- **Auto Sync** — *„Setting that turns on or off automatic synchronization when a commit
  is made in the source control repository or GitHub repo."*
- **Publish Runbook** — *„Setting of On, if runbooks are automatically published after
  synchronization from source control, and Off otherwise."*

Takže `git push` → sync → publish, bez jediného kliknutí. Zní to jako hotová věc.

## Dvě omezení, která to pro tenhle kurz vyřadí

> [!WARNING] Source control integration podporuje **jen PowerShell 5.1**
> Verbatim z dokumentace: *„Source control integration is supported for **PowerShell 5.1
> runbooks only**."*
>
> Runbook v [`../elevated-access/lab-elevated-access.md`](../elevated-access/lab-elevated-access.md)
> běží na **runtime 7.2**, protože `PnP.PowerShell` 7.4+ vyžaduje PowerShell 7. Native
> cesta se na něj tedy nedá použít — a není to volba, je to hranice funkce.

> [!WARNING] Sync joby nepodporují MFA
> Verbatim: *„Azure Automation Jobs **do not support Multi-Factor Authentication (MFA)**."*
> Kurzový tenant má MFA povinné (viz [`../../environment.md`](../../environment.md)),
> takže i kdyby runtime souhlasil, narazí se tady.

Pro **5.1 runbooky v prostředí bez MFA** je to ale pořád dobrá volba a stojí za to ji znát —
zejména kvůli tomu promování mezi prostředími přes branche.

## Když jdete native cestou: čtyři věci, které zaskočí

| Co | Detail |
|---|---|
| **Rekurze nefunguje** | *„Only runbooks in the specified folder are synchronized. **Recursion isn't supported**."* Jedna plochá složka, typicky `/Runbooks`. Strukturovaný projekt se do toho nevejde. |
| **Jednosměrně** | *„supports **single-direction** synchronization"* — repo → Automation. Co naklikáte v portálu, se do repa **nevrátí** a příští sync to přepíše. |
| **Webhook expiruje po roce** | *„Auto-sync may fail if Source Control was created over a year ago, as the webhook used to invoke the Source Control expires after one year."* Auto Sync pak **tiše přestane fungovat**. Řešení podle docs: založit source control znovu se stejnou konfigurací. |
| **Azure DevOps má default proti vám** | *„Third-party application access via OAuth policy is defaulted to off for all new organizations"* → chyba `SourceControl securityToken is invalid`. Musí se zapnout v Organization Settings → Policies **předem**. |

Plus tři provozní podmínky:

- Automation account potřebuje **managed identity s rolí Contributor na sám sebe**
  (u user-assigned navíc automation variable `AUTOMATION_SC_USER_ASSIGNED_IDENTITY_ID`
  s jejím Client ID — bez ní se použije system-assigned).
- **Auto Sync smí zapnout jen Project Administrator nebo owner repa.** Verbatim:
  *„Collaborators can only configure Source Control without Auto Sync."*
- **Cross-tenant autentizace není podporovaná** a Auto Sync **nefunguje s Automation
  Private Link** (webhook přichází zvenčí sítě).

Sync joby se navíc **účtují jako běžné Automation joby** — není to zdarma.

### PAT oprávnění, když to konfigurujete skriptem

`New-AzAutomationSourceControl` chce PAT jako secure string. Minimální rozsahy:

| Zdroj | Rozsah |
|---|---|
| **GitHub** | `repo` (`repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`) + `admin:repo_hook` (`write:repo_hook`, `read:repo_hook`) |
| **Azure DevOps** | `Code` Read, `Project and team` Read, `Identity` Read, `User profile` Read, `Work items` Read, a **`Service connections` Read/query/manage — jen když je zapnutý autosync** |

`admin:repo_hook` u GitHubu není náhoda: právě tím se zakládá ten webhook, který po roce
vyprší. **PAT se přes portál nedá vyměnit** — jen přes REST API nebo
`Update-AzAutomationSourceControl`.

## Vlastní pipeline: co to je a proč je to i tam, kde native funguje, lepší

Dva cmdlety, které už znáte z [`tutorial-script-to-azure.md`](tutorial-script-to-azure.md),
jen spuštěné v CI po úspěšných testech:

```powershell
# 0. Cesty odvodit od korenu repa, ne od aktualni slozky. V CI nikdy nespolehat
#    na to, kde runner stoji - relativni "./" se vyhodnocuje proti pracovnimu
#    adresari, ne proti umisteni skriptu.
$repo   = $env:GITHUB_WORKSPACE ?? $env:BUILD_SOURCESDIRECTORY ?? (Get-Location).Path
$module = Join-Path $repo 'day-4/elevated-access'
$out    = Join-Path $repo 'out'

# 1. Testy. Kdyz spadnou, dal se nejde - tohle je cely rozdil proti native syncu.
Invoke-Pester (Join-Path $module 'solution/Grant-RequestedAccess.Tests.ps1') -CI

# 2. Sestavit runbook. Runbook nema disk, takze knihovna funkci a volaci blok
#    se musi slepit do jednoho souboru.
New-Item -ItemType Directory -Force $out | Out-Null
# runbook-body.ps1 je ten volaci blok z labu (param + Connect-PnPOnline -ManagedIdentity
# + Invoke-AccessRequestQueue). V realnem projektu lezi v repu vedle reseni.
Get-Content (Join-Path $module 'solution/Grant-RequestedAccess.ps1'), `
            (Join-Path $module 'runbook-body.ps1') |
    Set-Content (Join-Path $out 'Grant-Access.ps1')

# 3. Nahrat a publikovat
Import-AzAutomationRunbook -ResourceGroupName $env:RG -AutomationAccountName $env:AA `
  -Name "Grant-Access" -Type PowerShell -Path (Join-Path $out "Grant-Access.ps1") -Force

Publish-AzAutomationRunbook -ResourceGroupName $env:RG -AutomationAccountName $env:AA `
  -Name "Grant-Access"
```

Tři důvody, proč je to lepší volba i bez toho omezení na 5.1:

1. **Testy jsou branka, ne dokumentace.** Native sync publikuje, co je v repu — bez ohledu
   na to, jestli to prošlo. Pipeline publikuje jen to, co prošlo.
2. **Sestavování ze víc souborů.** Native sync mapuje *jeden soubor = jeden runbook*.
   Náš runbook je knihovna funkcí **plus** volací blok, takže se musí slepit. Native cesta
   to neumí a musel byste knihovnu duplikovat do každého runbooku.
3. **Žádný PAT.** Pipeline se autentizuje **federated credentials** (workload identity)
   nebo certifikátem — nikoli tokenem s právem zakládat webhooky v repu, který za rok
   vyprší.

> [!NOTE] Ve VS Code na to nepotřebujete nic navíc
> Jsou to `.ps1` soubory v repozitáři. PowerShell rozšíření, které učebna má podle
> [`../../environment.md`](../../environment.md), stačí — struktura projektu je vaše věc,
> ne věc Automation accountu. To je právě ta svoboda, kterou native sync svým „jedna plochá
> složka, bez rekurze" nedává.

## Klíčové rozlišení

- **Sync vs deploy.** Source Control Integration **zrcadlí** repo do Automation účtu.
  Pipeline **nasazuje** artefakt, který prošel testy. První je pohodlí, druhé je kontrola.
- **Jeden soubor = jeden runbook vs sestavený artefakt.** Rozhoduje o tom, jestli můžete
  mít knihovnu funkcí sdílenou mezi runbooky, nebo ji budete kopírovat.
- **PAT vs federated credentials.** PAT je secret s expirací, který musí umět zakládat
  webhooky. Federated credentials nejsou secret vůbec — je to tentýž princip jako managed
  identity v runbooku samotném, jen o vrstvu výš.
- **Portálový editor vs repo.** Runbook naklikaný v portálu není verzovaný a příští sync
  ho přepíše. Portálový editor je na **ladění**, ne na autorství.

## Zdroje (Microsoft)

- [Use Source Control Integration in Azure Automation](https://learn.microsoft.com/en-us/azure/automation/source-control-integration) — podporované typy, Auto Sync, Publish Runbook, omezení na PowerShell 5.1, PAT rozsahy, expirace webhooku
- [New-AzAutomationSourceControl](https://learn.microsoft.com/en-us/powershell/module/az.automation/new-azautomationsourcecontrol) — konfigurace skriptem
- [Update-AzAutomationSourceControl](https://learn.microsoft.com/en-us/powershell/module/az.automation/update-azautomationsourcecontrol) — výměna expirovaného PAT
- [Az.Automation](https://learn.microsoft.com/en-us/powershell/module/az.automation/) — `Import-AzAutomationRunbook`, `Publish-AzAutomationRunbook`, `Start-AzAutomationSourceControlSyncJob`
- [Workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation) — autentizace pipeline bez secretu

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — stav k 2026-09.
> **Omezení „PowerShell 5.1 runbooks only" je nosný argument celého tohoto souboru.**
> Kdyby Microsoft source control integration rozšířil na 7.2, převáží u části scénářů
> native cesta a rozhodovací tabulka výše se mění. Ověřit před **každým** během na
> [source-control-integration](https://learn.microsoft.com/en-us/azure/automation/source-control-integration).
>
> Totéž platí pro nepodporu MFA u Automation jobů — je to druhý blokátor a mění se
> nezávisle na prvním.
>
> Minimální PAT rozsahy u GitHubu i Azure DevOps se mění spolu s tím, jak se v obou
> službách mění model tokenů (GitHub fine-grained PATs). Před během ověřit, ne opisovat
> odsud.
