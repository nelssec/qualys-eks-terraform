variable "region" {
  description = "AWS region of the cluster."
  type        = string
}

variable "cluster_name" {
  description = "Name of the existing EKS cluster."
  type        = string
}

variable "qualys_platform" {
  description = "Qualys platform identifier, e.g. US2."
  type        = string
}

variable "qualys_customer_id" {
  description = "Qualys Customer ID (UUID)."
  type        = string
  sensitive   = true
}

variable "qualys_activation_id" {
  description = "Qualys Activation ID (UUID)."
  type        = string
  sensitive   = true
}

variable "components" {
  description = "Which sensors to enable."
  type = object({
    cluster_sensor       = optional(bool, true)
    qcs_sensor           = optional(bool, true)
    runtime_sensor       = optional(bool, false)
    admission_controller = optional(bool, false)
  })
  default = {}
}

variable "sensor_tags" {
  description = "Sensor tags for profile assignment."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "AWS tags."
  type        = map(string)
  default     = {}
}
