# GitHub Actions delivery and Azure access

Start with the [delivery guide](../../docs/delivery.md) for the documentation
index, state boundaries and approval requirements. Role inventories and
migration notes below are historical requirements or reported status, not
confirmation of current Azure access or state.

## Delivery architecture

The CI/CD entry points are split by deployable root and source path. Pull
requests run the matching path-filtered check workflow; pushes to `main` run
the matching CD workflow after checks. The logging, registry, Foundry, gateway
and global CI workflows share
[`reusable-terraform-checks.yml`](./reusable-terraform-checks.yml), which
composes shared-module publication with root validation and planning. Their CD
workflows pass the verified root and shared-module artifacts to
[`reusable-terraform-deploy.yml`](./reusable-terraform-deploy.yml), which
validates those artifacts and makes a fresh plan before applying.

Backend and Frontend have additional release stages because their Terraform
roots consume image digests. Their CD workflows publish the images tested by
CI and pass the resulting registry digests to the reusable deployment. Backend
then checks and promotes the exact hosted-agent version; Frontend deploys the
tested frontend and bridge images. Foundry CI/CD packages a toolbox source
artifact separately; Foundry CD deploys that artifact only after Terraform
succeeds. These workflows are configured for `dev`; the reusable Terraform jobs
accept an environment matrix, but no additional environment target is currently
configured here.

The CI/CD workflows are path-filtered. A workflow with no matching changed
paths may not run, so the presence of its file alone does not make it an
appropriate unconditional required check for all pull requests. The checked-in
workflow files do not establish which repository or organization branch rules
are active.

For resource ownership, root dependencies, regional limits, and the
infrastructure lifecycle rationale, see the
[infrastructure architecture overview](../../docs/architecture.md).

Track Azure access for the GitHub OIDC deployment identity here as requirements
are confirmed. Assign Azure RBAC roles to the app registration's service principal
(enterprise application), not as Microsoft Graph API permissions.

The initial inventory below records the roles reported as configured; it is not
a verified minimum permission set. Keep assignments Terraform-managed and use the
narrowest supported scope. Documentation changes do not grant or remove access.

## OIDC deployment identity

| Azure role | Purpose and scope | Requirement / status |
| --- | --- | --- |
| Contributor | Manage deployment resources at the target resource-group scopes, with access to referenced resources as needed. Creating resource groups also requires permission at subscription scope. Does not grant role-assignment management or blob data access. | Historically reported configured; verify the target permissions for the workflows being run. |
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
Verify that the target state is present and any separately approved migration
has completed before triggering Foundry CD; the workflows do not perform a
state migration.

The Foundry plan guard permits only the declared project image-pull role
assignment outside the Foundry resource group, on the dev registry
`crskiregistrydevncus`. The OIDC identity needs registry read access and
role-assignment management at that registry scope to manage that grant.

Backend, Foundry, gateway, logging, registry, and global CD skip Terraform apply when
the fresh, verified deployment plan has no changes. The job summary records
the skip. Output-only changes still apply, and a failed plan or target check
still fails deployment.

Front Door CD has an additional caller-level opt-in and does not automatically
deploy the frontend allowlist. Its filters, artifact chain, identity
requirements, skip conditions and `ENABLE_GLOBAL_FRONT_DOOR_DEPLOYMENT` gate
are documented in [Front Door delivery](../../docs/delivery.md#front-door-ci-and-opt-in-cd).

## Separate workload identities

### Dev backend delivery

`backend-ci.yml` builds and verifies the `linux/amd64` image for every
matching PR. Same-repository human PRs also run a live Terraform plan: the plan
uses the latest active Foundry version's ACR digest, not a PR image or a stale
state output. Fork and bot PRs do not get Azure credentials. On pushes to
`main`, `backend-cd.yml` repeats the same checks and verifies the tested image
artifact from that run, publishes it to `ski-backend`,
then freshly plans the verified Terraform source using the exact registry
digest and applies it if there are changes. Before Terraform, Backend CD records
the current pinned serving version. Automatic-latest routing fails this preflight;
pin a concrete serving version before running CD so an unchecked candidate cannot
receive default traffic. After Terraform completes, `backend-cd.yml` directly
runs `wait_for_agent.py` to check readiness and invoke a session pinned to the
captured candidate, even when apply is skipped. Only after those checks pass
does the backend-specific routing action promote that exact version at 100%.
It checks the previous selector for concurrent changes and verifies the new
selector without changing protocol or authorization settings. Failed checks
leave the baseline selected; a failed routing write requires inspecting the
live selector before retrying, not an automatic rollback. No Azure Container
App is changed. The reusable Terraform deployment workflow does not execute
backend readiness checks or promotion.

The routing action accepts the target tenant, subscription, project endpoint,
and agent name from its caller, so it can also be reused by other environments.
Branch/event restrictions and GitHub Environment approvals belong to the calling
workflow; Backend CD currently enables only DEV.

Dev explicitly references the existing `Microsoft.DefaultV2` guardrail in
`infra/backend/dev.tfvars`.

Before enabling delivery, verify actual state and permissions. The migration
item below is historical and applies only if the old-key state still needs to
be migrated; it is not evidence that a migration is needed or completed:

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
- [Reusable workflows](https://docs.github.com/actions/how-tos/reuse-automations/reuse-workflows)
- [GitHub Actions artifacts](https://docs.github.com/actions/using-workflows/storing-workflow-data-as-artifacts)
- [GitHub Actions environments](https://docs.github.com/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [GitHub Actions OIDC with Azure](https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
