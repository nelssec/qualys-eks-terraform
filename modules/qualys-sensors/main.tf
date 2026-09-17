data "aws_secretsmanager_secret_version" "credentials" {
  secret_id = var.credentials_secret_arn

  lifecycle {
    postcondition {
      condition = (
        can(jsondecode(self.secret_string)) &&
        can(jsondecode(self.secret_string)[var.credentials_secret_keys.customer_id]) &&
        can(jsondecode(self.secret_string)[var.credentials_secret_keys.activation_id])
      )
      error_message = "Secret ${var.credentials_secret_arn} must be a JSON object with keys '${var.credentials_secret_keys.customer_id}' and '${var.credentials_secret_keys.activation_id}'. Create it with the qualys-secrets module or set credentials_secret_keys to match your secret."
    }
  }
}

locals {
  credentials   = jsondecode(data.aws_secretsmanager_secret_version.credentials.secret_string)
  customer_id   = local.credentials[var.credentials_secret_keys.customer_id]
  activation_id = local.credentials[var.credentials_secret_keys.activation_id]
}

module "values" {
  source = "../qualys-sensor-values"

  cluster_arn                = var.cluster_arn
  qualys_platform            = var.qualys_platform
  gateway_url                = var.gateway_url
  cmsqag_public_url          = var.cmsqag_public_url
  components                 = var.components
  container_runtime          = var.container_runtime
  proxy                      = var.proxy
  root_ca_certificate_base64 = var.root_ca_certificate_base64
  images                     = var.images
  image_pull_secrets         = var.image_pull_secrets
  sensor_tags                = var.sensor_tags
  cluster_sensor             = var.cluster_sensor
  qcs_sensor                 = var.qcs_sensor
  runtime_sensor             = var.runtime_sensor
  admission_controller       = var.admission_controller
  node_selector              = var.node_selector
  tolerations                = var.tolerations
  extra_values               = var.extra_values
}

resource "helm_release" "this" {
  name             = var.release_name
  repository       = var.chart_repository
  chart            = "qualys-tc"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  atomic          = var.helm_atomic
  cleanup_on_fail = true
  wait            = var.helm_wait
  timeout         = var.helm_timeout_seconds

  values = [
    module.values.values_yaml,
    module.values.extra_values_yaml,
  ]

  set_sensitive = concat(
    [
      { name = "global.customerId", value = local.customer_id },
      { name = "global.activationId", value = local.activation_id },
    ],
    module.values.sensitive_set_values,
  )
}
