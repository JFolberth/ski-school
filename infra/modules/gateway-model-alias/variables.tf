variable "model_id" {
  type        = string
  description = "Single gateway backend-model ARM ID; not the upstream Foundry deployment."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Stable alias resource name and client-facing routing name."
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]+$", var.name))
    error_message = "Alias names may contain only alphanumeric, underscore, period and hyphen characters."
  }
}

variable "workspace_id" {
  type        = string
  description = "Service-created gateway default workspace ARM ID."
  nullable    = false
}
