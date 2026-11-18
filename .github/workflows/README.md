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
isolated state account. Migrate the existing logging state to that key before
deployment; the logging plan and deploy steps verify the root's existing
resource addresses and stop when the selected state is empty or incomplete.

## Separate workload identities

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
