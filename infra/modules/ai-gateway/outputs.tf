output "hostname" {
  description = "Service-returned hostname, not a fabricated endpoint; routing still requires separate configuration."
  value       = azapi_resource.this.output.properties.frontend.defaultHostname
}

output "id" {
  description = "Gateway ARM ID, not a model endpoint or evidence of configured routing."
  value       = azapi_resource.this.id
}

output "principal_id" {
  description = "Gateway system-assigned principal for a later verified upstream binding."
  value       = azapi_resource.this.identity[0].principal_id
}
