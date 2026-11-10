variable "location" {
  type        = string
  description = "Registry Azure location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Globally unique alphanumeric registry name; no truncation."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]{5,50}$", var.name))
    error_message = "ACR names must be 5–50 lowercase alphanumeric characters."
  }
}

variable "resource_group_id" {
  type        = string
  description = "Owning resource group ARM ID."
  nullable    = false
}

variable "sku_name" {
  type        = string
  description = "ACR service tier; Basic is the cost-conscious development default. No extra Premium resources/features are enabled."
  default     = "Basic"
  nullable    = false
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "Select Basic, Standard or Premium; legacy Classic is not supported."
  }
}
