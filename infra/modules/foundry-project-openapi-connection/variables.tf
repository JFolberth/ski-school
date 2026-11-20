variable "name" {
  type        = string
  description = "OpenAPI project connection name."
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,32}$", var.name))
    error_message = "Connection names must be 3–33 alphanumeric, underscore or hyphen characters with an alphanumeric start."
  }
}

variable "project_id" {
  type        = string
  description = "Owning Foundry project ARM ID; the connection is private to this project."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+/projects/[^/]+$", var.project_id))
    error_message = "Supply the full Foundry project ARM ID."
  }
}

variable "target" {
  type        = string
  description = "HTTPS base URL of the anonymous OpenAPI target."
  nullable    = false
  validation {
    condition     = can(regex("^https://[a-zA-Z0-9.-]+/?$", var.target))
    error_message = "Target must be an HTTPS host URL without credentials, query, or fragment."
  }
}
