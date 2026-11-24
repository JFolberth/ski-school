# Terraform Azure diagrams

These eight interactive HTML diagrams are rendered locally with
[TerraVision 0.56.4](https://github.com/patrickchugh/terravision/releases/tag/v0.56.4).
They are **manually mapped logical views of checked-in Terraform and dev
inputs**, not automatically extracted Terraform plans, Azure discovery, or
evidence of a successful deployment. No Terraform initialization, state access,
plan, apply, Azure calls or AI annotation service is used to render them.

## Diagrams and evidence

**Start with [the interactive overview](architecture.html).** Each HTML file
contains its diagram, icons, scripts and metadata, works offline without a
server, and supports pan/zoom, search and clicking nodes. The node inspector
contains authored logical labels and relationships, **not plan-derived or live
Azure properties**. Download/open the HTML locally; GitHub's source-file viewer
does not execute it. In the overview, hover or focus a connection or legend
item to highlight that type of flow; select a legend item to keep it highlighted.
Hover a resource group or focus its boundary for its purpose; hover or focus a
numbered request badge for a detailed explanation. Animated direction cues
respect the operating system's reduced-motion setting.
The viewer includes AGPL-3.0-licensed TerraVision code and D3.js; see the
[third-party notices](THIRD_PARTY_NOTICES.md).

Each deployment page also embeds an SVG preview linked to its HTML. A "piece"
here means a deployment root; reusable modules appear within their callers,
not as fictitious resource groups or independent states.

| Diagram | Configuration establishing the view |
| --- | --- |
| [Overall flow](architecture.html) | All seven roots below; [nginx](../../src/frontend/nginx.conf), [bridge](../../src/frontend/bridge/main.py) and [MAF runtime](../../src/backend/main.py) establish the application hops. |
| [Logging](logging.html) | [Root](../../infra/logging/main.tf), [dev placement](../../infra/logging/dev.tfvars), [Log Analytics](../../infra/modules/log-analytics/main.tf), [Monitor workspace](../../infra/modules/monitor-workspace/main.tf), and consumer diagnostic/telemetry configuration below. |
| [Registry](registry.html) | [Root](../../infra/registry/main.tf), [dev inputs](../../infra/registry/dev.tfvars), [registry module](../../infra/modules/container-registry/main.tf), project pull connection/grant in Foundry, and image-pull identity/grant in the [ACA module](../../infra/modules/aca/main.tf). |
| [Foundry](foundry.html) | [Root](../../infra/foundry/main.tf), [connections](../../infra/foundry/locals.tf), [dev inputs](../../infra/foundry/dev.tfvars), [toolbox source](../../infra/foundry/toolboxes/ski-tools/azure.yaml), and separate [toolbox publication](../../.github/workflows/foundry-cd.yml). |
| [Gateway](gateway.html) | [Root](../../infra/gateway/main.tf), [dev inputs](../../infra/gateway/dev.tfvars), [routing locals](../../infra/gateway/locals.tf), [Application Insights](../../infra/modules/application-insights/main.tf), and [OTLP exporter](../../infra/modules/ai-gateway-telemetry-exporter/main.tf). |
| [Backend](backend.html) | [Root](../../infra/backend/main.tf), [agent definition](../../infra/modules/hosted-agent/main.tf), and [release orchestration](../../.github/workflows/backend-cd.yml). |
| [Frontend](frontend.html) | [Root](../../infra/frontend/main.tf), [dev inputs](../../infra/frontend/dev.tfvars), [ACA resources and grants](../../infra/modules/aca/main.tf), and application sources linked above. |
| [Global Front Door](frontdoor.html) | [Root](../../infra/frontdoor/main.tf), [dev inputs](../../infra/frontdoor/dev.tfvars), [frontend lookup](../../infra/frontdoor/data.tf), [routing locals](../../infra/frontdoor/locals.tf), and [Front Door modules](../../infra/modules/). |

## Reading the boundaries and arrows

- **Blue dotted boxes with the resource-group icon** are logical Azure resource
  group boundaries. `OWNED` identifies the root being described; external boxes
  retain their actual owner's placement. The overview has six Terraform-owned
  groups, not seven.
- **Gray dashed boxes** are logical parents or state/compute subdivisions, not
  additional resource groups. Backend owns its agent and runtime grants in
  separate state inside the existing Foundry project. The frontend detail
  draws nginx and the bridge as two containers in **one** Container App, not
  two Container Apps.
- **Labeled arrows and numbered badges** describe requests, image pulls,
  configuration associations, diagnostics, or release handoffs, as their text
  states. A dashed arrow from an identity denotes permission, not network
  traffic. Configuration chains inside Front Door are not extra network hops.
  Cross-root arrows do not mean Terraform remote-state reads or automatic
  orchestration: IDs and other values are supplied explicitly.
- Locations follow the selected dev inputs. The logging RG's metadata is in
  North Central US while its workspaces are in East US 2. Global Front Door is
  not a regional replica; only one frontend origin is configured. No regional
  failover, private network boundary, or edge-only ingress is implied.
- Logging destinations and Application Insights associations show configured
  paths, not verified instrumentation or ingestion. The overview and Logging
  view abstract the Gateway OTLP ingestion pipeline; the Gateway detail shows
  the supplied DCR/endpoints in a **service-managed external RG**, not another
  Terraform-owned group. Monitor workspace service-managed children are omitted.
  Foundry native OTLP is disabled in dev; Gateway native OTLP and **payload
  capture are enabled**. The frontend Application Insights association alone
  does not establish application telemetry.
- Icons are presentation symbols, **not Terraform provider declarations or
  exact resource-type inventories**. TerraVision's `azurerm_*` graph vocabulary
  selects Azure icons; the infrastructure still uses AzAPI. The AI Gateway
  uses the supplied gateway icon, while API Management icons represent gateway
  alias and MCP configuration, not a separately provisioned APIM service.
  Foundry icons also identify the hosted agent and toolbox. The external DCR/endpoints use the
  generic Azure Monitor icon, not an assertion of another workspace.
  The labels and linked Terraform, not icon equivalence, establish ownership.

For platform context, see [Azure resource groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal),
[Azure Monitor workspace managed resources](https://learn.microsoft.com/en-us/azure/azure-monitor/metrics/azure-monitor-workspace-manage),
and [AI Gateway documentation](https://ai.gateway.azure.com/docs).
These views describe checked-in configuration, not independently verified
regional support, API availability, or live resources.

## Regeneration

Keep Graphviz (`dot`, `neato`, and `gvpr`) on `PATH`. With `uv` and Python 3.12
available, run from the repository root:

```bash
uv run --no-project --python 3.12 --with terravision==0.56.4 \
  python docs/diagrams/render.py

# Refresh the embedded documentation previews too.
uv run --no-project --python 3.12 --with terravision==0.56.4 \
  python docs/diagrams/render.py --format svg

# Refresh the main README's static preview from the overview SVG (requires librsvg).
rsvg-convert --width 2400 -o docs/diagrams/architecture.png docs/diagrams/architecture.svg

# Render just one HTML view, or create PNGs outside the tracked directory.
uv run --no-project --python 3.12 --with terravision==0.56.4 \
  python docs/diagrams/render.py logging
uv run --no-project --python 3.12 --with terravision==0.56.4 \
  python docs/diagrams/render.py architecture --format png --output-dir /tmp/ski-diagrams
```

The renderer reads standard [TerraVision graphs](https://github.com/patrickchugh/terravision/blob/v0.56.4/docs/graph-format.md)
from `*.tvg.json` and annotations from matching `*.annotations.json` files.
JSON annotations use TerraVision's `title`, `update`, `connect`, and `flows`
sections. Both sets of inputs are hand-maintained: review the cited root,
modules and explicit inputs when infrastructure changes, then regenerate.
Do not copy state, plans, credentials, tenant/subscription/principal IDs,
connection strings, or actual telemetry endpoint URLs into these files.

`render.py` calls this pinned version's drawing/annotation modules directly.
It changes only the in-process Azure drawing policy to keep shared-service
arrows visible: TerraVision normally suppresses connections involving Log
Analytics and Container Registry, which would hide required flows here. The
ordinary CLI can render each graph with `--annotate`, but without that policy
override it is **not equivalent** to the checked-in rendering. Revisit these
module interfaces and the policy when upgrading TerraVision.

The renderer also embeds remaining local image references from TerraVision's
bundled icons and the flow badges generated for that diagram. This works around
this release's incomplete HTML/badge embedding; unrecognized local image paths
are rejected rather than copied. Rendering fails if a graph node or flow arrow
is missing from the result.

HTML scripts and SVG icons are embedded, so no CDN, local icon paths or running
server are needed to view them. Generated timestamps and graph IDs can change on regeneration.
The images here were rendered from the official `v0.56.4` source checkout;
its footer reports `dev` when package installation metadata is absent.
