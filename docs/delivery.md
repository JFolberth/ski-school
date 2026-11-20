# Delivery and operations

## State and deployment prerequisites

Each root has an independent remote state key:

| Root | Key |
| --- | --- |
| Logging | `ski-school-logging.tfstate` |
| Registry | `ski-school-registry.tfstate` |
| Foundry | `ski-school-foundry.tfstate` |
| Gateway | `ski-school-gateway.tfstate` |
| Backend | `ski-school-backend.tfstate` |
| Frontend | `ski-school-frontend.tfstate` |
| Global Front Door | `ski-school-global.tfstate` |

The same root key is used in each environment's separate storage account.
Backend settings are supplied at initialization separately from explicitly
selected root `.tfvars`; the latter do not configure the backend. Root
`dev.tfvars` files are checked-in **non-secret** inputs. Never commit secrets,
backend credentials, Terraform state, plans, or `.terraform/`; restrict access
to encrypted state and use identity-based access and locking.

State infrastructure bootstrap and ownership are not established by these
roots. Before bootstrap or migration, agree how its infrastructure is managed,
how initial state is secured and how it migrates to locked remote state, and
obtain explicit approval. Do not silently use local state. Historical migration
notes are not evidence that a migration has completed; inspect the target
before taking action.

Before any deployment, cloud write, backend migration or state mutation,
identify tenant, subscription, resource group and environment, review the
plan, cost and material risks, and obtain explicit approval for that target and
operation. Stop for unexpected targets, replacements or destructive changes.
Do not force-unlock, remove state entries or delete cloud resources as a
shortcut. See [historical prerequisites and recovery](../infra/README.md)
and each scope's inputs and dependencies.

## GitHub Actions

Root-specific CI and CD entry points are path-filtered. The reusable Terraform
checks package shared modules and validate the root and its referenced modules
before planning; deployment verifies the source and module artifacts, makes a
fresh plan, and applies when needed. Backend and frontend add verified image
publication. Foundry packages and deploys toolbox
source separately after its infrastructure deployment.

| Scope | Pull-request checks | Main-branch release |
| --- | --- | --- |
| Logging | [logging CI](../.github/workflows/logging-ci.yml) | [logging CD](../.github/workflows/logging-cd.yml) |
| Registry | [registry CI](../.github/workflows/registry-ci.yml) | [registry CD](../.github/workflows/registry-cd.yml) |
| Foundry | [Foundry CI](../.github/workflows/foundry-ci.yml) | [Foundry CD](../.github/workflows/foundry-cd.yml) |
| Gateway | [gateway CI](../.github/workflows/gateway-ci.yml) | [gateway CD](../.github/workflows/gateway-cd.yml) |
| Backend | [backend CI](../.github/workflows/backend-ci.yml) | [backend CD](../.github/workflows/backend-cd.yml) |
| Frontend | [frontend CI](../.github/workflows/frontend-ci.yml) | [frontend CD](../.github/workflows/frontend-cd.yml) |
| Global Front Door | [Front Door CI](../.github/workflows/frontdoor-ci.yml) | [Front Door CD](../.github/workflows/frontdoor-cd.yml) |

Path filters mean a workflow may not run on an unrelated change; skipped checks
are not passing evidence. Checked-in callers select `dev`. The workflow files
do not establish live GitHub Environment approval rules, Azure permissions,
deployment health, or that a run succeeded.

GitHub OIDC authenticates a deployment identity through the selected GitHub
Environment; Azure RBAC and state blob permissions are separate requirements.
Image publication, project image pull, agent runtime, and frontend runtime use
distinct identities and scopes. See [workflow identity and release details](../.github/workflows/README.md)
for the role inventory, trust conditions, state migration caveats and backend
promotion sequence.

### Front Door CI and opt-in CD

Front Door CI runs on PRs targeting `main`; Front Door CD runs on pushes to
`main`. Both filter on `infra/global/**`, shared modules, the two Front Door workflows,
reusable Terraform workflows and the listed Terraform composite actions. A
frontend-only change does not trigger global delivery, and a global-only
change does not trigger frontend delivery. Shared-module changes can trigger
both. See the [CI](../.github/workflows/frontdoor-ci.yml) and
[CD](../.github/workflows/frontdoor-cd.yml) filters; path-filtered skips are not
evidence of success.

Both callers pass the global root, key, artifact prefix and a dev-only target
manifest with the expected global resource group to
[`reusable-terraform-checks`](../.github/workflows/reusable-terraform-checks.yml).
It invokes [module publication](../.github/workflows/reusable-terraform-modules.yml),
the [plan workflow](../.github/workflows/reusable-terraform-plan.yml), and
root [source packaging](../.github/actions/terraform-source-artifact/action.yml).
The plan validates the target matrix; for main pushes and same-repository
human PRs it checks recursive formatting, initializes without the backend and
validates, then authenticates and plans with the selected `dev.tfvars` and
remote backend. Fork and bot PRs skip the plan and root source publication;
they do not get a live Terraform plan from this workflow. The plan reads the
existing frontend ingress and therefore requires Azure read access even when
the global state is new. The global caller does **not** require an existing
state blob; it never migrates state automatically. Caller concurrency does
not cancel an in-progress run; plan and deploy also share a concurrency group
derived from the repository, backend coordinates and state key.

The CD deploy job requires successful checks **and**
`ENABLE_GLOBAL_FRONT_DOOR_DEPLOYMENT == 'true'` on a main push; otherwise it
is skipped. The condition is evaluated on the caller job, before the called
deployment job selects an environment, so configure this opt-in as a
repository or organization variable available to the caller, not solely as a
`dev` environment variable. The setting's actual value is not in this
repository. This gate does not stop the preceding checks and authenticated
plan, and it does not gate the separate frontend workflow.

The [deployment callee](../.github/workflows/reusable-terraform-deploy.yml)
receives source and module artifact IDs, SHA-256 digests and the validated
manifest from checks. It verifies run, revision, archive hashes and manifests,
validates the extracted source, signs in, and makes a fresh private plan.
The [plan action](../.github/actions/terraform-plan-artifact/action.yml)
checks tenant, subscription, environment, resource-group scope and blocks
deletes or replacements; it applies the saved fresh plan only on main when
there are changes, otherwise it skips apply. Plans and diagnostics are not
published as artifacts. This path provisions infrastructure only: it does not
build or push frontend images or publish agent versions. Frontend CD has
separate image publication and Terraform deployment stages.

Workflow permissions default to `contents: read`; plan jobs additionally use
`id-token: write`, and deployment also uses `actions: read` for artifacts. The
plan and deploy jobs select the `dev` GitHub Environment and read the Azure
client, tenant and subscription configuration variables. OIDC federation and
Azure RBAC must permit state blob access, frontend read and the relevant global
resource operations; creating the resource group requires appropriate
subscription scope. Neither authentication nor environment approvals,
protections or actual permissions can be verified from these files. References:
[workflow filters and permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax),
[environment rules](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments),
[variables context](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#vars-context),
[Azure OIDC](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-azure),
[checkout v7](https://github.com/actions/checkout/tree/v7),
[upload-artifact v7](https://github.com/actions/upload-artifact/tree/v7),
[setup-terraform v4](https://github.com/hashicorp/setup-terraform/tree/v4),
and [Azure login v3](https://github.com/Azure/login/tree/v3).

References: [Terraform Azure Blob backend](https://developer.hashicorp.com/terraform/language/backend/azurerm),
[GitHub reusable workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows),
and [GitHub OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure).
