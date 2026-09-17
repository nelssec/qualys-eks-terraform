#!/usr/bin/env bash
# Renders every tests/fixtures/*.tfvars through modules/qualys-sensor-values and
# validates the result against the real qualys-tc chart with helm lint + helm template.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_VERSION="${CHART_VERSION:-2.10.0}"
CHART_REPO="https://qualys.github.io/Qualys-Helm-Charts/"
RENDER_DIR="$ROOT/tests/render"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PLACEHOLDER_ID="00000000-0000-0000-0000-000000000000"

echo "== pulling qualys-tc $CHART_VERSION"
helm repo add qualys-helm-chart "$CHART_REPO" >/dev/null 2>&1 || true
helm repo update qualys-helm-chart >/dev/null
helm pull qualys-helm-chart/qualys-tc --version "$CHART_VERSION" --untar --untardir "$WORK/chart"
CHART="$WORK/chart/qualys-tc"

( cd "$RENDER_DIR" && terraform init -input=false -backend=false >/dev/null )

status=0
for fixture in "$ROOT"/tests/fixtures/*.tfvars; do
  name="$(basename "$fixture" .tfvars)"
  echo "== $name"
  state="$WORK/$name.tfstate"
  ( cd "$RENDER_DIR" \
    && terraform apply -auto-approve -input=false -state="$state" -var-file="$fixture" >/dev/null \
    && terraform output -state="$state" -raw values_yaml > "$WORK/$name.values.yaml" \
    && terraform output -state="$state" -raw extra_values_yaml > "$WORK/$name.extra.yaml" )

  common=( -f "$WORK/$name.values.yaml" -f "$WORK/$name.extra.yaml"
           --set "global.customerId=$PLACEHOLDER_ID" --set "global.activationId=$PLACEHOLDER_ID" )

  if ! helm lint "$CHART" -n qualys "${common[@]}" >"$WORK/$name.lint.log" 2>&1; then
    echo "   helm lint FAILED"; cat "$WORK/$name.lint.log"; status=1; continue
  fi
  if ! helm template qualys-tc "$CHART" -n qualys "${common[@]}" >"$WORK/$name.manifest.yaml" 2>"$WORK/$name.template.log"; then
    echo "   helm template FAILED"; cat "$WORK/$name.template.log"; status=1; continue
  fi

  # Sanity checks on the rendered manifest.
  kinds="$(grep -E '^kind:' "$WORK/$name.manifest.yaml" | sort | uniq -c | awk '{print $3":"$1}' | tr '\n' ' ')"
  echo "   kinds: $kinds"
  grep -q 'kind: Deployment' "$WORK/$name.manifest.yaml" || { echo "   missing cluster sensor Deployment"; status=1; }
  # qcs_sensor defaults to enabled and no fixture disables it, so a DaemonSet must always render.
  grep -q 'kind: DaemonSet' "$WORK/$name.manifest.yaml" || { echo "   missing QCS sensor DaemonSet"; status=1; }
  if grep -q 'admission_controller *= *true' "$fixture"; then
    grep -q 'kind: ValidatingWebhookConfiguration' "$WORK/$name.manifest.yaml" || { echo "   missing ValidatingWebhookConfiguration"; status=1; }
  fi
  if grep -q '^proxy' "$fixture"; then
    grep -q 'qualys_https_proxy' "$WORK/$name.manifest.yaml" || { echo "   proxy env not rendered into qcs-sensor"; status=1; }
  fi
  if grep -q 'render-only-placeholder' "$WORK/$name.values.yaml"; then
    echo "   pull secret password leaked into values YAML"; status=1
  fi
done

exit $status
