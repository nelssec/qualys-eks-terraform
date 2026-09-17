module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.name
  kubernetes_version = var.kubernetes_version

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids != null ? var.control_plane_subnet_ids : var.subnet_ids

  endpoint_private_access      = true
  endpoint_public_access       = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  authentication_mode                      = var.authentication_mode
  access_entries                           = var.access_entries
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  enabled_log_types = var.enabled_log_types

  create_kms_key    = var.kms_key_arn == null
  encryption_config = var.kms_key_arn == null ? {} : { provider_key_arn = var.kms_key_arn }

  enable_irsa = var.enable_irsa

  addons = var.addons

  eks_managed_node_groups = {
    for k, ng in var.node_groups : k => {
      instance_types = ng.instance_types
      min_size       = ng.min_size
      max_size       = ng.max_size
      desired_size   = ng.desired_size
      ami_type       = ng.ami_type
      capacity_type  = ng.capacity_type
      subnet_ids     = ng.subnet_ids
      labels         = ng.labels
      taints         = ng.taints
      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = ng.disk_size
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }
    }
  }

  fargate_profiles = var.fargate_profiles

  tags = var.tags
}
