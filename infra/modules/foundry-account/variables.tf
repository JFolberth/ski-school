variable "location" {
  type        = string
  description = "Foundry account Azure location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Foundry account name and unique Entra-enabled custom subdomain."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.name))
    error_message = "Use 2–63 lowercase alphanumeric or hyphen characters, with alphanumeric ends (also safe for DNS)."
  }
}

variable "resource_group_id" {
  type        = string
  description = "Owning resource group ARM ID."
  nullable    = false
}

variable "sku_name" {
  type        = string
  description = "Foundry AIServices account SKU; S0 is the verified applicable tier, distinct from model deployment capacity."
  default     = "S0"
  nullable    = false
  validation {
    condition     = var.sku_name == "S0"
    error_message = "Only S0 is verified for this AIServices account configuration."
  }
}
