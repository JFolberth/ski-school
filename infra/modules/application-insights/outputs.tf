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
    description = "Service-returned native OTLP metadata. Gateway endpoints are deliberately not exported; null fields may also mean metadata is not yet ready."
  value = var.native_otlp == null ? null : {
    data_collection_rule_id = try(azapi_resource.this.output.properties.DataCollectionRuleResourceId, null)
endpoints = var.gateway_otlp_schema_exception ? null : {
      logs    = try(azapi_resource.this.output.properties.OTLPLogsEndpoint, null)
      metrics = try(azapi_resource.this.output.properties.OTLPMetricsEndpoint, null)
      traces  = try(azapi_resource.this.output.properties.OTLPTracesEndpoint, null)
    }
  }
}
