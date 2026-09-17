locals {
  global = {
    gatewayUrl       = local.gateway_url
    cmsqagPublicUrl  = local.cmsqag_public_url
    imagePullSecrets = local.image_pull_secrets_public
    clusterInfoArgs = {
      cloudProvider        = "AWS"
      useCloudProviderRbac = false
      AWS                  = { arn = var.cluster_arn }
    }
    rootCA = { certificate = local.root_ca }
    proxy = {
      value         = local.proxy_value
      certificate   = local.proxy_certificate
      skipVerifyTLS = local.proxy_skip_verify
    }
    openshift    = false
    gkeAutopilot = { enabled = false, allowlistLabelForQcsSensor = "" }
    containerRuntimes = {
      containerd = local.containerd_runtime
      crio       = local.crio_runtime
    }
  }

  cluster_sensor_values = merge(
    {
      enabled = var.components.cluster_sensor
      tags    = local.sensor_tags_csv
    },
    var.images.cluster_sensor == null ? {} : { image = var.images.cluster_sensor },
  )

  qcs_sensor_values = {
    enabled    = var.components.qcs_sensor
    containerd = local.containerd_runtime
    crio       = local.crio_runtime
    docker     = { enabled = false }
    qualys = merge(
      {
        args = {
          tagSensorProfile = local.sensor_tags_csv
        }
      },
      var.images.qcs_sensor == null ? {} : { image = var.images.qcs_sensor },
    )
  }

  runtime_sensor_values = merge(
    {
      enabled = var.components.runtime_sensor
      tags    = local.sensor_tags_csv
    },
    var.images.runtime_sensor == null ? {} : { image = var.images.runtime_sensor },
  )

  admission_controller_values = merge(
    {
      enabled = var.components.admission_controller
    },
    var.images.admission_controller == null ? {} : { image = var.images.admission_controller },
  )

  values = {
    global              = local.global
    clusterSensor       = local.cluster_sensor_values
    qcsSensor           = local.qcs_sensor_values
    runtimeSensor       = local.runtime_sensor_values
    admissionController = local.admission_controller_values
  }
}
