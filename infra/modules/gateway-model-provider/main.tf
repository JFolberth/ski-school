resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/modelProviders@2026-11-01"
  name      = var.name
  parent_id = var.workspace_id
  # Approved AzAPI 2.13.0 schema exception: https://github.com/Azure/azure-rest-api-specs/blob/main/specification/apimanagement/resource-manager/Microsoft.ApiManagement/AIGateway/stable/2026-11-01/openapi.json
  schema_validation_enabled = false
  body = {
    properties = {
      kind = "Foundry"
      name = var.name
      foundry = {
        endpoint    = "${trimsuffix(var.endpoint, "/")}/"
        resourceIds = [var.account_id]
        authentication = {
          kind = "ManagedIdentity"
          managedIdentity = {
            resource = "https://cognitiveservices.azure.com/"
          }
        }
      }
    }
  }
}
