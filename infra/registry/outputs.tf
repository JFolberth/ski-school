output "registry_id" {
  description = "Registry ARM ID for the Foundry project connection and project-owned pull assignment handoff."
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
