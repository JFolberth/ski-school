# Copy to an ignored root-local dev.tfvar and select it explicitly.
# Supply required subscription_id and tenant_id separately (TF_VAR_* or that file).
base_name                                 = "ski-logs"
environment                               = "dev"
location                                  = "northcentralus"
monitor_workspace_location                = "eastus2"
monitor_workspace_resource_context_access = true
tags                                      = {}
workspace_location                        = "eastus2"
workspace_retention_in_days               = 30
workspace_sku_name                        = "PerGB2018"
