module "resource_group" {
  source          = "../modules/resource-group"
  location        = var.location
  name            = "rg-${local.suffix}"
  subscription_id = var.subscription_id
}

module "gateway" {
  source   = "../modules/ai-gateway"
  location = var.location
  # Locally proposed aig prefix; CAF does not list standalone AI Gateway.
  name              = "aig-${local.suffix}"
  resource_group_id = module.resource_group.id
  sku               = var.gateway_sku
}

module "application_insights" {
  count                         = var.native_otlp_enabled ? 1 : 0
  source                        = "../modules/application-insights"
  application_type              = var.application_insights.application_type
  gateway_otlp_schema_exception = true
  location                      = var.location
  name                          = "appi-${local.suffix}"
  native_otlp = var.native_otlp_enabled ? {
    monitor_workspace_id = var.monitor_workspace_id
  } : null
  resource_group_id   = module.resource_group.id
  retention_in_days   = var.application_insights.retention_in_days
  sampling_percentage = var.application_insights.sampling_percentage
  workspace_id        = var.workspace_id
}

module "model_provider" {
  for_each     = local.alias_backends
  source       = "../modules/ai-gateway-model-provider"
  account_id   = var.model_provider.account_id
  endpoint     = var.model_provider_endpoint
  name         = var.model_provider.provider_name
  workspace_id = local.default_workspace_id
}

module "model" {
  for_each            = local.model_backends
  source              = "../modules/ai-gateway-model"
  deployment_id       = each.value.deployment_id
  model_version       = each.value.model_version
  name                = each.value.model_name
  provider_id         = module.model_provider["primary"].id
  supported_endpoints = each.value.supported_endpoints
}

module "model_alias" {
  for_each = local.alias_backends
  source   = "../modules/ai-gateway-model-alias"
  backend_models = [
    for key in local.alias_model_keys : {
      resource_id         = module.model[key].id
      selector_model_name = local.model_backends[key].selector_model_name
      priority            = local.model_backends[key].priority
      weight              = local.model_backends[key].weight
    }
  ]
  auto_model_selection = var.auto_model_selection
  name                 = each.value.name
  policy_limits        = var.alias_policy_limits
  workspace_id         = local.default_workspace_id
}

module "model_caller" {
  for_each     = var.model_callers
  source       = "../modules/role-assignment"
  principal_id = each.value
  # AI Gateway Models User permits inference through the scoped model alias.
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/a6b68e3d-a1f0-4c60-8678-237c050cf4ea"
  scope_id           = module.model_alias["primary"].id
}

module "telemetry_publisher" {
  for_each     = local.telemetry_exporters
  source       = "../modules/role-assignment"
  principal_id = module.gateway.principal_id
  # Monitoring Metrics Publisher permits telemetry ingestion on this DCR.
  role_definition_id = "/subscriptions/${split("/", nonsensitive(var.telemetry_exporter.data_collection_rule_id))[2]}/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb"
  scope_id           = nonsensitive(var.telemetry_exporter.data_collection_rule_id)
}

module "telemetry_exporter" {
  for_each                = local.telemetry_exporters
  source                  = "../modules/ai-gateway-telemetry-exporter"
  application_insights_id = module.application_insights[0].id
  endpoints               = var.telemetry_exporter.endpoints
  name                    = "otlp-${local.suffix}"
  workspace_id            = local.default_workspace_id
  # Registration requires DCR publish authorization, which is not an exporter property.
  depends_on = [module.telemetry_publisher]
}
