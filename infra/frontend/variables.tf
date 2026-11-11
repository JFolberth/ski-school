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

  validation {
    condition = can(regex(
      "^[a-z0-9]+([._-][a-z0-9]+)*(\\/[a-z0-9]+([._-][a-z0-9]+)*)*$",
      var.container_image_repository
    ))
    error_message = "container_image_repository must be a lowercase OCI repository path without a registry hostname or tag."
  }
}

variable "environment" {
  description = "Deployment environment used for resource tags and isolated naming."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, staging, or prod."
  }
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

variable "name_prefix" {
  description = "Short lowercase prefix for frontend resources; must be unique where Azure requires it."
  type        = string
  nullable    = false

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
