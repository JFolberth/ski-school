variable "acr_login_server" {
  type        = string
  description = "Existing ACR login hostname from the registry root; module validates its format."
  nullable    = false
}

variable "agent_name" {
  type        = string
  description = "Logical agent name including this environment; Terraform is its sole writer."
  nullable    = false
  validation {
    condition     = endswith(var.agent_name, "-${var.environment}")
    error_message = "Agent name must end with -<environment> to distinguish releases."
  }
}

variable "application_insights_id" {
  type        = string
  description = "Full ARM ID of the Application Insights component connected to the Foundry project; the backend owns the agent identity's telemetry publisher grant."
  nullable    = false
  validation {
    condition = can(regex("(?i)^/subscriptions/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/resourceGroups/[^/[:space:]?#]+/providers/Microsoft\\.Insights/components/[^/[:space:]?#]+$", var.application_insights_id)) && try(
      lower(split("/", var.application_insights_id)[2]) == lower(var.subscription_id),
      false
    )
    error_message = "Supply the full connected Application Insights component ARM ID in the workload subscription."
  }
}

variable "container_image_digest" {
  type        = string
  description = "Published linux/amd64 image sha256:<64 lowercase hex> digest, not a mutable tag."
  nullable    = false
}

variable "container_image_repository" {
  type        = string
  description = "Existing repository path; match the registry root's image_pull_projects repository."
  nullable    = false
}

variable "cpu" {
  type        = string
  description = "Per-session vCPU: 0.5, 1 or 2, paired with memory 1Gi, 2Gi or 4Gi respectively."
  default     = "0.5"
  nullable    = false
}

variable "environment" {
  type        = string
  description = "Release environment selected with an explicit root-local variable file and an isolated account using the ski-school-backend.tfstate key."
  default     = "dev"
  nullable    = false
  validation {
    condition     = can(regex("^[a-z]{3}$", var.environment))
    error_message = "Environment must be exactly three lowercase letters."
  }
}

variable "existing_agent" {
  type        = bool
  description = "Require an existing Foundry agent and verify that version updates preserve its runtime identity."
  default     = false
  nullable    = false
}

variable "gateway_base_url" {
  type        = string
  description = "Reviewed full HTTPS gateway model API base URL, including actual environment host/location and route, ending in /. No direct-model fallback."
  nullable    = false
  sensitive   = true
}

variable "gateway_mcp_servers" {
  type = map(object({
    url            = string
    tool_server_id = string
  }))
  description = "Named AI Gateway MCP servers with server-scoped role assignments. AI Gateway enforces tool availability."
  nullable    = false
  validation {
    condition = (
      length(var.gateway_mcp_servers) > 0 &&
      length(var.gateway_mcp_servers) <= 8 &&
      length(toset([for name in keys(var.gateway_mcp_servers) : replace(name, "-", "_")])) ==
      length(var.gateway_mcp_servers) &&
      alltrue([
        for name, server in var.gateway_mcp_servers :
        can(regex("^[a-z][a-z0-9_-]{0,62}$", name)) &&
        can(regex(
          "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/toolservers/(?P<server>[a-zA-Z0-9_-]+)/mcp$",
          server.url
        )) &&
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
        ).workspace &&
        regex(
          "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/toolservers/(?P<server>[a-zA-Z0-9_-]+)/mcp$",
          server.url
        ).server == name &&
        can(regex(
          "(?i)^/subscriptions/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/resourceGroups/[^/[:space:]?#]+/providers/Microsoft\\.ApiManagement/aigateways/[^/[:space:]?#]+/workspaces/[^/[:space:]?#]+/toolservers/[^/[:space:]?#]+$",
          server.tool_server_id
        )) &&
        lower(split("/", server.tool_server_id)[2]) == lower(var.subscription_id) &&
        lower(split("/", server.tool_server_id)[10]) == lower(regex(
          "^https://(?P<origin>[a-zA-Z0-9.-]+)/(?P<workspace>[a-zA-Z0-9_-]+)/toolservers/(?P<server>[a-zA-Z0-9_-]+)/mcp$",
          server.url
        ).workspace) &&
        lower(split("/", server.tool_server_id)[12]) == lower(name) &&
        lower(join("/", slice(split("/", server.tool_server_id), 0, 11))) ==
        lower(join("/", slice(split("/", var.gateway_model_alias_id), 0, 11)))
      ])
    )
    error_message = "Configure 1-8 named MCP servers. Each needs a unique name matching its HTTPS gateway /<workspace>/toolservers/<name>/mcp URL and a matching server ARM ID under the model alias's gateway/workspace and workload subscription."
  }
}

variable "gateway_model_alias" {
  type        = string
  description = "Existing gateway model alias name used by the agent; must match gateway_model_alias_id."
  nullable    = false
}

variable "gateway_model_alias_id" {
  type        = string
  description = "Reviewed gateway root model_alias_id ARM output for this environment; the backend owns the agent's alias-scoped grant."
  nullable    = false
  validation {
    condition = can(regex("(?i)^/subscriptions/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/resourceGroups/[^/[:space:]?#]+/providers/Microsoft\\.ApiManagement/aigateways/[^/[:space:]?#]+/workspaces/[^/[:space:]?#]+/aliases/[^/[:space:]?#]+$", var.gateway_model_alias_id)) && try(
      lower(split("/", var.gateway_model_alias_id)[2]) == lower(var.subscription_id) && split("/", var.gateway_model_alias_id)[12] == var.gateway_model_alias,
      false
    )
    error_message = "Supply the full gateway alias ARM ID in the workload subscription, with an alias name matching gateway_model_alias."
  }
}

variable "idle_timeout_seconds" {
  type        = number
  description = "Per-session idle timeout in seconds, integer 120-14400; platform default is 900."
  default     = 900
  nullable    = false
}

variable "memory" {
  type        = string
  description = "Per-session memory: 1Gi, 2Gi or 4Gi paired with vCPU 0.5, 1 or 2 respectively."
  default     = "1Gi"
  nullable    = false
}

variable "project_endpoint" {
  type        = string
  description = "Reviewed existing Foundry HTTPS project data-plane endpoint, not an ARM ID; no project is created by this root."
  nullable    = false
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

variable "subscription_id" {
  type        = string
  description = "Explicit workload subscription UUID, independent of backend authentication."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "Supply the explicit workload subscription UUID."
  }
}

variable "tenant_id" {
  type        = string
  description = "Explicit workload tenant UUID, independent of backend authentication."
  nullable    = false
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.tenant_id))
    error_message = "Supply the explicit workload tenant UUID."
  }
}