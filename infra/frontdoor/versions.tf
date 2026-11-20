terraform {
  required_version = ">= 1.11.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.14.0, < 3.0.0"
    }
  }
}
