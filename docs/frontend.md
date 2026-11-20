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

## Front Door and browser origins

The global root reads this app's public ingress and configures it as an HTTPS
origin; see [global Front Door](frontdoor.md). Front Door
sets the origin `Host` to the Container App hostname, while the browser's
`Origin` is the edge hostname. [nginx](../src/frontend/nginx.conf) passes its
received `Host` to the bridge.
For `/api/messages`, the [bridge origin check](../src/frontend/bridge/main.py)
accepts an HTTPS origin matching that host or an exact additional allowlist
entry; local CLI mode also permits matching localhost HTTP. It rejects missing
or unapproved origins. This is a browser-origin check, not caller
authentication or network access control.

[`bridge_allowed_origins`](../infra/frontend/variables.tf) becomes the JSON
`BRIDGE_ALLOWED_ORIGINS` environment variable in
[`aca`](../infra/modules/aca/main.tf). Entries must be exact lowercase HTTPS
DNS origins without ports, wildcards or paths. The
[dev input](../infra/frontend/dev.tfvars) lists an edge origin explicitly; it
is not wired to the global output. Compare the actual generated
`default_hostnames` output with the configured HTTPS origin after approved edge
provisioning. If they differ, an independently approved frontend update is
needed before edge-hosted message requests can work. A global-only change does
not automatically run frontend delivery. Coordinate endpoint replacement and
allowlist updates; no cross-root orchestration enforces this handoff.

The Container App still has external HTTPS ingress. Neither the bridge
allowlist nor the checked-in edge configuration restricts access to this
origin to this Front Door profile. No Front Door-specific ingress IP or
`X-Azure-FDID` validation is configured. Direct-origin use remains possible.
See Microsoft's [origin security guidance](https://learn.microsoft.com/en-us/azure/frontdoor/origin-security)
for the distinction between public-origin filtering and private access; the
repository does not establish that either is implemented.

References: [Container Apps containers](https://learn.microsoft.com/en-us/azure/container-apps/containers)
and [Foundry roles and agent consumers](https://learn.microsoft.com/en-us/azure/foundry/concepts/rbac-foundry).
