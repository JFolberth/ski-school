resource "azapi_resource" "this" {
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  name      = var.name
  parent_id = var.resource_id
  body = {
    properties = {
      workspaceId = var.workspace_id
      logs = [for category in sort(tolist(var.log_categories)) : {
        category = category
        enabled  = true
      }]
      metrics = [for category in sort(tolist(var.metric_categories)) : {
        category = category
        enabled  = true
      }]
    }
  }
}
