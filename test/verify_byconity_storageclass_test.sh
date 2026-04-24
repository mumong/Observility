#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/tools/verify-byconity-storageclass.sh"

if [[ ! -x "${SCRIPT_PATH}" ]]; then
  echo "missing executable script: ${SCRIPT_PATH}" >&2
  exit 1
fi

OUTPUT="$("${SCRIPT_PATH}")"

echo "${OUTPUT}" | rg -q 'PASS: byconity default render does not force empty storageClassName'
echo "${OUTPUT}" | rg -q 'PASS: byconity render inherits tracing.global.storageClass'

echo "PASS: verify_byconity_storageclass_test"
