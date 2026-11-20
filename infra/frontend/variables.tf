variable "acr_resource_id" {
  description = "Resource ID of the existing Azure Container Registry used for image pulls."
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

variable "bridge_cpu" {
  description = "CPU cores allocated to the loopback-only FastAPI bridge sidecar."
  type        = number
  nullable    = false
  default     = 0.25

  validation {
    condition     = var.bridge_cpu >= 0.25 && var.bridge_cpu <= 4 && var.bridge_cpu * 4 == floor(var.bridge_cpu * 4)
    error_message = "bridge_cpu must be between 0.25 and 4 cores in increments of 0.25."
  }
}

variable "bridge_image_digest" {
  description = "Immutable sha256 digest of the separately published bridge image, serving 127.0.0.1:8089."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.bridge_image_digest))
    error_message = "bridge_image_digest must be a full sha256 digest, not a mutable tag."
  }
}

variable "bridge_image_repository" {
  description = "Explicit bridge image repository in the existing ACR, without a hostname, tag, or digest."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9]+([._-][a-z0-9]+)*(\\/[a-z0-9]+([._-][a-z0-9]+)*)*$", var.bridge_image_repository))
    error_message = "bridge_image_repository must be a lowercase OCI repository path."
  }
}

variable "bridge_memory" {
  description = "Memory allocated to the bridge in Gi; Consumption requires twice its CPU allocation."
  type        = string
  nullable    = false
  default     = "0.5Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.bridge_memory))
    error_message = "bridge_memory must be expressed in Gi, for example 0.5Gi."
  }
}

variable "container_cpu" {
  description = "CPU cores allocated to the frontend container."
  type        = number
  nullable    = false
  default     = 0.25
}

variable "container_image_digest" {
  description = "Immutable sha256 digest of the published frontend image."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.container_image_digest))
    error_message = "container_image_digest must be a full sha256 digest; mutable tags and placeholders are not accepted."
  }
}

variable "container_image_repository" {
  description = "Repository path of the frontend image within the existing registry, without a registry hostname or tag."
  type        = string
  nullable    = false
  default     = "ski-school/frontend"

  validation {
    condition = can(regex(
      "^[a-z0-9]+([._-][a-z0-9]+)*(\\/[a-z0-9]+([._-][a-z0-9]+)*)*$",
      var.container_image_repository
    ))
    error_message = "container_image_repository must be a lowercase OCI repository path without a registry hostname or tag."
  }
}

variable "container_memory" {
  description = "Memory allocated to the frontend container."
  type        = string
  nullable    = false
  default     = "0.5Gi"
}
variable "deployment_timestamp" {
  description = "UTC timestamp supplied by the deployment process, or null when unavailable."
  type        = string
  default     = null
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

variable "environment" {
  description = "Deployment environment used for resource tags and isolated naming."
  type        = string
  nullable    = false
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, staging, or prod."
  }
}

variable "foundry_agent_resource_id" {
  description = "Existing agent's ARM scope, ending in /accounts/<account>/projects/<project>/agents/<agent>; only this agent receives a runtime role assignment."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/resourcegroups/[^/]+/providers/microsoft\\.cognitiveservices/accounts/[^/]+/projects/[A-Za-z0-9._-]+/agents/[A-Za-z0-9._-]+$", var.foundry_agent_resource_id))
    error_message = "foundry_agent_resource_id must identify one existing Foundry agent, not an account, project, or agent version."
  }
}

variable "http_concurrent_requests" {
  description = "Concurrent HTTP requests per replica before scaling."
  type        = number
  nullable    = false
  default     = 10
}

variable "location" {
  description = "Azure region for the new frontend resource group and resources."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}$", var.location))
    error_message = "location must be a real Azure region name in lowercase, not a placeholder."
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
}

variable "min_replicas" {
  description = "Minimum number of frontend replicas."
  type        = number
  nullable    = false
  default     = 0
}

variable "name_prefix" {
  description = "Short lowercase prefix for frontend resources; must be unique where Azure requires it."
  type        = string
  nullable    = false
  default     = "ski-frontend"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,18}[a-z0-9]$", var.name_prefix))
    error_message = "name_prefix must be 3-20 lowercase letters, digits, or hyphens, beginning and ending with a letter or digit."
  }
}

variable "resource_group_name" {
  description = "Name of the new frontend-only resource group."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9._()-]{1,90}$", var.resource_group_name)) && !strcontains(lower(var.resource_group_name), "replace")
    error_message = "resource_group_name must be a real Azure resource group name, not a placeholder."
  }
}

variable "subscription_id" {
  description = "Reviewed Azure subscription ID in which the new frontend resource group will be created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id)) && var.subscription_id != "00000000-0000-0000-0000-000000000000"
    error_message = "subscription_id must be the real reviewed Azure subscription ID."
  }
}

variable "tags" {
  description = "Additional non-sensitive tags applied to frontend resources."
  type        = map(string)
  nullable    = false
  default     = {}
}
