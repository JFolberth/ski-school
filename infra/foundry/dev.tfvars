# Explicit selection: terraform plan -var-file=dev.tfvar (after separate backend approval).
# Recovered deployment inputs; runtime grants outside Terraform remain external.
account_sku_name = "S0"
application_insights = {
  application_type    = "web"
  retention_in_days   = 30
  sampling_percentage = 100
}
application_insights_metadata_version = 2
base_name                             = "ski-foundry"
diagnostic_log_categories             = ["Audit"]
environment                           = "dev"
gateway_foundry_user_principals = {
  gateway = "b80ce36a-10f0-4c3a-a57a-85a9b8fe2393"
}
gateway_model_key  = "gpt_5_4_mini"
gateway_principals = {}
location           = "northcentralus"
models = {
  gpt_5_4_mini = {
    capacity               = 10
    model_name             = "gpt-5.4-mini"
    sku_name               = "GlobalStandard"
    model_version          = "2026-03-17"
    version_upgrade_option = "NoAutoUpgrade"
  }
  gpt_5_6_sol = {
    capacity      = 10
    model_name    = "gpt-5.6-sol"
    model_version = "2026-07-09"
  }
}
monitor_workspace_id = null
native_otlp_enabled  = false
project_acr_connection = {
  registry_id           = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-registry-dev-ncus/providers/Microsoft.ContainerRegistry/registries/crskiregistrydevncus"
  registry_login_server = "crskiregistrydevncus.azurecr.io"
  repository            = "ski-backend"
}
project_description                  = "Michigan skiing hosted-agent project."
project_telemetry_connection_enabled = true
subscription_id                      = "9a7e9255-7824-4c0d-a414-366f436f61dd"
tags                                 = {}
telemetry_publisher_principals = {
  project = "62333077-eb7a-4660-9a58-6f47f9d9b225"
}
tenant_id    = "5a4de383-e76f-4737-9623-e6281d36d202"
workspace_id = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-logs-dev-ncus/providers/Microsoft.OperationalInsights/workspaces/log-ski-logs-dev-eus2"
