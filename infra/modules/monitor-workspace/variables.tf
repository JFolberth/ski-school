variable "location" {
  type        = string
  description = "Actual Azure Monitor workspace location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Azure Monitor workspace name; amw is a locally proposed prefix, not a listed CAF abbreviation."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,258}[a-z0-9]$", var.name))
    error_message = "Use 2–260 lowercase alphanumeric or hyphen characters with alphanumeric ends."
  }
}

variable "resource_context_access" {
  type        = bool
  description = "Enable metric query access based on source-resource permissions instead of workspace-wide grants."
  default     = true
  nullable    = false
}

variable "resource_group_id" {
  type        = string
  description = "Logging/monitoring resource group ARM ID. The workspace shares the logging root's state."
  nullable    = false
}
