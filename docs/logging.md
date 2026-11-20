# Logging deployment scope

[`infra/logging`](../infra/logging/) owns a resource group containing the shared
Log Analytics workspace and Azure Monitor workspace. Separating this foundation
from application resource groups gives observability its own deployment and
access boundary; consumers still depend on the workspaces and their availability.
Azure can also create service-managed resources for the Monitor workspace.

## Configuration and handoffs

- `workspace_location`, `workspace_sku_name`, and
  `workspace_retention_in_days` configure Log Analytics. The Monitor workspace
  has its own `monitor_workspace_location` and resource-context access setting.
- Outputs `workspace_id` and `monitor_workspace_id` are passed explicitly to
  consuming roots. `resource_group_id` identifies the root's group.
- Checked-in [dev inputs](../infra/logging/dev.tfvars) put the resource group in
  North Central US and both workspaces in East US 2; Log Analytics retention is
  30 days. This is placement configuration, not regional redundancy.
- The Log Analytics module disables local authentication, enables
  resource-permission-based access and allows public ingestion and query.
  The Monitor workspace has its own resource-context access configuration.
  Review access and retention before directing application data to either.

Registry and Foundry diagnostics and the frontend environment consume Log
Analytics; gateway telemetry can use both workspaces. Deploy the workspaces
before configuring those consumers. A location, retention, access, or removal
change can affect downstream diagnostics and telemetry. Inspect all consumers,
state and the proposed plan before changes; a separate state does not protect
them from a workspace replacement.

The root's state key is `ski-school-logging.tfstate`. For identity-based state,
deployment approvals, and the historical account of region constraints, see
[delivery](delivery.md) and [deployment notes](../infra/README.md).

Reference: [Azure Monitor workspace managed resources](https://learn.microsoft.com/en-us/azure/azure-monitor/metrics/azure-monitor-workspace-manage).
