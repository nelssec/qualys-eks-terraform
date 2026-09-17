# qualys-sensors

Deploys the Qualys Container Security sensors onto an EKS cluster: reads the Customer ID and Activation ID from a Secrets Manager secret, renders `qualys-tc` chart values via `modules/qualys-sensor-values`, and manages the release with an atomic `helm_release`. This is the module most consumers of this repository start with.

## Usage

```hcl
module "qualys_sensors" {
  source                 = "git::https://github.com/<org>/qualys-eks-terraform.git//modules/qualys-sensors?ref=v0.1.0"
  cluster_arn            = data.aws_eks_cluster.this.arn
  qualys_platform        = "US2"
  credentials_secret_arn = module.qualys_secrets.secret_arn
}
```

The `helm` provider must be configured against the target cluster; see `examples/existing-cluster/providers.tf`.

## Credential visibility

**Credential visibility.** The `qualys-tc` chart injects the Customer ID and Activation ID as container arguments, environment variables, and a ConfigMap. This module keeps them out of tfvars, plan output, and values YAML by passing them through `set_sensitive`, but anyone with `get pods` on the sensor namespace can read them. This is a chart limitation, not something the module can change.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `credentials_secret_arn` | string | required | ARN of the Secrets Manager secret holding the Qualys Customer ID and Activation ID as a JSON object. Use the qualys-secrets module or supply your own. |
| `credentials_secret_keys` | object | `{}` | JSON key names inside the secret. See `variables.tf` for fields (`customer_id` default "customer_id", `activation_id` default "activation_id"). |
| `release_name` | string | `"qualys-tc"` | Helm release name. |
| `namespace` | string | `"qualys"` | Namespace for all Qualys components. The qcs-sensor containerd TLS secret template hardcodes 'qualys'; keep the default unless you do not use that feature. |
| `create_namespace` | bool | `true` | Create the namespace if it does not exist. |
| `chart_repository` | string | `"https://qualys.github.io/Qualys-Helm-Charts/"` | Helm repository URL for qualys-tc. |
| `chart_version` | string | `"2.10.0"` | qualys-tc chart version. Pinned; bump deliberately and read the chart README compatibility matrix first. |
| `helm_timeout_seconds` | number | `600` | Timeout for Helm operations. |
| `helm_atomic` | bool | `true` | Roll back the release if install/upgrade fails. |
| `helm_wait` | bool | `true` | Wait for resources to become ready before marking the release successful. |
| `cluster_arn` | string | required | ARN of the target EKS cluster. Rendered to global.clusterInfoArgs.AWS.arn. |
| `qualys_platform` | string | required | Qualys platform (POD) identifier. See docs/platform-urls.md. |
| `gateway_url` | string | `null` | Override for global.gatewayUrl. |
| `cmsqag_public_url` | string | `null` | Override for global.cmsqagPublicUrl. |
| `components` | object | `{}` | Which qualys-tc sub-charts to enable. See `variables.tf` for fields (`cluster_sensor`, `qcs_sensor` default true; `runtime_sensor`, `admission_controller` default false). |
| `container_runtime` | object | `{}` | Container runtime on the worker nodes (containerd or crio). See `variables.tf` for fields. |
| `proxy` | object | `null` | Outbound proxy for Qualys platform traffic. See `variables.tf` for fields. |
| `root_ca_certificate_base64` | string | `null` | Custom root CA (base64) required to reach the Qualys platform. |
| `images` | object | `{}` | Per-component image overrides for private registries. See `variables.tf` for fields. |
| `image_pull_secrets` | list(object) | `[]` | Image pull secrets for private registries. Credential fields are passed via set_sensitive. See `variables.tf` for fields. |
| `sensor_tags` | list(string) | `[]` | Tags applied to cluster, runtime and QCS sensors. |
| `cluster_sensor` | object | `{}` | Cluster Sensor options. See `variables.tf` for fields. |
| `qcs_sensor` | object | `{}` | QCS Sensor options. See `variables.tf` for fields. |
| `runtime_sensor` | object | `{}` | Container Runtime Sensor options. See `variables.tf` for fields. |
| `admission_controller` | object | `{}` | Admission Controller options. See `variables.tf` for fields. |
| `node_selector` | map(string) | `{}` | nodeSelector applied to every Qualys component. |
| `tolerations` | list(object) | `[]` | Tolerations applied to every Qualys component. See `variables.tf` for fields. |
| `extra_values` | any | `{}` | Escape hatch: arbitrary qualys-tc values merged by Helm after the rendered values. |

## Outputs

| Name | Description |
| --- | --- |
| `release_name` | Helm release name. |
| `namespace` | Namespace the sensors run in. |
| `chart_version` | Deployed qualys-tc chart version. |
| `release_status` | Helm release status. |
| `enabled_components` | Enabled Qualys components. |
| `gateway_url` | Effective Qualys gateway URL. |
| `cmsqag_public_url` | Effective Qualys cmsqagpublic URL. |
| `rendered_values_yaml` | Rendered values YAML (no credentials). Useful for GitOps hand-off or debugging. |

## Requirements

Terraform >= 1.9, AWS provider ~> 6.59, Helm provider ~> 3.0.
