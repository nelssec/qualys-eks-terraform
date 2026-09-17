output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name."
}

output "cluster_arn" {
  value       = module.eks.cluster_arn
  description = "EKS cluster ARN. Feed this to qualys-sensors.cluster_arn."
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "API server endpoint."
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "Base64 CA data for provider configuration."
}

output "cluster_version" {
  value       = module.eks.cluster_version
  description = "Kubernetes version."
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN for IRSA, or null when disabled."
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Cluster security group."
}

output "node_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "Node shared security group."
}

output "fargate_profile_names" {
  value       = [for k, p in module.eks.fargate_profiles : k]
  description = "Names of created Fargate profiles."
}
