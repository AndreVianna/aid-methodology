#!/usr/bin/env bash
# Purpose: run the managed resync portability tests.
# Usage: bash tests/canonical/test-sync-dogfood.sh
# Exit codes: 0 when all tests pass; nonzero otherwise.
# COVERS: .claude/skills/generate-profile/scripts/sync_dogfood.py tests/canonical/test_sync_dogfood.py
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/canonical/test_sync_dogfood.py"
