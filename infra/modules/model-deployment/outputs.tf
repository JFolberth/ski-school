output "id" {
  description = "Account-level deployment ARM ID; does not establish a gateway route."
  value       = azapi_resource.this.id
}

output "model_version" {
  description = "Service-returned deployed model version, including any service-side version upgrade."
  value       = azapi_resource.this.output.properties.model.version
}
