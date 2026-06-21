#!/usr/bin/env bash
# test-summarize-preflight.sh -- unit tests for the FR31 legacy-summary migration
# block inside summarize-preflight.sh, plus a stale-check-after-migrate integration.
#
# Note: Only the migration block (step 6) and stale-check integration are tested here.
# The earlier prerequisite checks (1-5) require a real approved KB + network, so they
# are exercised by integration / dogfood runs. These tests construct minimal fixtures
# that satisfy checks 1-5 with stubs so the script reaches the migration block.
#
# Test scenarios:
#   T1a: old present + new absent  -> after preflight, new exists and old absent
#   T1b: both present              -> no clobber: new untouched, old still present
#   T1c: neither present           -> no-op (preflight still exits 0)
#   T1d: old present + new absent + .aid/dashboard unwritable -> best-effort, exit 0
#   T1e: idempotency               -> run twice, second run is a no-op
#   T2:  stale-check-after-migrate -> migrated summary makes stale-check.sh return CURRENT_APPROVED
#
# Usage:
#   test-summarize-preflight.sh [-v | --verbose]
#
# Exit codes:
#   0 -- all tests passed
#   1 -- one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFLIGHT_SCRIPT="${SCRIPT_DIR}/../../canonical/aid/scripts/summarize/summarize-preflight.sh"
STALE_CHECK_SCRIPT="${SCRIPT_DIR}/../../canonical/aid/scripts/summarize/stale-check.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "${SCRIPT_DIR}/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Create a minimal valid KB fixture so preflight checks 1-5 pass.
# This stubs Node.js, network, and populates .aid/knowledge/STATE.md + a doc.
# The script is run inside the fixture dir (cd into it).
make_kb_fixture() {
    local dir="$1"
    mkdir -p "${dir}/.aid/knowledge"

    # Check 1+2: STATE.md with User Approved: yes
    cat > "${dir}/.aid/knowledge/STATE.md" <<'STATEEOF'
## Knowledge Documents Status

**User Approved:** yes

## Knowledge Summary Status

**User Approved:** yes (2026-06-01)

## Review History

| # | Date | Grade | Source | Notes |
|---|------|-------|--------|-------|
| 1 | 2026-06-01 | A | /aid-discover | initial |

## Summarization History

| # | Date | Grade | ... |
|---|------|-------|-----|
| 1 | 2026-06-01 | A | initial |
STATEEOF

    # Check 3: a populated KB doc (>30 non-blank lines)
    local doc="${dir}/.aid/knowledge/architecture.md"
    printf '# Architecture\n' > "$doc"
    for i in $(seq 1 35); do printf 'Line %d\n' "$i"; done >> "$doc"
}

# Run preflight inside a fixture directory, stubbing out node + curl to avoid
# real network/Node checks. We pass --cdn-mermaid to skip the network check and
# point to a fake 'node' that reports version 20.
run_preflight_in() {
    local dir="$1"
    # Create a stub node in a temp bin dir that reports version 20
    local stub_bin="${dir}/.stub-bin"
    mkdir -p "$stub_bin"
    cat > "${stub_bin}/node" <<'NODEEOF'
#!/usr/bin/env sh
# stub: print version string and exit 0
case "$*" in
    *process.versions*) echo "20" ;;
    *) echo "v20.0.0" ;;
esac
exit 0
NODEEOF
    chmod +x "${stub_bin}/node"

    # Run preflight with the stub node on PATH, CDN mode (skip network), inside dir
    ( cd "$dir" && PATH="${stub_bin}:$PATH" bash "$PREFLIGHT_SCRIPT" --cdn-mermaid 2>&1 )
    return $?
}

# ---------------------------------------------------------------------------
# Global teardown
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
echo ""
echo "=== T1a: old present + new absent -> migrated to new path ==="

REPO_1A="${TMPDIR_BASE}/t1a"
make_kb_fixture "$REPO_1A"

OLD_1A="${REPO_1A}/.aid/knowledge/knowledge-summary.html"
NEW_1A="${REPO_1A}/.aid/dashboard/kb.html"

# Plant the old summary file
echo "<html>pre-d009 summary</html>" > "$OLD_1A"

out_1a=$(run_preflight_in "$REPO_1A")
code_1a=$?

assert_exit_zero "$code_1a" "T1a: preflight exits 0"

if [[ -f "$NEW_1A" ]]; then
    pass "T1a: new path exists after migrate"
else
    fail "T1a: new path does not exist after migrate"
fi

if [[ ! -f "$OLD_1A" ]]; then
    pass "T1a: old path removed after migrate (mv, not cp)"
else
    fail "T1a: old path still present after migrate (should be gone)"
fi

assert_output_contains "$out_1a" "Migrated legacy summary" "T1a: migrate message printed"

# Content must be preserved (mv, not cp+truncate)
CONTENT_1A=$(cat "$NEW_1A" 2>/dev/null || echo "")
assert_output_contains "$CONTENT_1A" "pre-d009 summary" "T1a: migrated file content preserved"

# ---------------------------------------------------------------------------
echo ""
echo "=== T1b: both present -> no clobber (new untouched, old left) ==="

REPO_1B="${TMPDIR_BASE}/t1b"
make_kb_fixture "$REPO_1B"

OLD_1B="${REPO_1B}/.aid/knowledge/knowledge-summary.html"
NEW_1B="${REPO_1B}/.aid/dashboard/kb.html"

mkdir -p "${REPO_1B}/.aid/dashboard"
echo "<html>old pre-d009</html>"  > "$OLD_1B"
echo "<html>new post-d009</html>" > "$NEW_1B"
ORIG_NEW_CONTENT=$(cat "$NEW_1B")

run_preflight_in "$REPO_1B" > /dev/null 2>&1
code_1b=$?

assert_exit_zero "$code_1b" "T1b: preflight exits 0 when both present"

# New path must be untouched (no clobber)
CONTENT_NEW_1B=$(cat "$NEW_1B" 2>/dev/null || echo "")
if [[ "$CONTENT_NEW_1B" == "$ORIG_NEW_CONTENT" ]]; then
    pass "T1b: new path content unchanged (no clobber)"
else
    fail "T1b: new path content changed (clobber occurred!)"
fi

# Old path must still exist (we did not delete it when both present)
if [[ -f "$OLD_1B" ]]; then
    pass "T1b: old path still present when both exist"
else
    fail "T1b: old path was removed (should not be when both present)"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== T1c: neither present -> no-op, preflight exits 0 ==="

REPO_1C="${TMPDIR_BASE}/t1c"
make_kb_fixture "$REPO_1C"

OLD_1C="${REPO_1C}/.aid/knowledge/knowledge-summary.html"
NEW_1C="${REPO_1C}/.aid/dashboard/kb.html"

run_preflight_in "$REPO_1C" > /dev/null 2>&1
code_1c=$?

assert_exit_zero "$code_1c" "T1c: preflight exits 0 when neither file present"

if [[ ! -f "$OLD_1C" ]] && [[ ! -f "$NEW_1C" ]]; then
    pass "T1c: neither path created (correct no-op)"
else
    fail "T1c: unexpected file created when neither was present"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== T1d: old present + unwritable dashboard dir -> best-effort, exit 0 ==="

REPO_1D="${TMPDIR_BASE}/t1d"
make_kb_fixture "$REPO_1D"

OLD_1D="${REPO_1D}/.aid/knowledge/knowledge-summary.html"
NEW_1D="${REPO_1D}/.aid/dashboard/kb.html"

echo "<html>pre-d009</html>" > "$OLD_1D"

# Create dashboard dir and make it unwritable so mv fails
mkdir -p "${REPO_1D}/.aid/dashboard"
chmod 000 "${REPO_1D}/.aid/dashboard"

out_1d=$(run_preflight_in "$REPO_1D" 2>&1)
code_1d=$?

# Restore permissions for cleanup
chmod 755 "${REPO_1D}/.aid/dashboard"

assert_exit_zero "$code_1d" "T1d: preflight exits 0 even when migrate fails (best-effort)"

# New path must NOT exist (migrate failed gracefully)
if [[ ! -f "$NEW_1D" ]]; then
    pass "T1d: new path absent after failed migrate (correct)"
else
    fail "T1d: new path created despite unwritable dir"
fi

# Old path must still exist (not deleted on failure)
if [[ -f "$OLD_1D" ]]; then
    pass "T1d: old path preserved after failed migrate"
else
    fail "T1d: old path deleted despite migrate failure"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== T1e: idempotency -- run twice, second run is a no-op ==="

REPO_1E="${TMPDIR_BASE}/t1e"
make_kb_fixture "$REPO_1E"

OLD_1E="${REPO_1E}/.aid/knowledge/knowledge-summary.html"
NEW_1E="${REPO_1E}/.aid/dashboard/kb.html"

echo "<html>pre-d009 idempotency</html>" > "$OLD_1E"

# First run -- should migrate
run_preflight_in "$REPO_1E" > /dev/null 2>&1
code_1e_first=$?

assert_exit_zero "$code_1e_first" "T1e: first run exits 0"
if [[ -f "$NEW_1E" ]]; then
    pass "T1e: first run migrated file to new path"
else
    fail "T1e: first run did not migrate file"
fi

MTIME_AFTER_FIRST=$(stat -c '%Y' "$NEW_1E" 2>/dev/null || stat -f '%m' "$NEW_1E" 2>/dev/null || echo "0")
CONTENT_AFTER_FIRST=$(cat "$NEW_1E")

# Second run -- should be a no-op
run_preflight_in "$REPO_1E" > /dev/null 2>&1
code_1e_second=$?

assert_exit_zero "$code_1e_second" "T1e: second run exits 0"

CONTENT_AFTER_SECOND=$(cat "$NEW_1E")
if [[ "$CONTENT_AFTER_FIRST" == "$CONTENT_AFTER_SECOND" ]]; then
    pass "T1e: second run is a no-op (content unchanged)"
else
    fail "T1e: second run modified the migrated file"
fi

# Old path must still be gone (was removed on first run)
if [[ ! -f "$OLD_1E" ]]; then
    pass "T1e: old path still absent after second run"
else
    fail "T1e: old path reappeared after second run"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== T2: stale-check-after-migrate -> CURRENT_APPROVED ==="
# After migration, stale-check.sh must see the kb.html at the new path and
# (with a current+approved STATE.md) return CURRENT_APPROVED.

REPO_T2="${TMPDIR_BASE}/t2"
make_kb_fixture "$REPO_T2"

OLD_T2="${REPO_T2}/.aid/knowledge/knowledge-summary.html"
NEW_T2="${REPO_T2}/.aid/dashboard/kb.html"

echo "<html>pre-d009 stale-check test</html>" > "$OLD_T2"

# Migrate via preflight
run_preflight_in "$REPO_T2" > /dev/null 2>&1

# Now new path should exist
if [[ -f "$NEW_T2" ]]; then
    pass "T2: migration produced kb.html at new path"
else
    fail "T2: kb.html not present at new path after migration"
fi

# Run stale-check (from inside the repo dir)
stale_out=$(cd "$REPO_T2" && bash "$STALE_CHECK_SCRIPT" 2>&1)
stale_last=$(cd "$REPO_T2" && bash "$STALE_CHECK_SCRIPT" 2>/dev/null | tail -1)

assert_output_contains "$stale_last" "CURRENT_APPROVED" \
    "T2: stale-check returns CURRENT_APPROVED after migration"

# It must NOT return FIRST_RUN or STALE (those would trigger regeneration)
if echo "$stale_last" | grep -qF "FIRST_RUN"; then
    fail "T2: stale-check returned FIRST_RUN (did not see migrated kb.html)"
fi
if echo "$stale_last" | grep -qF "STALE"; then
    fail "T2: stale-check returned STALE (should have been CURRENT_APPROVED)"
fi

# ---------------------------------------------------------------------------
echo ""
test_summary
