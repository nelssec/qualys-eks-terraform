output "release_status" {
  value = module.qualys_sensors.release_status
}

output "enabled_components" {
  value = module.qualys_sensors.enabled_components
}

output "gateway_url" {
  value = module.qualys_sensors.gateway_url
}

output "credentials_secret_arn" {
  value = module.qualys_secrets.secret_arn
}
