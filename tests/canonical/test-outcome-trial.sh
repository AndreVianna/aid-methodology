#!/usr/bin/env bash
# Exercise opt-in trial installation and direct-state compatibility.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHONDONTWRITEBYTECODE=1 python3 "$SCRIPT_DIR/test_outcome_trial.py"
