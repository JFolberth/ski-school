resource "azapi_resource" "this" {
  # Keep the same state address for both contracts; OTLP fields are preview-only.
  # Stable contract: https://learn.microsoft.com/azure/templates/microsoft.insights/2020-02-02/components
  type      = var.native_otlp == null ? "Microsoft.Insights/components@2020-02-02" : "Microsoft.Insights/components@2025-01-23-preview"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  body = {
    kind = var.application_type
    properties = merge({
      Application_Type                = var.application_type
      DisableIpMasking                = false
      DisableLocalAuth                = true
      Flow_Type                       = "Bluefield"
      ImmediatePurgeDataOn30Days      = var.retention_in_days == 30
      IngestionMode                   = "LogAnalytics"
      Request_Source                  = "rest"
      RetentionInDays                 = var.retention_in_days
      SamplingPercentage              = var.sampling_percentage
      WorkspaceResourceId             = var.workspace_id
      publicNetworkAccessForIngestion = "Enabled"
      publicNetworkAccessForQuery     = "Enabled"
      }, var.native_otlp == null ? {} : {
      AzureMonitorWorkspaceIngestionMode = "Enabled"
      AzureMonitorWorkspaceResourceId    = var.native_otlp.monitor_workspace_id
    })
  }
  response_export_values = concat(var.export_connection_metadata ? ["properties.ConnectionString"] : [], var.native_otlp == null ? [] : [
    "properties.DataCollectionRuleResourceId",
    "properties.OTLPLogsEndpoint",
    "properties.OTLPMetricsEndpoint",
    "properties.OTLPTracesEndpoint",
  ])
}
