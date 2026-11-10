resource "azapi_resource" "this" {
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  name      = var.name
  parent_id = "/subscriptions/${var.subscription_id}"
  location  = var.location
}
