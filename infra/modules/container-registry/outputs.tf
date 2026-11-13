output "id" {
  description = "Registry ARM ID, including the scope for later verified image-pull grants."
  value       = azapi_resource.this.id
}

output "login_server" {
  description = "Registry login server, not credentials."
  value       = azapi_resource.this.output.properties.loginServer
}

output "role_assignment_mode" {
  description = "ARM-returned ACR permission mode; callers must reject unknown modes rather than guess a pull role."
  value       = azapi_resource.this.output.properties.roleAssignmentMode
}
