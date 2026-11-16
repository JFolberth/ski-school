# Identity-based ACR contract from Microsoft's hosted-agent sample.
# Its ManagedIdentity credentials.clientId intentionally uses the PROJECT
# principalId (as in the service sample), not a newly created user identity.
# https://github.com/Azure-Samples/simple-foundry-hosted-agent-python-aigateway/blob/main/infra/foundry-agents/main.bicep
resource "azapi_resource" "this" {
  # Newest connection API covered by AzAPI 2.13.0's embedded schema.
  # 2026-09-15-preview exists in ARM but is not yet covered; no bypass.
  # https://learn.microsoft.com/azure/templates/microsoft.cognitiveservices/2026-05-15-preview/accounts/projects/connections
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2026-05-15-preview"
  name                      = var.name
  parent_id                 = var.project_id
  schema_validation_enabled = true
  body = {
    properties = {
      category = "ContainerRegistry"
      target   = var.registry_login_server
      authType = "ManagedIdentity"
      credentials = {
        clientId   = var.project_principal_id
        resourceId = var.registry_id
      }
      isSharedToAll = false
      metadata = {
        ResourceId = var.registry_id
      }
    }
  }
}