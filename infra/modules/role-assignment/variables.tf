variable "condition" {
  type        = string
  description = "Optional reviewed Azure ABAC expression; null preserves existing unconditional assignments. Condition syntax is fixed at 2.0."
  default     = null
  validation {
    condition     = var.condition == null ? true : length(trimspace(var.condition)) > 0
    error_message = "Use null or a nonempty reviewed ABAC expression."
  }
}

variable "principal_id" {
  type        = string
  description = "User or service principal object UUID, including a Foundry agent instance identity; never an application/client ID."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.principal_id))
    error_message = "Supply the actual principal object UUID."
  }
}

variable "principal_type" {
  type        = string
  description = "Azure RBAC principal type. Existing workload assignments default to ServicePrincipal."
  default     = "ServicePrincipal"
  nullable    = false
  validation {
    condition     = contains(["ServicePrincipal", "User"], var.principal_type)
    error_message = "Use ServicePrincipal or User."
  }
}

variable "role_definition_id" {
  type        = string
  description = "Verified fully qualified role definition ARM ID, selected by the scope-owning root."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/providers/Microsoft\\.Authorization/roleDefinitions/[0-9a-f-]{36}$", var.role_definition_id))
    error_message = "Supply a subscription-qualified role definition ARM ID."
  }
}

variable "scope_id" {
  type        = string
  description = "Narrowest verified resource scope. The invoking root owns only this assignment, not externally service-managed scopes."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/[^/]+/.+$", var.scope_id))
    error_message = "Use an explicit resource scope, not a subscription or resource-group-wide grant."
  }
}
