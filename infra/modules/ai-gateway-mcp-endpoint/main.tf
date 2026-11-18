resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/toolServers@2026-11-01"
  name      = var.name
  parent_id = var.workspace_id

  body = {
    properties = {
      displayName    = var.name
      toolServerType = "mcp"
      endpoints = [{
        id   = var.name
        kind = "mcp"
        mode = "failClosed"
        mcp = {
          endpoint  = { url = var.backend_url }
          transport = "streamableHttp"
        }
        authentication = {
          managedIdentity = { resource = var.token_audience }
        }
      }]
    }
  }
}
