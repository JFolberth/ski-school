output "endpoint" {
  description = "Account endpoint returned by ARM."
  value       = azapi_resource.this.output.properties.endpoint
}

output "id" {
  description = "Foundry account ARM ID."
  value       = azapi_resource.this.id
}

output "principal_id" {
  description = "Account system-assigned principal; not necessarily the agent image-pull identity."
  value       = azapi_resource.this.identity[0].principal_id
}
