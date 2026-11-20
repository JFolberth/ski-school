output "hostname" {
  description = "Azure-generated default endpoint hostname."
  value       = azapi_resource.this.output.properties.hostName
}

output "id" {
  description = "Front Door endpoint resource ID."
  value       = azapi_resource.this.id
}
