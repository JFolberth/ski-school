variable "backend_url" {
  type        = string
  description = "Complete upstream Streamable HTTP MCP URL without credentials."
  nullable    = false
}

variable "name" {
  type        = string
  description = "Stable name of the gateway MCP server."
  nullable    = false
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
