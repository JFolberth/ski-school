module "resource_group" {
  source          = "../modules/resource-group"
  location        = var.location
  name            = "rg-${local.suffix}"
  subscription_id = var.subscription_id
}

module "account" {
  source            = "../modules/foundry-account"
  location          = var.location
  name              = "aif-${local.suffix}"
  resource_group_id = module.resource_group.id
  sku_name          = var.account_sku_name
}

module "project" {
  source       = "../modules/foundry-project"
  account_id   = module.account.id
  description  = var.project_description
  display_name = var.project_display_name
  location     = var.location
  name         = "proj-${local.suffix}"
}

module "model" {
  source                 = "../modules/model-deployment"
  account_id             = module.account.id
  capacity               = var.model_capacity
  model_name             = var.model_name
  model_version          = var.model_version
  name                   = local.model_deployment_name
  sku_name               = var.model_sku_name
  version_upgrade_option = var.model_version_upgrade_option
}

module "application_insights" {
  source                     = "../modules/application-insights"
  application_type           = var.application_insights.application_type
  export_connection_metadata = var.project_telemetry_connection_enabled
  location                   = var.location
  name                       = "appi-${local.suffix}"
  native_otlp = var.native_otlp_enabled ? {
    monitor_workspace_id = var.monitor_workspace_id
  } : null
  resource_group_id   = module.resource_group.id
  retention_in_days   = var.application_insights.retention_in_days
  sampling_percentage = var.application_insights.sampling_percentage
  workspace_id        = var.workspace_id
}

module "diagnostics" {
  source       = "../modules/diagnostic-setting"
  name         = "aif-${local.suffix}"
  resource_id  = module.account.id
  workspace_id = var.workspace_id
  # Only Audit is enabled. Match the verified ARM GET order and disabled
  # categories explicitly; RequestResponse/Trace payload capture stays off.
  log_categories = var.diagnostic_log_categories
  disabled_log_categories = [
    "RequestResponse",
    "AzureOpenAIRequestUsage",
    "Trace",
    "ManagedNetworkEvent",
  ]
  disabled_metric_categories = ["AllMetrics"]
}

module "project_telemetry_connection" {
  count                   = var.project_telemetry_connection_enabled ? 1 : 0
  source                  = "../modules/foundry-project-connection"
  application_insights_id = module.application_insights.id
  connection_string       = module.application_insights.connection_string
  metadata_version        = var.application_insights_metadata_version
  name                    = "appi-${local.suffix}"
  project_id              = module.project.id
  depends_on              = [module.telemetry_publisher]
}

moved {
  from = module.project_telemetry_connection
  to   = module.project_telemetry_connection[0]
}

module "gateway_inference" {
  for_each     = var.gateway_principals
  source       = "../modules/role-assignment"
  principal_id = each.value
  # Cognitive Services OpenAI User includes responses/chat inference, unlike broader Foundry User.
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"
  scope_id           = module.account.id
}

module "gateway_foundry_user" {
  for_each     = var.gateway_foundry_user_principals
  source       = "../modules/role-assignment"
  principal_id = each.value
  # Foundry User is the role used by the AI Gateway Foundry integration.
  # https://learn.microsoft.com/en-us/azure/ai-gateway/quickstart-create-ai-gateway
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/53ca6127-db72-4b80-b1b0-d745d6d5456d"
  scope_id           = module.account.id
}

module "telemetry_publisher" {
  for_each     = var.telemetry_publisher_principals
  source       = "../modules/role-assignment"
  principal_id = each.value
  # Monitoring Metrics Publisher permits telemetry ingestion on this component.
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb"
  scope_id           = module.application_insights.id
}

# The private telemetry association does not establish the still-unverified
# standalone-gateway project MODEL connection or a direct-model bypass.
