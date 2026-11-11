output "id" {
  description = "Alias ARM ID and narrow scope for model-only caller assignments."
  value       = azapi_resource.this.id
}

output "name" {
  description = "Managed alias name sent in a model request."
  value       = azapi_resource.this.name
}
