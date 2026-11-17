locals {
  region_abbreviations = { eastus2 = "eus2", swedencentral = "swc" }
  region               = local.region_abbreviations[var.location]
  suffix               = "${var.base_name}-${var.environment}-${local.region}"
  default_workspace_id = "${module.gateway.id}/workspaces/default"
  model_backends       = var.models
  alias_backends       = length(var.models) == 0 ? {} : { primary = { name = var.model_alias } }
  alias_model_keys     = sort(keys(var.models))
  # Only the presence of the handoff is public; endpoint values remain sensitive.
  telemetry_exporters = nonsensitive(var.telemetry_exporter == null) ? toset([]) : toset(["primary"])
}
