# Backend hosted-agent deployment scope

[`infra/backend`](../infra/backend/) manages the hosted-agent release and its
runtime grants in an existing Foundry project. It has its own Terraform state
and deployment lifecycle, but **does not create a resource group**; the agent
belongs to the Foundry project. Its only Foundry resource operation is an
AzAPI data-plane call to manage the hosted agent; it does not manage or change
the Foundry account or project. Those are owned by the
[Foundry root](foundry.md). This separate state and release lifecycle lets the
agent be updated independently of its account and project foundation without
claiming the resources or dependencies are independent.

## Runtime

[`src/backend/main.py`](../src/backend/main.py) builds a Python MAF agent served
through the Foundry Responses hosting adapter. It requires the gateway model
base URL, model alias and a JSON map of gateway MCP server URLs. It validates
that model and tool endpoints use the expected HTTPS gateway origin and
workspace. The hosted default uses managed identity; Azure CLI authentication
is restricted to local use.

The agent loads application instructions and discovers configured tools through
the gateway; model inference is routed through its configured alias. Its
application-specific behavior and tool usage are separate from this deployment
architecture. Model attribution is recorded only when an unambiguous
served-model header is observed.

The backend root assigns the agent identity access to the configured gateway
model alias, individual tool servers, and the Foundry Application Insights
component through role-assignment resources. These grants do not make the
backend root an owner of the Foundry account or project. The project identity
that pulls the image is separately managed by Foundry. Host-side
sensitive-message capture is disabled in code; gateway payload capture is a
separate setting described in [gateway](gateway.md).

## Release and handoffs

The root takes the Foundry project endpoint, registry login server and immutable
image digest, gateway URL, alias and tool-server IDs, and telemetry ID. Its
outputs include agent name, principal, candidate version, image URI and project
endpoint; it does not output the agent ARM ID used by the frontend root.
The hosted-agent definition also configures CPU, memory, session idle timeout
and a responsible-AI policy. Terraform guards against destroying the logical
agent and checks the existing agent identity remains stable during updates.

Backend CD builds and verifies the image, publishes it, records the current
serving baseline, and deploys the exact digest. It checks readiness and invokes
the exact candidate before promoting that version. A failed check does not
intentionally promote the candidate; a failed routing write requires inspecting
the live selector before retrying. The detailed sequence and state-migration
prerequisites are in [workflow guidance](../.github/workflows/README.md#dev-backend-delivery).
Backend state uses `ski-school-backend.tfstate`; publication and promotion
are separate from the reusable Terraform deployment.

References: [Foundry hosted-agent management](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/manage-hosted-agent)
and [hosted-agent permissions](https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/hosted-agent-permissions).
