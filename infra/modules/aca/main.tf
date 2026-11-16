locals {
  base_name = "${var.name_prefix}-${var.environment_name}"

  acr_role_definition_guids = {
    AbacRepositoryPermissions = "b93aa761-3e63-49ed-ac28-beffa264f7ac" # Container Registry Repository Reader
    LegacyRegistryPermissions = "7f951dda-4ed3-4680-a7ca-43fe172d538d" # AcrPull
  }

  acr_role_definition_guid = lookup(local.acr_role_definition_guids, local.acr_role_assignment_mode, null)
  acr_role_assignment_mode = coalesce(
    try(data.azapi_resource.acr.output.properties.roleAssignmentMode, null),
    "Unavailable"
  )
  acr_subscription_scope = join("/", slice(split("/", var.acr_resource_id), 0, 3))

  image_repositories = sort(distinct([
    var.container_image_repository,
    var.bridge_image_repository,
  ]))

  tags = merge(var.tags, {
    environment = var.environment_name
    managed_by  = "terraform"
  })
}

data "azapi_resource" "acr" {
  type        = "Microsoft.ContainerRegistry/registries@2025-11-01"
  resource_id = var.acr_resource_id

  response_export_values = [
    "properties.loginServer",
    "properties.roleAssignmentMode",
  ]
}

resource "azapi_resource" "application_insights" {
  type      = "Microsoft.Insights/components@2020-02-02"
  name      = "${local.base_name}-appi"
  parent_id = var.resource_group_id
  location  = var.location
  tags      = local.tags

  body = {
    kind = "web"
    properties = {
      Application_Type    = "web"
      Flow_Type           = "Bluefield"
      IngestionMode       = "LogAnalytics"
      Request_Source      = "rest"
      WorkspaceResourceId = var.log_analytics_workspace_id
    }
  }
}

resource "azapi_resource" "managed_environment" {
  type      = "Microsoft.App/managedEnvironments@2025-07-01"
  name      = "${local.base_name}-aca-env"
  parent_id = var.resource_group_id
  location  = var.location
  tags      = local.tags

  body = {
    properties = {
      # Use Azure Monitor diagnostic settings rather than the shared-key
      # Log Analytics destination on the managed environment.
      appLogsConfiguration = {
        destination = "azure-monitor"
      }
    }
  }
}

resource "azapi_resource" "image_pull_identity" {
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  name      = "${local.base_name}-pull"
  parent_id = var.resource_group_id
  location  = var.location
  tags      = local.tags

  response_export_values = [
    "properties.principalId",
  ]
}

resource "azapi_resource" "acr_pull_role_assignment" {
  type = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name = uuidv5(
    "dns",
    "${var.acr_resource_id}/${azapi_resource.image_pull_identity.id}/${local.acr_role_assignment_mode}"
  )
  parent_id = var.acr_resource_id

  body = {
    properties = merge(
      {
        principalId      = azapi_resource.image_pull_identity.output.properties.principalId
        principalType    = "ServicePrincipal"
        roleDefinitionId = local.acr_role_definition_guid == null ? "" : "${local.acr_subscription_scope}/providers/Microsoft.Authorization/roleDefinitions/${local.acr_role_definition_guid}"
      },
      local.acr_role_assignment_mode == "AbacRepositoryPermissions" ? {
        # Exact repository matches only; no wildcard, catalog-listing grant,
        # or registry-wide fallback. Request attribute contract:
        # https://learn.microsoft.com/azure/container-registry/container-registry-rbac-abac-repository-permissions
        condition = "(${join(" OR ", [
          for repository in local.image_repositories :
          "@Request[Microsoft.ContainerRegistry/registries/repositories:name] StringEqualsIgnoreCase '${repository}'"
        ])})"
        conditionVersion = "2.0"
      } : {}
    )
  }

  lifecycle {
    precondition {
      condition     = local.acr_role_definition_guid != null
      error_message = "The existing ACR roleAssignmentMode is unavailable or unsupported. Verify the registry API/access mode before planning; no role will be guessed."
    }
  }
}

resource "azapi_resource" "container_app" {
  # Newest containerApps API covered by AzAPI 2.13.0's embedded schema.
  # Newer 2026-07-01 is published but not embedded; no schema exception.
  type      = "Microsoft.App/containerApps@2026-01-01"
  name      = "${local.base_name}-ui"
  parent_id = var.resource_group_id
  location  = var.location
  tags      = local.tags

  # Azure normalizes ingress transport casing; this affects all body strings.
  ignore_casing = true

  response_export_values = [
    "identity.principalId",
    "properties.configuration.ingress.fqdn",
  ]

  # Keep the entire array here, never in body or response exports. AzAPI 2.13
  # merges named arrays by name; owning it in one place avoids partial-array
  # merges. This module owns the complete ACA secret array.
  # Intentionally omit sensitive_body_version: unchanged versions
  # omit fields from PUT. Instead, supply the key on every actual update;
  # AzAPI stores only a SHA-256 change-detection hash in private state.
  # https://registry.terraform.io/providers/Azure/azapi/2.13.0/docs/guides/feature_ephemeral_resource
  sensitive_body = {
    properties = {
      configuration = {
        secrets = [
          {
            name  = "session-signing-key"
            value = var.session_signing_key
          }
        ]
      }
    }
  }

  body = {
    identity = {
      type = "SystemAssigned, UserAssigned"
      userAssignedIdentities = {
        (azapi_resource.image_pull_identity.id) = {}
      }
    }
    properties = {
      configuration = {
        activeRevisionsMode = "Single"
        identitySettings = [
          {
            # ACR pulls retain their existing pre-authorized identity, but
            # application code cannot acquire tokens for that identity.
            # Container Apps returns this resource ID segment in lowercase.
            identity  = replace(azapi_resource.image_pull_identity.id, "resourceGroups", "resourcegroups")
            lifecycle = "None"
          }
        ]
        ingress = {
          allowInsecure = false
          external      = true
          targetPort    = 8080
          traffic = [
            {
              latestRevision = true
              weight         = 100
            }
          ]
          transport = "auto"
        }
        registries = [
          {
            identity = azapi_resource.image_pull_identity.id
            server   = data.azapi_resource.acr.output.properties.loginServer
          }
        ]
      }
      environmentId = azapi_resource.managed_environment.id
      template = {
        containers = [
          {
            image = "${data.azapi_resource.acr.output.properties.loginServer}/${var.container_image_repository}@${var.container_image_digest}"
            name  = "frontend"
            env = [
              {
                name  = "IMAGE_NAME"
                value = "${var.container_image_repository}@${var.container_image_digest}"
              },
              {
                name  = "DEPLOYED_AT"
                value = var.deployment_timestamp == null ? "" : var.deployment_timestamp
              }
            ]
            probes = [
              {
                failureThreshold    = 3
                initialDelaySeconds = 10
                periodSeconds       = 10
                successThreshold    = 1
                timeoutSeconds      = 2
                type                = "Liveness"
                httpGet = {
                  path   = "/healthz"
                  port   = 8080
                  scheme = "HTTP"
                }
              },
              {
                failureThreshold    = 3
                initialDelaySeconds = 5
                periodSeconds       = 10
                successThreshold    = 1
                timeoutSeconds      = 2
                type                = "Readiness"
                httpGet = {
                  path   = "/healthz"
                  port   = 8080
                  scheme = "HTTP"
                }
              },
              {
                failureThreshold    = 30
                initialDelaySeconds = 1
                periodSeconds       = 5
                successThreshold    = 1
                timeoutSeconds      = 2
                type                = "Startup"
                httpGet = {
                  path   = "/healthz"
                  port   = 8080
                  scheme = "HTTP"
                }
              }
            ]
            resources = {
              cpu    = var.container_cpu
              memory = var.container_memory
            }
          },
          {
            image = "${data.azapi_resource.acr.output.properties.loginServer}/${var.bridge_image_repository}@${var.bridge_image_digest}"
            name  = "bridge"
            env = [
              {
                name  = "BRIDGE_AUTH_MODE"
                value = "managed_identity"
              },
              {
                name  = "FOUNDRY_AGENT_BASE_URL"
                value = trimsuffix(var.foundry_agent_base_url, "/")
              },
              {
                name      = "SESSION_SIGNING_KEY"
                secretRef = "session-signing-key"
              },
              {
                # Secret changes alone do not restart ACA revisions.
                # Change this non-secret identifier alongside every rotation.
                name  = "SESSION_SIGNING_KEY_VERSION"
                value = var.session_signing_key_version
              }
            ]
            # The image binds 127.0.0.1:8089 for Nginx in the same replica.
            # No external port mapping or platform probe to its loopback port.
            resources = {
              cpu    = var.bridge_cpu
              memory = var.bridge_memory
            }
          }
        ]
        scale = {
          maxReplicas = var.max_replicas
          minReplicas = var.min_replicas
          rules = [
            {
              http = {
                metadata = {
                  concurrentRequests = tostring(var.http_concurrent_requests)
                }
              }
              name = "http-requests"
            }
          ]
        }
      }
    }
  }

  # The ACR role assignment has no output consumed by Container Apps; this
  # narrow edge ensures the private image is not pulled before its grant exists.
  depends_on = [
    azapi_resource.acr_pull_role_assignment,
  ]

  lifecycle {
    precondition {
      condition     = var.min_replicas <= var.max_replicas
      error_message = "min_replicas must not exceed max_replicas."
    }

    precondition {
      condition     = try(tonumber(trimsuffix(var.container_memory, "Gi")) == var.container_cpu * 2, false)
      error_message = "Consumption memory must be twice the CPU allocation in Gi, for example 0.25 CPU and 0.5Gi memory."
    }

    precondition {
      # The existing environment has no workload profiles (Consumption-only).
      # https://learn.microsoft.com/azure/container-apps/containers#vcpu-and-memory-allocation-requirements
      condition     = try(tonumber(trimsuffix(var.bridge_memory, "Gi")) == var.bridge_cpu * 2, false) && var.container_cpu + var.bridge_cpu <= 2
      error_message = "Bridge Consumption memory must be twice its CPU allocation in Gi; total replica CPU across frontend and bridge must not exceed 2 cores in this Consumption-only environment."
    }

    precondition {
      condition = try(endswith(
        trimsuffix(var.foundry_agent_base_url, "/"),
        "/api/projects/${split("/", var.foundry_agent_resource_id)[10]}/agents/${split("/", var.foundry_agent_resource_id)[12]}/endpoint/protocols/openai"
      ), false)
      error_message = "The endpoint project and agent names must match the configured agent RBAC scope."
    }
  }
}

resource "azapi_resource" "foundry_agent_consumer" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("dns", "${var.foundry_agent_resource_id}/${azapi_resource.container_app.output.identity.principalId}/agent-consumer")
  parent_id = var.foundry_agent_resource_id

  # Agent-scope assignments are evaluated for this agent's endpoint only.
  # https://learn.microsoft.com/azure/foundry/concepts/rbac-foundry#agent-scope-role-assignments
  body = {
    properties = {
      principalId   = azapi_resource.container_app.output.identity.principalId
      principalType = "ServicePrincipal"
      # Foundry Agent Consumer
      roleDefinitionId = "${join("/", slice(split("/", var.foundry_agent_resource_id), 0, 3))}/providers/Microsoft.Authorization/roleDefinitions/eed3b665-ab3a-47b6-8f48-c9382fb1dad6"
    }
  }
}

resource "azapi_resource" "diagnostic_settings" {
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  name      = "${local.base_name}-aca-logs"
  parent_id = azapi_resource.managed_environment.id

  body = {
    properties = {
      logs = concat([
        {
          category = "ContainerAppConsoleLogs"
          enabled  = true
        },
        {
          category = "ContainerAppSystemLogs"
          enabled  = true
        }
        ], [for category in var.diagnostic_disabled_categories : {
          category = category
          enabled  = false
      }])
      workspaceId = var.log_analytics_workspace_id
    }
  }
}
