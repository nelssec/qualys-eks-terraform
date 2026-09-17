terraform {
  required_version = ">= 1.9.0"
}

variable "cluster_arn" {
  type    = string
  default = "arn:aws:eks:us-east-1:123456789012:cluster/render-check"
}
variable "qualys_platform" {
  type    = string
  default = "US2"
}
variable "components" {
  type    = any
  default = {}
}
variable "container_runtime" {
  type    = any
  default = {}
}
variable "proxy" {
  type    = any
  default = null
}
variable "root_ca_certificate_base64" {
  type    = string
  default = null
}
variable "images" {
  type    = any
  default = {}
}
variable "image_pull_secrets" {
  type    = any
  default = []
}
variable "sensor_tags" {
  type    = list(string)
  default = []
}
variable "qcs_sensor" {
  type    = any
  default = {}
}
variable "runtime_sensor" {
  type    = any
  default = {}
}
variable "admission_controller" {
  type    = any
  default = {}
}
variable "cluster_sensor" {
  type    = any
  default = {}
}
variable "node_selector" {
  type    = map(string)
  default = {}
}
variable "tolerations" {
  type    = any
  default = []
}
variable "extra_values" {
  type    = any
  default = {}
}

module "values" {
  source = "../../modules/qualys-sensor-values"

  cluster_arn                = var.cluster_arn
  qualys_platform            = var.qualys_platform
  components                 = var.components
  container_runtime          = var.container_runtime
  proxy                      = var.proxy
  root_ca_certificate_base64 = var.root_ca_certificate_base64
  images                     = var.images
  image_pull_secrets         = var.image_pull_secrets
  sensor_tags                = var.sensor_tags
  qcs_sensor                 = var.qcs_sensor
  runtime_sensor             = var.runtime_sensor
  admission_controller       = var.admission_controller
  cluster_sensor             = var.cluster_sensor
  node_selector              = var.node_selector
  tolerations                = var.tolerations
  extra_values               = var.extra_values
}

output "values_yaml" {
  value = module.values.values_yaml
}

output "extra_values_yaml" {
  value = module.values.extra_values_yaml
}
