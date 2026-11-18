# Initial infrastructure deployment

The Terraform roots in this directory own separate resource groups and state.
The initial dev deployment uses the existing logging and registry roots before
Foundry. The gateway is a later stage; a gateway resource alone does not create
a usable Foundry model connection. Publishing an agent and its image is also a
separate lifecycle from provisioning these roots.

## Prerequisites and state

- Install Azure CLI and Terraform `>= 1.11, < 2.0`. Each root pins AzAPI in its
  checked-in lockfile. Sign in with `az login` (or `az login --use-device-code`
  on a remote host), select the intended subscription, and verify the tenant.
- Each root needs an explicit, ignored `dev.tfvar` passed with
  `-var-file=dev.tfvar`. Start with that root's `example.tfvars`; supply the
  tenant, subscription, and dependent resource IDs explicitly. Terraform does
  not automatically load `.tfvar` files.
- The backend settings are separate from variables. Copy the relevant
  `dev.backend.hcl.example` to ignored `dev.backend.hcl`, verify the storage
  coordinates and choose the matching isolated state key. Do not copy
  credentials into either file or commit state, plans, or `.terraform/`.
- The existing dev backend was already provisioned before these deployments;
  its bootstrap configuration and state ownership are not established in this
  repository. Before a new bootstrap or migration, agree on how the backend
  infrastructure itself is managed, how initial state is encrypted and secured,
  and how it will be migrated to locked remote state. Obtain explicit approval;
  never fall back silently to local state.
- The backend uses Microsoft Entra data-plane authentication and Azure Blob
  leases for locking. The existing account has encryption and HTTPS enabled,
  and shared-key access disabled. For a new environment verify these controls,
  access, key ownership, and network policy before initialization. HashiCorp
  recommends **Storage Blob Data Contributor** at the container scope for state
  access; the initial dev operator had an existing assignment at storage-account
  scope. No backend role was granted as part of these deployments.
- Check the appropriate resource providers are registered and that the deployer
  has the required resource and diagnostic-setting actions at their actual
  scopes. Provider auto-registration is disabled in the roots. Registration,
  role grants, bootstrap and other cloud writes require separate approval.

Before backend initialization or any apply, identify the tenant, subscription,
resource group and environment, review the effects and costs, and obtain
explicit approval for that operation. For each root, initialize the approved
remote backend with `terraform init -backend-config=dev.backend.hcl
-lockfile=readonly`, validate, and generate a saved plan with the explicit dev
variable file. Review and approve the exact plan before applying it. Stop for
unexpected changes, replacement, deletion, conflicts, or target differences.

## Initial dev sequence

1. **Logging (`logging`)**: Log Analytics and its resource group are in North
   Central US. Azure Monitor workspace is in East US 2 because Azure's provider
   metadata did not offer that workspace type in North Central US. Set
   `monitor_workspace_location = "eastus2"` explicitly. Azure also creates a
   service-managed resource group, data collection rule and endpoint for the
   Monitor workspace. The Log Analytics workspace uses 30-day retention,
   resource-context access and disabled local authentication.
2. **Registry (`registry`)**: deploy the Basic registry in North Central US
   and pass the logging root's Log Analytics `workspace_id` output explicitly.
   The registry uses public network access, with admin and anonymous pulls
   disabled. Audit diagnostics send login and repository events to Log
   Analytics. Azure returns disabled `AllMetrics` in the diagnostic setting;
   the module explicitly models it as disabled to avoid recurring drift.
3. **Foundry (`foundry`)**: provide the Log Analytics workspace ID and an
   explicitly verified model version, deployment type and capacity. Dev
   selected `gpt-5.4-mini` version `2026-03-17`, GlobalStandard capacity `10`.
   Recheck region, quota and pricing for the target before each deployment.
   GlobalStandard can process inference outside the resource region.
   Dev keeps `native_otlp_enabled = false` because native OTLP across the
   existing workspace regions remains unverified. The dev project has a
   project-managed-identity tracing connection to the deployed Log
   Analytics-backed Application Insights component. Azure returned the
   configured connection properties, but actual trace ingestion has not been
   verified. Foundry Audit diagnostics are also deployed. Azure returns other
   log categories and `AllMetrics` disabled; the diagnostic setting models
   these explicitly without enabling request, response or trace capture.
4. **Gateway (`gateway`)**: the dev gateway foundation is in East US 2 with
   public backend routing and a system-assigned identity. Azure rejected the
   example `AIGateway` SKU during the first apply and required `Standard`;
   the approved recovery created the gateway using that SKU. The gateway now
   has Foundry access, a registered model and alias, and a configured OpenTelemetry
   exporter. Dev explicitly enables payload capture; end-to-end telemetry ingestion
   and cross-region inference remain unverified, and caller authorization remains
   deferred.

## Initial identity and role boundaries

- Do not use keys as an authentication fallback or grant broad roles to bypass
  missing access. Separate the deployment operator, gateway, project, hosted
  agent, image-pull and telemetry identities. A system-assigned identity is the
  preferred Azure workload identity where the specific integration supports it.
- The logging and registry deployments did **not** create workload role
  assignments. Registry image-pull access was deliberately deferred; do not
  assume the Foundry account identity is the image-pull principal. Microsoft's
  hosted-agent guidance identifies the project managed identity for image pulls
  and a separate agent identity for code execution. Verify the registry
  permission mode, exact role and scope, and project connection before granting
  access. Build/push and hosted-agent publication are not part of these roots.
- The Foundry root can grant **Foundry User**, the role used by Microsoft's
  gateway integration, to an explicitly supplied gateway identity at the
  Foundry account scope. Dev has this grant deployed to the gateway identity.
  The existing narrower
  **Cognitive Services OpenAI User** option is retained; don't assign both to
  the same gateway. The gateway root can grant **AI Gateway Models User** to
  an explicitly supplied caller at the model alias scope.
- The project identity has **Monitoring Metrics Publisher** on the Foundry
  Application Insights component, managed by the Foundry root. The dev tracing
  connection is deployed, but actual ingestion remains unverified. Microsoft's
  tracing guidance specifies a separate publisher grant
  for the hosted-agent identity when its code emits traces; that grant remains
  deferred. Traces can contain prompts, outputs and tool data; review redaction
  and retention before enabling them. The gateway exporter also supports payload
  capture; the dev setting captures prompts, completions, and tool input/output,
  with no built-in PII redaction. Review the telemetry destination's access and
  retention controls.

## Deployment notes and recovery

- Azure CLI sign-in and the existing backend use identity-based access. The
  root-local inputs and backend configuration are ignored and may contain
  environment-specific information; recreate them securely on another host.
- The first Foundry apply was **partial**: the resource group, account, model
  deployment and Audit diagnostic were created. Azure rejected the Application
  Insights preview API, and project creation encountered a concurrent
  account-operation conflict. The approved recovery used the supported
  `2020-02-02` Application Insights API with native OTLP disabled and created
  both missing resources after the account operation completed. The account,
  project, model and Application Insights component reported `Succeeded`, and
  the follow-up plan showed no changes. For future recovery, inspect resources
  and remote state and review a new plan; do not remove state, force-unlock, or
  delete resources as a shortcut.
- The native OTLP opt-out and tracing-connection opt-out are independent.
  Disabling an existing project connection can plan its removal; native OTLP
  cannot necessarily be disabled after it is enabled. Review changes carefully
  when modifying existing environments.
- The project connection uses `ProjectManagedIdentity` and Microsoft sample
  destination metadata; its narrowly approved AzAPI schema exception leaves
  server-side validation in place. The Application Insights connection string
  is destination metadata, not an authentication fallback. Terraform reads it
  from the component and stores that provider response in encrypted remote
  state; restrict state access. The connection's write-only sensitive body
  avoids persisting another copy there. Increment
  `application_insights_metadata_version` if that metadata changes.
- The gateway's initial apply created its resource group but failed on the SKU;
  the reviewed recovery plan created the gateway with `Standard`. The gateway
  reported `Succeeded` and its follow-up plan showed no changes. Its remote
  state uses the isolated `gateway-dev.tfstate` key. The subsequent approved
  model-route apply created a Foundry provider, model and Responses alias;
  Azure returned their configured properties and the follow-up plan showed no
  changes. No caller grant or end-to-end inference test has been completed.
- The previous `2026-11-01` gateway child API is published in the
  [official specification](https://github.com/Azure/azure-rest-api-specs/blob/main/specification/apimanagement/resource-manager/Microsoft.ApiManagement/AIGateway/stable/2026-11-01/openapi.json),
  but Azure rejected this version for provider, alias and exporter reads on the
  dev gateway. The approved model-route apply failed during AzAPI's initial
  provider GET with `MissingOrIncorrectVersionParameter`, before any provider
  create; model and alias creation were not attempted. The gateway modules now
  use the `2025-09-01-preview` contracts shown in Microsoft's
  [gateway sample](https://github.com/Azure-Samples/ai-gateway-foundry-terraform/blob/main/standalone/ai_gateway.tf)
  and [model sample](https://github.com/Azure-Samples/ai-gateway-foundry-terraform/blob/main/standalone/ai_gateway_models.tf),
  with individually approved local schema exceptions. Server-side validation
  remains enabled. The provider, model and alias were created successfully
  using this preview version; the telemetry exporter remains deferred.

## References

- [Terraform Azure Blob backend and Entra authentication](https://developer.hashicorp.com/terraform/language/backend/azurerm)
- [Azure Monitor workspace managed resources](https://learn.microsoft.com/en-us/azure/azure-monitor/metrics/azure-monitor-workspace-manage)
- [Azure Monitor OTLP setup and region guidance](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/opentelemetry-protocol-ingestion)
- [Foundry quota and deployment capacity](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/quota)
- [Hosted-agent deployment and identities](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/deploy-hosted-agent)
- [Foundry tracing with Microsoft Entra authentication](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-ingestion-entra-authentication)
