#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

require_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || {
    echo "missing required command: ${cmd}" >&2
    exit 1
  }
}

log_pass() {
  echo "PASS: $1"
}

render_inventory() {
  local rendered_file="$1"
  local inventory_file="$2"
  yq e -N 'select(.kind != null and .metadata.name != null) | [(.kind // ""), (.metadata.namespace // ""), .metadata.name] | join("\t")' "${rendered_file}" | sort -u > "${inventory_file}"
}

require_match() {
  local pattern="$1"
  local file="$2"
  rg -q --multiline "${pattern}" "${file}" || {
    echo "missing expected pattern in ${file}: ${pattern}" >&2
    exit 1
  }
}

require_absent() {
  local pattern="$1"
  local file="$2"
  if rg -q --multiline "${pattern}" "${file}"; then
    echo "unexpected pattern present in ${file}: ${pattern}" >&2
    exit 1
  fi
}

main() {
  require_cmd helm
  require_cmd rg
  require_cmd yq

  cd "${ROOT_DIR}"

  helm lint . >/dev/null
  log_pass "helm lint (default)"

  helm lint . -f observability-all-enabled.yaml >/dev/null
  log_pass "helm lint (all-enabled)"

  helm template observability ./ -n xnet > current-rendered.yaml
  log_pass "render default -> current-rendered.yaml"

  helm template observability ./ -n xnet -f observability-all-enabled.yaml > verify-rendered.yaml
  log_pass "render all-enabled -> verify-rendered.yaml"

  cat > "${TMP_DIR}/final-parity-check.yaml" <<'EOF'
tracing:
  byconity:
    enabled: false
metric:
  crds:
    enabled: false
EOF
  helm template observability ./ -n xnet -f "${TMP_DIR}/final-parity-check.yaml" > compare-rendered.yaml
  render_inventory final.yaml "${TMP_DIR}/final.inventory.tsv"
  render_inventory compare-rendered.yaml "${TMP_DIR}/compare.inventory.tsv"
  comm -23 "${TMP_DIR}/final.inventory.tsv" "${TMP_DIR}/compare.inventory.tsv" > "${TMP_DIR}/only-in-final.tsv"
  comm -13 "${TMP_DIR}/final.inventory.tsv" "${TMP_DIR}/compare.inventory.tsv" > "${TMP_DIR}/only-in-compare.tsv"
  [[ ! -s "${TMP_DIR}/only-in-final.tsv" ]]
  [[ ! -s "${TMP_DIR}/only-in-compare.tsv" ]]
  log_pass "render parity with final.yaml"

  cat > "${TMP_DIR}/control-proof-tracing.yaml" <<'EOF'
tracing:
  enabled: true
  global:
    image:
      repository: registry.trace.local/obs
      pullPolicy: Always
    timezone: UTC
  mysql:
    enabled: true
    image:
      repository: "{{ .Values.tracing.global.image.repository }}/mysql-proof"
      pullPolicy: "{{ .Values.tracing.global.image.pullPolicy }}"
  clickhouse:
    enabled: true
    image:
      repository: "{{ .Values.tracing.global.image.repository }}/clickhouse-proof"
      pullPolicy: "{{ .Values.tracing.global.image.pullPolicy }}"
  deepflow-agent:
    enabled: true
    image:
      repository: "{{ .Values.tracing.global.image.repository }}/agent-proof"
      pullPolicy: "{{ .Values.tracing.global.image.pullPolicy }}"
  stella-agent-ce:
    enabled: true
    image:
      repository: "{{ .Values.tracing.global.image.repository }}/stella-proof"
      pullPolicy: "{{ .Values.tracing.global.image.pullPolicy }}"
  byconity:
    enabled: true
    fdbShell:
      image:
        repository: "{{ .Values.tracing.global.image.repository }}/shell-proof"
EOF
  helm template observability ./ -n xnet -f "${TMP_DIR}/control-proof-tracing.yaml" > "${TMP_DIR}/control-proof-tracing.rendered.yaml"
  require_match 'registry\.trace\.local/obs/mysql-proof:8\.0\.39' "${TMP_DIR}/control-proof-tracing.rendered.yaml"
  require_match 'registry\.trace\.local/obs/clickhouse-proof:23\.10' "${TMP_DIR}/control-proof-tracing.rendered.yaml"
  require_match 'registry\.trace\.local/obs/agent-proof:v7\.0' "${TMP_DIR}/control-proof-tracing.rendered.yaml"
  require_match 'registry\.trace\.local/obs/stella-proof:latest' "${TMP_DIR}/control-proof-tracing.rendered.yaml"
  require_match 'registry\.trace\.local/obs/shell-proof/foundationdb:7\.1\.15' "${TMP_DIR}/control-proof-tracing.rendered.yaml"
  require_match 'imagePullPolicy: Always' "${TMP_DIR}/control-proof-tracing.rendered.yaml"
  require_match 'value: "UTC"' "${TMP_DIR}/control-proof-tracing.rendered.yaml"
  log_pass "tracing parent controls"

  cat > "${TMP_DIR}/control-proof-metric.yaml" <<'EOF'
metric:
  enabled: true
  grafana:
    enabled: true
    service:
      type: ClusterIP
    image:
      repository: grafana-proof
      tag: proof-tag
  prometheus-node-exporter:
    enabled: false
  kube-state-metrics:
    enabled: false
  crds:
    enabled: true
    upgradeJob:
      enabled: true
      image:
        busybox:
          repository: busybox-proof
          tag: "1.99"
  extra:
    global:
      imageRegistry: registry.metric.local/ops
      imagePullSecrets:
        - name: metric-pull
      externalMySQL:
        enabled: true
        ip: 172.16.1.10
        port: 3308
        username: metric-user
        password: metric-pass
EOF
  helm template observability ./ -n xnet -f "${TMP_DIR}/control-proof-metric.yaml" > "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_absent '# Source: observability/templates/childcharts/metric/kube-state-metrics/' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_absent '# Source: observability/templates/childcharts/metric/prometheus-node-exporter/' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_match '# Source: observability/templates/childcharts/metric/crds/templates/upgrade/job.yaml' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_match 'registry\.metric\.local/ops/grafana-proof:proof-tag' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_match 'host = 172\.16\.1\.10:3308' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_match 'user = metric-user' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_match 'password = metric-pass' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_match 'registry\.metric\.local/ops/busybox-proof:1\.99' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  require_match 'name: metric-pull' "${TMP_DIR}/control-proof-metric.rendered.yaml"
  log_pass "metric parent controls"

  cat > "${TMP_DIR}/control-proof-logging.yaml" <<'EOF'
logging:
  enabled: true
  filebeat:
    enabled: true
    image: registry.logging.local/beats/filebeat-proof
    imageTag: "9.9.9"
    imagePullPolicy: Always
    daemonset:
      enabled: true
      hostNetworking: true
  kibana:
    enabled: true
    image: registry.logging.local/kibana-proof
    imageTag: "9.8.7"
    imagePullPolicy: Always
    service:
      type: ClusterIP
EOF
  helm template observability ./ -n xnet -f "${TMP_DIR}/control-proof-logging.yaml" > "${TMP_DIR}/control-proof-logging.rendered.yaml"
  require_match '# Source: observability/templates/logging/filebeat/daemonset.yaml' "${TMP_DIR}/control-proof-logging.rendered.yaml"
  require_match 'registry\.logging\.local/beats/filebeat-proof:9\.9\.9' "${TMP_DIR}/control-proof-logging.rendered.yaml"
  require_match 'hostNetwork: true' "${TMP_DIR}/control-proof-logging.rendered.yaml"
  require_match 'dnsPolicy: ClusterFirstWithHostNet' "${TMP_DIR}/control-proof-logging.rendered.yaml"
  require_match '# Source: observability/templates/logging/kibana/service.yaml' "${TMP_DIR}/control-proof-logging.rendered.yaml"
  require_match 'type: ClusterIP' "${TMP_DIR}/control-proof-logging.rendered.yaml"
  require_match 'registry\.logging\.local/kibana-proof:9\.8\.7' "${TMP_DIR}/control-proof-logging.rendered.yaml"
  require_match 'imagePullPolicy: "Always"' "${TMP_DIR}/control-proof-logging.rendered.yaml"
  log_pass "logging parent controls"
}

main "$@"
