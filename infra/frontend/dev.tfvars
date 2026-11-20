# Non-secret development target values. Update image digests and deployment
# timestamp together when publishing a new revision.
acr_resource_id         = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-registry-dev-ncus/providers/Microsoft.ContainerRegistry/registries/crskiregistrydevncus"
bridge_image_digest     = "sha256:613f1170f61a5668c790e29ab4ed7fa85048ec030d1c6c7aabc5d1ee75cf99dd"
bridge_image_repository = "ski-school/bridge"
container_image_digest  = "sha256:c878e5f1d0d6ee5020b937c7afb9a8dcfb0e240f0f0c296c42ba57a9b435f934"
deployment_timestamp    = "2026-11-17T05:01:31Z"
diagnostic_disabled_categories = [
  "ContainerAppHTTPLogs",
  "AppEnvSpringAppConsoleLogs",
  "AppEnvSessionConsoleLogs",
  "AppEnvSessionPoolEventLogs",
  "AppEnvSessionLifeCycleLogs",
]
environment                = "dev"
foundry_agent_resource_id  = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-foundry-dev-ncus/providers/Microsoft.CognitiveServices/accounts/aif-ski-foundry-dev-ncus/projects/proj-ski-foundry-dev-ncus/agents/ski-backend-dev"
location                   = "northcentralus"
log_analytics_workspace_id = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-logs-dev-ncus/providers/Microsoft.OperationalInsights/workspaces/log-ski-logs-dev-eus2"
resource_group_name        = "rg-ski-frontend-dev-ncus"
subscription_id            = "9a7e9255-7824-4c0d-a414-366f436f61dd"
tags = {
  workload = "ski-school-frontend"
}
