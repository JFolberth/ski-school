# Non-secret development target values. Update image digests and deployment
# timestamp together when publishing a new revision.
acr_resource_id         = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-registry-dev-ncus/providers/Microsoft.ContainerRegistry/registries/crskiregistrydevncus"
bridge_allowed_origins  = ["https://afd-ski-global-dev-fjhccsfqckbmenfe.b02.azurefd.net"]
bridge_image_digest     = "sha256:0f74c0f6798523438a786e9b7b510390396586bd3fc8fd67434c41dc6f4802e7"
bridge_image_repository = "ski-school/bridge"
container_image_digest  = "sha256:66d54c1ffb313788ab914a947b2dff021e744f971f274df601cc831045c7b605"
deployment_timestamp    = "2026-11-20T17:41:07Z"
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
