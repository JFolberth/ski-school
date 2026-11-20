locals {
  resource_group_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  profile_ids = {
    for key, profile in var.profiles :
    key => "${local.resource_group_id}/providers/Microsoft.Cdn/profiles/${profile.name}"
  }
  origin_group_ids = {
    for key, profile in var.profiles :
    key => "${local.profile_ids[key]}/originGroups/${profile.origin_group_name}"
  }
  endpoints = merge([
    for profile_key, profile in var.profiles : {
      for endpoint_key, endpoint in profile.endpoints :
      "${profile_key}/${endpoint_key}" => {
        profile_key  = profile_key
        endpoint_key = endpoint_key
        name         = endpoint.name
        route_name   = endpoint.route_name
        id           = "${local.profile_ids[profile_key]}/afdEndpoints/${endpoint.name}"
      }
    }
  ]...)
  origins = merge([
    for profile_key, profile in var.profiles : merge(
      profile.use_frontend ? {
        "${profile_key}/frontend" = {
          profile_key = profile_key
          name        = "frontend"
          hostname    = data.azapi_resource.frontend.output.properties.configuration.ingress.fqdn
          priority    = profile.frontend_origin_priority
          weight      = profile.frontend_origin_weight
        }
      } : {},
      {
        for origin_key, origin in profile.additional_origins :
        "${profile_key}/${origin_key}" => {
          profile_key = profile_key
          name        = origin_key
          hostname    = origin.hostname
          priority    = origin.priority
          weight      = origin.weight
        }
      }
    )
  ]...)
}
