#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/tools/verify-childchart-control.sh"

if [[ ! -x "${SCRIPT_PATH}" ]]; then
  echo "missing executable script: ${SCRIPT_PATH}" >&2
  exit 1
fi

OUTPUT="$("${SCRIPT_PATH}")"

echo "${OUTPUT}" | rg -q 'PASS: helm lint \(default\)'
echo "${OUTPUT}" | rg -q 'PASS: helm lint \(all-enabled\)'
echo "${OUTPUT}" | rg -q 'PASS: render parity with final.yaml'
echo "${OUTPUT}" | rg -q 'PASS: tracing parent controls'
echo "${OUTPUT}" | rg -q 'PASS: metric parent controls'
echo "${OUTPUT}" | rg -q 'PASS: logging parent controls'

[[ -s "${ROOT_DIR}/current-rendered.yaml" ]]
[[ -s "${ROOT_DIR}/verify-rendered.yaml" ]]
[[ -s "${ROOT_DIR}/compare-rendered.yaml" ]]

echo "PASS: verify_childchart_control_test"
