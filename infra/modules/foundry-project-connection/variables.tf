variable "application_insights_id" {
  type        = string
  description = "Dedicated Foundry Application Insights component ARM ID."
  nullable    = false
}

variable "connection_string" {
  type        = string
  description = "Approved ApiKey-labelled AppInsights destination metadata, not an ingestion authentication fallback."
  nullable    = false
  sensitive   = true
}

variable "metadata_version" {
  type        = number
  description = "Write-only metadata revision. Increment when the destination connection string is regenerated or rotated."
  default     = 1
  nullable    = false
  validation {
    condition     = var.metadata_version >= 1 && floor(var.metadata_version) == var.metadata_version
    error_message = "Metadata revision must be a positive integer."
  }
}

variable "name" {
  type        = string
  description = "Private project connection name, including environment and region."
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{2,32}$", var.name))
    error_message = "Connection names must be 3–33 alphanumeric, underscore or hyphen characters with an alphanumeric start."
  }
}

variable "project_id" {
  type        = string
  description = "Owning Foundry project ARM ID; this connection is not shared account-wide."
  nullable    = false
}
