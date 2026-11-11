module "resource_group" {
  source          = "../modules/resource-group"
  location        = var.location
  name            = "rg-${local.suffix}"
  subscription_id = var.subscription_id
}

module "workspace" {
  source            = "../modules/log-analytics"
  location          = var.location
  name              = "log-${local.suffix}"
  resource_group_id = module.resource_group.id
  retention_in_days = var.workspace_retention_in_days
  sku_name          = var.workspace_sku_name
}

module "monitor_workspace" {
  source                  = "../modules/monitor-workspace"
  location                = var.monitor_workspace_location
  name                    = "amw-${var.base_name}-${var.environment}-${local.region_abbreviations[var.monitor_workspace_location]}"
  resource_context_access = var.monitor_workspace_resource_context_access
  resource_group_id       = module.resource_group.id
}
