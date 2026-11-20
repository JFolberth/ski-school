variable "endpoint_id" {
  description = "Front Door endpoint resource ID."
  type        = string
  nullable    = false
}

variable "name" {
  description = "Route name."
  type        = string
  nullable    = false
}

variable "origin_group_id" {
  description = "Origin group resource ID."
  type        = string
  nullable    = false
}
