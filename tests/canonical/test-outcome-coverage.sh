#!/usr/bin/env bash
# Exercise the outcome-coverage validator through the canonical test runner.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$SCRIPT_DIR/test_outcome_coverage.py"
