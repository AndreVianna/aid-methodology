#!/usr/bin/env bash
# test-discover-preflight.sh -- Canonical tests for canonical/aid/scripts/kb/discover-preflight.sh
#
# Tests (PF01-PF08):
#
#   Self-bootstrap STATE (FR-41):
#   PF01  temp dir with NO STATE.md -> script exits 0 (self-creates STATE.md)
#   PF02  temp dir with NO STATE.md -> STATE.md exists after the script runs
#   PF03  temp dir with NO STATE.md -> STATE.md is non-empty after self-create
#   PF04  self-created STATE.md contains recognizable scaffolding content
#   PF05  with a pre-existing non-empty STATE.md -> script exits 0 (no clobber)
#   PF06  with a pre-existing non-empty STATE.md -> content is unchanged
#   PF07  zero-byte STATE.md -> script exits non-zero (error on empty)
#   PF08  zero-byte STATE.md -> script prints an error message
#
# HOME is pinned to a throwaway tmpdir so no real $HOME .aid/ is scanned.
#
# Usage:
#   bash tests/canonical/test-discover-preflight.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."

# Pin HOME to a throwaway directory so nothing scans the real developer HOME.
_FAKE_HOME="$(mktemp -d)"
export HOME="$_FAKE_HOME"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-discover-preflight.sh =="

SUT="${REPO}/canonical/aid/scripts/kb/discover-preflight.sh"

if [[ ! -f "$SUT" ]]; then
  echo "FATAL: discover-preflight.sh not found at $SUT" >&2
  exit 2
fi

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST" "$_FAKE_HOME"' EXIT

# ---------------------------------------------------------------------------
# PF01: NO STATE.md -> exits 0
# ---------------------------------------------------------------------------
KB_PF01="${TMPDIR_TEST}/pf01/knowledge"
mkdir -p "$KB_PF01"

out_pf01="$(bash "$SUT" "$KB_PF01" 2>&1)"
code_pf01=$?

assert_exit_zero "$code_pf01" "PF01 absent STATE.md -> exit 0 (self-create succeeded)"

# ---------------------------------------------------------------------------
# PF02: NO STATE.md -> STATE.md exists after run
# ---------------------------------------------------------------------------
assert_file_exists "${KB_PF01}/STATE.md" \
  "PF02 absent STATE.md -> STATE.md created after preflight"

# ---------------------------------------------------------------------------
# PF03: self-created STATE.md is non-empty
# ---------------------------------------------------------------------------
if [[ -s "${KB_PF01}/STATE.md" ]]; then
  pass "PF03 self-created STATE.md is non-empty"
else
  fail "PF03 self-created STATE.md is empty (should have content)"
fi

# ---------------------------------------------------------------------------
# PF04: self-created STATE.md contains recognizable scaffolding content
# (the template has '# Discovery State' as its H1, or the minimal fallback
#  scaffold has '# Discovery State' as well)
# ---------------------------------------------------------------------------
STATE_CONTENT_PF01="$(cat "${KB_PF01}/STATE.md")"
assert_output_contains "$STATE_CONTENT_PF01" "Discovery" \
  "PF04 self-created STATE.md contains 'Discovery' scaffolding"

# Stdout must say it seeded or wrote the file
assert_output_contains "$out_pf01" "STATE.md" \
  "PF04 preflight stdout mentions STATE.md during self-create"

# ---------------------------------------------------------------------------
# PF05: pre-existing non-empty STATE.md -> exit 0 (no-clobber path)
# ---------------------------------------------------------------------------
KB_PF05="${TMPDIR_TEST}/pf05/knowledge"
mkdir -p "$KB_PF05"
cat > "${KB_PF05}/STATE.md" <<'STATEEOF'
# Discovery State

**Status:** Initial

## Q&A (Pending)

(no questions yet)
STATEEOF

code_pf05=0
bash "$SUT" "$KB_PF05" > /dev/null 2>&1 || code_pf05=$?

assert_exit_zero "$code_pf05" \
  "PF05 pre-existing non-empty STATE.md -> exit 0"

# ---------------------------------------------------------------------------
# PF06: pre-existing STATE.md -> content is unchanged (no clobber)
# ---------------------------------------------------------------------------
ORIG_CONTENT_PF05="$(cat "${KB_PF05}/STATE.md")"
AFTER_CONTENT_PF05="$(cat "${KB_PF05}/STATE.md")"

if [[ "$ORIG_CONTENT_PF05" == "$AFTER_CONTENT_PF05" ]]; then
  pass "PF06 pre-existing STATE.md content unchanged after preflight (no clobber)"
else
  fail "PF06 pre-existing STATE.md was clobbered by preflight"
fi

# ---------------------------------------------------------------------------
# PF07: zero-byte STATE.md -> exits non-zero
# ---------------------------------------------------------------------------
KB_PF07="${TMPDIR_TEST}/pf07/knowledge"
mkdir -p "$KB_PF07"
: > "${KB_PF07}/STATE.md"   # touch a zero-byte file

code_pf07=0
bash "$SUT" "$KB_PF07" > /dev/null 2>&1 || code_pf07=$?

assert_exit_nonzero "$code_pf07" \
  "PF07 zero-byte STATE.md -> non-zero exit (error)"

# ---------------------------------------------------------------------------
# PF08: zero-byte STATE.md -> error message printed
# ---------------------------------------------------------------------------
out_pf08="$(bash "$SUT" "$KB_PF07" 2>&1 || true)"
assert_output_contains "$out_pf08" "empty" \
  "PF08 zero-byte STATE.md -> error message contains 'empty'"

# ---------------------------------------------------------------------------
echo
test_summary
exit $?
