#!/usr/bin/env bash
# test-connector-secret-ps1.sh -- Unit tests for the PowerShell mirror
# canonical/aid/scripts/connectors/connector-secret.ps1 (task-006,
# work-002-external_sources / feature-003 "Local Auth Registration").
#
# This is the most security-sensitive script in the connectors family, so this
# suite pays special attention to leak-proofing: every `write` invocation's
# captured stdout AND stderr are grepped for the literal secret value and
# asserted absent (feature-003 SPEC.md "Security Specs" -- AC-3, "Leak-proof").
#
# This suite is a thin bash wrapper (like test-assemble-3part-ps1.sh): it
# invokes `pwsh` as the SUT and asserts via tests/lib/assert.sh. Skips
# (exit 0) when pwsh is not on PATH.
#
# No-echo `write` is fed via a piped `printf` in every test below -- this sets
# [Console]::IsInputRedirected, which makes the script read the value directly
# off the redirected stream ([Console]::In.ReadLine()) instead of calling
# `Read-Host -AsSecureString` (which cannot be redirected at all -- it calls
# straight into the console API and hangs indefinitely rather than reading a
# piped/file stream; verified empirically while authoring the SUT). This is
# the documented, and only, way to drive `write` non-interactively (see the
# script's own .NOTES).
#
# Tests cover:
#   T1   write: happy path -- exact bytes stored, no trailing newline, no BOM
#   T2   write: happy path -- exit 0
#   T3   write: stdout is ONLY the `file:` reference (exact string)
#   T4   write: the secret value is ABSENT from captured stdout (no-leak proof)
#   T5   write: the secret value is ABSENT from captured stderr (no-leak proof)
#   T6   write: exact-bytes preservation of leading/trailing whitespace (no trim)
#   T7   write: empty secret input -- exit 1, no file created
#   T8   purge: present -- file removed, exit 0
#   T9   purge: absent -- idempotent no-op, exit 0
#   T10  purge: absent -- stdout is empty
#   T11  confinement: write rejects '../x' -- exit 3, no file created
#   T12  confinement: write rejects 'a/b' -- exit 3
#   T13  confinement: write rejects 'a\b' -- exit 3
#   T14  confinement: purge rejects '../x' -- exit 3
#   T15  confinement: purge rejects 'a/b' -- exit 3
#   T16  confinement: purge rejects 'a\b' -- exit 3
#   T17  fail-closed: write refuses when .gitignore is missing entirely -- exit 4
#   T18  fail-closed: write refuses when .gitignore exists but lacks .secrets/ -- exit 4
#   T19  fail-closed: purge does NOT require the ignore precondition
#   T20  usage: unknown operation -- exit 2
#   T21  usage: missing <Stem> -- exit 2
#   T22  write: overwrite -- update replaces the previously stored bytes
#
# Usage:
#   bash test-connector-secret-ps1.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/connectors/connector-secret.ps1"

[[ -f "$SUT" ]] || { echo "ERROR: connector-secret.ps1 not found at $SUT" >&2; exit 1; }

if ! command -v pwsh >/dev/null 2>&1; then
    echo "SKIP: pwsh not found on PATH -- skipping connector-secret.ps1 suite (needs PowerShell)."
    exit 0
fi

echo "== connector-secret.ps1 tests =="

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

ROOT="${TMPDIR}/connectors"
mkdir -p "$ROOT"
printf '.secrets/\n' > "${ROOT}/.gitignore"

SECRET="example-connector-test-plaintext"  # non-secret test fixture (plaintext bytes); NOT a real credential

# run_write SECRET_VALUE ARGS...  -> pipes SECRET_VALUE to stdin; sets OUT, ERR, RC
run_write() {
    local secret_value="$1"; shift
    OUT=$(printf '%s\n' "$secret_value" | pwsh -NoProfile -NonInteractive -File "$SUT" "$@" 2>"${TMPDIR}/_stderr")
    RC=$?
    ERR="$(cat "${TMPDIR}/_stderr")"
}

# run ARGS...  -> no stdin piped (stdin closed); sets OUT, ERR, RC
run() {
    OUT=$(pwsh -NoProfile -NonInteractive -File "$SUT" "$@" </dev/null 2>"${TMPDIR}/_stderr")
    RC=$?
    ERR="$(cat "${TMPDIR}/_stderr")"
}

# ---------------------------------------------------------------------------
# T1-T5: write happy path + leak-proofing
# ---------------------------------------------------------------------------
run_write "$SECRET" write ghtest -Root "$ROOT"
stored="$(cat "${ROOT}/.secrets/ghtest" 2>/dev/null)"
assert_eq "$stored" "$SECRET" "T1: write stores the exact secret bytes"

actual_size=$(wc -c < "${ROOT}/.secrets/ghtest" | tr -d ' ')
expected_size=${#SECRET}
assert_eq "$actual_size" "$expected_size" "T1b: write appends no trailing newline / no BOM (byte count matches)"

assert_exit_zero "$RC" "T2: write happy path"
# Shape check rather than an exact string match: on a Git-Bash/MSYS host, a
# Unix-style $ROOT (e.g. /tmp/tmp.XXXX) passed as an argument to the native
# pwsh.exe gets silently path-translated to a real Windows path by MSYS's exec
# layer before PowerShell ever sees it (a host/shell artifact, not an SUT
# behavior -- the Bash twin's own test proves exact-path equality with no
# such translation involved). So assert the shape instead: single line,
# `file:` prefix, ends with the expected stem. The printed reference is
# ALWAYS forward-slash (normalized in the SUT to match the Bash twin), so
# unlike a raw Windows path this is a single, exact suffix check now.
if [[ "$OUT" == file:* && "$OUT" != *$'\n'* && "$OUT" == *"/.secrets/ghtest" ]]; then
    pass "T3: stdout is ONLY the file: reference (single line, file: prefix, correct stem)"
else
    fail "T3: stdout is ONLY the file: reference -- got '$OUT'"
fi
if [[ "$OUT" != *'\'* ]]; then
    pass "T3b: file: reference uses forward slashes only (no backslash), matching the Bash twin"
else
    fail "T3b: file: reference contains a backslash -- got '$OUT'"
fi
assert_output_not_contains "$OUT" "$SECRET" "T4: secret value ABSENT from captured stdout (no-leak proof)"
assert_output_not_contains "$ERR" "$SECRET" "T5: secret value ABSENT from captured stderr (no-leak proof)"

# ---------------------------------------------------------------------------
# T6: exact-bytes preservation of leading/trailing whitespace
# ---------------------------------------------------------------------------
SPACEY="  has leading and trailing spaces  "
run_write "$SPACEY" write spacey -Root "$ROOT"
stored_spacey="$(cat "${ROOT}/.secrets/spacey" 2>/dev/null)"
assert_eq "$stored_spacey" "$SPACEY" "T6: write preserves leading/trailing whitespace exactly (no trim)"

# ---------------------------------------------------------------------------
# T7: empty secret input -- exit 1, no file created
# ---------------------------------------------------------------------------
run_write "" write emptytest -Root "$ROOT"
assert_exit_eq "$RC" 1 "T7: empty secret input exits 1"
if [[ ! -e "${ROOT}/.secrets/emptytest" ]]; then
    pass "T7b: empty secret input creates no value file"
else
    fail "T7b: empty secret input unexpectedly created a value file"
fi

# ---------------------------------------------------------------------------
# T8-T10: purge
# ---------------------------------------------------------------------------
run purge ghtest -Root "$ROOT"
assert_exit_zero "$RC" "T8: purge deletes the present value file"
if [[ ! -e "${ROOT}/.secrets/ghtest" ]]; then
    pass "T8b: purge removed the value file"
else
    fail "T8b: purge did not remove the value file"
fi

run purge ghtest -Root "$ROOT"
assert_exit_zero "$RC" "T9: purge on an already-absent value file is a clean no-op"
assert_eq "$OUT" "" "T10: purge prints nothing to stdout"

# ---------------------------------------------------------------------------
# T11-T16: path confinement -- rejected BEFORE any I/O
# ---------------------------------------------------------------------------
run write '../x' -Root "$ROOT"
assert_exit_eq "$RC" 3 "T11: write rejects stem '../x' with exit 3"
run write 'a/b' -Root "$ROOT"
assert_exit_eq "$RC" 3 "T12: write rejects stem 'a/b' with exit 3"
run write 'a\b' -Root "$ROOT"
assert_exit_eq "$RC" 3 "T13: write rejects stem 'a\\b' with exit 3"

run purge '../x' -Root "$ROOT"
assert_exit_eq "$RC" 3 "T14: purge rejects stem '../x' with exit 3"
run purge 'a/b' -Root "$ROOT"
assert_exit_eq "$RC" 3 "T15: purge rejects stem 'a/b' with exit 3"
run purge 'a\b' -Root "$ROOT"
assert_exit_eq "$RC" 3 "T16: purge rejects stem 'a\\b' with exit 3"

# ---------------------------------------------------------------------------
# T17-T19: fail-closed ignore precondition (write only)
# ---------------------------------------------------------------------------
ROOT_NO_GITIGNORE="${TMPDIR}/connectors-no-gitignore"
mkdir -p "$ROOT_NO_GITIGNORE"
run_write "$SECRET" write foo -Root "$ROOT_NO_GITIGNORE"
assert_exit_eq "$RC" 4 "T17: write refuses when .gitignore is missing entirely"
if [[ ! -e "${ROOT_NO_GITIGNORE}/.secrets/foo" ]]; then
    pass "T17b: fail-closed refusal created no value file"
else
    fail "T17b: fail-closed refusal unexpectedly created a value file"
fi

ROOT_BAD_GITIGNORE="${TMPDIR}/connectors-bad-gitignore"
mkdir -p "$ROOT_BAD_GITIGNORE"
printf 'node_modules/\n*.log\n' > "${ROOT_BAD_GITIGNORE}/.gitignore"
run_write "$SECRET" write foo -Root "$ROOT_BAD_GITIGNORE"
assert_exit_eq "$RC" 4 "T18: write refuses when .gitignore exists but does not ignore .secrets/"

mkdir -p "${ROOT_NO_GITIGNORE}/.secrets"
printf 'irrelevant' > "${ROOT_NO_GITIGNORE}/.secrets/orphan"
run purge orphan -Root "$ROOT_NO_GITIGNORE"
assert_exit_zero "$RC" "T19: purge does not require the ignore precondition"

# ---------------------------------------------------------------------------
# T20-T21: usage errors
# ---------------------------------------------------------------------------
run bogus foo -Root "$ROOT"
assert_exit_eq "$RC" 2 "T20: unknown operation exits 2"

run write -Root "$ROOT"
assert_exit_eq "$RC" 2 "T21: missing <Stem> exits 2"

# ---------------------------------------------------------------------------
# T22: overwrite -- update replaces the previously stored bytes
# ---------------------------------------------------------------------------
run_write "first-value" write updatable -Root "$ROOT"
run_write "second-value" write updatable -Root "$ROOT"
stored_updated="$(cat "${ROOT}/.secrets/updatable" 2>/dev/null)"
assert_eq "$stored_updated" "second-value" "T22: write overwrites a previously stored value"

test_summary
