locals {
  region_abbreviations = { northcentralus = "ncus", eastus2 = "eus2", global = "gbl" }
  region               = local.region_abbreviations[var.location]
  suffix               = "${var.base_name}-${var.environment}-${local.region}"
  model_deployment_name = coalesce(
    var.model_deployment_name,
    "gpt-5-4-mini-${local.suffix}"
  )
}
