variable "customer_id" {
  description = "Qualys Customer ID (UUID) from the Container Security sensor download page."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.customer_id))
    error_message = "customer_id must be a UUID."
  }
}

variable "activation_id" {
  description = "Qualys Activation ID (UUID) from the Container Security sensor download page."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.activation_id))
    error_message = "activation_id must be a UUID."
  }
}

variable "secret_name" {
  description = "Secrets Manager secret name."
  type        = string
  default     = "qualys/container-security/credentials"
}

variable "kms_key_id" {
  description = "Customer-managed KMS key for the secret. Null uses the AWS-managed key aws/secretsmanager."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Days before a deleted secret is purged. 0 forces immediate deletion (test environments only)."
  type        = number
  default     = 7

  validation {
    condition     = var.recovery_window_in_days == 0 || (var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30)
    error_message = "recovery_window_in_days must be 0 or between 7 and 30."
  }
}

variable "create_read_policy" {
  description = "Create an IAM policy granting read on this secret only, for the role that runs the qualys-sensors module."
  type        = bool
  default     = false
}

variable "read_policy_name" {
  description = "Name of the optional read policy."
  type        = string
  default     = "qualys-container-security-secret-read"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
