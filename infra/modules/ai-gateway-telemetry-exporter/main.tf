resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/telemetryExporters@2026-11-01"
  name      = var.name
  parent_id = var.workspace_id
  # Per-resource schema-validation exception; Azure validates against the documented API contract.
  # https://learn.microsoft.com/en-us/rest/api/aigateway/ai-gateway-telemetry-exporter-resources/create-or-update?view=rest-aigateway-2026-11-01
  schema_validation_enabled = false
  body = {
    properties = {
      telemetryExporterType = "OpenTelemetry"
      payloadCapture        = false
      authentication = {
        managedIdentity = {
          resource = "https://monitor.azure.com/"
        }
      }
      telemetry = {
        attributes = [
          {
            source = {
              kind  = "claims"
              value = "oid"
            }
            signals = ["logs", "traces", "metrics"]
          }
        ]
      }
    }
  }
  # Keep destination URLs in the sensitive body and export no API response fields.
  sensitive_body = {
    properties = {
      openTelemetry = {
        metricsEndpoint = {
          url = var.endpoints.metrics
        }
        logsEndpoint = {
          url = var.endpoints.logs
        }
        tracesEndpoint = {
          url = var.endpoints.traces
        }
      }
    }
  }
  # Without a version map AzAPI tracks a private hash and sends all write-only
  # fields on each create/update, including updates to unrelated body fields.
  # https://github.com/Azure/terraform-provider-azapi/blob/v2.13.0/docs/guides/feature_ephemeral_resource.md
  response_export_values = []
}
