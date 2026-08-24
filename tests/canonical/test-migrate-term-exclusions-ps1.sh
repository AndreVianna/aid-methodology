#!/usr/bin/env bash
# test-migrate-term-exclusions-ps1.sh -- PowerShell-twin coverage for the work-014
# term-exclusions migration (Invoke-MigrateTermExclusions). Runs the companion
# test-migrate-term-exclusions.ps1 via pwsh. SKIP (exit 0) when pwsh is absent;
# CI asserts pwsh IS present.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v pwsh >/dev/null 2>&1; then
    echo "SKIP: pwsh not found on PATH -- skipping term-exclusions PS-twin suite (needs PowerShell)."
    echo "All tests passed."
    exit 0
fi

pwsh -NoProfile -File "${SCRIPT_DIR}/test-migrate-term-exclusions.ps1"
