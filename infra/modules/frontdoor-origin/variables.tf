variable "hostname" {
  description = "Public DNS hostname used for TLS and the origin Host header."
  type        = string
  nullable    = false
  validation {
    condition     = length(var.hostname) <= 253 && can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.hostname))
    error_message = "hostname must be a lowercase DNS hostname without scheme, port or path."
  }
}

variable "name" {
  description = "Origin name within the group."
  type        = string
  nullable    = false
}

variable "origin_group_id" {
  description = "Owning origin group resource ID."
  type        = string
  nullable    = false
}

variable "priority" {
  description = "Origin priority; 1 is highest."
  type        = number
  nullable    = false
  validation {
    condition     = var.priority >= 1 && var.priority <= 5 && floor(var.priority) == var.priority
    error_message = "Priority must be an integer from 1 to 5."
  }
}

variable "weight" {
  description = "Weight among healthy origins within the permitted latency range."
  type        = number
  nullable    = false
  validation {
    condition     = var.weight >= 1 && var.weight <= 1000 && floor(var.weight) == var.weight
    error_message = "Weight must be an integer from 1 to 1000."
  }
}
