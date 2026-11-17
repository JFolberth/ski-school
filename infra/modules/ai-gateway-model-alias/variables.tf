variable "auto_model_selection" {
  type = object({
    objective = string
  })
  description = "Optional auto-selection objective; null keeps priority-only routing."
  default     = null
  validation {
    condition     = var.auto_model_selection == null || var.auto_model_selection.objective == "Balanced"
    error_message = "Only the officially verified Balanced selection objective is supported."
  }
}

variable "backend_models" {
  type = list(object({
    resource_id         = string
    selector_model_name = optional(string)
    priority            = optional(number, 0)
    weight              = optional(number, 100)
  }))
  description = "Optional complete backend set. When omitted, the legacy single model_id input is used."
  default     = []
  nullable    = false
  validation {
    condition = (
      length(var.backend_models) == length(toset([for backend in var.backend_models : lower(backend.resource_id)])) &&
      alltrue([
        for backend in var.backend_models :
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.ApiManagement/aigateways/[^/]+/workspaces/[^/]+/modelProviders/[^/]+/models/[^/]+$", backend.resource_id)) &&
        backend.priority >= 0 &&
        floor(backend.priority) == backend.priority &&
        backend.weight >= 1 &&
        backend.weight <= 100 &&
        floor(backend.weight) == backend.weight
      ])
    )
    error_message = "Backend IDs must be unique gateway model ARM IDs with nonnegative integer priorities and integer weights from 1 to 100."
  }
  validation {
    condition = var.auto_model_selection == null ? true : (
      length(var.backend_models) >= 2 &&
      alltrue([for backend in var.backend_models : try(length(trimspace(backend.selector_model_name)) > 0, false)]) &&
      length(toset([for backend in var.backend_models : try(lower(backend.selector_model_name), "")])) == length(var.backend_models)
    )
    error_message = "Balanced selection requires at least two backends with unique, nonempty canonical selector model names."
  }
}

variable "model_id" {
  type        = string
  description = "Legacy single gateway backend-model ARM ID; use backend_models for multi-model routing."
  default     = null
  nullable    = true
  validation {
    condition     = var.model_id == null || can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.ApiManagement/aigateways/[^/]+/workspaces/[^/]+/modelProviders/[^/]+/models/[^/]+$", var.model_id))
    error_message = "Supply a gateway backend-model ARM ID."
  }
  validation {
    condition     = (var.model_id == null) != (length(var.backend_models) == 0)
    error_message = "Supply either the legacy model_id or a nonempty backend_models list, but not both."
  }
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

variable "policy_limits" {
  type = object({
    requests_per_minute = number
    tokens_per_minute   = number
    monthly_cost_usd    = number
  })
  description = "Per-identity alias limits; cost is an estimate, not a billing cap."
  nullable    = false
  validation {
    condition     = var.policy_limits.requests_per_minute > 0 && var.policy_limits.requests_per_minute <= 2147483647 && floor(var.policy_limits.requests_per_minute) == var.policy_limits.requests_per_minute && var.policy_limits.tokens_per_minute > 0 && var.policy_limits.tokens_per_minute <= 2147483647 && floor(var.policy_limits.tokens_per_minute) == var.policy_limits.tokens_per_minute && var.policy_limits.monthly_cost_usd > 0
    error_message = "Request and token limits must be positive 32-bit integers; the estimated cost limit must be positive."
  }
}

variable "workspace_id" {
  type        = string
  description = "Service-created gateway default workspace ARM ID."
  nullable    = false
}
