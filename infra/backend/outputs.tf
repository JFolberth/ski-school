output "agent_name" {
  description = "Logical agent name for readiness checks."
  value       = module.agent.agent_name
}
output "agent_principal_id" {
  description = "Foundry-created default instance identity principal object ID granted access to the gateway alias."
  value       = module.agent.agent_principal_id
}
output "candidate_version" {
  description = "Capture once; independently verify this exact version and expected image before routing traffic."
  value       = module.agent.candidate_version
}
output "environment" {
  description = "Release environment; backend isolation is configured separately during approved initialization."
  value       = var.environment
}
output "image_uri" {
  description = "Expected immutable image URI for readiness checks."
  value       = module.agent.image_uri
}
output "project_endpoint" {
  description = "Reviewed existing project endpoint used by read-only release verification."
  value       = trimsuffix(var.project_endpoint, "/")
}