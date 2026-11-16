locals {
  project_acr_pull_roles = {
    # Container Registry Repository Reader: repository-restricted with ABAC below.
    AbacRepositoryPermissions = "b93aa761-3e63-49ed-ac28-beffa264f7ac"
    # AcrPull: legacy ACR has no repository-scoped Entra RBAC.
    LegacyRegistryPermissions = "7f951dda-4ed3-4680-a7ca-43fe172d538d"
  }
  region_abbreviations = { northcentralus = "ncus", eastus2 = "eus2", global = "gbl" }
  region               = local.region_abbreviations[var.location]
  suffix               = "${var.base_name}-${var.environment}-${local.region}"
  model_deployment_name = coalesce(
    var.model_deployment_name,
    "gpt-5-4-mini-${local.suffix}"
  )
}
