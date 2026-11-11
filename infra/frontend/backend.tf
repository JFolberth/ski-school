terraform {
  backend "azurerm" {
    # Supply the storage account, container, resource group, and
    # environment-specific state key through backend configuration at init.
    use_azuread_auth = true
    use_oidc         = true
  }
}
