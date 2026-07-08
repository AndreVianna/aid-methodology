#!/usr/bin/env bash
# test-connector-secret.sh -- Unit tests for
# canonical/aid/scripts/connectors/connector-secret.sh (task-006,
# work-002-external_sources / feature-003 "Local Auth Registration").
#
# This is the most security-sensitive script in the connectors family, so this
# suite pays special attention to leak-proofing: every `write` invocation's
# captured stdout AND stderr are grepped for the literal secret value and
# asserted absent (feature-003 SPEC.md "Security Specs" -- AC-3, "Leak-proof").
#
# No-echo `write` is fed via a piped `printf` / here-string (`<<<`) in every
# test below -- this redirects stdin away from a real tty, so `read -rs`'s
# terminal-echo suppression becomes a no-op (there is nothing left to
# suppress: no terminal is echoing the piped bytes back anywhere) and the
# value is read exactly as sent. This is the documented, and only, way to
# drive `write` without an interactive terminal (see the script's own header).
#
# Tests cover:
#   T1   write: happy path -- exact bytes stored, no trailing newline
#   T2   write: happy path -- exit 0
#   T3   write: stdout is ONLY the `file:` reference (exact string)
#   T4   write: the secret value is ABSENT from captured stdout (no-leak proof)
#   T5   write: the secret value is ABSENT from captured stderr (no-leak proof)
#   T6   write: exact-bytes preservation of leading/trailing whitespace (no trim)
#   T7   write: empty secret input -- exit 1, no file created
#   T8   purge: present -- file removed, exit 0
#   T9   purge: absent -- idempotent no-op, exit 0
#   T10  purge: absent -- stdout is empty
#   T11  confinement: write rejects '../x' -- exit 3, no file created, no hang
#   T12  confinement: write rejects 'a/b' -- exit 3
#   T13  confinement: write rejects 'a\b' -- exit 3
#   T14  confinement: purge rejects '../x' -- exit 3
#   T15  confinement: purge rejects 'a/b' -- exit 3
#   T16  confinement: purge rejects 'a\b' -- exit 3
#   T17  fail-closed: write refuses when .gitignore is missing entirely -- exit 4
#   T18  fail-closed: write refuses when .gitignore exists but lacks .secrets/ -- exit 4
#   T19  fail-closed: purge does NOT require the ignore precondition
#   T20  usage: unknown operation -- exit 2
#   T21  usage: missing <stem> -- exit 2
#   T22  usage: no operation at all -- exit 2
#   T23  confinement: stderr diagnostic names the rejected stem
#   T24  write: --root correctly scopes the write target
#   T25  write: overwrite -- update replaces the previously stored bytes
#
# Usage:
#   bash test-connector-secret.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/connectors/connector-secret.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

echo "== connector-secret.sh tests =="

# ---------------------------------------------------------------------------
# Fixture: a throwaway connectors root, cleaned up on exit. NEVER touches the
# repo's real .aid/connectors/.
# ---------------------------------------------------------------------------
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

ROOT="${TMPDIR}/connectors"
mkdir -p "$ROOT"
printf '.secrets/\n' > "${ROOT}/.gitignore"

SECRET="s3cr3t-T0k3n-value-99"

# ---------------------------------------------------------------------------
# T1-T5: write happy path + leak-proofing
# ---------------------------------------------------------------------------
out=$(printf '%s\n' "$SECRET" | bash "$SUT" write ghtest --root "$ROOT" 2>"${TMPDIR}/stderr1")
ec=$?
err="$(cat "${TMPDIR}/stderr1")"

stored="$(cat "${ROOT}/.secrets/ghtest" 2>/dev/null)"
if [[ "$stored" == "$SECRET" ]]; then
    pass "T1: write stores the exact secret bytes"
else
    fail "T1: write exact bytes -- got '$stored', expected '$SECRET'"
fi
# No trailing newline: file size must equal strlen(SECRET), not +1.
actual_size=$(wc -c < "${ROOT}/.secrets/ghtest" | tr -d ' ')
expected_size=${#SECRET}
if [[ "$actual_size" -eq "$expected_size" ]]; then
    pass "T1b: write appends no trailing newline (byte count matches)"
else
    fail "T1b: trailing newline check -- got $actual_size bytes, expected $expected_size"
fi

assert_exit_zero "$ec" "T2: write happy path"
assert_eq "$out" "file:${ROOT}/.secrets/ghtest" "T3: stdout is ONLY the file: reference"
assert_output_not_contains "$out" "$SECRET" "T4: secret value ABSENT from captured stdout (no-leak proof)"
assert_output_not_contains "$err" "$SECRET" "T5: secret value ABSENT from captured stderr (no-leak proof)"

# ---------------------------------------------------------------------------
# T6: exact-bytes preservation of leading/trailing whitespace
# ---------------------------------------------------------------------------
SPACEY="  has leading and trailing spaces  "
printf '%s\n' "$SPACEY" | bash "$SUT" write spacey --root "$ROOT" >/dev/null 2>&1
stored_spacey="$(cat "${ROOT}/.secrets/spacey" 2>/dev/null)"
if [[ "$stored_spacey" == "$SPACEY" ]]; then
    pass "T6: write preserves leading/trailing whitespace exactly (no read-trimming)"
else
    fail "T6: whitespace preservation -- got '$stored_spacey', expected '$SPACEY'"
fi

# ---------------------------------------------------------------------------
# T7: empty secret input -- exit 1, no file created
# ---------------------------------------------------------------------------
out=$(printf '' | bash "$SUT" write emptytest --root "$ROOT" 2>"${TMPDIR}/stderr7")
ec=$?
assert_exit_eq "$ec" 1 "T7: empty secret input exits 1"
if [[ ! -e "${ROOT}/.secrets/emptytest" ]]; then
    pass "T7b: empty secret input creates no value file"
else
    fail "T7b: empty secret input unexpectedly created a value file"
fi

# ---------------------------------------------------------------------------
# T8-T10: purge
# ---------------------------------------------------------------------------
out=$(bash "$SUT" purge ghtest --root "$ROOT" </dev/null)
ec=$?
assert_exit_zero "$ec" "T8: purge deletes the present value file"
if [[ ! -e "${ROOT}/.secrets/ghtest" ]]; then
    pass "T8b: purge removed the value file"
else
    fail "T8b: purge did not remove the value file"
fi

out=$(bash "$SUT" purge ghtest --root "$ROOT" </dev/null)
ec=$?
assert_exit_zero "$ec" "T9: purge on an already-absent value file is a clean no-op"
assert_eq "$out" "" "T10: purge prints nothing to stdout"

# ---------------------------------------------------------------------------
# T11-T16: path confinement -- rejected BEFORE any I/O, no hang (stdin closed)
# ---------------------------------------------------------------------------
for bad_stem in '../x' 'a/b' 'a\b'; do
    out=$(bash "$SUT" write "$bad_stem" --root "$ROOT" </dev/null 2>"${TMPDIR}/stderr_write_confine")
    ec=$?
    err="$(cat "${TMPDIR}/stderr_write_confine")"
    label_id=""
    case "$bad_stem" in
        '../x') label_id="T11" ;;
        'a/b')  label_id="T12" ;;
        'a\b')  label_id="T13" ;;
    esac
    assert_exit_eq "$ec" 3 "${label_id}: write rejects stem '${bad_stem}' with exit 3"
done

for bad_stem in '../x' 'a/b' 'a\b'; do
    out=$(bash "$SUT" purge "$bad_stem" --root "$ROOT" </dev/null 2>&1)
    ec=$?
    label_id=""
    case "$bad_stem" in
        '../x') label_id="T14" ;;
        'a/b')  label_id="T15" ;;
        'a\b')  label_id="T16" ;;
    esac
    assert_exit_eq "$ec" 3 "${label_id}: purge rejects stem '${bad_stem}' with exit 3"
done

# ---------------------------------------------------------------------------
# T17-T19: fail-closed ignore precondition (write only)
# ---------------------------------------------------------------------------
ROOT_NO_GITIGNORE="${TMPDIR}/connectors-no-gitignore"
mkdir -p "$ROOT_NO_GITIGNORE"
out=$(printf '%s\n' "$SECRET" | bash "$SUT" write foo --root "$ROOT_NO_GITIGNORE" 2>"${TMPDIR}/stderr17")
ec=$?
err="$(cat "${TMPDIR}/stderr17")"
assert_exit_eq "$ec" 4 "T17: write refuses when .gitignore is missing entirely"
if [[ ! -e "${ROOT_NO_GITIGNORE}/.secrets/foo" ]]; then
    pass "T17b: fail-closed refusal created no value file"
else
    fail "T17b: fail-closed refusal unexpectedly created a value file"
fi

ROOT_BAD_GITIGNORE="${TMPDIR}/connectors-bad-gitignore"
mkdir -p "$ROOT_BAD_GITIGNORE"
printf 'node_modules/\n*.log\n' > "${ROOT_BAD_GITIGNORE}/.gitignore"
out=$(printf '%s\n' "$SECRET" | bash "$SUT" write foo --root "$ROOT_BAD_GITIGNORE" 2>"${TMPDIR}/stderr18")
ec=$?
assert_exit_eq "$ec" 4 "T18: write refuses when .gitignore exists but does not ignore .secrets/"

# purge does NOT require the ignore precondition -- succeeds even with no
# .gitignore at all.
mkdir -p "${ROOT_NO_GITIGNORE}/.secrets"
printf 'irrelevant' > "${ROOT_NO_GITIGNORE}/.secrets/orphan"
out=$(bash "$SUT" purge orphan --root "$ROOT_NO_GITIGNORE" </dev/null)
ec=$?
assert_exit_zero "$ec" "T19: purge does not require the ignore precondition"

# ---------------------------------------------------------------------------
# T20-T22: usage errors
# ---------------------------------------------------------------------------
out=$(bash "$SUT" bogus foo --root "$ROOT" </dev/null 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "T20: unknown operation exits 2"

out=$(bash "$SUT" write --root "$ROOT" </dev/null 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "T21: missing <stem> exits 2"

out=$(bash "$SUT" </dev/null 2>&1)
ec=$?
assert_exit_eq "$ec" 2 "T22: no operation at all exits 2"

# ---------------------------------------------------------------------------
# T23: confinement diagnostic names the rejected stem
# ---------------------------------------------------------------------------
err=$(bash "$SUT" write '../evil' --root "$ROOT" </dev/null 2>&1 1>/dev/null)
if [[ "$err" == *"../evil"* ]]; then
    pass "T23: confinement diagnostic names the rejected stem"
else
    fail "T23: confinement diagnostic -- got '$err', expected it to name '../evil'"
fi

# ---------------------------------------------------------------------------
# T24: --root correctly scopes the write target (no writes outside --root)
# ---------------------------------------------------------------------------
ROOT2="${TMPDIR}/connectors-second"
mkdir -p "$ROOT2"
printf '.secrets/\n' > "${ROOT2}/.gitignore"
printf '%s\n' "$SECRET" | bash "$SUT" write scoped --root "$ROOT2" >/dev/null 2>&1
if [[ -f "${ROOT2}/.secrets/scoped" && ! -e "${ROOT}/.secrets/scoped" ]]; then
    pass "T24: --root scopes the write to the given root only"
else
    fail "T24: --root scoping -- expected value only under $ROOT2"
fi

# ---------------------------------------------------------------------------
# T25: overwrite -- update replaces the previously stored bytes
# ---------------------------------------------------------------------------
printf '%s\n' "first-value" | bash "$SUT" write updatable --root "$ROOT" >/dev/null 2>&1
printf '%s\n' "second-value" | bash "$SUT" write updatable --root "$ROOT" >/dev/null 2>&1
stored_updated="$(cat "${ROOT}/.secrets/updatable" 2>/dev/null)"
assert_eq "$stored_updated" "second-value" "T25: write overwrites a previously stored value"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo
test_summary
exit $?
