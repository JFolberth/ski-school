resource "azapi_resource" "this" {
  type      = "Microsoft.CognitiveServices/accounts@2026-05-15-preview"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  identity {
    type = "SystemAssigned"
  }
  body = {
    kind = "AIServices"
    sku  = { name = var.sku_name }
    properties = {
      allowProjectManagement    = true
      customSubDomainName       = var.name
      disableLocalAuth          = true
      publicNetworkAccess       = "Enabled"
      storedCompletionsDisabled = true
    }
  }
  response_export_values = ["properties.endpoint"]
}
