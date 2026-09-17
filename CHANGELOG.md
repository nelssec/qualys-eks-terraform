# Changelog

All notable changes to this project are documented here. Chart default bumps are always called out because they change what runs on customer nodes.

## [Unreleased]

## [0.1.0] - 2026-09-16

### Added
- `qualys-sensors`: `helm_release` of `qualys-tc` 2.10.0 with credentials from Secrets Manager via `set_sensitive`.
- `qualys-sensor-values`: provider-free renderer covering platform URLs, components, runtime, proxy, root CA, private images, pull secrets, tags, per-component options, scheduling, and `extra_values`.
- `qualys-secrets`: single JSON Secrets Manager secret with optional scoped read policy.
- `eks-cluster`: wrapper over terraform-aws-modules/eks ~> 21.0, private endpoint default, KMS secret encryption, all control-plane logs, Fargate namespace guard.
- Examples `existing-cluster` and `complete`; chart conformance script; `terraform test` suites.

### Chart default
- `qualys-tc` 2.10.0 (cluster-sensor 1.7.0-0, qcs-sensor 1.44.2-0, runtime-sensor 1.7.0-0, admission-controller 1.1.2-0).

### Integration
- Not yet run. Requires the complete example applied in a Qualys sandbox AWS account against US2; see examples/complete/README.md.
