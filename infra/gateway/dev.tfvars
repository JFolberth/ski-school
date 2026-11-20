# Select this file explicitly: terraform plan -var-file=dev.tfvars
# Backend initialization and deployment require separate approval.
# Includes the existing managed telemetry exporter; endpoint URLs are configuration metadata, not credentials.
# The live runtime caller grant is external; do not adopt it into this state.
# Keep actual credentials and connection strings out of this tracked configuration.
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
auto_model_selection = {
  objective = "Balanced"
}
base_name   = "ski-gateway"
environment = "dev"
gateway_sku = {
  name = "Standard"
}
location      = "eastus2"
model_alias   = "ski-assistant-dev"
model_callers = {}
model_provider = {
  account_id    = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-foundry-dev-ncus/providers/Microsoft.CognitiveServices/accounts/aif-ski-foundry-dev-ncus"
  provider_name = "foundry-ski-dev-ncus"
}
model_provider_endpoint = "https://aif-ski-foundry-dev-ncus.cognitiveservices.azure.com/"
models = {
  primary = {
    deployment_id       = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-foundry-dev-ncus/providers/Microsoft.CognitiveServices/accounts/aif-ski-foundry-dev-ncus/deployments/gpt-5-4-mini-ski-foundry-dev-ncus"
    model_name          = "gpt-5-4-mini-dev-ncus"
    model_version       = "2026-03-17"
    priority            = 0
    selector_model_name = "gpt-5.4-mini"
    supported_endpoints = ["/openai/v1/chat/completions", "/openai/v1/responses"]
    weight              = 50
  }
  gpt_5_6_sol = {
    deployment_id       = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-foundry-dev-ncus/providers/Microsoft.CognitiveServices/accounts/aif-ski-foundry-dev-ncus/deployments/gpt-5-6-sol-ski-foundry-dev-ncus"
    model_name          = "gpt-5-6-sol-dev-ncus"
    model_version       = "2026-07-09"
    priority            = 0
    selector_model_name = "gpt-5.6-sol"
    supported_endpoints = ["/openai/v1/chat/completions", "/openai/v1/responses"]
    weight              = 50
  }
}
mcp_endpoints = {
  ski-tools = {
    allowed_tools      = ["snowsure___search_resorts", "snowsure___get_resort", "open-meteo-forecast___get_weather_forecast", "open-meteo-historical___get_historical_weather"]
    backend_url        = "https://aif-ski-foundry-dev-ncus.services.ai.azure.com/api/projects/proj-ski-foundry-dev-ncus/toolboxes/ski-tools/versions/13/mcp?api-version=v1"
    blocked_tools      = ["snowsure___book_lodging"]
    supported_versions = ["2025-06-18", "2025-11-25"]
    token_audience     = "https://ai.azure.com"
  }
}
monitor_workspace_id = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-logs-dev-ncus/providers/Microsoft.Monitor/accounts/amw-ski-logs-dev-eus2"
native_otlp_enabled  = true
subscription_id      = "9a7e9255-7824-4c0d-a414-366f436f61dd"
tags                 = {}
# Endpoint URLs here are configured values, distinct from asynchronous service-returned DCR metadata.
telemetry_payload_capture = true
telemetry_exporter = {
  "data_collection_rule_id" : "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/ai_appi-ski-gateway-dev-eus2_50797926-934b-4403-a5c8-8a2d014953fe_managed/providers/Microsoft.Insights/dataCollectionRules/managed-appi-ski-gateway-dev-eus2-dcr",
  "endpoints" : {
    "logs" : "https://managed-appi-ski-gateway-dev-eus2-dce-qi3i.eastus2-1.ingest.monitor.azure.com/dataCollectionRules/dcr-9c17fd15037e44cebf07ae0e4abe9785/streams/Microsoft-OTLP-Logs/otlp/v1/logs",
    "metrics" : "https://managed-appi-ski-gateway-dev-eus2-dce-qi3i.eastus2-1.metrics.ingest.monitor.azure.com/dataCollectionRules/dcr-9c17fd15037e44cebf07ae0e4abe9785/streams/Microsoft-OtelMetrics/otlp/v1/metrics",
    "traces" : "https://managed-appi-ski-gateway-dev-eus2-dce-qi3i.eastus2-1.ingest.monitor.azure.com/dataCollectionRules/dcr-9c17fd15037e44cebf07ae0e4abe9785/streams/Microsoft-OTLP-Traces/otlp/v1/traces"
  }
}
tenant_id    = "5a4de383-e76f-4737-9623-e6281d36d202"
workspace_id = "/subscriptions/9a7e9255-7824-4c0d-a414-366f436f61dd/resourceGroups/rg-ski-logs-dev-ncus/providers/Microsoft.OperationalInsights/workspaces/log-ski-logs-dev-eus2"
