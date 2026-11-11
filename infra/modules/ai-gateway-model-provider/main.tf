resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/modelProviders@2025-09-01-preview"
  name      = var.name
  parent_id = var.workspace_id
  # Approved per-resource contract exception; AzAPI's embedded schema lacks this child type.
  # https://github.com/Azure-Samples/ai-gateway-foundry-terraform/blob/main/standalone/ai_gateway.tf
  schema_validation_enabled = false
  body = {
    properties = {
      kind        = "Foundry"
      displayName = var.name
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
