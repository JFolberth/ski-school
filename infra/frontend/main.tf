resource "azapi_resource" "frontend_resource_group" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  name      = var.resource_group_name
  parent_id = "/subscriptions/${var.subscription_id}"
  location  = var.location
  tags      = local.tags

  body = {}
}

module "aca" {
  source = "../modules/aca"

  acr_resource_id            = var.acr_resource_id
  container_image_digest     = var.container_image_digest
  container_image_repository = var.container_image_repository
  environment_name           = var.environment
  location                   = var.location
  log_analytics_workspace_id = var.log_analytics_workspace_id
  name_prefix                = var.name_prefix
  resource_group_id          = azapi_resource.frontend_resource_group.id
  tags                       = local.tags
}
