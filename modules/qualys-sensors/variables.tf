# ---------------------------------------------------------------------------
# Release / credentials
# ---------------------------------------------------------------------------

variable "credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the Qualys Customer ID and Activation ID as a JSON object. Use the qualys-secrets module or supply your own."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+$", var.credentials_secret_arn))
    error_message = "credentials_secret_arn must be a Secrets Manager secret ARN."
  }
}

variable "credentials_secret_keys" {
  description = "JSON key names inside the secret."
  type = object({
    customer_id   = optional(string, "customer_id")
    activation_id = optional(string, "activation_id")
  })
  default = {}
}

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "qualys-tc"
}

variable "namespace" {
  description = "Namespace for all Qualys components. The qcs-sensor containerd TLS secret template hardcodes 'qualys'; keep the default unless you do not use that feature."
  type        = string
  default     = "qualys"
}

variable "create_namespace" {
  description = "Create the namespace if it does not exist."
  type        = bool
  default     = true
}

variable "chart_repository" {
  description = "Helm repository URL for qualys-tc."
  type        = string
  default     = "https://qualys.github.io/Qualys-Helm-Charts/"
}

variable "chart_version" {
  description = "qualys-tc chart version. Pinned; bump deliberately and read the chart README compatibility matrix first."
  type        = string
  default     = "2.10.0"
}

variable "helm_timeout_seconds" {
  description = "Timeout for Helm operations."
  type        = number
  default     = 600
}

variable "helm_atomic" {
  description = "Roll back the release if install/upgrade fails."
  type        = bool
  default     = true
}

variable "helm_wait" {
  description = "Wait for resources to become ready before marking the release successful."
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# Forwarded to qualys-sensor-values (identical declarations)
# ---------------------------------------------------------------------------

variable "cluster_arn" {
  description = "ARN of the target EKS cluster. Rendered to global.clusterInfoArgs.AWS.arn."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-z-]*:eks:[a-z0-9-]+:[0-9]{12}:cluster/.+$", var.cluster_arn))
    error_message = "cluster_arn must look like arn:aws:eks:<region>:<account-id>:cluster/<name>."
  }
}

variable "qualys_platform" {
  description = "Qualys platform (POD) identifier. See docs/platform-urls.md."
  type        = string

  validation {
    condition     = contains(["US1", "US2", "US3", "US4", "GOV1", "EU1", "EU2", "EU3", "IN1", "CA1", "AE1", "UK1", "AU1", "KSA1"], var.qualys_platform)
    error_message = "qualys_platform must be one of US1, US2, US3, US4, GOV1, EU1, EU2, EU3, IN1, CA1, AE1, UK1, AU1, KSA1."
  }
}

variable "gateway_url" {
  description = "Override for global.gatewayUrl."
  type        = string
  default     = null
}

variable "cmsqag_public_url" {
  description = "Override for global.cmsqagPublicUrl."
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
  description = "Container runtime on the worker nodes (containerd or crio)."
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
  description = "Outbound proxy for Qualys platform traffic."
  type = object({
    url                   = string
    ca_certificate_base64 = optional(string)
    skip_verify_tls       = optional(bool, false)
  })
  default = null
}

variable "root_ca_certificate_base64" {
  description = "Custom root CA (base64) required to reach the Qualys platform."
  type        = string
  default     = null
}

variable "images" {
  description = "Per-component image overrides for private registries."
  type = object({
    cluster_sensor       = optional(string)
    qcs_sensor           = optional(string)
    runtime_sensor       = optional(string)
    admission_controller = optional(string)
  })
  default = {}
}

variable "image_pull_secrets" {
  description = "Image pull secrets for private registries. Credential fields are passed via set_sensitive."
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
  description = "Tags applied to cluster, runtime and QCS sensors."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.sensor_tags) <= 10
    error_message = "At most 10 sensor_tags are allowed by the sensors."
  }
}

variable "cluster_sensor" {
  description = "Cluster Sensor options."
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
}

variable "qcs_sensor" {
  description = "QCS Sensor options."
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
}

variable "runtime_sensor" {
  description = "Container Runtime Sensor options."
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
}

variable "admission_controller" {
  description = "Admission Controller options."
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
}

variable "extra_values" {
  description = "Escape hatch: arbitrary qualys-tc values merged by Helm after the rendered values."
  type        = any
  default     = {}
}
