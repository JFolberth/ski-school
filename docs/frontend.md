# Frontend deployment scope

[`infra/frontend`](../infra/frontend/) owns a resource group for the website's
Azure Container Apps environment, application and supporting telemetry and
identity resources. Separating the public-facing runtime from Foundry and the
agent release permits distinct deployment ownership and access boundaries.
The application still depends on the configured agent, registry and logging
workspace.

## Website and bridge

The JavaScript, HTML and CSS in [`src/frontend`](../src/frontend/) implement a
chat interface. nginx serves the static assets and proxies `/api/` and
`/healthz` to the Python bridge in the same Container App; it also exposes
deployment metadata. The browser does not receive Azure credentials.

The [bridge](../src/frontend/bridge/main.py) exposes message submission and a
health endpoint. It validates request origin and invokes the Foundry agent
using the Container App's system-assigned identity. Conversation history stays
in browser memory: the frontend sends up to five recent exchanges with each
message, and the bridge sends the assembled input to the Responses endpoint
with storage disabled. Reset clears the browser-side conversation; the bridge
does not maintain sessions or conversation history. Upstream failures are
surfaced instead of fabricated answers. Azure CLI authentication is intended
only for local use, not the Container App.

## Infrastructure and handoffs

The Container App has external HTTPS ingress, runs a single active revision,
and sends its environment diagnostics to Log Analytics through Azure Monitor.
Application Insights is associated with that workspace. Configurable replica
limits and HTTP concurrency govern scaling.

The root takes the existing agent ARM ID, registry and Log Analytics workspace
IDs, frontend and bridge image digests, scaling and resource settings. The
agent ID is supplied explicitly rather than read from a backend Terraform
output. A dedicated user-assigned managed
identity pulls images; the application system identity has Foundry Agent
Consumer access scoped to the agent. Neither is the CI deployment identity.
The image-pull identity is not available to application code for token
acquisition. For registries using ABAC permissions, the pull grant is limited
to the configured image repositories.

The root outputs the Container App URL and ID, runtime principal,
Application Insights ID and resource group ID. CD publishes the verified
frontend and bridge images and passes their digests into Terraform. Review
image changes, agent access, capacity and scaling together. Its state key is
`ski-school-frontend.tfstate`; the checked-in dev resource
group is in North Central US. See [delivery](delivery.md) for state and approval
requirements.

References: [Container Apps containers](https://learn.microsoft.com/en-us/azure/container-apps/containers)
and [Foundry roles and agent consumers](https://learn.microsoft.com/en-us/azure/foundry/concepts/rbac-foundry).
