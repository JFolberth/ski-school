resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/telemetryExporters@2026-11-01"
  name      = var.name
  parent_id = var.workspace_id
  # Approved AzAPI 2.13.0 schema exception: https://github.com/Azure/azure-rest-api-specs/blob/main/specification/apimanagement/resource-manager/Microsoft.ApiManagement/AIGateway/stable/2026-11-01/openapi.json
  schema_validation_enabled = false
  body = {
    properties = {
      kind           = "OpenTelemetry"
      payloadCapture = false
      applicationInsights = {
        resourceId = var.application_insights_id
      }
      openTelemetry = {
        metricsEndpoint = var.endpoints.metrics
        logsEndpoint    = var.endpoints.logs
        tracesEndpoint  = var.endpoints.traces
        credentials = {
          managedIdentity = {
            resource = "https://monitor.azure.com"
          }
        }
      }
    }
  }
}
