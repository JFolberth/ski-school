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
  count            = var.native_otlp_enabled ? 1 : 0
  source           = "../modules/application-insights"
  application_type = var.application_insights.application_type
  location         = var.location
  name             = "appi-${local.suffix}"
  native_otlp = var.native_otlp_enabled ? {
    monitor_workspace_id = var.monitor_workspace_id
  } : null
  resource_group_id   = module.resource_group.id
  retention_in_days   = var.application_insights.retention_in_days
  sampling_percentage = var.application_insights.sampling_percentage
  workspace_id        = var.workspace_id
}

module "model_provider" {
  for_each     = local.model_backends
  source       = "../modules/ai-gateway-model-provider"
  account_id   = each.value.account_id
  endpoint     = each.value.endpoint
  name         = "foundry-${local.suffix}"
  workspace_id = local.default_workspace_id
}

module "model" {
  for_each            = local.model_backends
  source              = "../modules/ai-gateway-model"
  deployment_id       = each.value.deployment_id
  model_version       = each.value.model_version
  name                = "model-${local.suffix}"
  provider_id         = module.model_provider[each.key].id
  supported_endpoints = each.value.supported_endpoints
}

module "model_alias" {
  for_each     = local.model_backends
  source       = "../modules/ai-gateway-model-alias"
  model_id     = module.model[each.key].id
  name         = "model-${local.suffix}"
  workspace_id = local.default_workspace_id
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
  role_definition_id = "/subscriptions/${split("/", each.value.data_collection_rule_id)[2]}/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb"
  scope_id           = each.value.data_collection_rule_id
}

module "telemetry_exporter" {
  for_each                = local.telemetry_exporters
  source                  = "../modules/ai-gateway-telemetry-exporter"
  application_insights_id = module.application_insights[0].id
  endpoints               = each.value.endpoints
  name                    = "otlp-${local.suffix}"
  workspace_id            = local.default_workspace_id
  # Registration requires DCR publish authorization, which is not an exporter property.
  depends_on = [module.telemetry_publisher]
}
