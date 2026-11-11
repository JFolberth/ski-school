terraform {
  backend "azurerm" {
    # Storage account, container, and resource group are supplied through
    # approved partial backend configuration at init time. This state key is
    # isolated to the frontend development root.
    key              = "frontend/dev/terraform.tfstate"
    use_azuread_auth = true
    use_oidc         = true
  }
}
