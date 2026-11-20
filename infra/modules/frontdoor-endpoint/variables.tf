variable "name" {
  description = "Globally unique Front Door endpoint name."
  type        = string
  nullable    = false
}

variable "profile_id" {
  description = "Owning Front Door profile resource ID."
  type        = string
  nullable    = false
}
