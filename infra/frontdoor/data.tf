data "azapi_resource" "frontend" {
  type        = "Microsoft.App/containerApps@2026-07-01"
  resource_id = var.frontend_container_app_id

  response_export_values = [
    "properties.configuration.ingress.external",
    "properties.configuration.ingress.fqdn",
  ]

  lifecycle {
    postcondition {
      condition     = try(self.output.properties.configuration.ingress.external == true, false)
      error_message = "The existing frontend Container App must have external ingress enabled."
    }

    postcondition {
      condition = try(
        length(self.output.properties.configuration.ingress.fqdn) <= 253 &&
        can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", self.output.properties.configuration.ingress.fqdn)),
        false
      )
      error_message = "The existing frontend must expose a valid lowercase ingress DNS hostname."
    }

    postcondition {
      condition = try(alltrue([
        for profile in values(var.profiles) :
        !profile.use_frontend || !contains([for origin in values(profile.additional_origins) : origin.hostname], self.output.properties.configuration.ingress.fqdn)
      ]), false)
      error_message = "Additional origins must not duplicate the frontend ingress hostname."
    }
  }
}
