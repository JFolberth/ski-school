# Copy to an ignored root-local dev.tfvars and select explicitly.
# Supply required subscription_id, tenant_id and workspace_id separately.
# Change only this root to eastus2 if NCUS preview is verified unavailable.
application_insights = {
  application_type    = "web"
  retention_in_days   = 30
  sampling_percentage = 100
}
base_name   = "ski-gateway"
environment = "dev"
gateway_sku = null
location    = "northcentralus"
# Required ID output from infra/logging. This enables native OTLP for this component.
# monitor_workspace_id = "<actual Azure Monitor workspace ARM ID>"
# First create the gateway identity, grant it inference in Foundry, then supply
# the Foundry gateway_backend output here to create one provider/model/alias.
model_backend = null
# Explicit stable labels -> actual caller principal UUIDs; grants alias scope only.
model_callers = {}
tags          = {}
# After native OTLP metadata is complete, supply application_insights_otlp here.
telemetry_exporter = null
