# Workflow Azure access

Track Azure access for the GitHub OIDC deployment identity here as requirements
are confirmed. Assign Azure RBAC roles to the app registration's service principal
(enterprise application), not as Microsoft Graph API permissions.

The initial inventory below records the roles reported as configured; it is not
a verified minimum permission set. Keep assignments Terraform-managed and use the
narrowest supported scope. Documentation changes do not grant or remove access.

## OIDC deployment identity

| Azure role | Purpose and scope | Requirement / status |
| --- | --- | --- |
| Contributor | Manage deployment resources at the target resource-group scopes, with access to referenced resources as needed. Creating resource groups also requires permission at subscription scope. Does not grant role-assignment management or blob data access. | Reported configured. Deployment permission for the gateway and logging CD workflows; frontend CI currently only validates and plans. |
| User Access Administrator | Create and manage Terraform-owned role assignments at their target scopes, including the registry and Foundry agent. Contributor alone cannot create these assignments. | Reported configured. Needed for applying role assignments, not for granting runtime access to the deployment identity itself. |
| AcrPush | Push and pull images using legacy RBAC registry permissions. Scope to the registry. ABAC-enabled registries instead use Container Registry Repository Writer, optionally restricted to specific repositories. | Reported configured. Required when publishing images to ACR, but not used by the current CI image builds, which upload GitHub artifacts instead. |
| Foundry User | Build and test agents through Foundry project data-plane APIs. Scope to the relevant project, with parent-resource read access where required. | Reported configured. Not required by the current frontend Terraform plan or local image builds. Does not by itself authorize agent publication. |
| Storage Blob Data Contributor | Read and update Terraform state and acquire blob leases for locking. Scope to the environment's state container (`tfstate` for the default dev configuration). | Required for the current authenticated backend operations; assignment not yet confirmed. Contributor and User Access Administrator do not substitute for blob data access. |

`reusable-terraform-plan.yml` selects the GitHub Environment and uses its
`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` variables.
The Azure federated credential must trust that GitHub Environment (`dev`
initially), and the plan job needs GitHub `id-token: write`. Federation permits
sign-in; Azure RBAC separately determines resource access.

The logging CI/CD workflow uses the same `dev` GitHub Environment and OIDC
identity as the existing Terraform workflows. Its remote state uses the
environment-neutral `ski-school-logging.tfstate` key in each environment's
isolated state account. The workflows use the existing remote backend and do
not fall back to local state.

Foundry CI/CD uses the same `dev` GitHub Environment and OIDC identity. CI
plans PR changes under `infra/foundry` or `infra/modules`; CD runs on matching
pushes to `main` and deploys only after the reusable checks succeed. Both
target `rg-ski-foundry-dev-ncus` using `infra/foundry/dev.tfvars` and require
the existing `saterraformstatedevswece/tfstate/ski-school-foundry.tfstate` blob.
Complete and verify the separate state migration before merging changes that
trigger Foundry CD; the workflows neither migrate nor initialize empty state.

The Foundry plan guard permits only the declared project image-pull role
assignment outside the Foundry resource group, on the dev registry
`crskiregistrydevncus`. The OIDC identity needs registry read access and
role-assignment management at that registry scope to manage that grant.

Backend, Foundry, gateway, logging, and registry CD skip Terraform apply when
the fresh, verified deployment plan has no changes. The job summary records
the skip. Output-only changes still apply, and a failed plan or target check
still fails deployment.

## Separate workload identities

### Dev backend delivery

`backend-ci.yml` builds and verifies the `linux/amd64` image for every
matching PR. Same-repository human PRs also run a live Terraform plan: the plan
uses the latest active Foundry version's ACR digest, not a PR image or a stale
state output. Fork and bot PRs do not get Azure credentials. On pushes to
`main`, `backend-cd.yml` repeats the same checks and verifies the tested image
artifact from that run, publishes it to `ski-backend`,
then freshly plans the verified Terraform source using the exact registry
digest and applies it if there are changes. It checks readiness and invokes a
session pinned to the version recorded in Terraform state, even when apply is
skipped. No Azure Container App or routing rules are changed. Foundry can
route dev traffic to the latest version before the smoke check finishes when
the endpoint uses its default selector.

Dev explicitly references the existing `Microsoft.DefaultV2` guardrail in
`infra/backend/dev.tfvars`. If an AzAPI write fails with an Azure HTTP
response, the job summary reports the status and any recognized error code,
without publishing the request URL or response body.

Before enabling delivery:

1. Migrate `backend-dev.tfstate` to `ski-school-backend.tfstate` in the dev
   `saterraformstatedevswece/tfstate` container. Pause all old-key writers,
   back up state securely, verify the same lineage and resource inventory at
   the destination, and retire the old key from all clients without deleting
   its blob. After migration approval, use a fresh Terraform data directory to
   initialize `infra/backend` against the old key, then rerun `terraform init
   -migrate-state` using `infra/backend/dev.backend.hcl.example` for the
   destination settings. Verify the destination before merging. The workflow
   refuses a missing destination.
2. Plan and release use the existing `dev` GitHub Environment and its
   `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` variables.
   The public gateway URL is configured in `infra/backend/dev.tfvars`. Verify that the
   shared OIDC identity can lease the state blob, read and manage the
   Foundry agent, invoke it, push to ACR, and manage the role assignments
   scoped to the gateway alias and App Insights component.
3. Keep Azure access limited to trusted PRs. The shared OIDC identity has the
   same Azure permissions in plan and release jobs, but only Backend CD
   publishes and deploys after checks pass on a matching push to `main`.
   Review the dev routing and release impact before merging.

The state move does not resolve existing Foundry drift. If state and Foundry
report different versions, review the first refreshed plan and keep the
previous image/version available for rollback. Dev plans read the existing
agent identity before planning role assignments, and an update fails if Foundry
returns a different identity. See
[Foundry hosted-agent permissions](https://learn.microsoft.com/azure/foundry/agents/concepts/hosted-agent-permissions)
and [hosted-agent routing](https://learn.microsoft.com/azure/foundry/agents/how-to/manage-hosted-agent).

### Frontend workload identities

Do not confuse roles held by the OIDC deployment identity with roles it assigns
to the deployed application. `infra/modules/aca/main.tf` currently manages:

| Identity | Role | Scope |
| --- | --- | --- |
| Dedicated image-pull managed identity | AcrPull for legacy registries, or Container Registry Repository Reader for ABAC-enabled registries | Registry; ABAC assignments restrict access to the configured frontend and bridge repositories. |
| Container App system-assigned runtime identity | Foundry Agent Consumer | The configured Foundry agent, for agent endpoint invocation only. |

Granting AcrPush or Foundry User to the OIDC identity does not grant access
to either workload identity; their separate role assignments are still required.

## References

- [Terraform Azure backend authentication and required roles](https://developer.hashicorp.com/terraform/language/backend/azurerm#storage-account-required-role-assignments)
- [Contributor and User Access Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/privileged)
- [ACR roles and registry permission modes](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-rbac-built-in-roles-overview)
- [Foundry roles, scopes, and agent consumers](https://learn.microsoft.com/en-us/azure/foundry/concepts/rbac-foundry)
