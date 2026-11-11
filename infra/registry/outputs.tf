output "registry_id" {
  description = "Registry scope for a later verified image-pull assignment owned by this root."
  value       = module.registry.id
}

output "registry_login_server" {
  description = "Non-secret image publication destination; this phase publishes no images."
  value       = module.registry.login_server
}

output "resource_group_id" {
  description = "Registry-owned resource group ARM ID."
  value       = module.resource_group.id
}
