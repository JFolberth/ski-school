variable "additional_latency_in_milliseconds" {
  description = "Extra latency allowed for weighted origin selection."
  type        = number
  nullable    = false
  validation {
    condition     = var.additional_latency_in_milliseconds >= 0 && floor(var.additional_latency_in_milliseconds) == var.additional_latency_in_milliseconds
    error_message = "Additional latency must be a nonnegative integer."
  }
}

variable "name" {
  description = "Origin group name."
  type        = string
  nullable    = false
}

variable "probe_interval_seconds" {
  description = "Interval between HTTPS health probes."
  type        = number
  nullable    = false
  validation {
    condition     = var.probe_interval_seconds >= 1 && var.probe_interval_seconds <= 255 && floor(var.probe_interval_seconds) == var.probe_interval_seconds
    error_message = "Probe interval must be an integer from 1 to 255 seconds."
  }
}

variable "profile_id" {
  description = "Owning Front Door profile resource ID."
  type        = string
  nullable    = false
}

variable "sample_size" {
  description = "Number of probe samples used to assess health."
  type        = number
  nullable    = false
  validation {
    condition     = var.sample_size >= 1 && var.sample_size <= 16 && floor(var.sample_size) == var.sample_size
    error_message = "Sample size must be an integer from 1 to 16."
  }
}

variable "successful_samples_required" {
  description = "Number of successful samples required for a healthy origin."
  type        = number
  nullable    = false
  validation {
    condition     = var.successful_samples_required >= 1 && var.successful_samples_required <= var.sample_size && floor(var.successful_samples_required) == var.successful_samples_required
    error_message = "Successful samples must be an integer between 1 and sample_size."
  }
}
