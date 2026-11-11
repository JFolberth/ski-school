variable "account_id" {
  type        = string
  description = "Explicit Foundry account ARM ID; upstream authorization is owned separately by the Foundry root."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+$", var.account_id))
    error_message = "Supply a Foundry account ARM ID."
  }
}

variable "endpoint" {
  type        = string
  description = "Actual Foundry account endpoint; no credentials, query strings or fabricated hostname."
  nullable    = false
  validation {
    condition     = can(regex("^https://[a-zA-Z0-9.-]+/?$", var.endpoint))
    error_message = "Supply the service-returned HTTPS account origin."
  }
}

variable "name" {
  type        = string
  description = "Gateway provider resource/display name."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Provider names must be 3–63 lowercase alphanumeric or hyphen characters with alphanumeric ends."
  }
}

variable "workspace_id" {
  type        = string
  description = "Existing service-created gateway default workspace ARM ID; this module does not take ownership of it."
  nullable    = false
}
