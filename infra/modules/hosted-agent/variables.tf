variable "acr_login_server" {
  type        = string
  description = "Reviewed existing ACR login hostname, without scheme or path."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*\\.azurecr\\.io$", var.acr_login_server))
    error_message = "Supply the existing public Azure ACR login hostname only."
  }
}
variable "agent_name" {
  type        = string
  description = "Logical agent name including the environment; changing it requires replacing a protected resource."
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,62}$", var.agent_name))
    error_message = "Use 1-63 alphanumeric, underscore or hyphen characters with an alphanumeric start."
  }
}
variable "container_image_digest" {
  type        = string
  description = "Existing linux/amd64 image digest including sha256:, supplied by the separate image publication process."
  nullable    = false
  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.container_image_digest))
    error_message = "Use sha256: followed by exactly 64 lowercase hexadecimal characters; tags are not accepted."
  }
}
variable "container_image_repository" {
  type        = string
  description = "Existing ACR repository path without registry, tag or digest; match registry pull authorization."
  nullable    = false
  validation {
    condition     = length(var.container_image_repository) <= 255 && can(regex("^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*$", var.container_image_repository))
    error_message = "Use a lowercase repository path without a registry, tag, digest or condition-expression characters."
  }
}
variable "cpu" {
  type        = string
  description = "Per-session vCPU. Must pair with memory as 0.5/1Gi, 1/2Gi or 2/4Gi."
  default     = "0.5"
  nullable    = false
  validation {
    condition     = contains(["0.5", "1", "2"], var.cpu)
    error_message = "Supported vCPU values are 0.5, 1 and 2."
  }
}

variable "existing_agent" {
  type        = bool
  description = "Read and verify the existing logical agent's instance identity during a version update. Leave false when creating an agent."
  default     = false
  nullable    = false
}

variable "gateway_base_url" {
  type        = string
  description = "Reviewed full HTTPS gateway model API base URL including the environment-specific route; never derived from region."
  nullable    = false
  validation {
    condition     = can(regex("^https://[a-zA-Z0-9.-]+(/[^[:space:]?#@]*)?/$", var.gateway_base_url))
    error_message = "Supply the reviewed HTTPS model API base URL ending in /, without credentials, whitespace, query or fragment."
  }
}

variable "gateway_mcp_servers" {
  type = map(object({
    url = string
  }))
  description = "Named gateway MCP endpoints. The gateway controls tool availability; each server receives its own backend-root role assignment."
  nullable    = false
  validation {
    condition = length(var.gateway_mcp_servers) > 0 && length(var.gateway_mcp_servers) <= 8 && alltrue([
      for name, server in var.gateway_mcp_servers :
      can(regex("^[a-z][a-z0-9_-]{0,62}$", name)) &&
      can(regex(
        "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/toolservers/(?P<server>[a-zA-Z0-9_-]+)/mcp$",
        server.url
      )) &&
      regex(
        "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/toolservers/(?P<server>[a-zA-Z0-9_-]+)/mcp$",
        server.url
      ).server == name &&
      lower(regex(
        "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/toolservers/(?P<server>[a-zA-Z0-9_-]+)/mcp$",
        server.url
        ).origin) == lower(regex(
        "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/models/[^?#]+/$",
        nonsensitive(var.gateway_base_url)
      ).origin) &&
      regex(
        "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/toolservers/(?P<server>[a-zA-Z0-9_-]+)/mcp$",
        server.url
        ).workspace == regex(
        "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/models/[^?#]+/$",
        nonsensitive(var.gateway_base_url)
      ).workspace
    ])
    error_message = "Configure 1-8 named gateway MCP endpoints on the same origin/workspace as gateway_base_url, each with a matching server name."
  }
}

variable "gateway_model_alias" {
  type        = string
  description = "Existing gateway model alias; the caller owns authorization for the platform-created runtime agent principal."
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", var.gateway_model_alias))
    error_message = "Use the existing nonempty gateway alias name, not a URL."
  }
}
variable "idle_timeout_seconds" {
  type        = number
  description = "Session idle timeout in seconds (120-14400); default 900. Longer active sessions increase compute cost."
  default     = 900
  nullable    = false
  validation {
    condition     = floor(var.idle_timeout_seconds) == var.idle_timeout_seconds && var.idle_timeout_seconds >= 120 && var.idle_timeout_seconds <= 14400
    error_message = "Use an integer idle timeout from 120 through 14400 seconds."
  }
}
variable "memory" {
  type        = string
  description = "Per-session memory, paired with cpu. Supported pairs: 0.5/1Gi, 1/2Gi and 2/4Gi."
  default     = "1Gi"
  nullable    = false
  validation {
    condition     = contains(["1Gi", "2Gi", "4Gi"], var.memory)
    error_message = "Supported memory values are 1Gi, 2Gi and 4Gi."
  }
}
variable "project_endpoint" {
  type        = string
  description = "Reviewed existing Foundry HTTPS project data-plane endpoint, not its ARM ID."
  nullable    = false
  validation {
    condition     = can(regex("^https://[a-zA-Z0-9.-]+/api/projects/[a-zA-Z0-9_-]+/?$", var.project_endpoint))
    error_message = "Use the existing HTTPS project endpoint ending in /api/projects/<project>, without a query."
  }
}
variable "rai_policy_id" {
  type        = string
  description = "Full ARM ID of a reviewed account policy, or null to enable the platform default guardrail. Verify live filtering separately."
  default     = null
  nullable    = true
  validation {
    condition     = var.rai_policy_id == null ? true : can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+/raiPolicies/[^/]+$", var.rai_policy_id))
    error_message = "Use null for the platform default, or supply a full account-scoped RAI policy ARM ID."
  }
}