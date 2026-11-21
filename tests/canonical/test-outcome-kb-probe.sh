#!/usr/bin/env bash
# Verify the source-backed KB fixture and its predeclared outcome oracle.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$SCRIPT_DIR/test_outcome_kb_probe.py"
