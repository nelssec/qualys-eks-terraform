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
      s.password == null ? [] : [{ name = "global.imagePullSecrets[${i}].password", value = replace(replace(s.password, "\\", "\\\\"), ",", "\\,"), type = "string" }],
      s.dockerconfigjson == null ? [] : [{ name = "global.imagePullSecrets[${i}].dockerconfigjson", value = s.dockerconfigjson, type = "string" }],
    )
  ])
}

locals {
  # Convert an optional {limits, requests} object into a chart-shaped map with null fields removed.
  cluster_sensor_resources = var.cluster_sensor.resources == null ? {} : {
    for section, vals in { limits = var.cluster_sensor.resources.limits, requests = var.cluster_sensor.resources.requests } :
    section => { for k, v in { cpu = vals.cpu, memory = vals.memory } : k => v if v != null } if vals != null
  }
  runtime_sensor_resources = var.runtime_sensor.resources == null ? {} : {
    for section, vals in { limits = var.runtime_sensor.resources.limits, requests = var.runtime_sensor.resources.requests } :
    section => { for k, v in { cpu = vals.cpu, memory = vals.memory } : k => v if v != null } if vals != null
  }
  admission_controller_resources = var.admission_controller.resources == null ? {} : {
    for section, vals in { limits = var.admission_controller.resources.limits, requests = var.admission_controller.resources.requests } :
    section => { for k, v in { cpu = vals.cpu, memory = vals.memory } : k => v if v != null } if vals != null
  }
  qcs_sensor_cont_resources = try(var.qcs_sensor.resources.sensor, null) == null ? {} : {
    for section, vals in { limits = var.qcs_sensor.resources.sensor.limits, requests = var.qcs_sensor.resources.sensor.requests } :
    section => { for k, v in { cpu = vals.cpu, memory = vals.memory } : k => v if v != null } if vals != null
  }
  qcs_scanning_cont_resources = try(var.qcs_sensor.resources.scanning, null) == null ? {} : {
    for section, vals in { limits = var.qcs_sensor.resources.scanning.limits, requests = var.qcs_sensor.resources.scanning.requests } :
    section => { for k, v in { cpu = vals.cpu, memory = vals.memory } : k => v if v != null } if vals != null
  }

  tolerations = [for t in var.tolerations : { for k, v in t : k => v if v != null }]

  scheduling = {
    nodeSelector = var.node_selector
    tolerations  = local.tolerations
  }
}
