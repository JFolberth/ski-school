resource "azapi_resource" "this" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-09-15-preview"
  name                      = var.name
  parent_id                 = var.project_id
  schema_validation_enabled = true
  body = {
    properties = {
      authType      = "None"
      category      = "OpenAPI"
      isSharedToAll = false
      metadata = {
        type = "openapi"
      }
      target = var.target
    }
  }
}
