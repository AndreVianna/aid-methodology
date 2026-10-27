#!/usr/bin/env bash
# Purpose: verify runtime manifest parity on an autocrlf Git checkout.
# Usage: bash tests/canonical/test-lf-manifest-policy.sh
# Exit codes: 0 parity holds; nonzero on failure.
# COVERS: .gitattributes canonical/aid/templates/*.yml tests/canonical/test_lf_manifest_policy.py
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/canonical/test_lf_manifest_policy.py"
