output "account_endpoint" {
  description = "ARM-returned account endpoint for a later verified gateway upstream."
  value       = module.account.endpoint
}

output "account_id" {
  description = "Foundry account ARM ID."
  value       = module.account.id
}

output "account_principal_id" {
  description = "Account system-assigned principal, distinct from project/runtime identities."
  value       = module.account.principal_id
}

output "additional_model_deployment_ids" {
  description = "Account-level model deployment ARM IDs other than the explicitly selected singular handoff, keyed by their stable input labels."
  value       = { for key, deployment in module.model : key => deployment.id if key != var.gateway_model_key }
}

output "application_insights_connection_id" {
  description = "Private project telemetry destination metadata association, null when deferred. No connection string is exposed."
  value       = var.project_telemetry_connection_enabled ? module.project_telemetry_connection[0].id : null
}

output "application_insights_id" {
  description = "Dedicated Foundry telemetry destination; creation alone does not establish telemetry flow."
  value       = module.application_insights.id
}

output "application_insights_otlp" {
  description = "Non-secret asynchronous native OTLP DCR and signal endpoints, null when not opted in. Runtime export remains separate."
  value       = module.application_insights.otlp
}

output "gateway_backend" {
  description = "Minimal non-secret gateway root model_backend handoff for gateway_model_key; configure upstream identity authorization separately in this root."
  value = {
    account_id    = module.account.id
    deployment_id = module.model[var.gateway_model_key].id
    endpoint      = module.account.endpoint
    model_version = module.model[var.gateway_model_key].model_version
  }
}

output "model_deployment_id" {
  description = "Account-level model deployment ARM ID selected by gateway_model_key; no direct project route is configured."
  value       = module.model[var.gateway_model_key].id
}

output "project_acr_connection_id" {
  description = "Image-pull connection ARM ID, null when deferred. Project-specific ACR pull RBAC is owned by this Foundry root."
  value       = try(module.project_acr_connection["backend"].id, null)
}

output "project_id" {
  description = "Foundry project ARM ID."
  value       = module.project.id
}

output "project_principal_id" {
  description = "Project system-assigned image-pull principal; NOT the platform-created runtime agent principal."
  value       = module.project.principal_id
}

output "resource_group_id" {
  description = "Foundry-owned resource group ARM ID."
  value       = module.resource_group.id
}
