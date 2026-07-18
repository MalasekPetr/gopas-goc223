# Explainer · TypeScript/Node cesta: přímé napojení na Graph API

Deep-dive k [`README.md`](README.md). PowerShell není jediná cesta — automatizaci lze psát
i jako TypeScript/Node skripty s přímým voláním Microsoft Graph. Pro cílovku kurzu
(DevOps/platform engineers) je to relevantní alternativa: stejná auth matice, jiný jazyk.

## Stavební bloky

| Balíček | Role |
|---|---|
| `@microsoft/microsoft-graph-client` | Graph JS SDK — fluent volání `client.api('/sites/...').get()` |
| `@microsoft/microsoft-graph-types` | TypeScript typy Graph entit (IntelliSense nad users/sites/drives) |
| `@azure/identity` | credentials — stejné auth módy jako v PowerShellu (viz níže) |
| `@pnp/sp` (PnPjs) | SPO-native volání tam, kde Graph nestačí — TS ekvivalent role PnP.PowerShell |

## Stejná auth matice, jiný jazyk

Auth rozhodnutí z [`../../day-2/powershell-deep-dive/`](../../day-2/powershell-deep-dive/) platí beze změny —
mění se jen implementace: `DeviceCodeCredential`, `ClientCertificateCredential`,
`ManagedIdentityCredential` z `@azure/identity` jsou 1:1 protějšky PowerShell auth módů.
Graph JS SDK je napojí přes `TokenCredentialAuthenticationProvider`.

```typescript
// App-only pristup s certifikatem - protejsek Connect-PnPOnline -CertificateThumbprint
import { ClientCertificateCredential } from "@azure/identity";
import { Client } from "@microsoft/microsoft-graph-client";
import { TokenCredentialAuthenticationProvider } from
  "@microsoft/microsoft-graph-client/authProviders/azureTokenCredentials";

const credential = new ClientCertificateCredential(tenantId, clientId, certPath);
const client = Client.initWithMiddleware({
  authProvider: new TokenCredentialAuthenticationProvider(credential, {
    scopes: ["https://graph.microsoft.com/.default"],
  }),
});
const site = await client.api("/sites/root").get();
```

## Kdy zvolit TS/Node místo PowerShellu

- Tým je primárně vývojářský (TS je domácí jazyk) a skripty žijí vedle aplikačního kódu.
- Cíl běhu je Node prostředí — Azure Function (TS), CI pipeline s node image (viz
  [`../vscode-copilot-env/explainer-runtime-environments.md`](../vscode-copilot-env/explainer-runtime-environments.md)).
- Návaznost na SPFx ([`../../day-5/spfx-fundamentals/`](../../day-5/spfx-fundamentals/)) —
  stejný jazyk a tooling pro webparty i automatizaci. CLI for Microsoft 365 je sám Node/TS,
  takže tahle cesta je "to samé o vrstvu níž".

Kdy naopak zůstat u PowerShellu: admin-orientované úlohy s hotovými cmdlety (PnP provisioning,
tenant nastavení) — psát je v TS znamená znovu vynalézat, co cmdlety dávno umí.

## Zdroje (Microsoft)

- [Build TypeScript apps with Microsoft Graph](https://learn.microsoft.com/en-us/graph/tutorials/typescript)
- [Build TypeScript apps with Microsoft Graph — app-only authentication](https://learn.microsoft.com/en-us/graph/tutorials/typescript-app-only)
- [Install a Microsoft Graph SDK](https://learn.microsoft.com/en-us/graph/sdks/sdk-installation)

## Stav produktu / delta

> [!WARNING] Ověřit k datu běhu — vedle `@microsoft/microsoft-graph-client` existuje novější
> Kiota-based `@microsoft/msgraph-sdk` (v době psaní pre-release); ověřit, který SDK je k
> datu běhu doporučený default pro nové projekty.
