variable "application_insights" {
  type = object({
    application_type    = optional(string, "web")
    retention_in_days   = optional(number, 30)
    sampling_percentage = optional(number, 100)
  })
  description = "Dedicated Application Insights settings, used only when native OTLP is enabled; DCR/endpoints arrive asynchronously."
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["web", "other"], var.application_insights.application_type) && contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.application_insights.retention_in_days) && var.application_insights.sampling_percentage >= 1 && var.application_insights.sampling_percentage <= 100 && floor(var.application_insights.sampling_percentage) == var.application_insights.sampling_percentage
    error_message = "Use web/other, a supported component retention (30,60,90,120,180,270,365,550,730), and integer sampling 1–100."
  }
}

variable "base_name" {
  type        = string
  description = "Independent short gateway stem, maximum 11 characters for aig-<base>-<env>-<region> (24 total). aig is a proposed local prefix, not CAF."
  nullable    = false
  validation {
    condition     = length(var.base_name) <= 11 && can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.base_name)) && !can(regex("(^|-)(${var.environment}|ncus|eus2|swc|gbl)(-|$)", var.base_name))
    error_message = "Use a 1–11 character lowercase alphanumeric/hyphen stem without environment or region tokens; no silent truncation."
  }
}

variable "environment" {
  type        = string
  description = "Three-letter environment selected explicitly with a root-local variable file and matching isolated backend key."
  default     = "dev"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{3}$", var.environment))
    error_message = "Environment must be exactly three lowercase letters."
  }
}

variable "gateway_sku" {
  type = object({
    name     = string
    tier     = optional(string)
    capacity = optional(number)
  })
  description = "Optional target-verified gateway SKU; null omits SKU. No offering or capacity requirement is inferred from generic ARM fields."
  default     = null
  validation {
    condition     = var.gateway_sku == null ? true : length(trimspace(var.gateway_sku.name)) > 0 && (var.gateway_sku.capacity == null ? true : var.gateway_sku.capacity >= 1 && floor(var.gateway_sku.capacity) == var.gateway_sku.capacity)
    error_message = "Provide a verified SKU name and, if needed, a positive integer capacity."
  }
}

variable "location" {
  type        = string
  description = "AI Gateway public-preview region; dev selects East US 2. Never auto-fail over."
  nullable    = false
  validation {
    condition     = contains(["eastus2", "swedencentral"], var.location)
    error_message = "AI Gateway public preview is currently supported in eastus2 and swedencentral."
  }
}

variable "model_backend" {
  type = object({
    account_id          = string
    deployment_id       = string
    endpoint            = string
    model_version       = string
    supported_endpoints = optional(set(string), ["/openai/v1/responses"])
  })
  description = "Staged Foundry gateway_backend output handoff. Null creates gateway identity first; populate after the Foundry root grants that principal upstream inference access. This enables one provider/model/alias without a direct project bypass."
  default     = null
  validation {
    condition     = var.model_backend == null ? true : startswith(lower(var.model_backend.deployment_id), "${lower(var.model_backend.account_id)}/deployments/")
    error_message = "The backend deployment must belong to the explicitly supplied Foundry account."
  }
}

variable "model_callers" {
  type        = map(string)
  description = "Explicit caller managed-identity principal UUIDs keyed by stable labels (for example project). Grants AI Gateway Models User at this root's alias only; does not create a Foundry project model connection."
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for principal_id in values(var.model_callers) : can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", principal_id))]) && (length(var.model_callers) == 0 || var.model_backend != null)
    error_message = "Supply actual principal UUIDs under explicit stable keys; an alias/backend must be configured before caller grants."
  }
}

variable "monitor_workspace_id" {
  type        = string
  description = "Azure Monitor workspace ARM ID from the logging root; required only when native OTLP is enabled."
  default     = null
  validation {
    condition     = var.monitor_workspace_id == null ? !var.native_otlp_enabled : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Monitor/accounts/[^/]+$", var.monitor_workspace_id))
    error_message = "Supply a valid Azure Monitor workspace ARM ID when native OTLP is enabled."
  }
}

variable "native_otlp_enabled" {
  type        = bool
  description = "Opt in to native OTLP only after the Log Analytics and Azure Monitor workspaces are verified for the same-region ingestion design."
  default     = false
  nullable    = false
}

variable "subscription_id" {
  type        = string
  description = "Required workload subscription UUID, independent of backend coordinates."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Supply the explicit workload subscription UUID."
  }
}

variable "tags" {
  type        = map(string)
  description = "Non-secret additional tags; environment and managed_by are provider-enforced."
  default     = {}
  nullable    = false
}

variable "telemetry_exporter" {
  type = object({
    data_collection_rule_id = string
    endpoints = object({
      logs    = string
      metrics = string
      traces  = string
    })
  })
  description = "Later-stage exact gateway application_insights_otlp output after all metadata is non-null. This root owns the publisher assignment on that service-created component DCR, not the DCR/managed RG. Requires narrow roleAssignments/write there; no scripts, fabricated endpoints or default Monitor DCR."
  default     = null
  validation {
    condition     = var.telemetry_exporter == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Insights/dataCollectionRules/[^/]+$", var.telemetry_exporter.data_collection_rule_id))
    error_message = "Supply the actual component OTLP data collection rule ARM ID."
  }
  validation {
    condition = var.telemetry_exporter == null ? true : (
      var.native_otlp_enabled &&
      try(module.application_insights[0].otlp.data_collection_rule_id, null) != null &&
      var.telemetry_exporter.data_collection_rule_id == try(module.application_insights[0].otlp.data_collection_rule_id, null) &&
      var.telemetry_exporter.endpoints.logs == try(module.application_insights[0].otlp.endpoints.logs, null) &&
      var.telemetry_exporter.endpoints.metrics == try(module.application_insights[0].otlp.endpoints.metrics, null) &&
      var.telemetry_exporter.endpoints.traces == try(module.application_insights[0].otlp.endpoints.traces, null)
    )
    error_message = "Enable native OTLP with a region-compatible workspace pair, then supply this component's actual non-null DCR and signal endpoints in a separately approved stage."
  }
}

variable "tenant_id" {
  type        = string
  description = "Required workload tenant UUID, independent of backend authentication."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Supply the explicit workload tenant UUID."
  }
}

variable "workspace_id" {
  type        = string
  description = "Log Analytics workspace ARM ID from the logging root; required only when native OTLP is enabled."
  default     = null
  validation {
    condition     = var.workspace_id == null ? !var.native_otlp_enabled : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.workspace_id))
    error_message = "Supply a valid Log Analytics workspace ARM ID when native OTLP is enabled."
  }
}
