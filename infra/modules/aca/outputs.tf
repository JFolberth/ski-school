output "application_insights_id" {
  description = "Resource ID of the workspace-based Application Insights component."
  value       = azapi_resource.application_insights.id
}

output "container_app_id" {
  description = "Resource ID of the frontend Container App."
  value       = azapi_resource.container_app.id
}

output "container_app_url" {
  description = "HTTPS URL of the public frontend Container App."
  value       = "https://${azapi_resource.container_app.output.properties.configuration.ingress.fqdn}"
}
