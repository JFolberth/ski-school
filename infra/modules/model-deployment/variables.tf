variable "account_id" {
  type        = string
  description = "Parent Foundry account ARM ID."
  nullable    = false
}

variable "capacity" {
  type        = number
  description = "Explicit approved GlobalStandard SKU capacity units. Verify model-specific TPM/RPM mapping and quota before deployment; this is not a token count."
  nullable    = false
  validation {
    condition     = var.capacity >= 1 && floor(var.capacity) == var.capacity
    error_message = "Provide an explicit positive integer capacity in the model's supported SKU units."
  }
}

variable "model_name" {
  type        = string
  description = "Azure OpenAI model identifier. The invoking root enforces the approved model choice."
  default     = "gpt-5.4-mini"
  nullable    = false
  validation {
    condition     = length(trimspace(var.model_name)) > 0
    error_message = "Supply a model identifier."
  }
}

variable "model_version" {
  type        = string
  description = "Explicit Azure model version verified against target availability before deployment."
  nullable    = false
  validation {
    condition     = can(regex("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$", var.model_version))
    error_message = "Supply an explicit dated Azure model version, for example the documented candidate 2026-03-17."
  }
}

variable "name" {
  type        = string
  description = "Stable account-level model deployment name."
  nullable    = false
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,62}[a-z0-9]$", var.name))
    error_message = "Use 2–64 lowercase alphanumeric or hyphen characters."
  }

}

variable "sku_name" {
  type        = string
  description = "Approved pay-as-you-go deployment SKU; no provisioned-capacity fallback."
  default     = "GlobalStandard"
  nullable    = false
  validation {
    condition     = var.sku_name == "GlobalStandard"
    error_message = "Only the approved GlobalStandard SKU is configured."
  }
}

variable "version_upgrade_option" {
  type        = string
  description = "Model-version upgrade policy. NoAutoUpgrade keeps version selection explicit; retirement still requires review."
  default     = "NoAutoUpgrade"
  nullable    = false
  validation {
    condition     = contains(["NoAutoUpgrade", "OnceCurrentVersionExpired", "OnceNewDefaultVersionAvailable"], var.version_upgrade_option)
    error_message = "Use a documented Azure model version-upgrade option."
  }
}
