# Recover only the verified orphan in the approved gateway-dev state.
# Other targets must verify their own ownership before adding an import.
# Monitoring Metrics Publisher; the DCR input is validated against this component.
# https://registry.terraform.io/providers/Azure/azapi/2.13.0/docs/resources/resource#import
import {
  for_each = (
    var.environment == "dev" &&
    var.tenant_id == "5a4de383-e76f-4737-9623-e6281d36d202" &&
    var.subscription_id == "9a7e9255-7824-4c0d-a414-366f436f61dd" &&
    local.suffix == "ski-gateway-dev-eus2"
  ) ? local.telemetry_exporters : toset([])
  to = module.telemetry_publisher[each.key].azapi_resource.this
  id = "${nonsensitive(var.telemetry_exporter.data_collection_rule_id)}/providers/Microsoft.Authorization/roleAssignments/5bea142a-0c53-5737-bad2-1aaa73fa4f07?api-version=2022-04-01"
}