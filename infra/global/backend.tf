terraform {
  backend "azurerm" {
    # Supply the isolated environment storage account, container and
    # ski-school-global.tfstate key separately during approved initialization.
    use_azuread_auth = true
    use_oidc         = true
  }
}
