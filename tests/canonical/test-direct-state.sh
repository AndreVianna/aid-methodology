#!/usr/bin/env bash
# COVERS: direct work initialization and writer compatibility.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
exec python3 "$ROOT/tests/canonical/test_direct_state.py"
