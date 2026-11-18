output "application_insights_id" {
  description = "Dedicated gateway component ARM ID, null until native OTLP is enabled."
  value       = try(module.application_insights[0].id, null)
}

output "application_insights_otlp" {
  description = "Sensitive asynchronous service-returned component OTLP metadata, null until native OTLP is enabled. Retrieve with terraform output -json when required."
  value       = try(module.application_insights[0].otlp, null)
  sensitive   = true
}

output "gateway_hostname" {
  description = "Sensitive service-returned runtime hostname; retrieve with terraform output -json when required."
  value       = module.gateway.hostname
  sensitive   = true
}

output "gateway_id" {
  description = "Gateway ARM ID, not a configured inference route."
  value       = module.gateway.id
}

output "gateway_principal_id" {
  description = "System-assigned gateway principal for explicit narrow upstream authorization in the Foundry scope-owning root."
  value       = module.gateway.principal_id
}

output "mcp_endpoint_urls" {
  description = "Gateway MCP invocation URLs keyed by server name; empty when no MCP endpoints are configured."
  value = {
    for name in keys(var.mcp_endpoints) :
    name => "https://${module.gateway.hostname}/default/toolservers/${name}/mcp"
  }
  sensitive = true
}

output "model_alias_id" {
  description = "Alias ARM ID and caller authorization scope, null until the shared provider, alias, and model map are configured."
  value       = try(module.model_alias["primary"].id, null)
}

output "model_alias_name" {
  description = "Managed client-facing alias name; a Foundry project model connection still needs a verified contract."
  value       = try(module.model_alias["primary"].name, null)
}

output "model_ids" {
  description = "Gateway backend-model ARM IDs keyed by the stable labels in the models input."
  value       = { for key, model in module.model : key => model.id }
}

output "resource_group_id" {
  description = "Gateway-owned resource group ARM ID."
  value       = module.resource_group.id
}

output "telemetry_exporter_endpoints" {
  description = "Sensitive configured OTLP endpoint URL metadata; retrieve with terraform output -json when required."
  value       = try(var.telemetry_exporter.endpoints, null)
  sensitive   = true
}

output "telemetry_exporter_id" {
  description = "Native exporter ARM ID, null until verified metadata and DCR publish authorization are configured."
  value       = try(module.telemetry_exporter["primary"].id, null)
}
