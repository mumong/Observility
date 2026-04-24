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
    echo "missing expected image mapping in ${file}: ${pattern}" >&2
    exit 1
  }
}

require_absent() {
  local pattern="$1"
  local file="$2"
  if rg -q --multiline "${pattern}" "${file}"; then
    echo "unexpected image mapping present in ${file}: ${pattern}" >&2
    exit 1
  fi
}

main() {
  require_cmd helm
  require_cmd rg

  cd "${ROOT_DIR}"

  helm template obs ./ -n test \
    --set tracing.byconity.enabled=true \
    --set tracing.byconity.hdfs.enabled=false \
    > "${TMP_DIR}/byconity.rendered.yaml"

  require_match 'xnet\.registry\.io:8443/observability/foundationdb-kubernetes-sidecar:7\.1\.15-1' "${TMP_DIR}/byconity.rendered.yaml"
  require_match 'xnet\.registry\.io:8443/observability/fdb-kubernetes-operator:v1\.9\.0' "${TMP_DIR}/byconity.rendered.yaml"
  require_match 'image: "xnet\.registry\.io:8443/observability/byconity/foundationdb:7\.1\.15"' "${TMP_DIR}/byconity.rendered.yaml"
  require_match 'baseImage: xnet\.registry\.io:8443/observability/foundationdb-kubernetes-sidecar' "${TMP_DIR}/byconity.rendered.yaml"
  require_match 'mainContainer:\s+imageConfigs:\s+- baseImage: '\''xnet\.registry\.io:8443/observability/byconity/foundationdb'\''\s+version: '\''7\.1\.15'\''' "${TMP_DIR}/byconity.rendered.yaml"
  require_absent 'foundationdb/foundationdb:7\.1\.15' "${TMP_DIR}/byconity.rendered.yaml"
  require_absent 'baseImage: xnet\.registry\.io:8443/observability/foundationdb/foundationdb' "${TMP_DIR}/byconity.rendered.yaml"

  echo "PASS: verify image mapping"
}

main "$@"
