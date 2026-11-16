# Copy to ignored root-local dev.tfvars; replace every placeholder.
# Select explicitly: terraform plan -var-file=dev.tfvars (only after target/backend approval).
# Registry/project prerequisites precede release; the agent gateway grant follows creation.
acr_login_server           = "<existing-registry-login-server>"
agent_name                 = "ski-backend-dev"
application_insights_id    = "/subscriptions/<subscription>/resourceGroups/<resource-group>/providers/Microsoft.Insights/components/<connected-application-insights>"
container_image_digest     = "sha256:<published-64-lowercase-hex-digest>"
container_image_repository = "ski-backend"
cpu                        = "0.5"
environment                = "dev"
gateway_base_url           = "https://<reviewed-gateway-host>/<reviewed-model-api-route>/"
gateway_model_alias        = "<existing-gateway-alias>"
gateway_model_alias_id     = "/subscriptions/<subscription>/resourceGroups/<gateway-resource-group>/providers/Microsoft.ApiManagement/aigateways/<gateway>/workspaces/<workspace>/aliases/<existing-gateway-alias>"
idle_timeout_seconds       = 900
memory                     = "1Gi"
project_endpoint           = "https://<existing-account>.services.ai.azure.com/api/projects/<existing-project>"
# Null enables the platform default guardrail; provide a reviewed full policy ARM ID to override it.
rai_policy_id   = null
subscription_id = "<workload-subscription-uuid>"
tenant_id       = "<workload-tenant-uuid>"