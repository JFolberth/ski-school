locals {
  region_abbreviations = { eastus2 = "eus2", swedencentral = "swc" }
  region               = local.region_abbreviations[var.location]
  suffix               = "${var.base_name}-${var.environment}-${local.region}"
  default_workspace_id = "${module.gateway.id}/workspaces/default"
  model_backends       = var.model_backend == null ? {} : { primary = var.model_backend }
  # Only the presence of the handoff is public; endpoint values remain sensitive.
  telemetry_exporters = nonsensitive(var.telemetry_exporter == null) ? toset([]) : toset(["primary"])
}
