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
# First create the gateway identity, grant it inference in Foundry, then supply
# the Foundry gateway_backend output here to create one provider/model/alias.
model_backend = null
# Explicit stable labels -> actual caller principal UUIDs; grants alias scope only.
model_callers = {}
# Supply the existing East US 2 Monitor workspace ID and the replacement
# Log Analytics workspace ID before enabling native OTLP in a reviewed stage.
monitor_workspace_id = null
native_otlp_enabled  = false
tags                 = {}
# Later supply the component DCR and actual endpoints securely via TF_VAR_telemetry_exporter.
telemetry_exporter = null
workspace_id       = null
