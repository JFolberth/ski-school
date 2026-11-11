variable "account_id" {
  type        = string
  description = "Parent Foundry account ARM ID."
  nullable    = false
}

variable "description" {
  type        = string
  description = "Human-readable project description, containing no secrets."
  default     = "Foundry hosted-agent project."
  nullable    = false
}

variable "display_name" {
  type        = string
  description = "Optional project display name; defaults to the resource name."
  default     = null
}

variable "location" {
  type        = string
  description = "Parent account's Azure location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Base-derived project name with environment and parent-region suffix."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,62}[a-z0-9]$", var.name))
    error_message = "Project names must be 2–64 lowercase alphanumeric or hyphen characters."
  }
}
