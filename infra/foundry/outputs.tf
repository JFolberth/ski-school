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
  description = "Minimal non-secret gateway root model_backend handoff; configure upstream identity authorization separately in this root."
  value = {
    account_id    = module.account.id
    deployment_id = module.model.id
    endpoint      = module.account.endpoint
    model_version = module.model.model_version
  }
}

output "model_deployment_id" {
  description = "Account-level model deployment ARM ID; no direct project route is configured."
  value       = module.model.id
}

output "project_id" {
  description = "Foundry project ARM ID."
  value       = module.project.id
}

output "project_principal_id" {
  description = "Project principal for explicit scoped handoff; not a verified hosted-agent image-pull principal."
  value       = module.project.principal_id
}

output "resource_group_id" {
  description = "Foundry-owned resource group ARM ID."
  value       = module.resource_group.id
}
