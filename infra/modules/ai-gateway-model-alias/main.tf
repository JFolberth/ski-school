resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/aliases@2025-09-01-preview"
  name      = var.name
  parent_id = var.workspace_id
  # Approved per-resource contract exception; AzAPI's embedded schema lacks this child type.
  # https://github.com/Azure-Samples/ai-gateway-foundry-terraform/blob/main/standalone/ai_gateway_models.tf
  schema_validation_enabled = false
  body = {
    properties = {
      aliasName = var.name
      backendModels = [{
        resourceId = var.model_id
        priority   = 0
        weight     = 100
      }]
    }
  }
}
