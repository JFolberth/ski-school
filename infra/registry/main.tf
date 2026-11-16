module "resource_group" {
  source          = "../modules/resource-group"
  location        = var.location
  name            = "rg-${local.suffix}"
  subscription_id = var.subscription_id
}

module "registry" {
  source            = "../modules/container-registry"
  location          = var.location
  name              = replace("cr-${local.suffix}", "-", "")
  resource_group_id = module.resource_group.id
  sku_name          = var.registry_sku_name
}

module "diagnostics" {
  source         = "../modules/diagnostic-setting"
  name           = "cr-${local.suffix}"
  resource_id    = module.registry.id
  workspace_id   = var.workspace_id
  log_categories = var.diagnostic_log_categories
  # Match ACR's normalized disabled metrics without enabling collection.
  disabled_metric_categories = ["AllMetrics"]
}
