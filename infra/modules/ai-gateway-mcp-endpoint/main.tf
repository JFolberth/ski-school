resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/toolServers@2026-11-01"
  name      = var.name
  parent_id = var.workspace_id

  body = {
    properties = merge(
      {
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
      },
      var.supported_versions == null ? {} : { versions = var.supported_versions },
      var.allowed_tools == null ? {} : { allowList = var.allowed_tools },
      var.blocked_tools == null ? {} : { blockList = var.blocked_tools },
    )
  }
}
