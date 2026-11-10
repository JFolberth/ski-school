resource "azapi_resource" "this" {
  type      = "Microsoft.CognitiveServices/accounts/projects@2026-05-15-preview"
  name      = var.name
  parent_id = var.account_id
  location  = var.location
  identity {
    type = "SystemAssigned"
  }
  body = {
    properties = {
      displayName = coalesce(var.display_name, var.name)
      description = var.description
    }
  }
}
