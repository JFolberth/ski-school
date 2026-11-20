environment                = "dev"
frontend_container_app_id  = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-frontend-dev-ncus/providers/Microsoft.App/containerApps/ski-frontend-dev-ui"
location                   = "northcentralus"
log_analytics_workspace_id = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-logs-dev-ncus/providers/Microsoft.OperationalInsights/workspaces/log-ski-logs-dev-eus2"
profiles = {
  main = {
    name                               = "afd-ski-global-dev-gbl"
    origin_group_name                  = "og-ski-global-dev-gbl"
    diagnostic_name                    = "diag-ski-global-dev-gbl"
    sku_name                           = "Standard_AzureFrontDoor"
    origin_response_timeout_seconds    = 240
    probe_interval_seconds             = 240
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 0
    frontend_origin_priority           = 1
    frontend_origin_weight             = 50
    use_frontend                       = true
    additional_origins                 = {}
    endpoints = {
      main = {
        name       = "afd-ski-global-dev"
        route_name = "route-ski-global-dev-gbl"
      }
    }
  }
}
resource_group_name = "rg-ski-global-dev-gbl"
subscription_id     = "9a7e9255-7824-4c0d-a414-366f436f61dd"
tags                = {}
tenant_id           = "5a4de383-e76f-4737-9623-e6281d36d202"
