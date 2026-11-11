resource "azapi_resource" "this" {
  type      = "Microsoft.CognitiveServices/accounts/deployments@2026-05-15-preview"
  name      = var.name
  parent_id = var.account_id
  body = {
    sku = {
      name     = var.sku_name
      capacity = var.capacity
    }
    properties = {
      model = {
        format  = "OpenAI"
        name    = var.model_name
        version = var.model_version
      }
      versionUpgradeOption = var.version_upgrade_option
    }
  }
  response_export_values = ["properties.model.version"]
  # GlobalStandard describes inference processing, not the account's resource location.
}
