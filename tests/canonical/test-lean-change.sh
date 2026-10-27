#!/usr/bin/env bash
# Purpose: run behavior tests for the lean change helpers.
# Usage: bash tests/canonical/test-lean-change.sh
# Exit codes: 0 all tests pass; nonzero on failure.
# COVERS: canonical/aid/scripts/change/** tests/canonical/test_lean_change.py
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/canonical/test_lean_change.py"
