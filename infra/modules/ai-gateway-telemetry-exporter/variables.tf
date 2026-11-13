variable "application_insights_id" {
  type        = string
  description = "Dedicated gateway Application Insights component ARM ID."
  nullable    = false
}

variable "endpoints" {
  type = object({
    logs    = string
    metrics = string
    traces  = string
  })
  description = "Actual full service-returned OTLP signal URLs, including their paths; no constructed defaults, credentials or query strings."
  nullable    = false
  sensitive   = true
  validation {
    condition     = alltrue([for endpoint in values(var.endpoints) : can(regex("^https://[a-zA-Z0-9.-]+/[^?#[:space:]]+$", endpoint))])
    error_message = "Provide actual full HTTPS OTLP signal URLs without credentials, query strings or fragments."
  }
}

variable "name" {
  type        = string
  description = "Telemetry exporter resource name."
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.name))
    error_message = "Exporter names may contain only alphanumeric, underscore and hyphen characters."
  }
}

variable "workspace_id" {
  type        = string
  description = "Service-created gateway default workspace ARM ID."
  nullable    = false
}
