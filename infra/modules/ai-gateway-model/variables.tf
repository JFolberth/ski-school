variable "deployment_id" {
  type        = string
  description = "Actual account-level Foundry model deployment ARM ID; its final segment is the upstream deployment name."
  nullable    = false
  validation {
    condition     = can(regex("(?i)^/subscriptions/[0-9a-f-]{36}/resourceGroups/[^/]+/providers/Microsoft\\.CognitiveServices/accounts/[^/]+/deployments/[^/]+$", var.deployment_id))
    error_message = "Supply the actual Cognitive Services model deployment ARM ID."
  }
}

variable "model_version" {
  type        = string
  description = "Version actually deployed in the upstream Foundry account."
  nullable    = false
  validation {
    condition     = can(regex("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$", var.model_version))
    error_message = "Supply the explicit dated deployed model version."
  }
}

variable "name" {
  type        = string
  description = "Gateway backend-model resource/display name."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Model resource names must be 3–63 lowercase alphanumeric or hyphen characters with alphanumeric ends."
  }
}

variable "provider_id" {
  type        = string
  description = "Parent gateway model provider ARM ID."
  nullable    = false
}

variable "supported_endpoints" {
  type        = set(string)
  description = "Verified native model endpoint paths; no translation policies are added."
  default     = ["/openai/v1/responses"]
  nullable    = false
  validation {
    condition     = length(var.supported_endpoints) > 0 && length(setsubtract(var.supported_endpoints, toset(["/openai/v1/responses", "/openai/v1/chat/completions"]))) == 0
    error_message = "Choose verified /openai/v1/responses and/or /openai/v1/chat/completions endpoint paths."
  }
}
