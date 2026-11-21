#!/usr/bin/env bash
# Purpose: run the Codex safeguard's offline handler behavior tests.
# Usage: bash tests/canonical/test-codex-guard.sh
# Exit codes: 0 all tests pass; nonzero on a failure.
# COVERS: canonical/aid/scripts/change/codex_safeguard.py
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/canonical/test_codex_guard.py"
