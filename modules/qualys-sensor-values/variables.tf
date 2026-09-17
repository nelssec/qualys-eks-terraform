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
