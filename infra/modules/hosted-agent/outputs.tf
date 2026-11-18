output "agent_name" {
  description = "Managed logical agent name."
  value       = azapi_data_plane_resource.this.name
}
output "agent_principal_id" {
  description = "Foundry-created default instance identity's principal object ID, used by general hosted-agent runtime tokens."
  value = var.existing_agent ? (
    data.azapi_data_plane_resource.existing[0].output.instance_identity.principal_id
  ) : azapi_data_plane_resource.this.output.instance_identity.principal_id
}
output "candidate_version" {
  description = "Capture once under exclusive deployment ownership, then verify this version's image/status; latest is not an atomic publication receipt or readiness proof."
  value       = azapi_data_plane_resource.this.output.versions.latest.version
}
output "image_uri" {
  description = "Expected immutable image URI for candidate readiness verification."
  value       = local.image_uri
}