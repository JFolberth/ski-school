variable "disabled_log_categories" {
  type        = list(string)
  description = "Verified log categories to explicitly disable, in the source service's normalized response order. When supplied, log entries include normalized null categoryGroup and disabled retention."
  default     = []
  nullable    = false
  validation {
    condition     = length(distinct(var.disabled_log_categories)) == length(var.disabled_log_categories) && length(setintersection(toset(var.disabled_log_categories), var.log_categories)) == 0
    error_message = "Disabled log categories must be unique and cannot also be enabled."
  }
}

variable "disabled_metric_categories" {
  type        = set(string)
  description = "Verified metric categories to explicitly disable, including when transitioning from enabled collection."
  default     = []
  nullable    = false
  validation {
    condition     = length(setintersection(var.disabled_metric_categories, var.metric_categories)) == 0
    error_message = "A metric category cannot be both enabled and disabled."
  }
}

variable "log_categories" {
  type        = set(string)
  description = "Only verified, explicitly selected categories; never allLogs or sensitive RequestResponse/Trace capture."
  default     = []
  nullable    = false
  validation {
    condition     = length(setintersection(var.log_categories, toset(["RequestResponse", "Trace", "allLogs"]))) == 0
    error_message = "Sensitive payload and unrestricted log capture are not approved."
  }
}

variable "metric_categories" {
  type        = set(string)
  description = "Verified exportable metric categories for this source."
  default     = []
  nullable    = false
}

variable "name" {
  type        = string
  description = "Diagnostic setting name derived from source-root naming."
  nullable    = false
}

variable "resource_id" {
  type        = string
  description = "Source resource ARM ID; its root owns this diagnostic setting."
  nullable    = false
}

variable "workspace_id" {
  type        = string
  description = "Explicit shared workspace ARM ID."
  nullable    = false
}
