#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/tools/verify-childchart-storageclass.sh"

if [[ ! -x "${SCRIPT_PATH}" ]]; then
  echo "missing executable script: ${SCRIPT_PATH}" >&2
  exit 1
fi

OUTPUT="$("${SCRIPT_PATH}")"

echo "${OUTPUT}" | rg -q 'PASS: childcharts default render does not force empty storageClassName'
echo "${OUTPUT}" | rg -q 'PASS: childcharts can render explicit storageClass when parent/global values provide one'

echo "PASS: verify_childchart_storageclass_test"
