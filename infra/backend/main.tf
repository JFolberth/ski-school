# Release state owns the agent and its runtime grants. The project, connections,
# ACR and foundation grants retain their owners. Build/push images separately.
module "agent" {
  source                     = "../modules/hosted-agent"
  acr_login_server           = var.acr_login_server
  agent_name                 = var.agent_name
  container_image_digest     = var.container_image_digest
  container_image_repository = var.container_image_repository
  cpu                        = var.cpu
  existing_agent             = var.existing_agent
  gateway_base_url           = var.gateway_base_url
  gateway_model_alias        = var.gateway_model_alias
  idle_timeout_seconds       = var.idle_timeout_seconds
  memory                     = var.memory
  project_endpoint           = var.project_endpoint
  rai_policy_id              = var.rai_policy_id
}
module "agent_gateway_caller" {
  source       = "../modules/role-assignment"
  principal_id = module.agent.agent_principal_id
  # AI Gateway Models User permits inference through the scoped model alias.
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/a6b68e3d-a1f0-4c60-8678-237c050cf4ea"
  scope_id           = var.gateway_model_alias_id
}
module "agent_telemetry_publisher" {
  source       = "../modules/role-assignment"
  principal_id = module.agent.agent_principal_id
  # Monitoring Metrics Publisher permits telemetry ingestion on this component.
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/3913510d-42f4-4e42-8a64-420c390055eb"
  scope_id           = var.application_insights_id
}