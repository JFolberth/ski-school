output "id" {
  description = "Registry ARM ID, including the scope for later verified image-pull grants."
  value       = azapi_resource.this.id
}

output "login_server" {
  description = "Registry login server, not credentials."
  value       = azapi_resource.this.output.properties.loginServer
}
