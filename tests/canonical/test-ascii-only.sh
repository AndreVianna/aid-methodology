#!/usr/bin/env bash
# test-ascii-only.sh - Guard: all shipped scripts must contain only ASCII bytes.
#
# Rationale: non-ASCII chars in shipped scripts cause PowerShell parse failures
# when the host decodes files in a non-UTF-8 ANSI codepage (e.g. Windows-1252).
# ASCII bytes decode identically in every single-byte codepage, so ASCII-only
# files are safe regardless of the shell's default encoding.
#
# Usage:
#   bash test-ascii-only.sh
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ---------------------------------------------------------------------------
# Shipped scripts that must be ASCII-only.
# ---------------------------------------------------------------------------
SHIPPED_SCRIPTS=(
    "lib/aid-install-core.sh"
    "lib/AidInstallCore.psm1"
    "bin/aid"
    "bin/aid.ps1"
    "bin/aid.cmd"
    "install.sh"
    "install.ps1"
    "packages/npm/bin/aid.js"
    "packages/npm/scripts/vendor.js"
    "packages/pypi/aid_installer/__main__.py"
    "packages/pypi/scripts/vendor.py"
)

echo "=== ASCII-only guard ==="

for rel in "${SHIPPED_SCRIPTS[@]}"; do
    path="${REPO_ROOT}/${rel}"
    if [[ ! -f "$path" ]]; then
        fail "ASCII-only: $rel -- file not found: $path"
        continue
    fi

    # grep -P '[^\x00-\x7F]' exits 0 when non-ASCII bytes ARE found (matches exist).
    # We want the inverse: no matches = pass.
    if grep -qP '[^\x00-\x7F]' "$path"; then
        # Collect the offending chars for the error message.
        offenders=$(grep -oP '[^\x00-\x7F]' "$path" | python3 -c "
import sys
chars = {}
for line in sys.stdin:
    c = line.rstrip('\n')
    if c:
        chars[c] = chars.get(c, 0) + 1
parts = [f'U+{ord(c):04X}({n}x)' for c, n in sorted(chars.items(), key=lambda x: ord(x[0]))]
print(' '.join(parts))
" 2>/dev/null || echo "(non-ASCII bytes found)")
        fail "ASCII-only: $rel -- non-ASCII bytes found: $offenders"
    else
        pass "ASCII-only: $rel"
    fi
done

test_summary
