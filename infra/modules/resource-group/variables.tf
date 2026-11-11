variable "location" {
  type        = string
  description = "Azure resource group metadata location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Resource group name."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,88}[a-z0-9]$", var.name))
    error_message = "Use 2–90 lowercase alphanumeric or hyphen characters, ending in alphanumeric."
  }
}

variable "subscription_id" {
  type        = string
  description = "Explicit workload subscription, independent of the state backend."
  nullable    = false
}
