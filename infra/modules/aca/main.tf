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
        # Restrict the ABAC repository-reader grant to this one image repository.
        condition        = "@Resource[Microsoft.ContainerRegistry/registries/repositories:RepositoryName] StringEqualsIgnoreCase '${var.container_image_repository}'"
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
  type      = "Microsoft.App/containerApps@2025-07-01"
  name      = "${local.base_name}-ui"
  parent_id = var.resource_group_id
  location  = var.location
  tags      = local.tags

  response_export_values = [
    "properties.configuration.ingress.fqdn",
  ]

  body = {
    identity = {
      type = "UserAssigned"
      userAssignedIdentities = {
        (azapi_resource.image_pull_identity.id) = {}
      }
    }
    properties = {
      configuration = {
        activeRevisionsMode = "Single"
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
                type                = "Startup"
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
