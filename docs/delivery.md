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
checks validate modules and prepare a plan; deployment verifies the source and
module artifacts, makes a fresh plan, and applies when needed. Backend and
frontend add verified image publication. Foundry packages and deploys toolbox
source separately after its infrastructure deployment.

| Scope | Pull-request checks | Main-branch release |
| --- | --- | --- |
| Logging | [logging CI](../.github/workflows/logging-ci.yml) | [logging CD](../.github/workflows/logging-cd.yml) |
| Registry | [registry CI](../.github/workflows/registry-ci.yml) | [registry CD](../.github/workflows/registry-cd.yml) |
| Foundry | [Foundry CI](../.github/workflows/foundry-ci.yml) | [Foundry CD](../.github/workflows/foundry-cd.yml) |
| Gateway | [gateway CI](../.github/workflows/gateway-ci.yml) | [gateway CD](../.github/workflows/gateway-cd.yml) |
| Backend | [backend CI](../.github/workflows/backend-ci.yml) | [backend CD](../.github/workflows/backend-cd.yml) |
| Frontend | [frontend CI](../.github/workflows/frontend-ci.yml) | [frontend CD](../.github/workflows/frontend-cd.yml) |

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

References: [Terraform Azure Blob backend](https://developer.hashicorp.com/terraform/language/backend/azurerm),
[GitHub reusable workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows),
and [GitHub OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure).
