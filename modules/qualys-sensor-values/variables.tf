variable "cluster_arn" {
  description = "ARN of the target EKS cluster. Rendered to global.clusterInfoArgs.AWS.arn."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:eks:[a-z0-9-]+:[0-9]{12}:cluster/.+$", var.cluster_arn))
    error_message = "cluster_arn must look like arn:aws:eks:<region>:<account-id>:cluster/<name>."
  }
}

variable "qualys_platform" {
  description = "Qualys platform (POD) identifier. Selects the gateway and cmsqagpublic URLs unless gateway_url / cmsqag_public_url are set. See docs/platform-urls.md."
  type        = string

  validation {
    condition     = contains(["US1", "US2", "US3", "US4", "GOV1", "EU1", "EU2", "EU3", "IN1", "CA1", "AE1", "UK1", "AU1", "KSA1"], var.qualys_platform)
    error_message = "qualys_platform must be one of US1, US2, US3, US4, GOV1, EU1, EU2, EU3, IN1, CA1, AE1, UK1, AU1, KSA1."
  }
}

variable "gateway_url" {
  description = "Override for global.gatewayUrl. Use for private platforms; otherwise leave null and set qualys_platform."
  type        = string
  default     = null
}

variable "cmsqag_public_url" {
  description = "Override for global.cmsqagPublicUrl. Use for private platforms; otherwise leave null and set qualys_platform."
  type        = string
  default     = null
}

variable "components" {
  description = "Which qualys-tc sub-charts to enable."
  type = object({
    cluster_sensor       = optional(bool, true)
    qcs_sensor           = optional(bool, true)
    runtime_sensor       = optional(bool, false)
    admission_controller = optional(bool, false)
  })
  default = {}
}

variable "container_runtime" {
  description = "Container runtime on the worker nodes. EKS AL2023 and Bottlerocket use containerd. Sets both global.containerRuntimes and qcsSensor runtime flags."
  type = object({
    type        = optional(string, "containerd")
    socket_path = optional(string)
  })
  default = {}

  validation {
    condition     = contains(["containerd", "crio"], var.container_runtime.type)
    error_message = "container_runtime.type must be containerd or crio."
  }
}

variable "proxy" {
  description = "Outbound proxy for Qualys platform traffic. url format http://host:port. ca_certificate_base64 is the proxy CA in base64."
  type = object({
    url                   = string
    ca_certificate_base64 = optional(string)
    skip_verify_tls       = optional(bool, false)
  })
  default = null
}

variable "root_ca_certificate_base64" {
  description = "Custom root CA (base64) required to reach the Qualys platform, e.g. behind TLS inspection."
  type        = string
  default     = null
}

variable "images" {
  description = "Per-component image overrides (repository:tag) for private registries. Omitted entries use the chart defaults."
  type = object({
    cluster_sensor       = optional(string)
    qcs_sensor           = optional(string)
    runtime_sensor       = optional(string)
    admission_controller = optional(string)
  })
  default = {}
}

variable "image_pull_secrets" {
  description = "Image pull secrets for private registries. create=false references an existing Secret by name. create=true lets the chart create it from registry_url/username/password or dockerconfigjson; those two credential fields are routed through set_sensitive and never rendered into YAML. ECR in the same account needs no pull secret when the node role has ECR read access."
  type = list(object({
    name             = string
    create           = optional(bool, false)
    registry_url     = optional(string)
    username         = optional(string)
    password         = optional(string)
    dockerconfigjson = optional(string)
  }))
  default = []
}

variable "sensor_tags" {
  description = "Tags applied to cluster, runtime and QCS sensors (used for sensor profile assignment). Max 10; joined with commas."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.sensor_tags) <= 10
    error_message = "At most 10 sensor_tags are allowed by the sensors."
  }
}

variable "cluster_sensor" {
  description = "Cluster Sensor options. Null fields fall back to chart defaults."
  type = object({
    k8s_compliance             = optional(bool, true)
    host_scanner               = optional(bool, true)
    host_scanner_run_on_master = optional(bool, true)
    log_level                  = optional(string)
    resources = optional(object({
      limits   = optional(object({ cpu = optional(string), memory = optional(string) }))
      requests = optional(object({ cpu = optional(string), memory = optional(string) }))
    }))
  })
  default = {}

  validation {
    condition     = var.cluster_sensor.log_level == null || contains(["debug", "info", "warn", "error", "fatal"], coalesce(var.cluster_sensor.log_level, "info"))
    error_message = "cluster_sensor.log_level must be one of debug, info, warn, error, fatal."
  }
}

variable "qcs_sensor" {
  description = "QCS (Container Security) Sensor options."
  type = object({
    concurrent_scan            = optional(number, 4)
    perform_sca_scan           = optional(bool, false)
    perform_secret_detection   = optional(bool, false)
    perform_malware_detection  = optional(bool, false)
    without_persistent_storage = optional(bool, false)
    enable_console_logs        = optional(bool, false)
    log_level                  = optional(number, 3)
    populate_k8s_metadata      = optional(bool, false)
    optimize_image_scans       = optional(bool, true)
    resources = optional(object({
      sensor = optional(object({
        limits   = optional(object({ cpu = optional(string), memory = optional(string) }))
        requests = optional(object({ cpu = optional(string), memory = optional(string) }))
      }))
      scanning = optional(object({
        limits   = optional(object({ cpu = optional(string), memory = optional(string) }))
        requests = optional(object({ cpu = optional(string), memory = optional(string) }))
      }))
    }))
  })
  default = {}

  validation {
    condition     = var.qcs_sensor.concurrent_scan >= 1 && var.qcs_sensor.concurrent_scan <= 20
    error_message = "qcs_sensor.concurrent_scan must be between 1 and 20."
  }
  validation {
    condition     = var.qcs_sensor.log_level >= 0 && var.qcs_sensor.log_level <= 5
    error_message = "qcs_sensor.log_level must be between 0 (fatal) and 5 (trace)."
  }
}

variable "runtime_sensor" {
  description = "Container Runtime Sensor (CRS) options."
  type = object({
    process_allow_list      = optional(list(string), [])
    event_global_rate_limit = optional(number, 200)
    log_level               = optional(string, "info")
    resources = optional(object({
      limits   = optional(object({ cpu = optional(string), memory = optional(string) }))
      requests = optional(object({ cpu = optional(string), memory = optional(string) }))
    }))
  })
  default = {}

  validation {
    condition     = var.runtime_sensor.event_global_rate_limit >= 10 && var.runtime_sensor.event_global_rate_limit <= 500
    error_message = "runtime_sensor.event_global_rate_limit must be between 10 and 500."
  }
  validation {
    condition     = contains(["debug", "info", "warn", "error", "fatal"], var.runtime_sensor.log_level)
    error_message = "runtime_sensor.log_level must be one of debug, info, warn, error, fatal."
  }
}

variable "admission_controller" {
  description = "Admission Controller options. Block mode denies non-compliant pods; start with Audit."
  type = object({
    enforcement_action = optional(string, "Audit")
    failure_policy     = optional(string, "Ignore")
    certs_provider     = optional(string, "helm")
    resources = optional(object({
      limits   = optional(object({ cpu = optional(string), memory = optional(string) }))
      requests = optional(object({ cpu = optional(string), memory = optional(string) }))
    }))
  })
  default = {}

  validation {
    condition     = contains(["Audit", "Block"], var.admission_controller.enforcement_action)
    error_message = "admission_controller.enforcement_action must be Audit or Block."
  }
  validation {
    condition     = contains(["Ignore", "Fail"], var.admission_controller.failure_policy)
    error_message = "admission_controller.failure_policy must be Ignore or Fail."
  }
  validation {
    condition     = contains(["helm", "cert-manager"], var.admission_controller.certs_provider)
    error_message = "admission_controller.certs_provider must be helm or cert-manager."
  }
}

variable "node_selector" {
  description = "nodeSelector applied to every Qualys component."
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations applied to every Qualys component."
  type = list(object({
    key      = optional(string)
    operator = string
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for t in var.tolerations : contains(["Exists", "Equal"], t.operator)])
    error_message = "Every toleration operator must be Exists or Equal."
  }
}

variable "extra_values" {
  description = "Escape hatch: arbitrary qualys-tc values merged by Helm AFTER the rendered values, so they win on conflict. Must not contain global.customerId or global.activationId."
  type        = any
  default     = {}

  validation {
    condition     = !can(var.extra_values.global.customerId) && !can(var.extra_values.global.activationId)
    error_message = "extra_values must not set global.customerId or global.activationId; credentials come from Secrets Manager."
  }
}
