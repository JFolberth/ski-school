module "resource_group" {
  source          = "../modules/resource-group"
  location        = var.location
  name            = var.resource_group_name
  subscription_id = var.subscription_id
}

module "profiles" {
  source   = "../modules/frontdoor-profile"
  for_each = var.profiles

  name                            = each.value.name
  origin_response_timeout_seconds = each.value.origin_response_timeout_seconds
  resource_group_id               = local.resource_group_id
  sku_name                        = each.value.sku_name

  # ARM needs the RG to exist; the deterministic parent ID alone is not an edge.
  depends_on = [module.resource_group]
}

module "endpoints" {
  source   = "../modules/frontdoor-endpoint"
  for_each = local.endpoints

  name       = each.value.name
  profile_id = local.profile_ids[each.value.profile_key]

  # Each plan-known parent must exist before its child ARM request.
  depends_on = [module.profiles]
}

module "origin_groups" {
  source   = "../modules/frontdoor-origin-group"
  for_each = var.profiles

  additional_latency_in_milliseconds = each.value.additional_latency_in_milliseconds
  name                               = each.value.origin_group_name
  probe_interval_seconds             = each.value.probe_interval_seconds
  profile_id                         = local.profile_ids[each.key]
  sample_size                        = each.value.sample_size
  successful_samples_required        = each.value.successful_samples_required

  depends_on = [module.profiles]
}

module "origins" {
  source   = "../modules/frontdoor-origin"
  for_each = local.origins

  hostname        = each.value.hostname
  name            = each.value.name
  origin_group_id = local.origin_group_ids[each.value.profile_key]
  priority        = each.value.priority
  weight          = each.value.weight

  depends_on = [module.origin_groups]
}

module "routes" {
  source   = "../modules/frontdoor-route"
  for_each = local.endpoints

  endpoint_id     = each.value.id
  name            = each.value.route_name
  origin_group_id = local.origin_group_ids[each.value.profile_key]

  # ARM requires the endpoint and a nonempty origin group before route creation.
  depends_on = [module.endpoints, module.origins]
}

module "diagnostic_settings" {
  source   = "../modules/diagnostic-setting"
  for_each = var.profiles

  disabled_log_categories = ["FrontDoorAccessLog", "FrontDoorWebApplicationFirewallLog"]
  log_categories          = ["FrontDoorHealthProbeLog"]
  metric_categories       = ["AllMetrics"]
  name                    = each.value.diagnostic_name
  resource_id             = local.profile_ids[each.key]
  workspace_id            = var.log_analytics_workspace_id

  depends_on = [module.profiles]
}
