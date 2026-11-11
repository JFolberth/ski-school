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

variable "environment_name" {
  description = "Environment label used in resource naming and tags."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_name)
    error_message = "environment_name must be one of dev, staging, or prod."
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
