resource "azapi_resource" "this" {
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  name      = uuidv5("url", lower("${var.scope_id}|${var.principal_id}|${var.role_definition_id}"))
  parent_id = var.scope_id
  body = {
    properties = {
      principalId      = var.principal_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = var.role_definition_id
    }
  }
}
