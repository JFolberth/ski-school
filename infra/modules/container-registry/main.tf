resource "azapi_resource" "this" {
  type      = "Microsoft.ContainerRegistry/registries@2026-03-01-preview"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  body = {
    sku = { name = var.sku_name }
    properties = {
      adminUserEnabled     = false
      anonymousPullEnabled = false
      publicNetworkAccess  = "Enabled"
      roleAssignmentMode   = "LegacyRegistryPermissions"
           # Required by Foundry image pulling with ARM-audience Entra tokens.
      policies = {
        azureADAuthenticationAsArmPolicy = { status = "enabled" }
      }
    }
  }
  response_export_values = ["properties.loginServer", "properties.roleAssignmentMode"]
}
