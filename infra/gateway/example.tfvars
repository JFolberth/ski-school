# Copy to an ignored root-local dev.tfvar and select explicitly with -var-file=dev.tfvar.
# Supply required subscription_id and tenant_id separately.
# AI Gateway is available in East US 2 and Sweden Central during public preview.
application_insights = {
  application_type    = "web"
  retention_in_days   = 30
  sampling_percentage = 100
}
base_name   = "ski-gateway"
environment = "dev"
gateway_sku = {
  name = "Standard"
}
location = "eastus2"
# Keep native OTLP disabled until the Log Analytics and Azure Monitor workspace
# regions are verified for the documented ingestion topology.
monitor_workspace_id = null
# First create the gateway identity, grant it inference in Foundry, then supply
# the Foundry gateway_backend output here to create one provider/model/alias.
model_backend = null
# Explicit stable labels -> actual caller principal UUIDs; grants alias scope only.
model_callers       = {}
native_otlp_enabled = false
tags                = {}
# After native OTLP metadata is complete, supply application_insights_otlp here.
telemetry_exporter = null
workspace_id       = null
