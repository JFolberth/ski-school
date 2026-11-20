resource "azapi_resource" "this" {
  type      = "Microsoft.Cdn/profiles/afdEndpoints@2026-10-01"
  name      = var.name
  parent_id = var.profile_id
  location  = "global"

  body = {
    properties = {
      enabledState = "Enabled"
    }
  }
  response_export_values = ["properties.hostName"]
}
