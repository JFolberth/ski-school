# Foundry deployment scope

[`infra/foundry`](../infra/foundry/) owns a resource group for the Foundry
account, project, model deployments, Application Insights and account
diagnostics. Keeping the foundation together while separating gateway policy
and agent releases allows these pieces to have different deployment ownership
and change lifecycles. The root also manages optional project connections and
cross-scope grants; it does not own the registry or gateway.

## Resources and dependencies

- The account and project provide the foundation for hosted agents. The
  `models` map configures model deployments, including model version, SKU and
  capacity; validate regional availability, quotas and cost for a target.
- The logging root provides `workspace_id` and, when native OTLP is enabled,
  `monitor_workspace_id`. Application Insights and account diagnostics use
  these inputs. The project telemetry connection is independently configurable.
- Optional `project_acr_connection` connects the project to the registry.
  The Foundry project managed identity receives the appropriate pull role
  based on registry permission mode. This is not the agent runtime identity.
- Explicitly supplied gateway and telemetry principals can receive scoped
  grants. The gateway integration and inference grants are configured on the
  account; telemetry publisher grants are scoped to Application Insights.
  Their existence, live role assignments and telemetry ingestion are not
  established merely by documentation.

Outputs include `account_id`, `account_endpoint`, `project_id`,
`project_principal_id`, model deployment IDs, `gateway_backend`, telemetry
identifiers, and the optional registry connection ID. They support explicit
handoffs to other roots; see [`outputs.tf`](../infra/foundry/outputs.tf) for
their exact shapes. The root state key is `ski-school-foundry.tfstate`.

The checked-in [dev configuration](../infra/foundry/dev.tfvars) has two model
entries and disables native OTLP while enabling a project telemetry connection.
Model configuration is not proof of available quota or active inference.
Examine changes to telemetry, connections, identity grants and dependent gateway
routes before applying a plan.

The project telemetry connection uses project managed identity. Its
connection metadata can be sensitive even when it is not an authentication
fallback; protect state and inspect the connection configuration before
changing or disabling it. Account diagnostics are separate from application
telemetry and configure Audit for dev.

## Toolbox lifecycle

The [ski-tools toolbox definition](../infra/foundry/toolboxes/ski-tools/azure.yaml)
declares the SnowSure MCP backend. Foundry CD packages its source separately,
then deploys and publishes the toolbox after the Terraform deployment succeeds.
The toolbox release is not Terraform provisioning. Gateway configuration
references a versioned toolbox endpoint; coordinate toolbox and gateway changes
and review external data exposure. See [delivery](delivery.md).

Historical recovery notes are in [infra/README.md](../infra/README.md); they
are not a current deployment-status check.

References: [Foundry hosted-agent permissions](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/hosted-agent-permissions),
[model quota](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/quota),
and [Foundry tracing with Entra authentication](https://learn.microsoft.com/en-us/azure/foundry/observability/how-to/trace-ingestion-entra-authentication).
