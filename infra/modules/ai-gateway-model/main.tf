resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/modelProviders/models@2025-09-01-preview"
  name      = var.name
  parent_id = var.provider_id
  # Approved per-resource contract exception; AzAPI's embedded schema lacks this child type.
  # https://github.com/Azure-Samples/ai-gateway-foundry-terraform/blob/main/standalone/ai_gateway_models.tf
  schema_validation_enabled = false
  body = {
    properties = {
      displayName        = var.name
      apiFormat          = "OpenAIChatCompletions"
      supportedEndpoints = sort(tolist(var.supported_endpoints))
      deployment = {
        resourceId   = var.deployment_id
        modelName    = reverse(split("/", var.deployment_id))[0]
        modelVersion = var.model_version
      }
    }
  }
}
