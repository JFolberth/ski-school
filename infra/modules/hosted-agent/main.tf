locals {
  project_parent_id = trimprefix(trimsuffix(var.project_endpoint, "/"), "https://")
}

# Read the existing identity independently of the managed agent's pending version update.
data "azapi_data_plane_resource" "existing" {
  count                  = var.existing_agent ? 1 : 0
  type                   = "Microsoft.Foundry/agents@v1"
  name                   = var.agent_name
  parent_id              = local.project_parent_id
  response_export_values = ["instance_identity.principal_id"]
}

# Logical agent, not an ARM agent/version resource. Terraform is its sole writer.
# https://learn.microsoft.com/azure/foundry/agents/how-to/deploy-hosted-agent-terraform
# AzAPI data-plane resources expose no ARM schema_validation_enabled switch.
# Keep Terraform input validation; the service validates the definition on write.
resource "azapi_data_plane_resource" "this" {
  type      = "Microsoft.Foundry/agents@v1"
  name      = var.agent_name
  parent_id = local.project_parent_id
  body = {
    name = var.agent_name
    definition = {
      kind = "hosted"
      container_configuration = {
        image = local.image_uri
      }
      cpu    = var.cpu
      memory = var.memory
      protocol_versions = [{
        protocol = "responses"
        version  = "2.0.0"
      }]
      environment_variables = {
        AI_GATEWAY_BASE_URL                                = var.gateway_base_url
        AI_GATEWAY_MCP_SERVERS                             = jsonencode(var.gateway_mcp_servers)
        AI_GATEWAY_MODEL_ALIAS                             = var.gateway_model_alias
        ENABLE_SENSITIVE_DATA                              = "false"
        OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT = "false"
        PYTHONNOUSERSITE                                   = "1"
      }
      # An empty object enables the platform default; omitting rai_config disables it.
      # https://learn.microsoft.com/azure/foundry/agents/how-to/add-hosted-agent-guardrails
      rai_config = var.rai_policy_id == null ? {} : { rai_policy_name = var.rai_policy_id }
      # REST field and seconds contract: azure-ai-projects SessionConfiguration.
      # https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/azure/ai/projects/models/_models.py
      session_configuration = {
        idle_timeout_seconds = var.idle_timeout_seconds
      }
    }
  }
  # The logical-agent GET returns the default instance identity, not the blueprint.
  # https://github.com/Azure/azure-sdk-for-python/blob/main/sdk/ai/azure-ai-projects/azure/ai/projects/models/_models.py
  response_export_values = ["instance_identity.principal_id", "versions.latest.version"]
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = contains(["0.5:1Gi", "1:2Gi", "2:4Gi"], "${var.cpu}:${var.memory}")
      error_message = "Choose a supported CPU/memory pair: 0.5/1Gi, 1/2Gi or 2/4Gi."
    }
    postcondition {
      condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", self.output.instance_identity.principal_id))
      error_message = "Foundry did not return a valid default instance identity principal ID; the gateway grant cannot be created."
    }
    postcondition {
      condition = var.existing_agent ? (
        lower(self.output.instance_identity.principal_id) ==
        lower(data.azapi_data_plane_resource.existing[0].output.instance_identity.principal_id)
      ) : true
      error_message = "Foundry changed the default instance identity during the update. Review its runtime role assignments before retrying."
    }
  }
}