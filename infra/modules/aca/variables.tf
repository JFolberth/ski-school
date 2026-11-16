variable "acr_resource_id" {
  description = "Resource ID of the existing Azure Container Registry."
  type        = string
  nullable    = false

  validation {
    condition = can(regex(
      "^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourcegroups/[^/]+/providers/microsoft\\.containerregistry/registries/[a-z0-9]{5,50}$",
      lower(var.acr_resource_id)
    )) && !strcontains(lower(var.acr_resource_id), "replace")
    error_message = "acr_resource_id must be the real Azure resource ID of an existing registry."
  }
}

variable "container_cpu" {
  description = "CPU cores allocated to the frontend container."
  type        = number
  nullable    = false
  default     = 0.25
  validation {
    condition     = var.container_cpu >= 0.25 && var.container_cpu <= 4 && var.container_cpu * 4 == floor(var.container_cpu * 4)
    error_message = "container_cpu must be between 0.25 and 4 cores in increments of 0.25."
  }
}

variable "container_image_digest" {
  description = "Full sha256 digest of the immutable image version."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.container_image_digest))
    error_message = "container_image_digest must be a full sha256 digest."
  }
}

variable "container_image_repository" {
  description = "Image repository path within the referenced registry."
  type        = string
  nullable    = false

  validation {
    condition = can(regex(
      "^[a-z0-9]+([._-][a-z0-9]+)*(\\/[a-z0-9]+([._-][a-z0-9]+)*)*$",
      var.container_image_repository
    ))
    error_message = "container_image_repository must be a lowercase OCI repository path."
  }
}

variable "container_memory" {
  description = "Memory allocated to the frontend container in Gi."
  type        = string
  nullable    = false
  default     = "0.5Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.container_memory))
    error_message = "container_memory must be expressed in Gi, for example 0.5Gi."
  }
}

variable "deployment_timestamp" {
  description = "UTC deployment timestamp supplied by the deployment process, or null when unavailable."
  type        = string
  default     = null

  validation {
    condition     = var.deployment_timestamp == null ? true : can(formatdate("YYYY", var.deployment_timestamp)) && endswith(var.deployment_timestamp, "Z")
    error_message = "deployment_timestamp must be a valid RFC 3339 UTC timestamp ending in Z, or null."
  }
}

variable "diagnostic_disabled_categories" {
  description = "Additional supported diagnostic log categories to keep explicitly disabled."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition     = length(distinct(var.diagnostic_disabled_categories)) == length(var.diagnostic_disabled_categories) && alltrue([for category in var.diagnostic_disabled_categories : can(regex("^[A-Za-z][A-Za-z0-9]+$", category)) && !contains(["ContainerAppConsoleLogs", "ContainerAppSystemLogs"], category)])
    error_message = "Disabled diagnostic categories must be unique category names distinct from the enabled console and system categories."
  }
}

variable "environment_name" {
  description = "Environment label used in resource naming and tags."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_name)
    error_message = "environment_name must be one of dev, staging, or prod."
  }
}

variable "http_concurrent_requests" {
  description = "Concurrent HTTP requests per replica before scaling."
  type        = number
  nullable    = false
  default     = 10

  validation {
    condition     = var.http_concurrent_requests >= 1 && floor(var.http_concurrent_requests) == var.http_concurrent_requests
    error_message = "http_concurrent_requests must be a positive whole number."
  }
}

variable "location" {
  description = "Azure region shared by resources in the ACA hosting module."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}$", var.location))
    error_message = "location must be a lowercase Azure region name."
  }
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the existing Log Analytics workspace used for ACA diagnostics and Application Insights."
  type        = string
  nullable    = false

  validation {
    condition = can(regex(
      "^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourcegroups/[^/]+/providers/microsoft\\.operationalinsights/workspaces/[^/]+$",
      lower(var.log_analytics_workspace_id)
    )) && !strcontains(lower(var.log_analytics_workspace_id), "replace")
    error_message = "log_analytics_workspace_id must be the real Azure resource ID of an existing Log Analytics workspace."
  }
}

variable "max_replicas" {
  description = "Maximum number of frontend replicas."
  type        = number
  nullable    = false
  default     = 1
  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 1000 && floor(var.max_replicas) == var.max_replicas
    error_message = "max_replicas must be a whole number between 1 and 1000."
  }
}

variable "min_replicas" {
  description = "Minimum number of frontend replicas."
  type        = number
  nullable    = false
  default     = 0
  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 1000 && floor(var.min_replicas) == var.min_replicas
    error_message = "min_replicas must be a whole number between 0 and 1000."
  }
}

variable "name_prefix" {
  description = "Short lowercase prefix for resources created by this module."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must contain 3-20 lowercase letters, digits, or hyphens."
  }
}

variable "resource_group_id" {
  description = "Resource ID of the frontend resource group managed by the root module."
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Non-sensitive tags applied to module resources."
  type        = map(string)
  nullable    = false
  default     = {}
}
