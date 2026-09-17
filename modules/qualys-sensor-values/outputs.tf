output "values" {
  description = "Rendered qualys-tc values as a Terraform object. Never contains credentials."
  value       = local.values
}

output "values_yaml" {
  description = "Rendered qualys-tc values as YAML. Pass as the first entry of helm_release.values."
  value       = yamlencode(local.values)
}

output "gateway_url" {
  description = "Effective global.gatewayUrl."
  value       = local.gateway_url
}

output "cmsqag_public_url" {
  description = "Effective global.cmsqagPublicUrl."
  value       = local.cmsqag_public_url
}

output "enabled_components" {
  description = "Names of enabled components in canonical order."
  value       = local.enabled_components
}
