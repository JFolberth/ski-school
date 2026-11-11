# Copy to an ignored root-local dev.tfvar and select explicitly.
# Supply required subscription_id, tenant_id and workspace_id separately.
base_name                 = "ski-registry"
diagnostic_log_categories = ["ContainerRegistryLoginEvents", "ContainerRegistryRepositoryEvents"]
environment               = "dev"
location                  = "northcentralus"
registry_sku_name         = "Basic"
tags                      = {}
