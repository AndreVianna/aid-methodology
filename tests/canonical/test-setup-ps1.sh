#!/usr/bin/env bash
# test-setup-ps1.sh — tests for setup.ps1, the Windows-host installer mirror of
# setup.sh. A thin bash wrapper invoking `pwsh` as the SUT (asserts via assert.sh).
#
# Scope note: setup.ps1 is the Windows installer — it joins copy paths with
# backslashes (`profiles\claude-code\.claude`) and #Requires -Version 5.1, so the
# actual file-copy install only resolves on Windows. On the Linux CI runner only
# its platform-independent PRE-install logic is exercised: target validation and
# the selection-menu loop (which run before any path joining). The install copy
# itself is covered cross-tool by the bash installer suite (test-setup.sh).
#
# The menu reads selections from stdin (1/2/3/4/5 toggle, 6 = Done); we drive it
# via a piped sequence always terminated with "6" so the loop breaks.
#
# Usage:
#   bash test-setup-ps1.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail. Skips (exit 0) if pwsh is not on PATH.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/setup.ps1"

[[ -f "$SUT" ]] || { echo "ERROR: setup.ps1 not found at $SUT" >&2; exit 1; }

if ! command -v pwsh >/dev/null 2>&1; then
    echo "SKIP: pwsh not found on PATH — skipping setup.ps1 suite (needs PowerShell)."
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

newtarget() { mktemp -d "${TMP}/tgt.XXXXXX"; }

# drive <target> <menu-input-with-newlines> → pipes menu choices to setup.ps1's stdin
drive() {
    local target="$1" input="$2"
    OUT=$(printf '%s\n' "$input" | pwsh -NoProfile -File "$SUT" "$target" 2>&1); RC=$?
}

# --- Target validation (runs before the menu / any path joining) ------------
OUT=$(pwsh -NoProfile -NonInteractive -File "$SUT" "${TMP}/nope-does-not-exist" 2>&1); RC=$?
assert_exit_eq "$RC" 1 "SPS01 nonexistent target → exit 1"
assert_output_contains "$OUT" "does not exist" "SPS01b 'does not exist' message"

# --- Menu logic that resolves without copying (Linux-safe) ------------------
T=$(newtarget)
drive "$T" "6"
assert_exit_eq "$RC" 0 "SPS02 select nothing (Done) → exit 0"
assert_output_contains "$OUT" "Nothing selected" "SPS02b 'Nothing selected'"

T=$(newtarget)
drive "$T" $'1\n1\n6'      # toggle Claude on then off → nothing selected, no copy reached
assert_exit_eq "$RC" 0 "SPS03 toggle on+off → exit 0 (no install)"
assert_output_contains "$OUT" "Nothing selected" "SPS03b toggle-off → nothing selected"
assert_eq "$([[ -d "$T/.claude" ]] && echo yes || echo no)" "no" "SPS03c nothing installed after toggle-off"

T=$(newtarget)
drive "$T" $'9\n6'         # invalid choice then Done
assert_output_contains "$OUT" "Invalid choice" "SPS04 invalid choice rejected"
assert_output_contains "$OUT" "Nothing selected" "SPS04b invalid-only → nothing selected"

# =============================================================================
# New providers (GitHub Copilot CLI = 4, Antigravity = 5, Done = 6)
# =============================================================================

# --- SPS05 Menu lists 5 tools + Done=6 --------------------------------------
# drive with just "6" (Done): menu must list all 5 tools and exit with Nothing selected.
T=$(newtarget)
drive "$T" "6"
assert_exit_eq "$RC" 0 "SPS05 select nothing (Done=6) → exit 0"
assert_output_contains "$OUT" "Nothing selected" "SPS05b Nothing selected"
assert_output_contains "$OUT" "GitHub Copilot CLI" "SPS05c menu lists GitHub Copilot CLI"
assert_output_contains "$OUT" "Antigravity" "SPS05d menu lists Antigravity"

# --- SPS06 Toggle new tool on+off -------------------------------------------
# Toggle Copilot CLI (4) on then off — nothing installed, .github absent.
T=$(newtarget)
drive "$T" $'4\n4\n6'
assert_exit_eq "$RC" 0 "SPS06 toggle Copilot on+off → exit 0"
assert_output_contains "$OUT" "Nothing selected" "SPS06b toggle Copilot off → nothing selected"
assert_eq "$([[ -d "$T/.github" ]] && echo yes || echo no)" "no" "SPS06c .github absent after Copilot toggle-off"

# --- SPS07 Out-of-range rejected with Done=6 --------------------------------
T=$(newtarget)
drive "$T" $'7\n6'
assert_output_contains "$OUT" "Invalid choice" "SPS07 choice 7 → Invalid choice"
assert_output_contains "$OUT" "Nothing selected" "SPS07b nothing installed after out-of-range"

# --- SPS08 Collision warning parity -----------------------------------------
# Select Codex (2) + Copilot CLI (4): two AGENTS.md-writing tools.
# The pre-copy collision block is Write-Host only (runs before the Windows-only copy),
# so the warning text is emitted on Linux CI without exercising the copy path.
# This validates ps1<->sh warning parity on Linux CI.
T=$(newtarget)
drive "$T" $'2\n4\n6'
assert_output_contains "$OUT" "Note:" "SPS08a Codex+Copilot → collision Note: warning emitted"
assert_output_contains "$OUT" "all install a shared AGENTS.md" "SPS08b warning names AGENTS.md collision"
assert_output_contains "$OUT" "GitHub Copilot CLI wins" "SPS08c warning names Copilot as survivor"

test_summary
