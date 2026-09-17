# qualys-secrets

Stores the Qualys Customer ID and Activation ID as a single AWS Secrets Manager secret. It exists so the enrollment credentials never need to appear in a `qualys-sensors` tfvars file, plan output, or state diff beyond the ARN.

## Usage

```hcl
module "qualys_secrets" {
  source        = "git::https://github.com/<org>/qualys-eks-terraform.git//modules/qualys-secrets?ref=v0.1.0"
  customer_id   = var.qualys_customer_id
  activation_id = var.qualys_activation_id
}
```

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `customer_id` | string | required | Qualys Customer ID (UUID) from the Container Security sensor download page. |
| `activation_id` | string | required | Qualys Activation ID (UUID) from the Container Security sensor download page. |
| `secret_name` | string | `"qualys/container-security/credentials"` | Secrets Manager secret name. |
| `kms_key_id` | string | `null` | Customer-managed KMS key for the secret. Null uses the AWS-managed key aws/secretsmanager. |
| `recovery_window_in_days` | number | `7` | Days before a deleted secret is purged. 0 forces immediate deletion (test environments only). |
| `create_read_policy` | bool | `false` | Create an IAM policy granting read on this secret only, for the role that runs the qualys-sensors module. |
| `read_policy_name` | string | `"qualys-container-security-secret-read"` | Name of the optional read policy. |
| `tags` | map(string) | `{}` | Tags applied to all resources. |

## Outputs

| Name | Description |
| --- | --- |
| `secret_arn` | ARN of the credentials secret. Sourced from the version resource so dependents wait until the value is written. |
| `secret_name` | Name of the credentials secret. |
| `read_policy_arn` | ARN of the optional read policy, or null. |

## Requirements

Terraform >= 1.9, AWS provider ~> 6.59.
