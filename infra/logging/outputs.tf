output "monitor_workspace_id" {
  description = "Shared Azure Monitor workspace ARM ID. Not interchangeable with workspace_id; no AppInsights OTLP association is enabled yet."
  value       = module.monitor_workspace.id
}

output "resource_group_id" {
  description = "Logging-owned resource group ARM ID."
  value       = module.resource_group.id
}

output "workspace_id" {
  description = "Pass explicitly to registry, Foundry and gateway roots; no remote-state read required."
  value       = module.workspace.id
}
