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
