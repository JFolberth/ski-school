output "id" {
  description = "Gateway backend-model ARM ID used by an alias, not the upstream deployment ID."
  value       = azapi_resource.this.id
}
