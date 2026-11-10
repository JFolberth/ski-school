variable "location" {
  type        = string
  description = "Explicit preview-supported Azure region; no automatic regional fallback."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Gateway name. Prefix aig is locally proposed, not an official CAF abbreviation."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,22}[a-z0-9]$", var.name))
    error_message = "Gateway names must be 3–24 lowercase alphanumeric or hyphen characters with alphanumeric ends; shorten base_name explicitly."
  }
}

variable "resource_group_id" {
  type        = string
  description = "Owning gateway resource group ARM ID."
  nullable    = false
}

variable "sku" {
  type = object({
    name     = string
    tier     = optional(string)
    capacity = optional(number)
  })
  description = "Optional SKU only after target-service verification. Omitted by default; generic ARM SKU fields do not establish an offering or capacity requirement."
  default     = null
  validation {
    condition     = var.sku == null ? true : length(trimspace(var.sku.name)) > 0 && (var.sku.capacity == null ? true : var.sku.capacity >= 1 && floor(var.sku.capacity) == var.sku.capacity)
    error_message = "If specifying a verified SKU, provide its name and an integer capacity of at least one when applicable."
  }
}
