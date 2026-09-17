# Example: complete (VPC + EKS + Qualys sensors)

Builds a three-AZ VPC with one NAT gateway, a production-shaped EKS cluster (private nodes, KMS-encrypted secrets, all control-plane logs, IRSA), stores the Qualys enrollment IDs in Secrets Manager, and deploys the Qualys sensors. Intended for Qualys end-to-end testing and as a customer reference. Cost: roughly the EKS control plane, two `m6i.large` nodes, and one NAT gateway per hour while it exists.

## Run

```bash
cp terraform.tfvars.example terraform.tfvars   # set admin_cidrs to your egress IP and fill in the Qualys IDs
terraform init
terraform apply
```

First apply takes 15 to 20 minutes, most of it EKS control-plane and node group creation.

## Integration runbook (manual gate before tagging a release)

Run this in a Qualys sandbox AWS account against the US2 platform.

1. `terraform apply` completes with `release_status = deployed`.
2. `$(terraform output -raw configure_kubectl)` then `kubectl -n qualys get pods -o wide`. Expect: one `cluster-sensor` pod `Running`; one `qualys-container-sensor` pod per node `Running`; no `CrashLoopBackOff`.
3. `kubectl -n qualys logs deploy/cluster-sensor --tail=50` shows a successful registration with the gateway (no `401`/`403` lines).
4. In the Qualys UI: Container Security > Assets > Sensors lists the cluster sensor and QCS sensors with status `Active` within 10 minutes.
5. Deploy any public image, e.g. `kubectl create deployment nginx --image=nginx:1.27`. Within 15 minutes Container Security > Assets > Images shows `nginx:1.27` with a completed vulnerability scan.
6. Optional: set `components.runtime_sensor = true` and `components.admission_controller = true`, apply again, and confirm `kubectl -n qualys get daemonset,deployment,validatingwebhookconfiguration` shows all four components.
7. `terraform destroy`. Confirm the Secrets Manager secret is gone (recovery window is 0 in this example) and the cluster is deleted.

Record the chart version, sensor image versions (`kubectl -n qualys get pods -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}'`), and the date in `CHANGELOG.md` under the release entry.

## Known caveats

- The Helm provider is configured from `module.eks` outputs. On a fresh `destroy`, Terraform may need `terraform destroy -target=module.qualys_sensors` first if the cluster is already unreachable.
- `admin_cidrs` opens the public endpoint to those CIDRs only. There is no `0.0.0.0/0` default.
