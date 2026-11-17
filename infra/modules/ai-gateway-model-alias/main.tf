locals {
  alias_backend_models = length(var.backend_models) > 0 ? var.backend_models : [
    {
      resource_id         = var.model_id
      selector_model_name = null
      priority            = 0
      weight              = 100
    }
  ]
}

resource "azapi_resource" "this" {
  type      = "Microsoft.ApiManagement/aigateways/workspaces/aliases@2026-11-01"
  name      = var.name
  parent_id = var.workspace_id
  # Approved contract-specific exception; AzAPI lacks the 2026-11-01 alias schema.
  # https://learn.microsoft.com/en-us/rest/api/aigateway/ai-gateway-alias-resources/create-or-update?view=rest-aigateway-2026-11-01
  schema_validation_enabled = false
  body = {
    properties = merge({
      aliasName = var.name
      backendModels = [
        for backend in local.alias_backend_models : merge(
          {
            resourceId = backend.resource_id
            priority   = backend.priority
            weight     = backend.weight
          },
          var.auto_model_selection == null ? {} : {
            selectorModelName = backend.selector_model_name
          }
        )
      ]
      selectionOrder = var.auto_model_selection == null ? ["priority"] : ["autoModelSelection", "priority"]
      policies = [
        {
          id         = "identity-requests-per-minute"
          type       = "requestRateLimit"
          count      = var.policy_limits.requests_per_minute
          period     = "minute"
          counterKey = ["identity"]
          scope      = "resource"
        },
        {
          id         = "identity-tokens-per-minute"
          type       = "tokenLimit"
          count      = var.policy_limits.tokens_per_minute
          period     = "minute"
          counterKey = ["identity"]
          scope      = "resource"
        },
        {
          id         = "identity-monthly-cost"
          type       = "costLimit"
          amount     = var.policy_limits.monthly_cost_usd
          period     = "month"
          counterKey = ["identity"]
          scope      = "resource"
        },
      ]
      }, var.auto_model_selection == null ? {} : {
      autoModelSelection = {
        objective = var.auto_model_selection.objective
      }
    })
  }
}
