# Qualys EKS Terraform

Terraform modules that deploy the Qualys Container Security sensors onto Amazon EKS using the official [`qualys-tc`](https://github.com/Qualys/Qualys-Helm-Charts) Helm chart. Credentials live in AWS Secrets Manager. An optional module builds a production-shaped EKS cluster for teams that want a reference.

## Modules

| Module | Purpose |
| --- | --- |
| `modules/qualys-sensors` | Deploys the sensors: reads the credentials secret, renders chart values, manages an atomic `helm_release`. Start here. |
| `modules/qualys-secrets` | Stores Customer ID and Activation ID in one Secrets Manager secret. |
| `modules/qualys-sensor-values` | Provider-free renderer used by `qualys-sensors`. Use directly if you deploy Helm through GitOps and only want the values YAML. |
| `modules/eks-cluster` | Wrapper over `terraform-aws-modules/eks` v21 with secure defaults and a guard against Fargate profiles capturing the sensor namespace. |

## Quick start (existing cluster)

```hcl
module "qualys_secrets" {
  source        = "git::https://github.com/<org>/qualys-eks-terraform.git//modules/qualys-secrets?ref=v0.1.0"
  customer_id   = var.qualys_customer_id
  activation_id = var.qualys_activation_id
}

module "qualys_sensors" {
  source                 = "git::https://github.com/<org>/qualys-eks-terraform.git//modules/qualys-sensors?ref=v0.1.0"
  cluster_arn            = data.aws_eks_cluster.this.arn
  qualys_platform        = "US2"
  credentials_secret_arn = module.qualys_secrets.secret_arn
}
```

Configure the `helm` provider against your cluster as shown in `examples/existing-cluster/providers.tf`. Full walk-throughs: `examples/existing-cluster` (customer path) and `examples/complete` (VPC + cluster + sensors).

## Defaults

- Components on: Cluster Sensor, QCS Sensor. Off: Runtime Sensor, Admission Controller. Toggle with `components`.
- Chart `qualys-tc` 2.10.0, namespace `qualys`, atomic install with rollback.
- Runtime containerd. Set `container_runtime = { type = "crio" }` for CRI-O nodes.
- Platform URLs derived from `qualys_platform`; see `docs/platform-urls.md`.

## Requirements

Terraform >= 1.9, AWS provider ~> 6.59, Helm provider ~> 3.0, Helm CLI 3.x for `make render-check`. Use an encrypted remote state backend: state contains the enrollment IDs like any Terraform-managed secret.

## Limitations

- **Fargate.** The QCS and Runtime sensors are DaemonSets and cannot run on EKS Fargate. See `docs/fargate.md`.
- **Credential visibility.** The chart places Customer ID and Activation ID in pod specs. Anyone with `get pods` in the sensor namespace can read them.
- **Private endpoints.** If the API endpoint is private-only, run Terraform from inside the VPC or a connected network.
- **Windows.** Not supported by the chart.

## Development

```bash
make all          # fmt-check, validate, lint, test, render-check
make test         # terraform test in every module
make render-check # render fixtures through the real chart with helm lint/template
```

Example lock files are committed and cover darwin/linux on amd64/arm64; refresh them with `terraform providers lock` when bumping providers.

## Versioning

Semver git tags. Pin with `?ref=vX.Y.Z`. `CHANGELOG.md` calls out every chart default bump.

## License

Apache-2.0.
