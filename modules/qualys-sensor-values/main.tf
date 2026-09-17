locals {
  global = {
    gatewayUrl      = local.gateway_url
    cmsqagPublicUrl = local.cmsqag_public_url
    clusterInfoArgs = {
      cloudProvider        = "AWS"
      useCloudProviderRbac = false
      AWS                  = { arn = var.cluster_arn }
    }
    openshift    = false
    gkeAutopilot = { enabled = false, allowlistLabelForQcsSensor = "" }
  }

  cluster_sensor_values       = { enabled = var.components.cluster_sensor }
  qcs_sensor_values           = { enabled = var.components.qcs_sensor }
  runtime_sensor_values       = { enabled = var.components.runtime_sensor }
  admission_controller_values = { enabled = var.components.admission_controller }

  values = {
    global              = local.global
    clusterSensor       = local.cluster_sensor_values
    qcsSensor           = local.qcs_sensor_values
    runtimeSensor       = local.runtime_sensor_values
    admissionController = local.admission_controller_values
  }
}
