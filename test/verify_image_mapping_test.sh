#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/tools/verify-image-mapping.sh"

if [[ ! -x "${SCRIPT_PATH}" ]]; then
  echo "missing executable script: ${SCRIPT_PATH}" >&2
  exit 1
fi

OUTPUT="$("${SCRIPT_PATH}")"
echo "${OUTPUT}" | rg -q 'PASS: verify image mapping'

echo "PASS: verify_image_mapping_test"
