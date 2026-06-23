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
    "packages/npm/scripts/postinstall.js"
    "packages/pypi/aid_installer/__main__.py"
    "packages/pypi/scripts/vendor.py"
    "dashboard/server/server.py"
    "dashboard/server/server.mjs"
    "dashboard/server/reader.mjs"
    "canonical/aid/scripts/migrate/migrate-work-hierarchy.sh"
    "canonical/aid/scripts/migrate/migrate-work-hierarchy.ps1"
    # f011 task-018: KB frontmatter migration script
    "canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh"
    # KB scripts shipped alongside the methodology (f001 task-003: add both to guard)
    "canonical/aid/scripts/kb/build-kb-index.sh"
    "canonical/aid/scripts/kb/lint-frontmatter.sh"
    # f004 task-006: harvest-coined-terms.sh + denylist
    "canonical/aid/scripts/kb/harvest-coined-terms.sh"
    "canonical/aid/scripts/kb/coined-term-denylist.txt"
    # f004 task-008: closure-check.sh coverage oracle
    "canonical/aid/scripts/kb/closure-check.sh"
    # f005 task-012: kb-teachback-questions.sh question-set generator
    "canonical/aid/scripts/kb/kb-teachback-questions.sh"
    # Maintainer test harness, but now run under Windows PowerShell 5.1 in CI
    # (installer-tests.yml 5.1 lane), which mis-parses non-ASCII in no-BOM files
    # via the ANSI codepage -- so it must stay ASCII like the shipped PS.
    "tests/windows/Test-AidInstaller.ps1"
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
