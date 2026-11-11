output "id" {
  description = "Workspace ARM ID for explicit cross-state handoff."
  value       = azapi_resource.this.id
}
