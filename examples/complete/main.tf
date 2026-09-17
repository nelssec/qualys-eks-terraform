data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.name
  cidr = "10.0.0.0/16"

  azs             = local.azs
  private_subnets = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  public_subnets  = ["10.0.48.0/24", "10.0.49.0/24", "10.0.50.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }

  tags = var.tags
}

module "eks" {
  source = "../../modules/eks-cluster"

  name               = var.name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.admin_cidrs

  node_groups = {
    default = {
      instance_types = ["m6i.large"]
      min_size       = 2
      desired_size   = 2
      max_size       = 4
    }
  }

  tags = var.tags
}

module "qualys_secrets" {
  source = "../../modules/qualys-secrets"

  customer_id             = var.qualys_customer_id
  activation_id           = var.qualys_activation_id
  secret_name             = "qualys/container-security/${var.name}"
  recovery_window_in_days = 0
  tags                    = var.tags
}

module "qualys_sensors" {
  source = "../../modules/qualys-sensors"

  cluster_arn            = module.eks.cluster_arn
  qualys_platform        = var.qualys_platform
  credentials_secret_arn = module.qualys_secrets.secret_arn
  components             = var.components
  sensor_tags            = ["demo", var.name]

  depends_on = [module.eks]
}
