# Non-secret values only. Replace every REPLACE_* value with the reviewed
# development target before using this file; variable validation rejects them.
acr_resource_id            = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-registry-dev-ncus/providers/Microsoft.ContainerRegistry/registries/crskiregistrydevncus"
container_image_digest     = "REPLACE_WITH_SHA256_DIGEST"
container_image_repository = "ski-school/frontend"
environment                = "dev"
location                   = "northcentralus"
log_analytics_workspace_id = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-logs-dev-ncus/providers/Microsoft.OperationalInsights/workspaces/log-ski-logs-dev-ncus"
name_prefix                = "ski-frontend"
resource_group_name        = "rg-ski-frontend-dev-ncus"
subscription_id            = "9a7e9255-7824-4c0d-a414-366f436f61dd"
tags = {
  workload = "ski-school-frontend"
}
