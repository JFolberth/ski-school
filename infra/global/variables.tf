variable "environment" {
  description = "Environment label; use a separate state storage account for each environment."
  type        = string
  default     = "dev"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{3}$", var.environment))
    error_message = "environment must be exactly three lowercase letters."
  }
}

variable "frontend_container_app_id" {
  description = "Explicit ARM resource ID of the existing public frontend Container App; its ingress FQDN is read without accessing frontend Terraform state."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/resourcegroups/[^/]+/providers/microsoft\\.app/containerapps/[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.frontend_container_app_id))
    error_message = "frontend_container_app_id must be an existing Container App ARM resource ID."
  }
}

variable "location" {
  description = "Resource-group metadata location; Front Door resources are global."
  type        = string
  nullable    = false
  validation {
    condition     = var.location == "northcentralus"
    error_message = "The approved global resource-group metadata location is northcentralus."
  }
}

variable "log_analytics_workspace_id" {
  description = "Explicit ARM resource ID of the existing Log Analytics workspace."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}/resourcegroups/[^/]+/providers/microsoft\\.operationalinsights/workspaces/[^/]+$", var.log_analytics_workspace_id))
    error_message = "log_analytics_workspace_id must identify an existing workspace."
  }
}

variable "profiles" {
  description = "Front Door profiles and endpoints in this resource group. Each profile routes all its endpoints to its own origin group."
  type = map(object({
    name              = string
    origin_group_name = string
    diagnostic_name   = string
    endpoints = map(object({
      name       = string
      route_name = string
    }))
    sku_name                           = optional(string, "Standard_AzureFrontDoor")
    origin_response_timeout_seconds    = optional(number, 240)
    probe_interval_seconds             = optional(number, 240)
    sample_size                        = optional(number, 4)
    successful_samples_required        = optional(number, 3)
    additional_latency_in_milliseconds = optional(number, 0)
    frontend_origin_priority           = optional(number, 1)
    frontend_origin_weight             = optional(number, 50)
    use_frontend                       = optional(bool, true)
    additional_origins = optional(map(object({
      hostname = string
      priority = optional(number, 1)
      weight   = optional(number, 50)
    })), {})
  }))
  nullable = false

  validation {
    condition = length(var.profiles) > 0 && alltrue([
      for key, profile in var.profiles : try(
        can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", key)) &&
        can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", profile.name)) && length(profile.name) <= 260 &&
        can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", profile.origin_group_name)) && length(profile.origin_group_name) <= 90 &&
        can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", profile.diagnostic_name)) && length(profile.diagnostic_name) <= 260 &&
        length(profile.endpoints) > 0 &&
        profile.sku_name == "Standard_AzureFrontDoor" &&
        profile.origin_response_timeout_seconds > 220 && profile.origin_response_timeout_seconds <= 240 &&
        floor(profile.origin_response_timeout_seconds) == profile.origin_response_timeout_seconds &&
        profile.probe_interval_seconds >= 1 && profile.probe_interval_seconds <= 255 &&
        floor(profile.probe_interval_seconds) == profile.probe_interval_seconds &&
        profile.sample_size >= 1 && profile.sample_size <= 16 && floor(profile.sample_size) == profile.sample_size &&
        profile.successful_samples_required >= 1 && profile.successful_samples_required <= profile.sample_size &&
        floor(profile.successful_samples_required) == profile.successful_samples_required &&
        profile.additional_latency_in_milliseconds >= 0 &&
        floor(profile.additional_latency_in_milliseconds) == profile.additional_latency_in_milliseconds &&
        profile.frontend_origin_priority >= 1 && profile.frontend_origin_priority <= 5 &&
        floor(profile.frontend_origin_priority) == profile.frontend_origin_priority &&
        profile.frontend_origin_weight >= 1 && profile.frontend_origin_weight <= 1000 &&
        floor(profile.frontend_origin_weight) == profile.frontend_origin_weight &&
        (profile.use_frontend || length(profile.additional_origins) > 0) &&
        !contains(keys(profile.additional_origins), "frontend") &&
        length(distinct([for origin in values(profile.additional_origins) : origin.hostname])) == length(profile.additional_origins) &&
        alltrue([for origin_key, origin in profile.additional_origins :
          can(regex("^[a-z0-9]([a-z0-9-]{0,88}[a-z0-9])?$", origin_key)) &&
          length(origin.hostname) <= 253 &&
          can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", origin.hostname)) &&
          origin.priority >= 1 && origin.priority <= 5 && floor(origin.priority) == origin.priority &&
          origin.weight >= 1 && origin.weight <= 1000 && floor(origin.weight) == origin.weight
        ]) &&
        alltrue([for endpoint_key, endpoint in profile.endpoints :
          can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", endpoint_key)) &&
          can(regex("^[a-z0-9]([a-z0-9-]{0,44}[a-z0-9])?$", endpoint.name)) &&
          can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", endpoint.route_name)) && length(endpoint.route_name) <= 90
        ]),
        false
      )
    ])
    error_message = "Profiles require valid names, at least one endpoint, Standard SKU, safe timeout/probe/load-balancing values, and valid unique additional origins; frontend is reserved."
  }

  validation {
    condition = try(
      length(distinct([for profile in values(var.profiles) : profile.name])) == length(var.profiles) &&
      length(distinct(flatten([for profile in values(var.profiles) : [for endpoint in values(profile.endpoints) : endpoint.name]]))) ==
      length(flatten([for profile in values(var.profiles) : [for endpoint in values(profile.endpoints) : endpoint.name]])),
      false
    )
    error_message = "Profile names and endpoint names must be unique across this deployment; Azure endpoint names must also be globally available."
  }
}

variable "resource_group_name" {
  description = "Explicit global resource group name, independent of its metadata location."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^rg-[a-z0-9]+(-[a-z0-9]+)*-gbl$", var.resource_group_name)) && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must be a lowercase rg-...-gbl name of at most 90 characters."
  }
}

variable "subscription_id" {
  description = "Explicit workload subscription UUID, independent of backend settings."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a subscription UUID."
  }
}

variable "tags" {
  description = "Non-secret tags applied by the provider."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "tenant_id" {
  description = "Explicit workload tenant UUID, independent of backend settings."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "tenant_id must be a tenant UUID."
  }
}
