resource "azapi_resource" "this" {
  type      = "Microsoft.OperationalInsights/workspaces@2025-07-01"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  body = {
    properties = {
      features = {
        disableLocalAuth                            = true
        enableLogAccessUsingOnlyResourcePermissions = true
        immediatePurgeDataOn30Days                  = var.retention_in_days == 30
      }
      publicNetworkAccessForIngestion = "Enabled"
      publicNetworkAccessForQuery     = "Enabled"
      retentionInDays                 = var.retention_in_days
      sku                             = { name = var.sku_name }
    }
  }
}
