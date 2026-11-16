variable "name" {
  type        = string
  description = "Private project ACR connection name including environment and region."
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,127}$", var.name))
    error_message = "Use 3-128 alphanumeric, underscore or hyphen characters with an alphanumeric start."
  }
}
variable "project_id" {
  type        = string
  description = "Existing project ARM ID; connection stays in the Foundry root's state."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+/projects/[^/]+$", var.project_id))
    error_message = "Supply the full Foundry project ARM ID."
  }
}
variable "project_principal_id" {
  type        = string
  description = "Foundry project's system-assigned principal object UUID for image pulling, distinct from the runtime agent identity."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.project_principal_id))
    error_message = "Supply the actual project system-assigned principal object UUID."
  }
}
variable "registry_id" {
  type        = string
  description = "Existing registry ARM ID from the registry root."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.ContainerRegistry/registries/[^/]+$", var.registry_id))
    error_message = "Supply the full existing ACR ARM ID."
  }
}
variable "registry_login_server" {
  type        = string
  description = "Existing registry login hostname, not a credential or image URI."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*\\.azurecr\\.io$", var.registry_login_server))
    error_message = "Supply the existing ACR login hostname only, without scheme or path."
  }
}