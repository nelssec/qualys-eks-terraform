variables {
  cluster_arn     = "arn:aws:eks:us-east-1:123456789012:cluster/demo"
  qualys_platform = "US2"
  components = {
    cluster_sensor       = true
    qcs_sensor           = true
    runtime_sensor       = true
    admission_controller = true
  }
}

run "component_defaults_match_chart_conventions" {
  command = plan
  assert {
    condition     = output.values.qcsSensor.qualys.args.concurrentScan == "4" && output.values.qcsSensor.qualys.args.logLevel == "3"
    error_message = "concurrentScan and logLevel must be emitted as strings"
  }
  assert {
    condition     = output.values.qcsSensor.qualys.args.performScaScan == false && output.values.qcsSensor.qualys.args.optimizeImageScans == true
    error_message = "qcs arg defaults wrong"
  }
  assert {
    condition     = output.values.clusterSensor.k8sCompliance.enable && output.values.clusterSensor.hostScanner.enable && output.values.clusterSensor.hostScanner.runOnMaster
    error_message = "cluster sensor defaults wrong"
  }
  assert {
    condition     = output.values.runtimeSensor.processAllowList.enabled == false && output.values.runtimeSensor.processAllowList.value == "" && output.values.runtimeSensor.eventGlobalRateLimit == 200
    error_message = "runtime sensor defaults wrong"
  }
  assert {
    condition     = output.values.admissionController.enforcementAction == "Audit" && output.values.admissionController.webhook.failurePolicy == "Ignore" && output.values.admissionController.certs.certsProvider == "helm"
    error_message = "admission controller defaults wrong"
  }
  assert {
    condition     = !contains(keys(output.values.clusterSensor), "resources") && !contains(keys(output.values.runtimeSensor), "resources") && !contains(keys(output.values.qcsSensor.qualys), "sensorContResources")
    error_message = "resources keys must be absent when not set so chart defaults apply"
  }
  assert {
    condition     = !contains(keys(output.values.clusterSensor), "logConfig")
    error_message = "cluster sensor logConfig must be absent when log_level is null"
  }
}

run "component_options_render" {
  command = plan
  variables {
    qcs_sensor = {
      concurrent_scan            = 8
      perform_sca_scan           = true
      perform_secret_detection   = true
      without_persistent_storage = true
      resources = {
        sensor   = { limits = { cpu = "1", memory = "1Gi" }, requests = { memory = "512Mi" } }
        scanning = { limits = { memory = "2Gi" } }
      }
    }
    runtime_sensor = {
      process_allow_list = ["/*/curl", "/*/(wget|nc)"]
      log_level          = "debug"
      resources          = { limits = { cpu = "1", memory = "2Gi" } }
    }
    admission_controller = {
      enforcement_action = "Block"
      failure_policy     = "Fail"
      certs_provider     = "cert-manager"
    }
    cluster_sensor = {
      host_scanner_run_on_master = false
      log_level                  = "debug"
      resources                  = { requests = { cpu = "250m", memory = "512Mi" } }
    }
  }
  assert {
    condition     = output.values.qcsSensor.qualys.args.concurrentScan == "8" && output.values.qcsSensor.qualys.args.performScaScan && output.values.qcsSensor.qualys.args.performSecretDetection && output.values.qcsSensor.qualys.args.withoutPersistentStorage
    error_message = "qcs args not rendered"
  }
  assert {
    condition     = jsonencode(output.values.qcsSensor.qualys.sensorContResources) == jsonencode({ enabled = true, limits = { cpu = "1", memory = "1Gi" }, requests = { memory = "512Mi" } })
    error_message = "sensorContResources wrong: ${jsonencode(output.values.qcsSensor.qualys.sensorContResources)}"
  }
  assert {
    condition     = jsonencode(output.values.qcsSensor.qualys.scanningContResources) == jsonencode({ enabled = true, limits = { memory = "2Gi" } })
    error_message = "scanningContResources wrong: ${jsonencode(output.values.qcsSensor.qualys.scanningContResources)}"
  }
  assert {
    condition     = output.values.runtimeSensor.processAllowList == { enabled = true, value = "/*/curl,/*/(wget|nc)" } && output.values.runtimeSensor.logConfig.logLevel == "debug"
    error_message = "runtime sensor options wrong"
  }
  assert {
    condition     = jsonencode(output.values.runtimeSensor.resources) == jsonencode({ limits = { cpu = "1", memory = "2Gi" } })
    error_message = "runtime resources wrong: ${jsonencode(output.values.runtimeSensor.resources)}"
  }
  assert {
    condition     = output.values.admissionController.enforcementAction == "Block" && output.values.admissionController.webhook.failurePolicy == "Fail" && output.values.admissionController.certs.certsProvider == "cert-manager"
    error_message = "admission controller options wrong"
  }
  assert {
    condition     = output.values.clusterSensor.hostScanner.runOnMaster == false && output.values.clusterSensor.logConfig.logLevel == "debug" && jsonencode(output.values.clusterSensor.resources) == jsonencode({ requests = { cpu = "250m", memory = "512Mi" } })
    error_message = "cluster sensor options wrong"
  }
}

run "scheduling_applies_to_all_components_with_nulls_stripped" {
  command = plan
  variables {
    node_selector = { "workload" = "security" }
    tolerations = [
      { key = "dedicated", operator = "Equal", value = "security", effect = "NoSchedule" },
      { operator = "Exists" },
    ]
  }
  assert {
    condition     = alltrue([for c in ["clusterSensor", "qcsSensor", "runtimeSensor", "admissionController"] : jsonencode(output.values[c].nodeSelector) == jsonencode({ "workload" = "security" })])
    error_message = "nodeSelector must be applied to every component"
  }
  assert {
    condition     = output.values.qcsSensor.tolerations == [{ key = "dedicated", operator = "Equal", value = "security", effect = "NoSchedule" }, { operator = "Exists" }]
    error_message = "tolerations must be applied with null fields removed: ${jsonencode(output.values.qcsSensor.tolerations)}"
  }
}

run "extra_values_yaml_is_separate_document" {
  command = plan
  variables {
    extra_values = {
      clusterSensor = { maskEnvVariable = true }
      qcsSensor     = { qualys = { args = { scanningPolicy = "StaticScanningOnly" } } }
    }
  }
  assert {
    condition     = yamldecode(output.extra_values_yaml).clusterSensor.maskEnvVariable == true
    error_message = "extra_values must round-trip through extra_values_yaml"
  }
  assert {
    condition     = !contains(keys(output.values.clusterSensor), "maskEnvVariable")
    error_message = "extra_values must not be merged into values; Helm merges the two documents"
  }
}

run "rejects_bad_enums_and_ranges" {
  command = plan
  variables {
    qcs_sensor           = { concurrent_scan = 21 }
    admission_controller = { enforcement_action = "Deny" }
    tolerations          = [{ operator = "Sometimes" }]
  }
  expect_failures = [var.qcs_sensor, var.admission_controller, var.tolerations]
}
