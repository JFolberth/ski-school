resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways@2026-11-01"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  identity {
    type = "SystemAssigned"
  }
  # Approved contract-specific schema exception; AzAPI lacks the 2026-11-01 schema.
  # https://learn.microsoft.com/en-us/rest/api/aigateway/ai-gateway-resources/create-or-update?view=rest-aigateway-2026-11-01
  schema_validation_enabled = false
  body = merge(
    { properties = {} },
    var.sku == null ? {} : { sku = { for key, value in var.sku : key => value if value != null } },
  )
  response_export_values = ["properties.frontend.defaultHostname"]
}
