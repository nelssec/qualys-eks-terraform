output "release_name" {
  value       = helm_release.this.name
  description = "Helm release name."
}

output "namespace" {
  value       = helm_release.this.namespace
  description = "Namespace the sensors run in."
}

output "chart_version" {
  value       = helm_release.this.version
  description = "Deployed qualys-tc chart version."
}

output "release_status" {
  value       = helm_release.this.status
  description = "Helm release status."
}

output "enabled_components" {
  value       = module.values.enabled_components
  description = "Enabled Qualys components."
}

output "gateway_url" {
  value       = module.values.gateway_url
  description = "Effective Qualys gateway URL."
}

output "cmsqag_public_url" {
  value       = module.values.cmsqag_public_url
  description = "Effective Qualys cmsqagpublic URL."
}

output "rendered_values_yaml" {
  value       = module.values.values_yaml
  description = "Rendered values YAML (no credentials). Useful for GitOps hand-off or debugging."
}
