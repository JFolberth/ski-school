output "hostname" {
  description = "Sensitive service-returned hostname, not a fabricated endpoint; retrieve through an explicitly sensitive root output."
  value       = azapi_resource.this.output.properties.frontend.defaultHostname
  sensitive   = true
}

output "id" {
  description = "Gateway ARM ID, not a model endpoint or evidence of configured routing."
  value       = azapi_resource.this.id
}

output "principal_id" {
  description = "Gateway system-assigned principal for a later verified upstream binding."
  value       = azapi_resource.this.identity[0].principal_id
}
