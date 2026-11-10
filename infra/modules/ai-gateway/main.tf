resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways@2026-11-01"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  identity {
    type = "SystemAssigned"
  }
  # Approved AzAPI 2.13.0 schema exception: https://github.com/Azure/azure-rest-api-specs/blob/main/specification/apimanagement/resource-manager/Microsoft.ApiManagement/AIGateway/stable/2026-11-01/openapi.json
  schema_validation_enabled = false
  body = merge(
    { properties = {} },
    var.sku == null ? {} : { sku = { for key, value in var.sku : key => value if value != null } },
  )
  response_export_values = ["properties.frontend.defaultHostname"]
}
