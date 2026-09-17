locals {
  platform_hosts = {
    US1  = "qg1.apps.qualys.com"
    US2  = "qg2.apps.qualys.com"
    US3  = "qg3.apps.qualys.com"
    US4  = "qg4.apps.qualys.com"
    GOV1 = "gov1.qualys.us"
    EU1  = "qg1.apps.qualys.eu"
    EU2  = "qg2.apps.qualys.eu"
    EU3  = "qg3.apps.qualys.it"
    IN1  = "qg1.apps.qualys.in"
    CA1  = "qg1.apps.qualys.ca"
    AE1  = "qg1.apps.qualys.ae"
    UK1  = "qg1.apps.qualys.co.uk"
    AU1  = "qg1.apps.qualys.com.au"
    KSA1 = "qg1.apps.qualysksa.com"
  }

  platform_host     = local.platform_hosts[var.qualys_platform]
  gateway_url       = var.gateway_url != null ? var.gateway_url : "https://gateway.${local.platform_host}"
  cmsqag_public_url = var.cmsqag_public_url != null ? var.cmsqag_public_url : "https://cmsqagpublic.${local.platform_host}/ContainerSensor"

  enabled_components = [
    for name in ["cluster_sensor", "qcs_sensor", "runtime_sensor", "admission_controller"] :
    name if var.components[name]
  ]
}

locals {
  default_socket_paths = {
    containerd = "/var/run/containerd/containerd.sock"
    crio       = "/var/run/crio/crio.sock"
  }
  runtime_is_containerd = var.container_runtime.type == "containerd"
  runtime_socket        = var.container_runtime.socket_path != null ? var.container_runtime.socket_path : local.default_socket_paths[var.container_runtime.type]

  containerd_runtime = {
    enabled    = local.runtime_is_containerd
    socketPath = local.runtime_is_containerd ? local.runtime_socket : local.default_socket_paths.containerd
  }
  crio_runtime = {
    enabled    = !local.runtime_is_containerd
    socketPath = local.runtime_is_containerd ? local.default_socket_paths.crio : local.runtime_socket
  }

  proxy_value       = var.proxy == null ? "" : var.proxy.url
  proxy_certificate = var.proxy == null ? "" : (var.proxy.ca_certificate_base64 == null ? "" : var.proxy.ca_certificate_base64)
  proxy_skip_verify = var.proxy == null ? false : var.proxy.skip_verify_tls
  root_ca           = var.root_ca_certificate_base64 == null ? "" : var.root_ca_certificate_base64

  sensor_tags_csv = join(",", var.sensor_tags)

  image_pull_secrets_public = [
    for s in var.image_pull_secrets : merge(
      { name = s.name, create = s.create },
      s.registry_url == null ? {} : { registry_url = s.registry_url },
      s.username == null ? {} : { username = s.username },
    )
  ]

  sensitive_set_values = flatten([
    for i, s in var.image_pull_secrets : concat(
      s.password == null ? [] : [{ name = "global.imagePullSecrets[${i}].password", value = s.password }],
      s.dockerconfigjson == null ? [] : [{ name = "global.imagePullSecrets[${i}].dockerconfigjson", value = s.dockerconfigjson }],
    )
  ])
}
