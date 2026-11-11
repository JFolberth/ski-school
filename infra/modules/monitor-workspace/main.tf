# This workspace is distinct from Microsoft.OperationalInsights/workspaces.
# Azure creates default ingestion DCR/DCE resources in a service-managed RG:
# https://learn.microsoft.com/azure/azure-monitor/metrics/azure-monitor-workspace-manage
# Do not adopt those resources or invent an OTLP association in this module.
resource "azapi_resource" "this" {
  type      = "Microsoft.Monitor/accounts@2025-10-03"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  body = {
    properties = {
      metrics = {
        enableAccessUsingResourcePermissions = var.resource_context_access
      }
      publicNetworkAccess = "Enabled"
    }
  }
}
