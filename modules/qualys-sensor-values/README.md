# qualys-sensor-values

Renders the `qualys-tc` Helm chart values for the Qualys Container Security sensors as a Terraform object and as YAML. It has no provider requirements and manages no resources, so it can back either a `helm_release` (see `modules/qualys-sensors`) or a GitOps hand-off.

## Usage

```hcl
module "qualys_values" {
  source          = "git::https://github.com/<org>/qualys-eks-terraform.git//modules/qualys-sensor-values?ref=v0.1.0"
  cluster_arn     = "arn:aws:eks:<region>:<account-id>:cluster/<name>"
  qualys_platform = "US2"
}
```

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `cluster_arn` | string | required | ARN of the target EKS cluster. Rendered to global.clusterInfoArgs.AWS.arn. |
| `qualys_platform` | string | required | Qualys platform (POD) identifier. Selects the gateway and cmsqagpublic URLs unless gateway_url / cmsqag_public_url are set. See docs/platform-urls.md. |
| `gateway_url` | string | `null` | Override for global.gatewayUrl. Use for private platforms; otherwise leave null and set qualys_platform. |
| `cmsqag_public_url` | string | `null` | Override for global.cmsqagPublicUrl. Use for private platforms; otherwise leave null and set qualys_platform. |
| `components` | object | `{}` | Which qualys-tc sub-charts to enable. See `variables.tf` for fields (`cluster_sensor`, `qcs_sensor` default true; `runtime_sensor`, `admission_controller` default false). |
| `container_runtime` | object | `{}` | Container runtime on the worker nodes. EKS AL2023 and Bottlerocket use containerd. Sets both global.containerRuntimes and qcsSensor runtime flags. See `variables.tf` for fields. |
| `proxy` | object | `null` | Outbound proxy for Qualys platform traffic. url format http://host:port. ca_certificate_base64 is the proxy CA in base64. See `variables.tf` for fields. |
| `root_ca_certificate_base64` | string | `null` | Custom root CA (base64) required to reach the Qualys platform, e.g. behind TLS inspection. |
| `images` | object | `{}` | Per-component image overrides (repository:tag) for private registries. Omitted entries use the chart defaults. See `variables.tf` for fields. |
| `image_pull_secrets` | list(object) | `[]` | Image pull secrets for private registries. create=false references an existing Secret by name. create=true lets the chart create it from registry_url/username/password or dockerconfigjson; those two credential fields are routed through set_sensitive and never rendered into YAML. ECR in the same account needs no pull secret when the node role has ECR read access. See `variables.tf` for fields. |
| `sensor_tags` | list(string) | `[]` | Tags applied to cluster, runtime and QCS sensors (used for sensor profile assignment). Max 10; joined with commas. |
| `cluster_sensor` | object | `{}` | Cluster Sensor options. Null fields fall back to chart defaults. See `variables.tf` for fields. |
| `qcs_sensor` | object | `{}` | QCS (Container Security) Sensor options. See `variables.tf` for fields. |
| `runtime_sensor` | object | `{}` | Container Runtime Sensor (CRS) options. See `variables.tf` for fields. |
| `admission_controller` | object | `{}` | Admission Controller options. Block mode denies non-compliant pods; start with Audit. See `variables.tf` for fields. |
| `node_selector` | map(string) | `{}` | nodeSelector applied to every Qualys component. |
| `tolerations` | list(object) | `[]` | Tolerations applied to every Qualys component. See `variables.tf` for fields. |
| `extra_values` | any | `{}` | Escape hatch: arbitrary qualys-tc values merged by Helm AFTER the rendered values, so they win on conflict. Must not contain global.customerId or global.activationId. |

## Outputs

| Name | Description |
| --- | --- |
| `values` | Rendered qualys-tc values as a Terraform object. Never contains credentials. |
| `values_yaml` | Rendered qualys-tc values as YAML. Pass as the first entry of helm_release.values. |
| `gateway_url` | Effective global.gatewayUrl. |
| `cmsqag_public_url` | Effective global.cmsqagPublicUrl. |
| `enabled_components` | Names of enabled components in canonical order. |
| `sensitive_set_values` | Helm set_sensitive entries for image pull secret credentials. Concatenate into helm_release.set_sensitive. |
| `extra_values_yaml` | extra_values as YAML. Pass as the second entry of helm_release.values so Helm merges it over values_yaml. |

## Requirements

Terraform >= 1.9. No provider requirements.
