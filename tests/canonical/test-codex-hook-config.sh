#!/usr/bin/env bash
# Purpose: test project-local Codex hook configuration without invoking Codex.
# Usage: bash tests/canonical/test-codex-hook-config.sh
# Exit codes: 0 all tests pass; nonzero on failure.
# COVERS: canonical/aid/scripts/change/codex_hook_config.py
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/canonical/test_codex_hook_config.py"
