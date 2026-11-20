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
  model_deployment_names = {
    for key, deployment in var.models :
    key => try(deployment.deployment_name != null ? deployment.deployment_name : "${replace(deployment.model_name, ".", "-")}-${local.suffix}", "")
  }
  openapi_connections = {
    forecast = {
      name   = "open-meteo-forecast"
      target = "https://api.open-meteo.com"
    }
    historical = {
      name   = "open-meteo-historical"
      target = "https://archive-api.open-meteo.com"
    }
  }
}
