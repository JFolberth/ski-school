variable "application_type" {
  type        = string
  description = "Application Insights application type."
  default     = "web"
  nullable    = false
  validation {
    condition     = contains(["web", "other"], var.application_type)
    error_message = "Application type must be web or other."
  }
}

variable "export_connection_metadata" {
  type        = bool
  description = "Read the destination connection string only for the approved private Foundry association; not needed by gateway native OTLP."
  default     = false
  nullable    = false
}

variable "gateway_otlp_schema_exception" {
  type        = bool
  description = "Approved only for the gateway-owned OTLP component's 2020-02-02 contract; other callers must leave this false."
  default     = false
  nullable    = false
  validation {
    condition     = !var.gateway_otlp_schema_exception || var.native_otlp != null
    error_message = "The gateway OTLP schema exception requires native OTLP to be enabled."
  }
}

variable "location" {
  type        = string
  description = "Component Azure location, independent of workspace location."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Application Insights component name."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,258}[a-z0-9]$", var.name))
    error_message = "Use 2–260 lowercase alphanumeric or hyphen characters."
  }
}

variable "native_otlp" {
  type = object({
    monitor_workspace_id = string
  })
  description = "Explicit native OTLP opt-in linked to the shared Microsoft.Monitor/accounts ID; null declines opt-in. Enabling cannot subsequently be undone. DCR/endpoints are asynchronous service metadata."
  default     = null
  validation {
    condition     = var.native_otlp == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Monitor/accounts/[^/]+$", var.native_otlp.monitor_workspace_id))
    error_message = "Native OTLP requires the explicit shared Azure Monitor workspace ARM ID; no replacement workspace is created implicitly."
  }
}

variable "resource_group_id" {
  type        = string
  description = "Owning service resource group ARM ID."
  nullable    = false
}

variable "retention_in_days" {
  type        = number
  description = "Component retention setting; workspace-based table retention is authoritative and may differ."
  default     = 30
  nullable    = false
  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.retention_in_days)
    error_message = "Choose a supported component retention: 30, 60, 90, 120, 180, 270, 365, 550 or 730 days."
  }
}

variable "sampling_percentage" {
  type        = number
  description = "Component sampling percentage. This does not replace later SDK/OpenTelemetry sampling and payload redaction configuration."
  default     = 100
  nullable    = false
  validation {
    condition     = var.sampling_percentage >= 1 && var.sampling_percentage <= 100 && floor(var.sampling_percentage) == var.sampling_percentage
    error_message = "Sampling percentage must be an integer from 1 to 100."
  }
}

variable "workspace_id" {
  type        = string
  description = "Explicit shared Log Analytics workspace ARM ID."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.workspace_id))
    error_message = "Supply a Log Analytics workspace ARM resource ID."
  }
}
