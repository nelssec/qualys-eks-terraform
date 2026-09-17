module "qualys_secrets" {
  source = "../../modules/qualys-secrets"

  customer_id   = var.qualys_customer_id
  activation_id = var.qualys_activation_id
  secret_name   = "qualys/container-security/${var.cluster_name}"
  tags          = var.tags
}

module "qualys_sensors" {
  source = "../../modules/qualys-sensors"

  cluster_arn            = data.aws_eks_cluster.this.arn
  qualys_platform        = var.qualys_platform
  credentials_secret_arn = module.qualys_secrets.secret_arn
  components             = var.components
  sensor_tags            = var.sensor_tags
}
