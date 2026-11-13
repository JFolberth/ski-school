locals {
  region_abbreviations = { northcentralus = "ncus", eastus2 = "eus2", global = "gbl" }
  region               = local.region_abbreviations[var.location]
  suffix               = "${var.base_name}-${var.environment}-${local.region}"
    workspace_location   = coalesce(var.workspace_location, var.location)
}
