# EKS Fargate and the Qualys sensors

## The limitation

EKS Fargate cannot schedule DaemonSets. The Qualys QCS sensor (image and container vulnerability scanning) and the Runtime Sensor are DaemonSets. They therefore never run on Fargate-backed pods. No Helm value and no Terraform input in this repository changes that.

## What this repository does about it

- `modules/eks-cluster` rejects any Fargate profile whose selector targets the sensor namespace (`sensor_namespace`, default `qualys`). If the profile captured that namespace, the cluster sensor and admission controller Deployments would be scheduled onto Fargate, where `hostNetwork` and `hostPath` are refused and the pods would fail.
- On clusters you already own, check your profiles before applying:

  ```bash
  aws eks list-fargate-profiles --cluster-name <name>
  aws eks describe-fargate-profile --cluster-name <name> --fargate-profile-name <profile> --query 'fargateProfile.selectors'
  ```

## What still works on a mixed cluster

| Component | EC2 nodes | Fargate pods |
| --- | --- | --- |
| Cluster Sensor (inventory, K8s compliance) | Yes | Yes, via the Kubernetes API |
| Admission Controller | Yes | Yes, evaluates every admission request |
| QCS Sensor (image/container vulns at runtime) | Yes | No |
| Runtime Sensor (process/network/file events) | Yes | No |

## Interim coverage for Fargate workloads

1. Registry scanning. Connect the ECR registries those pods pull from in Container Security > Configurations > Registries. Images are scanned before they run.
2. Pipeline scanning with `qscanner` in CI, so no image reaches ECR unscanned.
3. Qualys's event-driven ECS Fargate scan stack (EventBridge + Lambda + CodeBuild) targets ECS task definitions, not EKS pods. It does not apply here.

## Phase two

Fargate coverage for EKS is tracked separately (Qualys feature request FRS-20111). Nothing in this repository should be extended toward it until that design exists.
