variable "account_sku_name" {
  type        = string
  description = "AIServices account SKU, separate from model SKU and capacity. S0 is the verified supported tier."
  default     = "S0"
  nullable    = false
  validation {
    condition     = var.account_sku_name == "S0"
    error_message = "Only S0 is verified for this AIServices account."
  }
}

variable "application_insights" {
  type = object({
    application_type    = optional(string, "web")
    retention_in_days   = optional(number, 30)
    sampling_percentage = optional(number, 100)
  })
  description = "Dedicated Foundry component settings. Native OTLP is linked to the required shared Monitor workspace; runtime sampling/redaction and ingestion identity still require configuration."
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["web", "other"], var.application_insights.application_type) && contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.application_insights.retention_in_days) && var.application_insights.sampling_percentage >= 1 && var.application_insights.sampling_percentage <= 100 && floor(var.application_insights.sampling_percentage) == var.application_insights.sampling_percentage
    error_message = "Use web/other, a supported component retention (30,60,90,120,180,270,365,550,730), and integer sampling 1–100."
  }
}

variable "application_insights_metadata_version" {
  type        = number
  description = "Revision of approved private project destination metadata. Increment after the component ConnectionString is regenerated; not a runtime key-auth toggle."
  default     = 1
  nullable    = false
  validation {
    condition     = var.application_insights_metadata_version >= 1 && floor(var.application_insights_metadata_version) == var.application_insights_metadata_version
    error_message = "Use a positive integer destination metadata revision."
  }
}

variable "base_name" {
  type        = string
  description = "Independent Foundry stem without environment or region; must fit account/project/model naming limits without truncation."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.base_name)) && !can(regex("(^|-)(${var.environment}|ncus|eus2|gbl)(-|$)", var.base_name))
    error_message = "Use lowercase alphanumeric segments separated by single hyphens, without environment or region tokens."
  }
}

variable "diagnostic_log_categories" {
  type        = set(string)
  description = "Account platform logging. Only Audit is approved; sensitive RequestResponse/Trace capture is excluded."
  default     = ["Audit"]
  nullable    = false
  validation {
    condition     = var.diagnostic_log_categories == toset(["Audit"])
    error_message = "Only the verified Audit category is approved; do not enable payload capture."
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

variable "gateway_principals" {
  type        = map(string)
  description = "Existing gateway system-assigned principal UUIDs under explicit stable keys. Populate after gateway identity creation; this root grants only Cognitive Services OpenAI User at the verified account inference scope."
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for principal_id in values(var.gateway_principals) : can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", principal_id))])
    error_message = "Supply actual gateway managed identity principal object UUIDs under stable labels."
  }
}

variable "location" {
  type        = string
  description = "Actual account/project Azure region, not GlobalStandard inference geography. Hosted-agent/model support and quota must be verified before deployment."
  nullable    = false
  validation {
    condition     = var.location == "northcentralus"
    error_message = "Only northcentralus is approved for Foundry."
  }
}

variable "model_capacity" {
  type        = number
  description = "Required explicit approved GlobalStandard SKU capacity. Verify gpt-5.4-mini model-specific quota-unit-to-TPM/RPM mapping; no defensible default has been established."
  nullable    = false
  validation {
    condition     = var.model_capacity >= 1 && floor(var.model_capacity) == var.model_capacity
    error_message = "Supply a positive integer model capacity, after verifying target quota and unit semantics."
  }
}

variable "model_deployment_name" {
  type        = string
  description = "Optional Azure model deployment name override; defaults to gpt-5-4-mini derived from the Foundry base, environment, and region."
  default     = null
  nullable    = true
  validation {
    condition     = var.model_deployment_name == null || can(regex("^[a-z0-9][a-z0-9-]{0,62}[a-z0-9]$", var.model_deployment_name))
    error_message = "Use 2–64 lowercase alphanumeric or hyphen characters for the model deployment name."
  }
}

variable "model_name" {
  type        = string
  description = "Selected Azure OpenAI model; changing models requires a scope decision."
  default     = "gpt-5.4-mini"
  nullable    = false
  validation {
    condition     = var.model_name == "gpt-5.4-mini"
    error_message = "gpt-5.4-mini is the approved model; do not silently substitute."
  }
}

variable "model_sku_name" {
  type        = string
  description = "Approved pay-as-you-go model deployment type, distinct from resource location. No provisioned throughput or key fallback."
  default     = "GlobalStandard"
  nullable    = false
  validation {
    condition     = var.model_sku_name == "GlobalStandard"
    error_message = "Only GlobalStandard global pay-as-you-go inference processing is approved."
  }
}

variable "model_version" {
  type        = string
  description = "Required Azure gpt-5.4-mini version. Official sample candidate is 2026-03-17; confirm target model/version availability before selecting it."
  nullable    = false
  validation {
    condition     = can(regex("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$", var.model_version))
    error_message = "Supply an explicit dated Azure model version."
  }
}

variable "model_version_upgrade_option" {
  type        = string
  description = "Documented Azure model upgrade policy. Default NoAutoUpgrade keeps version selection explicit; retirement still requires review."
  default     = "NoAutoUpgrade"
  nullable    = false
  validation {
    condition     = contains(["NoAutoUpgrade", "OnceCurrentVersionExpired", "OnceNewDefaultVersionAvailable"], var.model_version_upgrade_option)
    error_message = "Use a documented model upgrade policy."
  }
}

variable "monitor_workspace_id" {
  type        = string
  description = "Required Azure Monitor workspace ARM ID from the logging root; enables the approved native OTLP association for this Application Insights component."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Monitor/accounts/[^/]+$", var.monitor_workspace_id))
    error_message = "Supply the explicit shared Azure Monitor workspace ARM ID."
  }
}

variable "project_description" {
  type        = string
  description = "Non-secret human-readable project description."
  default     = "Michigan skiing hosted-agent project."
  nullable    = false
}

variable "project_display_name" {
  type        = string
  description = "Optional human-readable project display name; resource naming remains base-derived."
  default     = null
}

variable "subscription_id" {
  type        = string
  description = "Required workload subscription UUID, not inferred from state storage."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Supply the explicit workload subscription UUID."
  }
}

variable "tags" {
  type        = map(string)
  description = "Non-secret additional tags; environment and managed_by are enforced by the provider."
  default     = {}
  nullable    = false
}

variable "telemetry_publisher_principals" {
  type        = map(string)
  description = "Only verified actual Foundry telemetry emitter principal UUIDs, keyed by stable labels. Grants Monitoring Metrics Publisher on this component only. Project/account attachment alone does not establish a hosted-agent emitter identity; leave empty until verified."
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for principal_id in values(var.telemetry_publisher_principals) : can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", principal_id))])
    error_message = "Supply actual verified telemetry emitter managed identity principal UUIDs."
  }
}

variable "tenant_id" {
  type        = string
  description = "Required workload Entra tenant UUID, independent of backend authentication."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Supply the explicit workload tenant UUID."
  }
}

variable "workspace_id" {
  type        = string
  description = "Explicit centralized workspace ARM ID from the logging root; not a connection string."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.workspace_id))
    error_message = "Supply the explicit Log Analytics workspace ARM ID."
  }
}
