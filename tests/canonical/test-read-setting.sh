#!/usr/bin/env bash
# test-read-setting.sh — Unit tests for canonical/aid/scripts/config/read-setting.sh.
#
# Tests cover the three-tier resolution model:
#   1. Per-skill override (e.g., discover.minimum_grade) wins over global
#   2. Global category default (review.minimum_grade) when no override
#   3. Hardcoded --default when neither global nor override present
#   4. --path mode (direct dotted lookup) works
#   5. Missing settings.yml + --default → returns default, exits 0
#   6. Missing settings.yml + no --default → exits 1
#   7. Inline comments stripped from value
#   8. Quoted values stripped of quotes
#   9. Dotless --path is a flat top-level scalar lookup (found → exit 0;
#      absent + no --default → exit 1, NOT an argument error)
#  10. Unknown flag → exits 2
#  11. --skill without --key (or vice versa) → exits 2
#
# Usage:
#   read-setting.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/config/read-setting.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Fixture builders
# ---------------------------------------------------------------------------

settings_full() {
    # Per-skill override + global category + execution + traceability
    cat <<'EOF'
project:
  name: test-project

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1

discover:
  minimum_grade: A+

execute:
  minimum_grade: B+
EOF
}

settings_global_only() {
    cat <<'EOF'
review:
  minimum_grade: B

execution:
  max_parallel_tasks: 3
EOF
}

settings_with_comments() {
    cat <<'EOF'
review:
  minimum_grade: A   # global minimum across all skills

discover:
  minimum_grade: "A+"   # quoted value with inline comment
EOF
}

# ---------------------------------------------------------------------------
# Test setup
# ---------------------------------------------------------------------------

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Sanity check: SUT exists
if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

echo "== read-setting.sh tests =="

# ---------------------------------------------------------------------------
# Test 1: per-skill override wins
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t1.yml"
settings_full > "$fixture"
out=$(bash "$SUT" --file "$fixture" --skill discover --key minimum_grade --default A 2>&1)
ec=$?
if [[ "$out" == "A+" && $ec -eq 0 ]]; then
    pass "T1: per-skill override (discover.minimum_grade=A+) wins"
else
    fail "T1: per-skill override" "got '$out' (ec=$ec), expected 'A+'"
fi

# ---------------------------------------------------------------------------
# Test 2: global category fallback when no per-skill override
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t2.yml"
settings_global_only > "$fixture"
out=$(bash "$SUT" --file "$fixture" --skill specify --key minimum_grade --default A 2>&1)
ec=$?
if [[ "$out" == "B" && $ec -eq 0 ]]; then
    pass "T2: global review.minimum_grade=B used when no specify.minimum_grade"
else
    fail "T2: global fallback" "got '$out' (ec=$ec), expected 'B'"
fi

# ---------------------------------------------------------------------------
# Test 3: --default kicks in when neither global nor per-skill is set
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t3.yml"
cat > "$fixture" <<'EOF'
project:
  name: test-only
EOF
out=$(bash "$SUT" --file "$fixture" --skill plan --key minimum_grade --default A 2>&1)
ec=$?
if [[ "$out" == "A" && $ec -eq 0 ]]; then
    pass "T3: --default A used when no review.minimum_grade and no plan.minimum_grade"
else
    fail "T3: default fallback" "got '$out' (ec=$ec), expected 'A'"
fi

# ---------------------------------------------------------------------------
# Test 4: --path mode works for non-grade settings
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t4.yml"
settings_full > "$fixture"
out=$(bash "$SUT" --file "$fixture" --path execution.max_parallel_tasks --default 1 2>&1)
ec=$?
if [[ "$out" == "5" && $ec -eq 0 ]]; then
    pass "T4: --path execution.max_parallel_tasks=5"
else
    fail "T4: --path mode" "got '$out' (ec=$ec), expected '5'"
fi

# ---------------------------------------------------------------------------
# Test 5: missing settings.yml + --default → returns default, exits 0
# ---------------------------------------------------------------------------
fixture="$TMPDIR/does-not-exist.yml"
out=$(bash "$SUT" --file "$fixture" --skill discover --key minimum_grade --default A 2>&1)
ec=$?
if [[ "$out" == "A" && $ec -eq 0 ]]; then
    pass "T5: missing settings.yml + --default returns default"
else
    fail "T5: missing+default" "got '$out' (ec=$ec), expected 'A' (ec=0)"
fi

# ---------------------------------------------------------------------------
# Test 6: missing settings.yml + no --default → exits 1
# ---------------------------------------------------------------------------
fixture="$TMPDIR/missing2.yml"
out=$(bash "$SUT" --file "$fixture" --skill discover --key minimum_grade 2>&1)
ec=$?
if [[ $ec -eq 1 ]]; then
    pass "T6: missing settings.yml + no --default exits 1"
else
    fail "T6: missing+no-default" "got ec=$ec, expected 1; out='$out'"
fi

# ---------------------------------------------------------------------------
# Test 7: inline comments stripped
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t7.yml"
settings_with_comments > "$fixture"
out=$(bash "$SUT" --file "$fixture" --skill specify --key minimum_grade --default Z 2>&1)
ec=$?
if [[ "$out" == "A" && $ec -eq 0 ]]; then
    pass "T7: inline comment after value is stripped (review.minimum_grade=A)"
else
    fail "T7: comment strip" "got '$out' (ec=$ec), expected 'A'"
fi

# ---------------------------------------------------------------------------
# Test 8: quoted values have quotes stripped
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t8.yml"
settings_with_comments > "$fixture"
out=$(bash "$SUT" --file "$fixture" --skill discover --key minimum_grade --default Z 2>&1)
ec=$?
if [[ "$out" == "A+" && $ec -eq 0 ]]; then
    pass "T8: surrounding quotes stripped (discover.minimum_grade=\"A+\" → A+)"
else
    fail "T8: quote strip" "got '$out' (ec=$ec), expected 'A+'"
fi

# ---------------------------------------------------------------------------
# Test 9: dotless --path is a flat top-level scalar lookup, not an argument
# error. A dotless --path <key> resolves against a top-level `key: value` line
# (the flat settings schema keeps name/description/type/minimum_grade etc. at
# the top level, no longer nested under project:/review:). Found → exit 0;
# absent with no --default → exit 1 (value missing), NOT exit 2.
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t9.yml"
cat > "$fixture" <<'EOF'
name: test-project
description: A test project
type: brownfield
EOF
out=$(bash "$SUT" --file "$fixture" --path name --default X 2>&1)
ec=$?
if [[ "$out" == "test-project" && $ec -eq 0 ]]; then
    pass "T9a: dotless --path name resolves the flat top-level scalar"
else
    fail "T9a: dotless path top-level lookup" "got '$out' (ec=$ec), expected 'test-project'"
fi

out=$(bash "$SUT" --file "$fixture" --path nonexistent_key 2>&1)
ec=$?
if [[ $ec -eq 1 ]]; then
    pass "T9b: dotless --path for an absent key with no --default exits 1 (not found), not an argument error"
else
    fail "T9b: dotless path absent key" "got ec=$ec, expected 1; out='$out'"
fi

# ---------------------------------------------------------------------------
# Test 10: unknown flag exits 2
# ---------------------------------------------------------------------------
out=$(bash "$SUT" --bogus 2>&1)
ec=$?
if [[ $ec -eq 2 ]]; then
    pass "T10: unknown flag exits 2"
else
    fail "T10: unknown flag" "got ec=$ec, expected 2; out='$out'"
fi

# ---------------------------------------------------------------------------
# Test 11: --skill without --key exits 2
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t11.yml"
settings_full > "$fixture"
out=$(bash "$SUT" --file "$fixture" --skill discover 2>&1)
ec=$?
if [[ $ec -eq 2 ]]; then
    pass "T11: --skill without --key exits 2"
else
    fail "T11: skill-no-key" "got ec=$ec, expected 2; out='$out'"
fi

# ---------------------------------------------------------------------------
# Test 12: another per-skill (execute.minimum_grade=B+) honored
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t12.yml"
settings_full > "$fixture"
out=$(bash "$SUT" --file "$fixture" --skill execute --key minimum_grade --default A 2>&1)
ec=$?
if [[ "$out" == "B+" && $ec -eq 0 ]]; then
    pass "T12: execute.minimum_grade=B+ honored (different per-skill than discover)"
else
    fail "T12: second per-skill" "got '$out' (ec=$ec), expected 'B+'"
fi

# ---------------------------------------------------------------------------
# Test 13: traceability.heartbeat_interval via --path
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t13.yml"
settings_full > "$fixture"
out=$(bash "$SUT" --file "$fixture" --path traceability.heartbeat_interval --default 0 2>&1)
ec=$?
if [[ "$out" == "1" && $ec -eq 0 ]]; then
    pass "T13: --path traceability.heartbeat_interval=1"
else
    fail "T13: path traceability" "got '$out' (ec=$ec), expected '1'"
fi

# ---------------------------------------------------------------------------
# Test 14 (F12): inline list-form value via --path returns comma-joined items
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t14.yml"
cat > "$fixture" <<'EOF'
tools:
  installed: [claude-code, codex, cursor]
EOF
out=$(bash "$SUT" --file "$fixture" --path tools.installed --default fallback 2>&1)
ec=$?
if [[ "$out" == "claude-code,codex,cursor" && $ec -eq 0 ]]; then
    pass "T14 (F12): inline list returns comma-joined items"
else
    fail "T14 (F12): inline list" "got '$out' (ec=$ec), expected 'claude-code,codex,cursor'"
fi

# ---------------------------------------------------------------------------
# Test 15 (F12): block-form list value via --path returns comma-joined items
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t15.yml"
cat > "$fixture" <<'EOF'
tools:
  installed:
    - claude-code
    - codex
EOF
out=$(bash "$SUT" --file "$fixture" --path tools.installed --default fallback 2>&1)
ec=$?
if [[ "$out" == "claude-code,codex" && $ec -eq 0 ]]; then
    pass "T15 (F12): block-form list returns comma-joined items"
else
    fail "T15 (F12): block list" "got '$out' (ec=$ec), expected 'claude-code,codex'"
fi

# ---------------------------------------------------------------------------
# Test 16 (F20): error message includes absolute resolved path
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t16-missing.yml"
err=$(bash "$SUT" --file "$fixture" --skill discover --key minimum_grade 2>&1 1>/dev/null)
ec=$?
if [[ $ec -eq 1 ]] && [[ "$err" == *"$TMPDIR"* ]] && [[ "$err" == *"t16-missing.yml"* ]]; then
    pass "T16 (F20): error message includes absolute resolved path"
else
    fail "T16 (F20): abs path in error" "got '$err' (ec=$ec), expected error containing '$TMPDIR/t16-missing.yml'"
fi

# ---------------------------------------------------------------------------
# Test 17a: inline list with whitespace inside brackets (MIN2 from round-2)
# tools.installed: [ claude-code , codex , cursor ]  ← spaces around items
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t17a.yml"
cat > "$fixture" <<'EOF'
tools:
  installed: [ claude-code , codex , cursor ]
EOF
out=$(bash "$SUT" --file "$fixture" --path tools.installed --default fallback 2>&1)
ec=$?
if [[ "$out" == "claude-code,codex,cursor" && $ec -eq 0 ]]; then
    pass "T17a (MIN2): inline list with bracket-padding whitespace parses correctly"
else
    fail "T17a (MIN2): bracket-padding" "got '$out' (ec=$ec), expected 'claude-code,codex,cursor'"
fi

# ---------------------------------------------------------------------------
# Test 17 (F13): set -e does NOT abort on lookup() finding no match
# ---------------------------------------------------------------------------
fixture="$TMPDIR/t17.yml"
cat > "$fixture" <<'EOF'
project:
  name: only-this-key
EOF
# Asking for a key not in the file should return the default cleanly, not abort.
out=$(bash "$SUT" --file "$fixture" --skill discover --key minimum_grade --default A 2>&1)
ec=$?
if [[ "$out" == "A" && $ec -eq 0 ]]; then
    pass "T17 (F13): set -e does not abort on key-not-found; default returned"
else
    fail "T17 (F13): set -e + miss" "got '$out' (ec=$ec), expected 'A'"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo
test_summary
exit $?
