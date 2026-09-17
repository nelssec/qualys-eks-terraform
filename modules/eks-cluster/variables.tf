variable "name" {
  description = "EKS cluster name."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-Za-z][A-Za-z0-9._-]{0,99}$", var.name))
    error_message = "name must be 1-100 characters, start alphanumeric, and contain only letters, digits, . _ -."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes minor version. Default is the newest version in EKS standard support at release time."
  type        = string
  default     = "1.36"
}

variable "vpc_id" {
  description = "VPC for the cluster."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for worker nodes (and the control plane unless control_plane_subnet_ids is set)."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "EKS requires subnets in at least two availability zones."
  }
}

variable "control_plane_subnet_ids" {
  description = "Subnets for control-plane ENIs. Defaults to subnet_ids."
  type        = list(string)
  default     = null
}

variable "endpoint_public_access" {
  description = "Expose the API server publicly. Private access is always enabled."
  type        = bool
  default     = false
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public endpoint. Required when endpoint_public_access is true; 0.0.0.0/0 must be written explicitly."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.endpoint_public_access || length(var.endpoint_public_access_cidrs) > 0
    error_message = "endpoint_public_access_cidrs must list at least one CIDR when endpoint_public_access is true."
  }
}

variable "authentication_mode" {
  description = "EKS authentication mode."
  type        = string
  default     = "API"

  validation {
    condition     = contains(["API", "API_AND_CONFIG_MAP", "CONFIG_MAP"], var.authentication_mode)
    error_message = "authentication_mode must be API, API_AND_CONFIG_MAP, or CONFIG_MAP."
  }
}

variable "access_entries" {
  description = "EKS access entries, passed through to the community module."
  type        = any
  default     = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Grant the Terraform identity cluster-admin via an access entry."
  type        = bool
  default     = true
}

variable "node_groups" {
  description = "EKS managed node groups. Root volume is gp3, encrypted, sized by disk_size."
  type = map(object({
    instance_types = optional(list(string), ["m6i.large"])
    min_size       = optional(number, 2)
    max_size       = optional(number, 5)
    desired_size   = optional(number, 2)
    ami_type       = optional(string, "AL2023_x86_64_STANDARD")
    capacity_type  = optional(string, "ON_DEMAND")
    disk_size      = optional(number, 50)
    subnet_ids     = optional(list(string))
    labels         = optional(map(string), {})
    taints = optional(map(object({
      key    = string
      value  = optional(string)
      effect = string
    })), {})
  }))
  default = {
    default = {}
  }

  validation {
    condition     = alltrue([for ng in values(var.node_groups) : ng.min_size <= ng.desired_size && ng.desired_size <= ng.max_size])
    error_message = "Each node group needs min_size <= desired_size <= max_size."
  }
}

variable "fargate_profiles" {
  description = "Fargate profiles. Selectors must not target sensor_namespace: the QCS and runtime sensors are DaemonSets and cannot run on Fargate."
  type = map(object({
    subnet_ids = optional(list(string))
    selectors = list(object({
      namespace = string
      labels    = optional(map(string))
    }))
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = length(flatten([
      for k, p in var.fargate_profiles : [for s in p.selectors : k if s.namespace == var.sensor_namespace]
    ])) == 0
    error_message = "A Fargate profile selects the Qualys sensor namespace. The Qualys sensors must run on EC2 nodes; remove that selector or change sensor_namespace."
  }
}

variable "sensor_namespace" {
  description = "Namespace the Qualys sensors will use. Only used to reject Fargate profiles that would capture it."
  type        = string
  default     = "qualys"
}

variable "enabled_log_types" {
  description = "Control-plane log types to ship to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition     = alltrue([for t in var.enabled_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)])
    error_message = "enabled_log_types entries must be api, audit, authenticator, controllerManager, or scheduler."
  }
}

variable "kms_key_arn" {
  description = "Existing KMS key for Kubernetes secrets envelope encryption. Null creates a dedicated key."
  type        = string
  default     = null
}

variable "enable_irsa" {
  description = "Create the OIDC provider for IAM Roles for Service Accounts."
  type        = bool
  default     = true
}

variable "addons" {
  description = "EKS add-ons. Defaults install CoreDNS, kube-proxy, VPC CNI, and the Pod Identity agent at their most recent versions."
  type = map(object({
    addon_version        = optional(string)
    most_recent          = optional(bool, true)
    before_compute       = optional(bool, false)
    configuration_values = optional(string)
  }))
  default = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = {}
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
