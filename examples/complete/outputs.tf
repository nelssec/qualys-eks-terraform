output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "release_status" {
  value = module.qualys_sensors.release_status
}

output "enabled_components" {
  value = module.qualys_sensors.enabled_components
}
