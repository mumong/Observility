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

log_pass() {
  echo "PASS: $1"
}

require_count_at_least() {
  local pattern="$1"
  local minimum="$2"
  local file="$3"
  local count
  count="$(rg -c --multiline "${pattern}" "${file}")"
  if (( count < minimum )); then
    echo "expected at least ${minimum} matches for pattern in ${file}, got ${count}: ${pattern}" >&2
    exit 1
  fi
}

main() {
  require_cmd helm
  require_cmd rg

  cd "${ROOT_DIR}"

  helm template obs ./ -n test \
    --set tracing.byconity.enabled=true \
    --set tracing.byconity.hdfs.enabled=true \
    > "${TMP_DIR}/byconity-default.yaml"

  require_absent 'storageClassName: ""' "${TMP_DIR}/byconity-default.yaml"
  log_pass "byconity default render does not force empty storageClassName"

  helm template obs ./ -n test \
    --set tracing.byconity.enabled=true \
    --set tracing.byconity.hdfs.enabled=true \
    --set tracing.global.storageClass=nfs-storage \
    > "${TMP_DIR}/byconity-nfs.yaml"

  require_count_at_least 'storageClassName: nfs-storage' 10 "${TMP_DIR}/byconity-nfs.yaml"
  require_match '# Source: observability/templates/childcharts/tracing/byconity/server.yaml' "${TMP_DIR}/byconity-nfs.yaml"
  require_match '# Source: observability/templates/childcharts/tracing/byconity/tso.yaml' "${TMP_DIR}/byconity-nfs.yaml"
  require_match '# Source: observability/templates/childcharts/tracing/byconity/vw.yaml' "${TMP_DIR}/byconity-nfs.yaml"
  require_match '# Source: observability/templates/childcharts/tracing/byconity/hdfs/datanodes.yaml' "${TMP_DIR}/byconity-nfs.yaml"
  require_match '# Source: observability/templates/childcharts/tracing/byconity/hdfs/namenode.yaml' "${TMP_DIR}/byconity-nfs.yaml"
  log_pass "byconity render inherits tracing.global.storageClass"
}

main "$@"
