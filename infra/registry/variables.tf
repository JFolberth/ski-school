variable "base_name" {
  type        = string
  description = "Independent registry stem without environment or region. ACR normalizes hyphens out of the complete derived name; uniqueness must be checked before deployment."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.base_name)) && !can(regex("(^|-)(${var.environment}|ncus|eus2|gbl)(-|$)", var.base_name))
    error_message = "Use lowercase alphanumeric segments separated by single hyphens, without environment or region tokens."
  }
}

variable "diagnostic_log_categories" {
  type        = set(string)
  description = "Verified registry platform log categories; no application telemetry component is created."
  default     = ["ContainerRegistryLoginEvents", "ContainerRegistryRepositoryEvents"]
  nullable    = false
  validation {
    condition     = length(var.diagnostic_log_categories) > 0 && length(setsubtract(var.diagnostic_log_categories, toset(["ContainerRegistryLoginEvents", "ContainerRegistryRepositoryEvents"]))) == 0
    error_message = "Select one or both verified ACR categories: ContainerRegistryLoginEvents and ContainerRegistryRepositoryEvents."
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

variable "location" {
  type        = string
  description = "Actual Azure location; ACR remains in North Central US."
  nullable    = false
  validation {
    condition     = var.location == "northcentralus"
    error_message = "Only northcentralus is approved for ACR."
  }
}

variable "registry_sku_name" {
  type        = string
  description = "Registry service tier; Basic defaults to cost-conscious development capacity. Standard/Premium increase cost and still require deployment approval."
  default     = "Basic"
  nullable    = false
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.registry_sku_name)
    error_message = "Use Basic, Standard or Premium; legacy Classic is not supported."
  }
}

variable "subscription_id" {
  type        = string
  description = "Required workload subscription UUID, independent of the backend."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Supply the explicit workload subscription UUID."
  }
}

variable "tags" {
  type        = map(string)
  description = "Non-secret additional tags; the provider enforces environment and managed_by."
  default     = {}
  nullable    = false
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
  description = "Shared Log Analytics workspace ARM ID supplied explicitly from the logging root output."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$", var.workspace_id))
    error_message = "Supply the explicit Log Analytics workspace ARM ID."
  }
}
