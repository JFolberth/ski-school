resource "azapi_resource" "this" {
  type      = "Microsoft.Cdn/profiles/originGroups/origins@2026-10-01"
  name      = var.name
  parent_id = var.origin_group_id

  body = {
    properties = {
      enabledState                       = "Enabled"
      enforceCertificateNameCheck        = true
      certificateNameCheckValidationMode = "OriginHostname"
      hostName                           = var.hostname
      originHostHeader                   = var.hostname
      priority                           = var.priority
      weight                             = var.weight
    }
  }
}
