# Example: existing EKS cluster

Deploys the Qualys Container Security sensors onto an EKS cluster you already own. Creates one Secrets Manager secret for the enrollment IDs and one Helm release of `qualys-tc`.

## Prerequisites

- AWS credentials with rights to read the cluster, create a Secrets Manager secret, and an EKS access entry (or aws-auth mapping) granting cluster-admin to that identity.
- Network path to the cluster API endpoint. For private-only endpoints run Terraform from inside the VPC or a connected network.
- No Fargate profile may select the `qualys` namespace. Check with `aws eks list-fargate-profiles` and `describe-fargate-profile`.

## Run

```bash
cp terraform.tfvars.example terraform.tfvars   # edit values; keep this file out of git
terraform init
terraform plan
terraform apply
```

## Verify

```bash
kubectl -n qualys get pods -o wide
```

Expect one `cluster-sensor` pod and one `qualys-container-sensor` pod per EC2 node, all `Running`. In the Qualys UI open Container Security > Assets > Sensors and confirm the cluster appears within about ten minutes.

## Using a secret you already have

Drop the `qualys_secrets` module and pass your own ARN:

```hcl
module "qualys_sensors" {
  source                 = "../../modules/qualys-sensors"
  cluster_arn            = data.aws_eks_cluster.this.arn
  qualys_platform        = "US2"
  credentials_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:my/qualys-creds-AbCdEf"
  credentials_secret_keys = {
    customer_id   = "CustomerId"
    activation_id = "ActivationId"
  }
}
```

## Remove

```bash
terraform destroy
```

The secret enters a 7-day recovery window; pass `recovery_window_in_days = 0` to the secrets module for immediate deletion in test accounts.
