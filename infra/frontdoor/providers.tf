provider "azapi" {
  subscription_id            = var.subscription_id
  tenant_id                  = var.tenant_id
  skip_provider_registration = true
  default_tags = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
  })
}
