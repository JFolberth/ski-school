resource "azapi_resource" "this" {
  type      = "Microsoft.Insights/components@2025-01-23-preview"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  # Approved AzAPI 2.13.0 schema exception: https://github.com/Azure/azure-rest-api-specs/blob/main/specification/applicationinsights/resource-manager/Microsoft.Insights/ApplicationInsights/Components/models.tsp
  schema_validation_enabled = false
  body = {
    kind = var.application_type
    properties = merge({
      Application_Type                   = var.application_type
      DisableIpMasking                   = false
      DisableLocalAuth                   = true
      Flow_Type                          = "Bluefield"
      ImmediatePurgeDataOn30Days         = var.retention_in_days == 30
      IngestionMode                      = "LogAnalytics"
      Request_Source                     = "rest"
      RetentionInDays                    = var.retention_in_days
      SamplingPercentage                 = var.sampling_percentage
      WorkspaceResourceId                = var.workspace_id
      publicNetworkAccessForIngestion    = "Enabled"
      publicNetworkAccessForQuery        = "Enabled"
      AzureMonitorWorkspaceIngestionMode = var.native_otlp == null ? "NotOptedIn" : "Enabled"
      }, var.native_otlp == null ? {} : {
      AzureMonitorWorkspaceResourceId = var.native_otlp.monitor_workspace_id
    })
  }
  response_export_values = concat(var.export_connection_metadata ? ["properties.ConnectionString"] : [], [
    "properties.DataCollectionRuleResourceId",
    "properties.OTLPLogsEndpoint",
    "properties.OTLPMetricsEndpoint",
    "properties.OTLPTracesEndpoint",
  ])
}
