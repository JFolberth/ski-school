output "application_insights_id" {
  description = "Resource ID of the dedicated workspace-based Application Insights component."
  value       = module.aca.application_insights_id
}

output "container_app_id" {
  description = "Resource ID of the public frontend Container App."
  value       = module.aca.container_app_id
}

output "container_app_url" {
  description = "HTTPS URL of the public frontend Container App."
  value       = module.aca.container_app_url
}

output "resource_group_id" {
  description = "Resource ID of the frontend-only resource group."
  value       = azapi_resource.frontend_resource_group.id
}

output "runtime_principal_id" {
  description = "System-assigned Container App runtime principal, separate from the ACR image-pull identity."
  value       = module.aca.runtime_principal_id
}
