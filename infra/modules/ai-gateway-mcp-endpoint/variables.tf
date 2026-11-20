variable "allowed_tools" {
  type        = list(string)
  description = "Exact gateway-exposed MCP tool names. When unset, use the gateway defaults."
  default     = null

  validation {
    condition = var.allowed_tools == null ? true : (
      length(var.allowed_tools) > 0 &&
      length(distinct(var.allowed_tools)) == length(var.allowed_tools) &&
      alltrue([for name in var.allowed_tools : can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", name))])
    )
    error_message = "Supply at least one unique exact MCP tool name without wildcards, or omit the list."
  }
}

variable "backend_url" {
  type        = string
  description = "Complete upstream Streamable HTTP MCP URL without credentials."
  nullable    = false
}

variable "blocked_tools" {
  type        = list(string)
  description = "Exact gateway-exposed MCP tool names whose calls the gateway must reject. Null uses the gateway defaults."
  default     = null

  validation {
    condition = var.blocked_tools == null ? true : (
      length(var.blocked_tools) > 0 &&
      length(distinct(var.blocked_tools)) == length(var.blocked_tools) &&
      alltrue([for name in var.blocked_tools : can(regex("^[A-Za-z0-9][A-Za-z0-9_.-]*$", name))])
    )
    error_message = "Supply at least one unique exact blocked MCP tool name without wildcards, or omit the list."
  }
}

variable "name" {
  type        = string
  description = "Stable name of the gateway MCP server."
  nullable    = false
}

variable "supported_versions" {
  type        = list(string)
  description = "Explicit MCP protocol versions for this server. Null uses the gateway defaults."
  default     = null

  validation {
    condition = var.supported_versions == null ? true : (
      length(var.supported_versions) > 0 &&
      length(distinct(var.supported_versions)) == length(var.supported_versions) &&
      alltrue([for version in var.supported_versions : can(regex("^\\d{4}-\\d{2}-\\d{2}$", version))])
    )
    error_message = "Supply at least one unique MCP protocol version in YYYY-MM-DD format, or omit the list."
  }
}

variable "token_audience" {
  type        = string
  description = "Microsoft Entra token audience expected by the upstream server."
  nullable    = false
}

variable "workspace_id" {
  type        = string
  description = "Parent gateway workspace ARM ID."
  nullable    = false
}
