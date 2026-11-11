# Copy to an ignored root-local dev.tfvar and select explicitly with -var-file=dev.tfvar.
# Supply subscription_id, tenant_id, workspace_id, model_capacity and model_version.
# Candidate model version: 2026-03-17; target support/quota remain unverified.
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
gateway_principals              = {}
location                        = "northcentralus"
# Optional override; otherwise the deployment name is derived from base_name, environment, and region.
# model_deployment_name = "gpt-5-4-mini-ski-foundry-dev-ncus"
model_name                   = "gpt-5.4-mini"
model_sku_name               = "GlobalStandard"
model_version_upgrade_option = "NoAutoUpgrade"
# Set a Monitor workspace ID when enabled; null when native OTLP is deferred.
# monitor_workspace_id = "<actual Azure Monitor workspace ARM ID>"
native_otlp_enabled = true
project_description = "Michigan skiing hosted-agent project."
tags                = {}
# Add only a verified actual runtime telemetry emitter, not an assumed identity.
telemetry_publisher_principals = {}
