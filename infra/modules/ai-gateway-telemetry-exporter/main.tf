resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/telemetryExporters@2025-09-01-preview"
  name      = var.name
  parent_id = var.workspace_id
  # Approved per-resource contract exception; AzAPI's embedded schema lacks this child type.
  # https://github.com/Azure-Samples/ai-gateway-foundry-terraform/blob/main/standalone/ai_gateway.tf
  schema_validation_enabled = false
  body = {
    properties = {
      kind           = "OpenTelemetry"
      payloadCapture = false
      applicationInsights = {
        resourceId = var.application_insights_id
      }
      openTelemetry = {
        credentials = {
          managedIdentity = {
            resource = "https://monitor.azure.com"
          }
        }
      }
    }
  }
  # Without a version map AzAPI tracks a private hash and sends all write-only
  # fields on each create/update, including updates to unrelated body fields.
  # https://github.com/Azure/terraform-provider-azapi/blob/v2.13.0/docs/guides/feature_ephemeral_resource.md
  sensitive_body = {
    properties = {
      openTelemetry = {
        metricsEndpoint = var.endpoints.metrics
        logsEndpoint    = var.endpoints.logs
        tracesEndpoint  = var.endpoints.traces
      }
    }
  }
  # Azure may echo endpoints in GET responses; never store them as raw output.
  response_export_values = []
}
