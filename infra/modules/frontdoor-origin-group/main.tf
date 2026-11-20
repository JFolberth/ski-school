resource "azapi_resource" "this" {
  type      = "Microsoft.Cdn/profiles/originGroups@2026-10-01"
  name      = var.name
  parent_id = var.profile_id

  body = {
    properties = {
      healthProbeSettings = {
        probeIntervalInSeconds = var.probe_interval_seconds
        probePath              = "/healthz"
        probeProtocol          = "Https"
        probeRequestType       = "GET"
      }
      loadBalancingSettings = {
        additionalLatencyInMilliseconds = var.additional_latency_in_milliseconds
        sampleSize                      = var.sample_size
        successfulSamplesRequired       = var.successful_samples_required
      }
      sessionAffinityState = "Disabled"
    }
  }
}
