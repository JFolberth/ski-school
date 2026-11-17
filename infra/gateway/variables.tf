variable "alias_policy_limits" {
  type = object({
    requests_per_minute = optional(number, 30)
    tokens_per_minute   = optional(number, 30000)
    monthly_cost_usd    = optional(number, 10)
  })
  description = "Per-identity alias limits; the monthly USD allowance is estimated, not a billing cap."
  default     = {}
  nullable    = false
  validation {
    condition     = var.alias_policy_limits.requests_per_minute > 0 && var.alias_policy_limits.requests_per_minute <= 2147483647 && floor(var.alias_policy_limits.requests_per_minute) == var.alias_policy_limits.requests_per_minute && var.alias_policy_limits.tokens_per_minute > 0 && var.alias_policy_limits.tokens_per_minute <= 2147483647 && floor(var.alias_policy_limits.tokens_per_minute) == var.alias_policy_limits.tokens_per_minute && var.alias_policy_limits.monthly_cost_usd > 0
    error_message = "Request and token limits must be positive 32-bit integers; the estimated cost limit must be positive."
  }
}

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

variable "auto_model_selection" {
  type = object({
    objective = string
  })
  description = "Optional AI Gateway automatic selection settings; null preserves priority-only routing."
  default     = null
  validation {
    condition     = var.auto_model_selection == null || var.auto_model_selection.objective == "Balanced"
    error_message = "Only the officially verified Balanced selection objective is supported by this configuration."
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

variable "model_alias" {
  type        = string
  description = "Single client-facing alias name shared by all registered gateway models."
  default     = null
  validation {
    condition     = var.model_alias == null || can(regex("^[a-zA-Z0-9_.-]+$", var.model_alias))
    error_message = "Alias names may contain only alphanumeric, underscore, period and hyphen characters."
  }
}

variable "model_callers" {
  type        = map(string)
  description = "Explicit caller managed-identity principal UUIDs keyed by stable labels (for example project). Grants AI Gateway Models User at this root's alias only; does not create a Foundry project model connection."
  default     = {}
  nullable    = false
  validation {
    condition     = alltrue([for principal_id in values(var.model_callers) : can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", principal_id))]) && (length(var.model_callers) == 0 || length(var.models) > 0)
    error_message = "Supply actual principal UUIDs under explicit stable keys; models and an alias must be configured before caller grants."
  }
}

variable "model_provider" {
  type = object({
    account_id    = string
    provider_name = string
  })
  description = "Shared Foundry account and provider registration for all gateway models."
  default     = null
  validation {
    condition = var.model_provider == null ? true : (
      can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+$", var.model_provider.account_id)) &&
      can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.model_provider.provider_name))
    )
    error_message = "Supply a valid Foundry account ARM ID and provider name."
  }
}

variable "model_provider_endpoint" {
  type        = string
  description = "Actual Foundry account endpoint URL configuration metadata; required with models and supplied separately from the shared account/provider identifiers."
  default     = null
  sensitive   = true
  validation {
    condition     = nonsensitive(var.model_provider_endpoint == null || can(regex("^https://[a-zA-Z0-9.-]+/?$", var.model_provider_endpoint)))
    error_message = "Supply the service-returned HTTPS account origin."
  }
}

variable "models" {
  type = map(object({
    deployment_id       = string
    model_version       = string
    model_name          = string
    selector_model_name = optional(string)
    supported_endpoints = optional(set(string), ["/openai/v1/responses"])
    priority            = optional(number, 0)
    weight              = optional(number, 100)
  }))
  description = "All gateway model registrations keyed by stable Terraform labels; each deployment uses the shared Foundry account/provider."
  default     = {}
  nullable    = false
  validation {
    condition = length(var.models) == 0 ? (
      var.model_provider == null && var.model_alias == null && var.model_provider_endpoint == null
      ) : (
      var.model_provider != null && var.model_alias != null && var.model_provider_endpoint != null &&
      alltrue([
        for key, model in var.models :
        can(regex("^[a-z][a-z0-9_]*$", key)) &&
        startswith(lower(model.deployment_id), "${lower(var.model_provider.account_id)}/deployments/") &&
        can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+/deployments/[^/]+$", model.deployment_id)) &&
        can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", model.model_name)) &&
        can(regex("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$", model.model_version)) &&
        (model.selector_model_name == null ? true : can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", model.selector_model_name))) &&
        length(model.supported_endpoints) > 0 &&
        length(setsubtract(model.supported_endpoints, toset(["/openai/v1/responses", "/openai/v1/chat/completions"]))) == 0 &&
        model.priority >= 0 &&
        floor(model.priority) == model.priority &&
        model.weight >= 1 &&
        model.weight <= 100 &&
        floor(model.weight) == model.weight
      ]) &&
      length(toset([for model in values(var.models) : lower(model.model_name)])) == length(var.models) &&
      length(toset([for model in values(var.models) : lower(model.deployment_id)])) == length(var.models)
    )
    error_message = "Models require stable valid keys, unique model names and deployments, deployments in the shared Foundry account, verified endpoint paths, valid dated versions/selectors, nonnegative integer priorities, and integer weights from 1 to 100; configure the shared provider, endpoint, and alias together."
  }
  validation {
    condition = var.auto_model_selection == null ? true : (
      length(var.models) >= 2 &&
      alltrue([
        for model in values(var.models) :
        contains(model.supported_endpoints, "/openai/v1/chat/completions") &&
        try(length(trimspace(model.selector_model_name)) > 0, false)
      ]) &&
      length(toset([for model in values(var.models) : try(lower(model.selector_model_name), "")])) == length(var.models)
    )
    error_message = "Auto selection requires at least two models with explicitly verified native Chat Completions support and unique nonempty selector model names, providing a common API for the MAF OpenAIChatClient. Supply supported_endpoints explicitly; enabling auto selection does not infer model capabilities."
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
  description = "Configured telemetry DCR ID and endpoint URL metadata. Terraform checks the DCR against asynchronous service-returned component metadata but cannot attest endpoint provenance. Publisher role assignment requires narrow roleAssignments/write on the service-created DCR."
  default     = null
  sensitive   = true
  validation {
    condition     = nonsensitive(var.telemetry_exporter == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.Insights/dataCollectionRules/[^/]+$", var.telemetry_exporter.data_collection_rule_id)))
    error_message = "Supply the actual component OTLP data collection rule ARM ID."
  }
  validation {
    condition = nonsensitive(var.telemetry_exporter == null) ? true : (
      var.native_otlp_enabled &&
      try(module.application_insights[0].otlp.data_collection_rule_id, null) != null &&
      nonsensitive(var.telemetry_exporter.data_collection_rule_id) == try(module.application_insights[0].otlp.data_collection_rule_id, null) &&
      nonsensitive(alltrue([for endpoint in values(var.telemetry_exporter.endpoints) : can(regex("^https://[a-zA-Z0-9.-]+/[^?#[:space:]]+$", endpoint))]))
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
