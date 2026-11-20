variable "name" {
  description = "Front Door profile name."
  type        = string
  nullable    = false
}

variable "origin_response_timeout_seconds" {
  description = "Origin response timeout in seconds."
  type        = number
  nullable    = false
  validation {
    condition     = var.origin_response_timeout_seconds >= 16 && var.origin_response_timeout_seconds <= 240 && floor(var.origin_response_timeout_seconds) == var.origin_response_timeout_seconds
    error_message = "The origin timeout must be an integer from 16 to 240 seconds."
  }
}

variable "resource_group_id" {
  description = "Resource ID of the owning resource group."
  type        = string
  nullable    = false
}

variable "sku_name" {
  description = "Approved Front Door SKU."
  type        = string
  nullable    = false
  validation {
    condition     = var.sku_name == "Standard_AzureFrontDoor"
    error_message = "Only Standard_AzureFrontDoor is approved."
  }
}
