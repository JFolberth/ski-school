output "id" {
  description = "Foundry project ARM ID."
  value       = azapi_resource.this.id
}

output "principal_id" {
  description = "Project system-assigned principal; do not assume agent image-pull equivalence."
  value       = azapi_resource.this.identity[0].principal_id
}
