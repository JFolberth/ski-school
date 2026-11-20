# Front Door deployment scope

[`infra/global`](../infra/global/) owns a separate global resource group for
Azure Front Door profiles, endpoints, origin groups, origins, routes and
diagnostic settings. It does not own the frontend app or logging workspace.
The checked-in [dev inputs](../infra/global/dev.tfvars) name the group
`rg-ski-global-dev-gbl`. Its North Central US location is resource-group
metadata; the Front Door profile and endpoint are configured as `global`.

## Profiles and routing

The root takes explicit tenant, subscription, resource-group and workspace
IDs, an existing frontend Container App ID, and a `profiles` map. It reads and
validates the app's public ingress hostname through Azure, not frontend state,
even when a profile does not use that frontend. See
[`data.tf`](../infra/global/data.tf),
[`variables.tf`](../infra/global/variables.tf),
[`main.tf`](../infra/global/main.tf), and
[`outputs.tf`](../infra/global/outputs.tf). The read uses
[`Microsoft.App/containerApps@2026-07-01`](https://learn.microsoft.com/en-us/azure/templates/microsoft.app/2026-07-01/containerapps).

One deployment can define multiple Standard profiles and endpoints. Each
profile has one origin group shared by its endpoints; optional additional
origins have configurable hostnames, priorities and weights. Dev configures one
profile, one endpoint and one frontend origin. When that origin is eligible,
it receives all origin-directed traffic. With more origins, selection depends
on health, priority, latency and weight; weights are not guaranteed traffic
percentages. Additional origins alone do not provision regional replicas,
replicate data or demonstrate failover.

Each [route](../infra/modules/frontdoor-route/main.tf) links the default domain,
matches `/*`, accepts HTTP and HTTPS, redirects HTTP to HTTPS, and forwards
to the origin over HTTPS. Caching, custom domains, a WAF policy and private
origin connections are not configured. The
[origin](../infra/modules/frontdoor-origin/main.tf) sends the origin hostname
as `Host` and enables certificate-name checking against that hostname. The
frontend Container App remains publicly reachable directly; the bridge's
origin allowlist is not network access control. See
[frontend origins](frontend.md#front-door-and-browser-origins), Microsoft's
[origin guidance](https://learn.microsoft.com/en-us/azure/frontdoor/origin),
[routing methods](https://learn.microsoft.com/en-us/azure/frontdoor/routing-methods),
and [caching guidance](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-caching).

## Health and telemetry

The [origin group](../infra/modules/frontdoor-origin-group/main.tf) uses HTTPS
`GET /healthz` and disables session affinity. Dev configures a 240-second probe
interval, four samples, three required successes and zero additional latency.
The profile's origin response timeout is 240 seconds. The
[bridge health endpoint](../src/frontend/bridge/main.py) returns `ok` but does
not check the agent or model, so the probe is not end-to-end readiness. See
Microsoft's [health-probe behavior](https://learn.microsoft.com/en-us/azure/frontdoor/health-probes).

Each profile's [diagnostic setting](../infra/global/main.tf) enables
`FrontDoorHealthProbeLog` and `AllMetrics` to the existing Log Analytics
workspace, and explicitly disables `FrontDoorAccessLog` and
`FrontDoorWebApplicationFirewallLog`. This is not access or WAF request
logging, nor proof that telemetry is arriving. See
[Front Door monitoring](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-diagnostics)
and the [diagnostic setting contract](https://learn.microsoft.com/en-us/azure/templates/microsoft.insights/2021-05-01-preview/diagnosticsettings).

## State and delivery

The root uses `ski-school-global.tfstate` in an environment-isolated backend;
backend settings are supplied separately from `.tfvars`. Outputs include the
resource-group ID and Azure-generated `default_hostnames` keyed by profile and
endpoint. Compare these hostnames with the separately configured
`bridge_allowed_origins` before serving edge-hosted message requests. Replacing
an endpoint can interrupt traffic or invalidate that allowlist; a global-only
change does not automatically deploy the frontend.

The [Front Door CI and CD workflows](delivery.md#front-door-ci-and-opt-in-cd) check
the global root. The CD deployment job is opt-in via
`ENABLE_GLOBAL_FRONT_DOOR_DEPLOYMENT`; neither a workflow configuration nor a
Terraform output proves a deployment succeeded. See [delivery](delivery.md)
for state, prerequisites and approval requirements.

The Front Door modules specify `Microsoft.Cdn` API `2026-10-01` and the root
locks [AzAPI 2.14.0](../infra/global/.terraform.lock.hcl). The
[versioned AzAPI resource reference](https://registry.terraform.io/providers/Azure/azapi/2.14.0/docs/resources/resource)
describes provider behavior, but a matching official `2026-10-01` Front Door
resource contract could not be verified in the accessible Microsoft Learn
references. Confirm that contract and provider compatibility before relying
on these settings; service guidance above is not a substitute for that API
contract.
