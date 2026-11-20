resource "azapi_resource" "this" {
  type      = "Microsoft.Cdn/profiles/afdEndpoints/routes@2026-10-01"
  name      = var.name
  parent_id = var.endpoint_id

  body = {
    properties = {
      enabledState        = "Enabled"
      forwardingProtocol  = "HttpsOnly"
      httpsRedirect       = "Enabled"
      linkToDefaultDomain = "Enabled"
      originGroup = {
        id = var.origin_group_id
      }
      patternsToMatch    = ["/*"]
      supportedProtocols = ["Http", "Https"]
      # Omitting cacheConfiguration disables caching for both site and API.
    }
  }
}
