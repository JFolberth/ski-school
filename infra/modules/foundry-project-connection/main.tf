resource "azapi_resource" "this" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-05-15-preview"
  name      = var.name
  parent_id = var.project_id
  # Approved for this contract: AzAPI's schema omits ProjectManagedIdentity.
  # Microsoft sample: https://github.com/Azure-Samples/simple-foundry-hosted-agent-python-aigateway/blob/main/infra/foundry-agents/main.bicep
  # Auth type: https://github.com/Azure/azure-rest-api-specs/blob/main/specification/cognitiveservices/resource-manager/Microsoft.CognitiveServices/CognitiveServices/models.tsp
  schema_validation_enabled = false
  body = {
    properties = {
      authType      = "ProjectManagedIdentity"
      category      = "AppInsights"
      isSharedToAll = false
      target        = var.application_insights_id
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.application_insights_id
      }
    }
  }
  sensitive_body = {
    properties = {
      metadata = {
        ApplicationInsightsConnectionString = var.connection_string
      }
    }
  }
  sensitive_body_version = {
    "properties.metadata.ApplicationInsightsConnectionString" = tostring(var.metadata_version)
  }
}
