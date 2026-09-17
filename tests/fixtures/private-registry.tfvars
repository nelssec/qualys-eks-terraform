images = {
  cluster_sensor       = "123456789012.dkr.ecr.us-east-1.amazonaws.com/qualys/cluster-sensor:1.7.0-0"
  qcs_sensor           = "123456789012.dkr.ecr.us-east-1.amazonaws.com/qualys/qcs-sensor:1.44.2-0"
  runtime_sensor       = "123456789012.dkr.ecr.us-east-1.amazonaws.com/qualys/runtime-sensor:1.7.0-0"
  admission_controller = "123456789012.dkr.ecr.us-east-1.amazonaws.com/qualys/admission-controller:1.1.2-0"
}
image_pull_secrets = [
  { name = "existing-pull-secret" },
  { name = "created-pull-secret", create = true, registry_url = "registry.example.com", username = "svc", password = "render-only-placeholder" },
]
components = {
  runtime_sensor       = true
  admission_controller = true
}
extra_values = {
  clusterSensor = { maskEnvVariable = true }
}
