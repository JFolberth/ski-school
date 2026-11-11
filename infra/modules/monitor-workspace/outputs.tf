output "id" {
  description = "Azure Monitor workspace ARM ID, distinct from the Log Analytics workspace ID."
  value       = azapi_resource.this.id
}
