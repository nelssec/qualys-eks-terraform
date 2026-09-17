variables {
  cluster_arn     = "arn:aws:eks:us-east-1:123456789012:cluster/demo"
  qualys_platform = "US2"
}

run "containerd_is_default_runtime_in_both_places" {
  command = plan
  assert {
    condition     = output.values.global.containerRuntimes.containerd.enabled && !output.values.global.containerRuntimes.crio.enabled
    error_message = "global.containerRuntimes must enable containerd only"
  }
  assert {
    condition     = output.values.qcsSensor.containerd.enabled && !output.values.qcsSensor.crio.enabled && !output.values.qcsSensor.docker.enabled
    error_message = "qcsSensor runtime flags must enable containerd only"
  }
  assert {
    condition     = output.values.qcsSensor.containerd.socketPath == "/var/run/containerd/containerd.sock"
    error_message = "default containerd socket path wrong"
  }
}

run "crio_runtime_with_custom_socket" {
  command = plan
  variables {
    container_runtime = { type = "crio", socket_path = "/run/crio/crio.sock" }
  }
  assert {
    condition     = output.values.global.containerRuntimes.crio.enabled && output.values.global.containerRuntimes.crio.socketPath == "/run/crio/crio.sock"
    error_message = "global crio settings wrong"
  }
  assert {
    condition     = output.values.qcsSensor.crio.enabled && !output.values.qcsSensor.containerd.enabled && output.values.qcsSensor.crio.socketPath == "/run/crio/crio.sock"
    error_message = "qcsSensor crio settings wrong"
  }
}

run "rejects_docker_runtime" {
  command = plan
  variables {
    container_runtime = { type = "docker" }
  }
  expect_failures = [var.container_runtime]
}

run "no_proxy_emits_empty_strings_not_nulls" {
  command = plan
  assert {
    condition     = output.values.global.proxy.value == "" && output.values.global.proxy.certificate == "" && output.values.global.proxy.skipVerifyTLS == false
    error_message = "proxy block must be present with empty values when unset"
  }
  assert {
    condition     = output.values.global.rootCA.certificate == ""
    error_message = "rootCA block must be present with empty certificate when unset"
  }
}

run "proxy_with_ca" {
  command = plan
  variables {
    proxy = {
      url                   = "http://proxy.corp.example.com:3128"
      ca_certificate_base64 = "LS0tLS1CRUdJTi0tLS0t"
      skip_verify_tls       = true
    }
    root_ca_certificate_base64 = "Um9vdENB"
  }
  assert {
    condition     = output.values.global.proxy.value == "http://proxy.corp.example.com:3128" && output.values.global.proxy.certificate == "LS0tLS1CRUdJTi0tLS0t" && output.values.global.proxy.skipVerifyTLS
    error_message = "proxy settings not rendered"
  }
  assert {
    condition     = output.values.global.rootCA.certificate == "Um9vdENB"
    error_message = "root CA not rendered"
  }
}

run "images_are_only_emitted_when_set" {
  command = plan
  variables {
    images = {
      cluster_sensor = "123456789012.dkr.ecr.us-east-1.amazonaws.com/qualys/cluster-sensor:1.7.0-0"
      qcs_sensor     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/qualys/qcs-sensor:1.44.2-0"
    }
  }
  assert {
    condition     = output.values.clusterSensor.image == "123456789012.dkr.ecr.us-east-1.amazonaws.com/qualys/cluster-sensor:1.7.0-0"
    error_message = "cluster sensor image override missing"
  }
  assert {
    condition     = output.values.qcsSensor.qualys.image == "123456789012.dkr.ecr.us-east-1.amazonaws.com/qualys/qcs-sensor:1.44.2-0"
    error_message = "qcs sensor image override missing (must be under qcsSensor.qualys.image)"
  }
  assert {
    condition     = !contains(keys(output.values.runtimeSensor), "image") && !contains(keys(output.values.admissionController), "image")
    error_message = "image keys must be absent when not overridden so chart defaults apply"
  }
}

run "pull_secret_credentials_leave_yaml_and_go_to_set_sensitive" {
  command = plan
  variables {
    image_pull_secrets = [
      { name = "existing-secret" },
      { name = "artifactory", create = true, registry_url = "registry.corp.example.com", username = "svc", password = "s3cr3t" },
    ]
  }
  assert {
    condition     = length(output.values.global.imagePullSecrets) == 2
    error_message = "both pull secrets must be listed"
  }
  assert {
    condition     = output.values.global.imagePullSecrets[0].name == "existing-secret" && output.values.global.imagePullSecrets[0].create == false
    error_message = "reference-only secret must default create=false"
  }
  assert {
    condition     = output.values.global.imagePullSecrets[1].registry_url == "registry.corp.example.com" && output.values.global.imagePullSecrets[1].username == "svc"
    error_message = "non-secret pull secret fields must be in YAML"
  }
  assert {
    condition     = !can(regex("s3cr3t", output.values_yaml))
    error_message = "password must not appear in values YAML"
  }
  assert {
    condition     = jsonencode(output.sensitive_set_values) == jsonencode([{ name = "global.imagePullSecrets[1].password", value = "s3cr3t", type = "string" }])
    error_message = "password must be routed through sensitive_set_values"
  }
}

run "pull_secret_password_is_escaped_for_helm_set" {
  command = plan
  variables {
    image_pull_secrets = [
      { name = "reg", create = true, registry_url = "registry.example.com", username = "svc", password = "a,b\\c" },
    ]
  }
  assert {
    condition     = output.sensitive_set_values[0].value == "a\\,b\\\\c"
    error_message = "commas and backslashes must be escaped for Helm --set: got ${output.sensitive_set_values[0].value}"
  }
}

run "sensor_tags_are_joined_for_all_sensors" {
  command = plan
  variables {
    sensor_tags = ["fadv", "eks-prod"]
  }
  assert {
    condition     = output.values.clusterSensor.tags == "fadv,eks-prod" && output.values.runtimeSensor.tags == "fadv,eks-prod" && output.values.qcsSensor.qualys.args.tagSensorProfile == "fadv,eks-prod"
    error_message = "sensor tags must be a comma-joined string on all three sensors"
  }
}
