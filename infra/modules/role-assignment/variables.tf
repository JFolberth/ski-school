variable "principal_id" {
  type        = string
  description = "Explicit existing managed-identity service principal object UUID; never an application/client ID."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.principal_id))
    error_message = "Supply the actual managed identity principal object UUID."
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
