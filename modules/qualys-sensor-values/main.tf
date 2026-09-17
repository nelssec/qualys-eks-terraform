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
      enabled       = var.components.cluster_sensor
      k8sCompliance = { enable = var.cluster_sensor.k8s_compliance }
      hostScanner   = { enable = var.cluster_sensor.host_scanner, runOnMaster = var.cluster_sensor.host_scanner_run_on_master }
      tags          = local.sensor_tags_csv
    },
    local.scheduling,
    var.images.cluster_sensor == null ? {} : { image = var.images.cluster_sensor },
    var.cluster_sensor.log_level == null ? {} : { logConfig = { logLevel = var.cluster_sensor.log_level } },
    length(local.cluster_sensor_resources) == 0 ? {} : { resources = local.cluster_sensor_resources },
  )

  qcs_sensor_values = merge(
    {
      enabled    = var.components.qcs_sensor
      containerd = local.containerd_runtime
      crio       = local.crio_runtime
      docker     = { enabled = false }
      qualys = merge(
        {
          args = {
            concurrentScan           = tostring(var.qcs_sensor.concurrent_scan)
            performScaScan           = var.qcs_sensor.perform_sca_scan
            performSecretDetection   = var.qcs_sensor.perform_secret_detection
            performMalwareDetection  = var.qcs_sensor.perform_malware_detection
            withoutPersistentStorage = var.qcs_sensor.without_persistent_storage
            enableConsoleLogs        = var.qcs_sensor.enable_console_logs
            logLevel                 = tostring(var.qcs_sensor.log_level)
            populateK8sMetadata      = var.qcs_sensor.populate_k8s_metadata
            optimizeImageScans       = var.qcs_sensor.optimize_image_scans
            tagSensorProfile         = local.sensor_tags_csv
          }
        },
        var.images.qcs_sensor == null ? {} : { image = var.images.qcs_sensor },
        length(local.qcs_sensor_cont_resources) == 0 ? {} : { sensorContResources = merge({ enabled = true }, local.qcs_sensor_cont_resources) },
        length(local.qcs_scanning_cont_resources) == 0 ? {} : { scanningContResources = merge({ enabled = true }, local.qcs_scanning_cont_resources) },
      )
    },
    local.scheduling,
  )

  runtime_sensor_values = merge(
    {
      enabled              = var.components.runtime_sensor
      logConfig            = { logLevel = var.runtime_sensor.log_level }
      eventGlobalRateLimit = var.runtime_sensor.event_global_rate_limit
      processAllowList = {
        enabled = length(var.runtime_sensor.process_allow_list) > 0
        value   = join(",", var.runtime_sensor.process_allow_list)
      }
      tags = local.sensor_tags_csv
    },
    local.scheduling,
    var.images.runtime_sensor == null ? {} : { image = var.images.runtime_sensor },
    length(local.runtime_sensor_resources) == 0 ? {} : { resources = local.runtime_sensor_resources },
  )

  admission_controller_values = merge(
    {
      enabled           = var.components.admission_controller
      enforcementAction = var.admission_controller.enforcement_action
      webhook           = { failurePolicy = var.admission_controller.failure_policy }
      certs             = { certsProvider = var.admission_controller.certs_provider }
    },
    local.scheduling,
    var.images.admission_controller == null ? {} : { image = var.images.admission_controller },
    length(local.admission_controller_resources) == 0 ? {} : { resources = local.admission_controller_resources },
  )

  values = {
    global              = local.global
    clusterSensor       = local.cluster_sensor_values
    qcsSensor           = local.qcs_sensor_values
    runtimeSensor       = local.runtime_sensor_values
    admissionController = local.admission_controller_values
  }
}
