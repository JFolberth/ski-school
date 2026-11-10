resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/modelProviders/models@2026-11-01"
  name      = var.name
  parent_id = var.provider_id
  # Approved AzAPI 2.13.0 schema exception: https://github.com/Azure/azure-rest-api-specs/blob/main/specification/apimanagement/resource-manager/Microsoft.ApiManagement/AIGateway/stable/2026-11-01/openapi.json
  schema_validation_enabled = false
  body = {
    properties = {
      name               = var.name
      supportedEndpoints = sort(tolist(var.supported_endpoints))
      deployment = {
        resourceId   = var.deployment_id
        modelName    = reverse(split("/", var.deployment_id))[0]
        modelVersion = var.model_version
      }
    }
  }
}
