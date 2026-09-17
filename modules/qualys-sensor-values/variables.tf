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
