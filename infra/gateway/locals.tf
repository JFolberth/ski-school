locals {
  region_abbreviations = { northcentralus = "ncus", eastus2 = "eus2", global = "gbl" }
  region               = local.region_abbreviations[var.location]
  suffix               = "${var.base_name}-${var.environment}-${local.region}"
  default_workspace_id = "${module.gateway.id}/workspaces/default"
  model_backends       = var.model_backend == null ? {} : { primary = var.model_backend }
  telemetry_exporters  = var.telemetry_exporter == null ? {} : { primary = var.telemetry_exporter }
}
