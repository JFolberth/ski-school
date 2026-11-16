output "id" {
  description = "Foundry project ARM ID."
  value       = azapi_resource.this.id
}

output "principal_id" {
  description = "Project system-assigned principal used by Foundry infrastructure for ACR image pulling; runtime agent identity is separate."
  value       = azapi_resource.this.identity[0].principal_id
}
