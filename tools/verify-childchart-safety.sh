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

require_absent() {
  local pattern="$1"
  local file="$2"
  if rg -q --multiline "${pattern}" "${file}"; then
    echo "unexpected pattern present in ${file}: ${pattern}" >&2
    exit 1
  fi
}

log_pass() {
  echo "PASS: $1"
}

main() {
  require_cmd helm
  require_cmd rg

  cd "${ROOT_DIR}"

  cat > "${TMP_DIR}/all-childcharts.yaml" <<'EOF'
tracing:
  enabled: true
  mysql:
    enabled: true
  clickhouse:
    enabled: true
  deepflow-agent:
    enabled: true
  stella-agent-ce:
    enabled: true
  byconity:
    enabled: true
    hdfs:
      enabled: true
metric:
  enabled: true
  grafana:
    enabled: true
    persistence:
      enabled: true
    useStatefulSet: true
  kube-state-metrics:
    enabled: true
  prometheus-node-exporter:
    enabled: true
EOF

  helm template observability ./ -n test > "${TMP_DIR}/default.yaml"
  helm template observability ./ -n test -f "${TMP_DIR}/all-childcharts.yaml" > "${TMP_DIR}/all-childcharts.yaml.rendered"

  require_absent 'storageClassName: ""' "${TMP_DIR}/default.yaml"
  require_absent 'storageClassName: ""' "${TMP_DIR}/all-childcharts.yaml.rendered"
  log_pass "no childchart renders empty storageClassName"

  require_absent 'docker\.io|quay\.io|registry\.k8s\.io|k8s\.gcr\.io|gcr\.io|ghcr\.io|foundationdb/foundationdb|foundationdb/foundationdb-kubernetes-sidecar|foundationdb/fdb-kubernetes-operator' "${TMP_DIR}/default.yaml"
  require_absent 'docker\.io|quay\.io|registry\.k8s\.io|k8s\.gcr\.io|gcr\.io|ghcr\.io|foundationdb/foundationdb|foundationdb/foundationdb-kubernetes-sidecar|foundationdb/fdb-kubernetes-operator' "${TMP_DIR}/all-childcharts.yaml.rendered"
  log_pass "no childchart render references external registries"
}

main "$@"
