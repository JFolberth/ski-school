resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/aliases@2026-11-01"
  name      = var.name
  parent_id = var.workspace_id
  # Approved AzAPI 2.13.0 schema exception: https://github.com/Azure/azure-rest-api-specs/blob/main/specification/apimanagement/resource-manager/Microsoft.ApiManagement/AIGateway/stable/2026-11-01/openapi.json
  schema_validation_enabled = false
  body = {
    properties = {
      aliasName = var.name
      backendModels = [{
        resourceId = var.model_id
        priority   = 0
        weight     = 1
      }]
    }
  }
}
