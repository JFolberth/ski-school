# Copy to an ignored root-local dev.tfvar and select explicitly with -var-file=dev.tfvar.
# Supply subscription_id, tenant_id, workspace_id, and each selected model's capacity and version.
account_sku_name = "S0"
application_insights = {
  application_type    = "web"
  retention_in_days   = 30
  sampling_percentage = 100
}
application_insights_metadata_version = 1
base_name                             = "ski-foundry"
diagnostic_log_categories             = ["Audit"]
environment                           = "dev"
# Later stage: stable gateway labels -> actual gateway system principal UUIDs.
# Select only one upstream role for a given principal.
gateway_foundry_user_principals = {}
gateway_model_key               = "gpt_5_4_mini"
gateway_principals              = {}
location                        = "northcentralus"
# Verify each example model/version and capacity against the target before use.
models = {
  gpt_5_4_mini = {
    capacity      = 10
    model_name    = "gpt-5.4-mini"
    model_version = "2026-03-17"
    # Optional deployment_name; otherwise derived from model_name and the root suffix.
    sku_name               = "GlobalStandard"
    version_upgrade_option = "NoAutoUpgrade"
  }
  gpt_5_6_sol = {
    capacity      = 10
    model_name    = "gpt-5.6-sol"
    model_version = "2026-07-09"
  }
}
# Set a Monitor workspace ID when enabled; null when native OTLP is deferred.
# monitor_workspace_id = "<actual Azure Monitor workspace ARM ID>"
native_otlp_enabled = true
# Populate with reviewed registry outputs before releasing the hosted agent.
# project_acr_connection = {
#   registry_id           = "<existing-registry-arm-id>"
#   registry_login_server = "<existing-registry-login-hostname>"
#   repository            = "ski-backend"
# }
project_acr_connection = null
project_description    = "Michigan skiing hosted-agent project."
tags                   = {}
# Add only a verified actual runtime telemetry emitter, not an assumed identity.
telemetry_publisher_principals = {}
