variable "base_name" {
  type        = string
  description = "Independent logging name stem; excludes environment and region tokens. Choose a short enough stem for all service limits."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.base_name)) && !can(regex("(^|-)(${var.environment}|ncus|eus2|gbl)(-|$)", var.base_name))
    error_message = "Use lowercase alphanumeric segments separated by single hyphens, without environment or region tokens."
  }
}

variable "environment" {
  type        = string
  description = "Three-letter environment, explicitly selected through a root-local variable file and a matching isolated backend key."
  default     = "dev"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{3}$", var.environment))
    error_message = "Environment must be exactly three lowercase letters."
  }
}

variable "location" {
  type        = string
  description = "Actual Azure location; centralized logging remains in North Central US."
  nullable    = false
  validation {
    condition     = var.location == "northcentralus"
    error_message = "Only northcentralus is approved for centralized logging."
  }
}

variable "monitor_workspace_resource_context_access" {
  type        = bool
  description = "Allow Monitor-workspace metric queries using permissions on the source resource, rather than workspace-wide read grants."
  default     = true
  nullable    = false
}

variable "subscription_id" {
  type        = string
  description = "Required workload subscription UUID, not inferred from backend coordinates or ambient identity."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Supply the explicit workload subscription UUID."
  }
}

variable "tags" {
  type        = map(string)
  description = "Non-secret resource tags; environment and managed_by are enforced by the root provider."
  default     = {}
  nullable    = false
}

variable "tenant_id" {
  type        = string
  description = "Required workload Entra tenant UUID; backend tenant/authentication is supplied separately."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Supply the explicit workload tenant UUID."
  }

}

variable "workspace_retention_in_days" {
  type        = number
  description = "Workspace default Analytics retention. Application Insights/Usage/AzureActivity table defaults can remain 90 days; this is not a universal payload retention guarantee."
  default     = 30
  nullable    = false
  validation {
    condition     = var.workspace_retention_in_days >= 30 && var.workspace_retention_in_days <= 730 && floor(var.workspace_retention_in_days) == var.workspace_retention_in_days
    error_message = "Workspace retention must be an integer from 30 through 730 days."
  }
}

variable "workspace_sku_name" {
  type        = string
  description = "Workspace billing SKU. Pay-as-you-go PerGB2018 is approved; a commitment tier needs a separate cost decision."
  default     = "PerGB2018"
  nullable    = false
  validation {
    condition     = var.workspace_sku_name == "PerGB2018"
    error_message = "Only PerGB2018 pay-as-you-go is approved."
  }
}
