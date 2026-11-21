#!/usr/bin/env bash
# Purpose: run offline tests of the Codex benchmark host adapter.
# Usage: bash tests/canonical/test-measure-codex.sh
# Exit codes: 0 all tests pass; nonzero on a failure.
# COVERS: tests/measure/measure.py tests/measure/repo_task.py tests/measure/test_codex_host.py tests/measure/test_usage_accounting.py tests/measure/test_notes_fixture.py
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/measure/test_codex_host.py"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/measure/test_usage_accounting.py"
PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tests/measure/test_notes_fixture.py"
