terraform {
  backend "azurerm" {
    # Supply the storage account, container, and root-specific key
    # (ski-school-frontend.tfstate) through backend configuration at init. Separate
    # environment storage accounts isolate state while reusing this key.
    # Standard blob endpoints with OIDC do not require the storage resource
    # group; state storage is separate from the frontend group Terraform creates.
    use_azuread_auth = true
    use_oidc         = true
  }
}
