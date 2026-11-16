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
