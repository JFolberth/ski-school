output "default_hostnames" {
  description = "Azure-generated default endpoint hostnames keyed by profile and endpoint."
  value = {
    for profile_key, profile in var.profiles : profile_key => {
      for endpoint_key in keys(profile.endpoints) :
      endpoint_key => module.endpoints["${profile_key}/${endpoint_key}"].hostname
    }
  }
}

output "resource_group_id" {
  description = "Deterministic resource ID of the global resource group, known before creation."
  value       = local.resource_group_id
}
