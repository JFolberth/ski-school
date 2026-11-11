# Non-secret development target values. Supply the published image digest
# separately when planning a deployment.
acr_resource_id            = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-registry-dev-ncus/providers/Microsoft.ContainerRegistry/registries/crskiregistrydevncus"
environment                = "dev"
location                   = "northcentralus"
log_analytics_workspace_id = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-logs-dev-ncus/providers/Microsoft.OperationalInsights/workspaces/log-ski-logs-dev-ncus"
resource_group_name        = "rg-ski-frontend-dev-ncus"
subscription_id            = "9a7e9255-7824-4c0d-a414-366f436f61dd"
tags = {
  workload = "ski-school-frontend"
}
