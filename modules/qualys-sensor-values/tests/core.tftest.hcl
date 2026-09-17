variables {
  cluster_arn     = "arn:aws:eks:us-east-1:123456789012:cluster/demo"
  qualys_platform = "US2"
}

run "defaults_render_us2_with_cluster_and_qcs_sensors" {
  command = plan

  assert {
    condition     = output.values.global.gatewayUrl == "https://gateway.qg2.apps.qualys.com"
    error_message = "US2 gateway URL rendered as ${output.values.global.gatewayUrl}"
  }
  assert {
    condition     = output.values.global.cmsqagPublicUrl == "https://cmsqagpublic.qg2.apps.qualys.com/ContainerSensor"
    error_message = "US2 cmsqagpublic URL rendered as ${output.values.global.cmsqagPublicUrl}"
  }
  assert {
    condition     = output.values.global.clusterInfoArgs.cloudProvider == "AWS" && output.values.global.clusterInfoArgs.AWS.arn == var.cluster_arn
    error_message = "clusterInfoArgs must carry cloudProvider=AWS and the cluster ARN"
  }
  assert {
    condition     = output.values.clusterSensor.enabled && output.values.qcsSensor.enabled && !output.values.runtimeSensor.enabled && !output.values.admissionController.enabled
    error_message = "default components must be cluster sensor + QCS on, runtime + admission off"
  }
  assert {
    condition     = output.enabled_components == ["cluster_sensor", "qcs_sensor"]
    error_message = "enabled_components was ${jsonencode(output.enabled_components)}"
  }
  assert {
    condition     = !can(regex("customerId|activationId", output.values_yaml))
    error_message = "values YAML must never contain credential keys"
  }
  assert {
    condition     = can(yamldecode(output.values_yaml))
    error_message = "values_yaml must be valid YAML"
  }
}

run "gov1_uses_its_own_host_pattern" {
  command = plan
  variables {
    qualys_platform = "GOV1"
  }
  assert {
    condition     = output.values.global.gatewayUrl == "https://gateway.gov1.qualys.us" && output.values.global.cmsqagPublicUrl == "https://cmsqagpublic.gov1.qualys.us/ContainerSensor"
    error_message = "GOV1 URLs wrong: ${output.values.global.gatewayUrl} / ${output.values.global.cmsqagPublicUrl}"
  }
}

run "explicit_urls_override_platform" {
  command = plan
  variables {
    gateway_url       = "https://gateway.private.example.com"
    cmsqag_public_url = "https://cmsqagpublic.private.example.com/ContainerSensor"
  }
  assert {
    condition     = output.gateway_url == "https://gateway.private.example.com" && output.cmsqag_public_url == "https://cmsqagpublic.private.example.com/ContainerSensor"
    error_message = "explicit URL overrides were not honoured"
  }
}

run "all_components_can_be_enabled" {
  command = plan
  variables {
    components = {
      cluster_sensor       = true
      qcs_sensor           = true
      runtime_sensor       = true
      admission_controller = true
    }
  }
  assert {
    condition     = output.values.runtimeSensor.enabled && output.values.admissionController.enabled
    error_message = "runtime sensor and admission controller should be enabled"
  }
  assert {
    condition     = length(output.enabled_components) == 4
    error_message = "expected 4 enabled components"
  }
}

run "rejects_unknown_platform" {
  command = plan
  variables {
    qualys_platform = "MARS1"
  }
  expect_failures = [var.qualys_platform]
}

run "rejects_malformed_cluster_arn" {
  command = plan
  variables {
    cluster_arn = "my-cluster"
  }
  expect_failures = [var.cluster_arn]
}
