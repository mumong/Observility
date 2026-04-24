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

require_match() {
  local pattern="$1"
  local file="$2"
  rg -q --multiline "${pattern}" "${file}" || {
    echo "missing expected pattern in ${file}: ${pattern}" >&2
    exit 1
  }
}

log_pass() {
  echo "PASS: $1"
}

main() {
  require_cmd helm
  require_cmd rg

  cd "${ROOT_DIR}"

  helm template observability ./ -n test \
    --set tracing.byconity.enabled=true \
    --set tracing.byconity.hdfs.enabled=true \
    --set tracing.mysql.enabled=true \
    --set tracing.clickhouse.enabled=true \
    --set metric.enabled=true \
    --set metric.grafana.enabled=true \
    --set metric.grafana.persistence.enabled=true \
    --set metric.grafana.useStatefulSet=true \
    > "${TMP_DIR}/childcharts-default.yaml"

  require_absent 'storageClassName: ""' "${TMP_DIR}/childcharts-default.yaml"
  log_pass "childcharts default render does not force empty storageClassName"

  helm template observability ./ -n test \
    --set tracing.byconity.enabled=true \
    --set tracing.byconity.hdfs.enabled=true \
    --set tracing.mysql.enabled=true \
    --set tracing.clickhouse.enabled=true \
    --set tracing.global.storageClass=nfs-storage \
    --set metric.enabled=true \
    --set metric.grafana.enabled=true \
    --set metric.grafana.persistence.enabled=true \
    --set metric.grafana.useStatefulSet=true \
    > "${TMP_DIR}/childcharts-nfs.yaml"

  require_match 'storageClassName: nfs-storage' "${TMP_DIR}/childcharts-nfs.yaml"
  log_pass "childcharts can render explicit storageClass when parent/global values provide one"
}

main "$@"
