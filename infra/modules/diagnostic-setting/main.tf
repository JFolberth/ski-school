resource "azapi_resource" "this" {
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
  name      = var.name
  parent_id = var.resource_id
  body = {
    properties = {
      workspaceId = var.workspace_id
      # Some sources return every category, including disabled entries, in a
      # stable service-defined order. Preserve existing behavior for other sources.
      logs = concat(
        [for category in sort(tolist(var.log_categories)) : merge({
          category = category
          enabled  = true
          }, length(var.disabled_log_categories) == 0 ? {} : {
          categoryGroup = null
          retentionPolicy = {
            days    = 0
            enabled = false
          }
        })],
        [for category in var.disabled_log_categories : {
          category      = category
          categoryGroup = null
          enabled       = false
          retentionPolicy = {
            days    = 0
            enabled = false
          }
        }]
      )
      metrics = concat(
        [for category in sort(tolist(var.metric_categories)) : {
          category = category
          enabled  = true
        }],
        [for category in sort(tolist(var.disabled_metric_categories)) : {
          category = category
          enabled  = false
          retentionPolicy = {
            days    = 0
            enabled = false
          }
        }]
      )
    }
  }
}
