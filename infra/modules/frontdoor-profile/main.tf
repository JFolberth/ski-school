resource "azapi_resource" "this" {
  type      = "Microsoft.Cdn/profiles@2026-10-01"
  name      = var.name
  parent_id = var.resource_group_id
  location  = "global"

  body = {
    sku = {
      name = var.sku_name
    }
    properties = {
      originResponseTimeoutSeconds = var.origin_response_timeout_seconds
    }
  }
}
