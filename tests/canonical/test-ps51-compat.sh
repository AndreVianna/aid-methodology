#!/usr/bin/env bash
# test-ps51-compat.sh - Guard: shipped PowerShell stays Windows PowerShell 5.1 compatible.
#
# The repo advertises "PowerShell 5.1+" (README, docs/install.md) and the shipped
# PS files declare "#Requires -Version 5.1". This suite runs an AST-based lint
# (ps51-compat-check.ps1) that fails on any PowerShell 6.0/7-only construct -
# 3-arg Join-Path, utf8NoBOM encoding, $IsWindows, web-calls-without-TLS12, etc.
#
# Why a custom lint and not PSScriptAnalyzer: PSSA's PSUseCompatible* rules
# silently MISS 3-arg Join-Path, utf8NoBOM, $IsWindows and 3-arg String.Replace
# (verified), so a PSSA-only gate gives false confidence. This catches them.
#
# NOTE: this is a STATIC lint. Runtime 5.1 behavior (BOM divergence, the actual
# TLS handshake, FileSystem-provider semantics) is covered by the real WinPS 5.1
# CI lane in .github/workflows/installer-tests.yml.
#
# Usage:  bash test-ps51-compat.sh [-v]
# Exit:   0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/pwsh.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECK="$(dirname "${BASH_SOURCE[0]}")/ps51-compat-check.ps1"

# Gate: skip when pwsh is absent (CI always has it; see the runtime-assert step).
PWSH="$(detect_pwsh || true)"
if [[ -z "$PWSH" ]]; then
    echo "SKIP: pwsh not found on PATH - skipping WinPS 5.1 compatibility lint (needs PowerShell)."
    exit 0
fi

out="$("$PWSH" -NoProfile -File "$CHECK" "$REPO_ROOT" 2>&1)"
rc=$?

if [[ $rc -eq 0 ]]; then
    pass "shipped PowerShell is Windows PowerShell 5.1-compatible (AST lint)"
    [[ "$VERBOSE" -eq 1 ]] && echo "$out"
else
    fail "shipped PowerShell has WinPS 5.1 incompatibilities:"$'\n'"$out"
fi

test_summary
