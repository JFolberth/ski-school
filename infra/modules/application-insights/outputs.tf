output "connection_string" {
  description = "Approved Foundry destination metadata only; ingestion still requires Entra authentication. Do not expose from deployment roots."
  value       = var.export_connection_metadata ? azapi_resource.this.output.properties.ConnectionString : null
  sensitive   = true
}

output "id" {
  description = "Application Insights component ARM ID; no keys or connection strings."
  value       = azapi_resource.this.id
}

output "otlp" {
  description = "Non-secret service-returned native OTLP metadata. Null fields mean not yet ready; never substitute constructed endpoints or a Monitor-workspace default DCR."
  value = var.native_otlp == null ? null : {
    data_collection_rule_id = try(azapi_resource.this.output.properties.DataCollectionRuleResourceId, null)
    endpoints = {
      logs    = try(azapi_resource.this.output.properties.OTLPLogsEndpoint, null)
      metrics = try(azapi_resource.this.output.properties.OTLPMetricsEndpoint, null)
      traces  = try(azapi_resource.this.output.properties.OTLPTracesEndpoint, null)
    }
  }
}
