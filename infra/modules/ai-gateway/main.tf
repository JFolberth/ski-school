resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways@2025-09-01-preview"
  name      = var.name
  parent_id = var.resource_group_id
  location  = var.location
  identity {
    type = "SystemAssigned"
  }
  # Approved contract-specific schema exception:
  # https://github.com/Azure-Samples/ai-gateway-foundry-terraform/blob/main/standalone/ai_gateway.tf
  schema_validation_enabled = false
  body = merge(
    { properties = {} },
    var.sku == null ? {} : { sku = { for key, value in var.sku : key => value if value != null } },
  )
  response_export_values = ["properties.frontend.defaultHostname"]
}
