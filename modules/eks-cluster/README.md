# eks-cluster

A thin, opinionated wrapper over `terraform-aws-modules/eks` that produces a production-shaped EKS cluster with secure defaults (private-only API endpoint by default, encrypted node volumes, control-plane logging). It also rejects any Fargate profile whose selector would capture the Qualys sensor namespace, since the QCS and Runtime sensors are DaemonSets and cannot run on Fargate.

Variable names follow terraform-aws-modules/eks v21 (no `cluster_` prefix). Pinned `~> 21.0`.

## Usage

```hcl
module "eks_cluster" {
  source     = "git::https://github.com/<org>/qualys-eks-terraform.git//modules/eks-cluster?ref=v0.1.0"
  name       = "<org>-eks"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}
```

See `examples/complete` for a full VPC + cluster + sensors walk-through.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name` | string | required | EKS cluster name. |
| `kubernetes_version` | string | `"1.36"` | Kubernetes minor version. Default is the newest version in EKS standard support at release time. |
| `vpc_id` | string | required | VPC for the cluster. |
| `subnet_ids` | list(string) | required | Private subnets for worker nodes (and the control plane unless control_plane_subnet_ids is set). |
| `control_plane_subnet_ids` | list(string) | `null` | Subnets for control-plane ENIs. Defaults to subnet_ids. |
| `endpoint_public_access` | bool | `false` | Expose the API server publicly. Private access is always enabled. |
| `endpoint_public_access_cidrs` | list(string) | `[]` | CIDRs allowed to reach the public endpoint. Required when endpoint_public_access is true; 0.0.0.0/0 must be written explicitly. |
| `authentication_mode` | string | `"API"` | EKS authentication mode. |
| `access_entries` | any | `{}` | EKS access entries, passed through to the community module. |
| `enable_cluster_creator_admin_permissions` | bool | `true` | Grant the Terraform identity cluster-admin via an access entry. |
| `node_groups` | map(object) | `{ default = {} }` | EKS managed node groups. Root volume is gp3, encrypted, sized by disk_size. See `variables.tf` for fields. |
| `fargate_profiles` | map(object) | `{}` | Fargate profiles. Selectors must not target sensor_namespace: the QCS and runtime sensors are DaemonSets and cannot run on Fargate. See `variables.tf` for fields. |
| `sensor_namespace` | string | `"qualys"` | Namespace the Qualys sensors will use. Only used to reject Fargate profiles that would capture it. |
| `enabled_log_types` | list(string) | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` | Control-plane log types to ship to CloudWatch. |
| `kms_key_arn` | string | `null` | Existing KMS key for Kubernetes secrets envelope encryption. Null creates a dedicated key. |
| `enable_irsa` | bool | `true` | Create the OIDC provider for IAM Roles for Service Accounts. |
| `addons` | map(object) | see `variables.tf` | EKS add-ons. Defaults install CoreDNS, kube-proxy, VPC CNI, and the Pod Identity agent at their most recent versions. |
| `tags` | map(string) | `{}` | Tags applied to all resources. |

## Outputs

| Name | Description |
| --- | --- |
| `cluster_name` | EKS cluster name. |
| `cluster_arn` | EKS cluster ARN. Feed this to qualys-sensors.cluster_arn. |
| `cluster_endpoint` | API server endpoint. |
| `cluster_certificate_authority_data` | Base64 CA data for provider configuration. |
| `cluster_version` | Kubernetes version. |
| `oidc_provider_arn` | OIDC provider ARN for IRSA, or null when disabled. |
| `cluster_security_group_id` | Cluster security group. |
| `node_security_group_id` | Node shared security group. |
| `fargate_profile_names` | Names of created Fargate profiles. |

## Requirements

Terraform >= 1.9, AWS provider ~> 6.59.
