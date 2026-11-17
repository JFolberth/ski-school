# Copy to an ignored root-local dev.tfvar and select explicitly with -var-file=dev.tfvar.
# Supply required subscription_id and tenant_id separately.
# AI Gateway is available in East US 2 and Sweden Central during public preview.
alias_policy_limits = {
  monthly_cost_usd    = 10
  requests_per_minute = 30
  tokens_per_minute   = 30000
}
application_insights = {
  application_type    = "web"
  retention_in_days   = 30
  sampling_percentage = 100
}
auto_model_selection = null
base_name            = "ski-gateway"
environment          = "dev"
gateway_sku = {
  name = "Standard"
}
location = "eastus2"
# Stage these shared provider and alias values with the model registrations below.
# Use the sensitive service-returned endpoint through TF_VAR_model_provider_endpoint.
model_alias = null
# Explicit stable labels -> actual caller principal UUIDs; grants alias scope only.
model_callers           = {}
model_provider          = null
model_provider_endpoint = null
# Keep all model registrations in this single map. `primary` is retained in dev
# for address compatibility; it has no special routing preference or required meaning.
models = {}
# Example shape (replace every fake ARM ID and value with verified Foundry outputs):
# model_alias = "ski-assistant-dev"
# model_provider = {
#   account_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.CognitiveServices/accounts/example-foundry"
#   provider_name = "foundry-ski-dev-ncus"
# }
# model_provider_endpoint = "https://example.invalid"
# models = {
#   primary = {
#     deployment_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.CognitiveServices/accounts/example-foundry/deployments/gpt-5-4-mini-ski-foundry-dev-ncus"
#     model_name          = "gpt-5-4-mini-dev-ncus"
#     model_version       = "2026-03-17"
#     priority            = 0
#     selector_model_name = "gpt-5.4-mini"
#     supported_endpoints = ["/openai/v1/chat/completions", "/openai/v1/responses"]
#     weight              = 50
#   }
#   gpt_5_6_sol = {
#     deployment_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-example/providers/Microsoft.CognitiveServices/accounts/example-foundry/deployments/gpt-5-6-sol-ski-foundry-dev-ncus"
#     model_name          = "gpt-5-6-sol-dev-ncus"
#     model_version       = "2026-07-09"
#     priority            = 0
#     selector_model_name = "gpt-5.6-sol"
#     supported_endpoints = ["/openai/v1/chat/completions", "/openai/v1/responses"]
#     weight              = 50
#   }
# }
monitor_workspace_id = null
native_otlp_enabled  = false
subscription_id      = "<workload-subscription-uuid>"
tags                 = {}
# Later supply the component DCR and actual endpoints securely via TF_VAR_telemetry_exporter.
telemetry_exporter = null
tenant_id          = "<workload-tenant-uuid>"
workspace_id       = null
