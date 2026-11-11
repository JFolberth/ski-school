output "application_insights_id" {
  description = "Dedicated gateway component ARM ID, null until native OTLP is enabled."
  value       = try(module.application_insights[0].id, null)
}

output "application_insights_otlp" {
  description = "Non-secret asynchronous component metadata, null until native OTLP is enabled. Once complete, pass this exact object as telemetry_exporter in a later approved stage."
  value       = try(module.application_insights[0].otlp, null)
}

output "gateway_hostname" {
  description = "Service-returned runtime hostname; use a configured alias and Entra caller authorization."
  value       = module.gateway.hostname
}

output "gateway_id" {
  description = "Gateway ARM ID, not a configured inference route."
  value       = module.gateway.id
}

output "gateway_principal_id" {
  description = "System-assigned gateway principal for explicit narrow upstream authorization in the Foundry scope-owning root."
  value       = module.gateway.principal_id
}

output "model_alias_id" {
  description = "Alias ARM ID and caller authorization scope, null until model_backend is explicitly configured."
  value       = try(module.model_alias["primary"].id, null)
}

output "model_alias_name" {
  description = "Managed client-facing alias name; a Foundry project model connection still needs a verified contract."
  value       = try(module.model_alias["primary"].name, null)
}

output "resource_group_id" {
  description = "Gateway-owned resource group ARM ID."
  value       = module.resource_group.id
}

output "telemetry_exporter_id" {
  description = "Native exporter ARM ID, null until verified metadata and DCR publish authorization are configured."
  value       = try(module.telemetry_exporter["primary"].id, null)
}
