variable "region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix for VPC and cluster."
  type        = string
  default     = "qualys-eks-demo"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.36"
}

variable "admin_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint (your workstation or CI egress)."
  type        = list(string)
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

variable "tags" {
  description = "AWS tags."
  type        = map(string)
  default     = { project = "qualys-eks-terraform", environment = "demo" }
}
