# Non-secret development target values. Update image digests and deployment
# timestamp together when publishing a new revision.
acr_resource_id         = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-registry-dev-ncus/providers/Microsoft.ContainerRegistry/registries/crskiregistrydevncus"
bridge_image_digest     = "sha256:a704d193f71b71fbf6cc96d1aef5fc483b344a60580b82390e159248fcc21aba"
bridge_image_repository = "ski-school/bridge"
container_image_digest  = "sha256:00ae9fd67efad0f2e4702fd96b104a399f7f2011175e0b6683cf007ba0d7fd12"
deployment_timestamp    = "2026-11-17T02:19:53Z"
diagnostic_disabled_categories = [
  "ContainerAppHTTPLogs",
  "AppEnvSpringAppConsoleLogs",
  "AppEnvSessionConsoleLogs",
  "AppEnvSessionPoolEventLogs",
  "AppEnvSessionLifeCycleLogs",
]
environment                 = "dev"
foundry_agent_resource_id   = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-foundry-dev-ncus/providers/Microsoft.CognitiveServices/accounts/aif-ski-foundry-dev-ncus/projects/proj-ski-foundry-dev-ncus/agents/ski-backend-dev"
location                    = "northcentralus"
log_analytics_workspace_id  = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-logs-dev-ncus/providers/Microsoft.OperationalInsights/workspaces/log-ski-logs-dev-eus2"
resource_group_name         = "rg-ski-frontend-dev-ncus"
session_signing_key_version = "dev-v1"
subscription_id             = "9a7e9255-7824-4c0d-a414-366f436f61dd"
tags = {
  workload = "ski-school-frontend"
}
