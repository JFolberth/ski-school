locals {
  foundry_agent_resource_id_parts = split("/", var.foundry_agent_resource_id)
  foundry_agent_base_url          = "https://${lower(local.foundry_agent_resource_id_parts[8])}.services.ai.azure.com/api/projects/${local.foundry_agent_resource_id_parts[10]}/agents/${local.foundry_agent_resource_id_parts[12]}/endpoint/protocols/openai"
}

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

  acr_resource_id                = var.acr_resource_id
  bridge_cpu                     = var.bridge_cpu
  bridge_image_digest            = var.bridge_image_digest
  bridge_image_repository        = var.bridge_image_repository
  bridge_memory                  = var.bridge_memory
  container_cpu                  = var.container_cpu
  container_image_digest         = var.container_image_digest
  container_image_repository     = var.container_image_repository
  container_memory               = var.container_memory
  deployment_timestamp           = var.deployment_timestamp
  diagnostic_disabled_categories = var.diagnostic_disabled_categories
  environment_name               = var.environment
  foundry_agent_base_url         = local.foundry_agent_base_url
  foundry_agent_resource_id      = var.foundry_agent_resource_id
  http_concurrent_requests       = var.http_concurrent_requests
  location                       = var.location
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  max_replicas                   = var.max_replicas
  min_replicas                   = var.min_replicas
  name_prefix                    = var.name_prefix
  resource_group_id              = azapi_resource.frontend_resource_group.id
  tags                           = local.tags
}
