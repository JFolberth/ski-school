resource "azapi_resource" "this" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-05-15-preview"
  name      = var.name
  parent_id = var.project_id
  body = {
    properties = {
      authType      = "ApiKey"
      category      = "AppInsights"
      isSharedToAll = false
      target        = var.application_insights_id
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.application_insights_id
      }
    }
  }
  # Approved destination-metadata exception, not runtime key authentication:
  # https://github.com/Azure-Samples/microsoft-foundry-baseline/blob/main/infra-as-code/bicep/ai-foundry-project.bicep
  sensitive_body = {
    properties = {
      credentials = {
        key = var.connection_string
      }
    }
  }
  sensitive_body_version = {
    "properties.credentials.key" = tostring(var.metadata_version)
  }
}
