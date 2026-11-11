variable "location" {
  type        = string
  description = "Workspace Azure location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Workspace name, including environment and region."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,61}[a-z0-9]$", var.name))
    error_message = "Workspace names must be 4–63 lowercase alphanumeric or hyphen characters."
  }
}

variable "resource_group_id" {
  type        = string
  description = "Owning resource group ARM ID."
  nullable    = false
}

variable "retention_in_days" {
  type        = number
  description = "Workspace default Analytics retention. Application Insights, Usage and AzureActivity tables can have independent 90-day defaults."
  default     = 30
  nullable    = false
  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730 && floor(var.retention_in_days) == var.retention_in_days
    error_message = "Workspace retention must be an integer from 30 through 730 days."
  }
}

variable "sku_name" {
  type        = string
  description = "Workspace billing SKU. Only pay-as-you-go is approved; commitment capacity requires a separate cost decision."
  default     = "PerGB2018"
  nullable    = false
  validation {
    condition     = var.sku_name == "PerGB2018"
    error_message = "Only the approved PerGB2018 pay-as-you-go workspace SKU is supported by this configuration."
  }
}
