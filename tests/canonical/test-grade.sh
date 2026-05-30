#!/usr/bin/env bash
# test-grade.sh — regression test suite for canonical/scripts/grade.sh
#
# Verifies schema-table parsing (new default), --from-prose legacy behavior,
# and the cycle-7 bug regression (severity tags in Description are NOT counted).
#
# Usage:
#   tests/canonical/test-grade.sh [-v | --verbose]
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GRADE_SH="${SCRIPT_DIR}/../../canonical/scripts/grade.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

PASS=0
FAIL=0
ERRORS=()

pass() { PASS=$((PASS + 1)); [[ "$VERBOSE" -eq 1 ]] && echo "  PASS: $*"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$*"); echo "  FAIL: $*"; }

assert_grade() {
  local label="$1"
  local expected="$2"
  local input="$3"   # file path or "-" for stdin
  shift 3
  local extra_flags=("$@")

  local actual
  if [[ "$input" == "-" ]]; then
    actual=$(echo "" | bash "$GRADE_SH" "${extra_flags[@]}" 2>/dev/null)
  else
    actual=$(bash "$GRADE_SH" "${extra_flags[@]}" "$input" 2>/dev/null)
  fi

  if [[ "$actual" == "$expected" ]]; then
    pass "$label → $actual"
  else
    fail "$label: expected $expected, got $actual"
  fi
}

assert_grade_stdin() {
  local label="$1"
  local expected="$2"
  local content="$3"
  shift 3
  local extra_flags=("$@")

  local actual
  actual=$(echo "$content" | bash "$GRADE_SH" "${extra_flags[@]}" 2>/dev/null)

  if [[ "$actual" == "$expected" ]]; then
    pass "$label → $actual"
  else
    fail "$label: expected $expected, got $actual"
  fi
}

# ---------------------------------------------------------------------------
# Create temp directory for test fixtures
# ---------------------------------------------------------------------------
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 1: Empty file → A+ ==="
# ---------------------------------------------------------------------------
EMPTY_FILE="${TMPDIR}/empty.md"
touch "$EMPTY_FILE"
assert_grade "T1 empty file" "A+" "$EMPTY_FILE"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 2: Header-only table (no data rows) → A+ ==="
# ---------------------------------------------------------------------------
HEADER_ONLY="${TMPDIR}/header-only.md"
cat > "$HEADER_ONLY" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
EOF
assert_grade "T2 header-only table" "A+" "$HEADER_ONLY"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 3: One [MINOR] Pending → A ==="
# ---------------------------------------------------------------------------
ONE_MINOR="${TMPDIR}/one-minor.md"
cat > "$ONE_MINOR" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [MINOR] | Pending | foo.md | 5 | heading capitalisation wrong | grep shows mixed case |
EOF
assert_grade "T3 one [MINOR] Pending" "A" "$ONE_MINOR"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 4: 6 [MINOR] Pending → A- ==="
# ---------------------------------------------------------------------------
SIX_MINORS="${TMPDIR}/six-minors.md"
cat > "$SIX_MINORS" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [MINOR] | Pending | foo.md | 1 | nit 1 | evidence 1 |
| 2 | [MINOR] | Pending | foo.md | 2 | nit 2 | evidence 2 |
| 3 | [MINOR] | Pending | foo.md | 3 | nit 3 | evidence 3 |
| 4 | [MINOR] | Pending | foo.md | 4 | nit 4 | evidence 4 |
| 5 | [MINOR] | Pending | foo.md | 5 | nit 5 | evidence 5 |
| 6 | [MINOR] | Pending | foo.md | 6 | nit 6 | evidence 6 |
EOF
assert_grade "T4 6 [MINOR] Pending" "A-" "$SIX_MINORS"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 5: One [HIGH] Pending → D+ ==="
# ---------------------------------------------------------------------------
ONE_HIGH="${TMPDIR}/one-high.md"
cat > "$ONE_HIGH" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [HIGH] | Pending | foo.md | 42 | wrong count: doc claims 7, disk shows 9 | ls shows 9 entries |
EOF
assert_grade "T5 one [HIGH] Pending" "D+" "$ONE_HIGH"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 6: One [CRITICAL] Pending → E+ ==="
# ---------------------------------------------------------------------------
ONE_CRIT="${TMPDIR}/one-critical.md"
cat > "$ONE_CRIT" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [CRITICAL] | Pending | arch.md | 10 | module count factually wrong | disk shows 9, doc claims 5 |
EOF
assert_grade "T6 one [CRITICAL] Pending" "E+" "$ONE_CRIT"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 7: 5 [HIGH] + 10 [LOW] Pending → D ==="
# ---------------------------------------------------------------------------
MULTI="${TMPDIR}/multi.md"
{
  echo "| # | Severity | Status | Doc | Line | Description | Evidence |"
  echo "|---|---|---|---|---|---|---|"
  for i in 1 2 3 4 5; do
    echo "| $i | [HIGH] | Pending | foo.md | $i | high finding $i | evidence |"
  done
  local_n=6
  for i in 1 2 3 4 5 6 7 8 9 10; do
    echo "| $local_n | [LOW] | Pending | bar.md | $i | low finding $i | evidence |"
    local_n=$((local_n + 1))
  done
} > "$MULTI"
assert_grade "T7 5 [HIGH] + 10 [LOW] Pending" "D" "$MULTI"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 8: Mix of Pending/Fixed/Accepted/OOS — only Pending+Recurred counted ==="
# ---------------------------------------------------------------------------
MIXED="${TMPDIR}/mixed.md"
cat > "$MIXED" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [HIGH] | Fixed | foo.md | 1 | was high, now fixed | resolved in commit abc |
| 2 | [MEDIUM] | Accepted | foo.md | 2 | accepted carryover | user accepted cycle-1 |
| 3 | [LOW] | OOS | foo.md | 3 | out of scope | methodology-refactor pending |
| 4 | [HIGH] | Invalid | foo.md | 4 | reviewer was wrong | verified correct on disk |
| 5 | [MINOR] | Pending | foo.md | 5 | nit still pending | not yet addressed |
| 6 | [MEDIUM] | Recurred | foo.md | 6 | medium that recurred | was Fixed cycle-2, back cycle-3 |
EOF
# Only rows 5 ([MINOR] Pending) and 6 ([MEDIUM] Recurred) count.
# Worst = [MEDIUM], count=1 → C+
assert_grade "T8 mixed statuses: only Pending+Recurred counted" "C+" "$MIXED"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 9: Pipe-escape in Description parsed correctly ==="
# ---------------------------------------------------------------------------
PIPE_ESC="${TMPDIR}/pipe-escape.md"
cat > "$PIPE_ESC" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [LOW] | Pending | foo.md | 10 | step A \| step B both wrong | `grep A\|B = 0 lines` |
EOF
assert_grade "T9 pipe-escape in Description" "B+" "$PIPE_ESC"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 10: Severity tag in Description text NOT counted (cycle-7 bug regression) ==="
# ---------------------------------------------------------------------------
CYCLE7_BUG="${TMPDIR}/cycle7-regression.md"
cat > "$CYCLE7_BUG" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [MINOR] | Pending | foo.md | 1 | zero [CRITICAL] / 0 [HIGH] / 0 [MEDIUM] found in summary | prose summary leaked severity tags |
EOF
# The Description contains [CRITICAL] and [HIGH] as text strings.
# Only the Severity column ([MINOR]) should be counted.
# Expected: 1 [MINOR] Pending → A
assert_grade "T10 cycle-7 regression: tags in Description not counted" "A" "$CYCLE7_BUG"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 11: Recurred treated same as Pending ==="
# ---------------------------------------------------------------------------
RECURRED="${TMPDIR}/recurred.md"
cat > "$RECURRED" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [HIGH] | Recurred | foo.md | 5 | regressed after cycle-3 fix | was Fixed cycle-3, returned cycle-5 |
EOF
assert_grade "T11 [HIGH] Recurred treated as Pending" "D+" "$RECURRED"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 12: --explain prints breakdown to stderr ==="
# ---------------------------------------------------------------------------
EXPLAIN_FILE="${TMPDIR}/explain.md"
cat > "$EXPLAIN_FILE" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [MEDIUM] | Pending | foo.md | 1 | medium issue | evidence |
| 2 | [MEDIUM] | Pending | foo.md | 2 | another medium | evidence |
| 3 | [MINOR] | Pending | foo.md | 3 | nit | evidence |
EOF
GRADE_OUT=$(bash "$GRADE_SH" --explain "$EXPLAIN_FILE" 2>/tmp/grade-stderr.txt)
STDERR_OUT=$(cat /tmp/grade-stderr.txt)

if [[ "$GRADE_OUT" == "C" ]]; then
  pass "T12a --explain: grade output is C"
else
  fail "T12a --explain: expected C, got $GRADE_OUT"
fi

if echo "$STDERR_OUT" | grep -q "MEDIUM:"; then
  pass "T12b --explain: stderr contains MEDIUM count"
else
  fail "T12b --explain: stderr missing MEDIUM count line; stderr was: $STDERR_OUT"
fi

if echo "$STDERR_OUT" | grep -q "MINOR:"; then
  pass "T12c --explain: stderr contains MINOR count"
else
  fail "T12c --explain: stderr missing MINOR count line; stderr was: $STDERR_OUT"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 13: --non-functional forces F ==="
# ---------------------------------------------------------------------------
NF_FILE="${TMPDIR}/nf.md"
cat > "$NF_FILE" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [MINOR] | Pending | foo.md | 1 | nit | evidence |
EOF
assert_grade "T13 --non-functional forces F" "F" "$NF_FILE" "--non-functional"

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 14: --from-prose legacy flag (deprecated) greps prose ==="
# ---------------------------------------------------------------------------
# With --from-prose, the old grep-everywhere behavior applies.
# Summary line "0 [CRITICAL] / 0 [HIGH]" would be counted by legacy mode.
PROSE_FILE="${TMPDIR}/prose.md"
cat > "$PROSE_FILE" << 'EOF'
Summary: 0 [CRITICAL] / 0 [HIGH] / 1 [MEDIUM] issues found.

Detailed findings:
- [MEDIUM] Something is slightly off | foo.md:42 | criterion X
EOF
# Legacy mode: grep counts [CRITICAL]=1 (from summary), [HIGH]=1 (from summary),
# [MEDIUM]=2 (summary + detail). Worst = [CRITICAL], count=1 → E+
LEGACY_OUT=$(bash "$GRADE_SH" --from-prose "$PROSE_FILE" 2>/dev/null)
if [[ "$LEGACY_OUT" == "E+" ]]; then
  pass "T14 --from-prose legacy: summary-line over-count occurs (E+ shows legacy greps prose)"
else
  fail "T14 --from-prose legacy: expected E+, got $LEGACY_OUT"
fi

# Confirm that WITHOUT --from-prose, the same file graded as schema-table gives A+
# (no valid data rows → zero findings)
SCHEMA_OUT=$(bash "$GRADE_SH" "$PROSE_FILE" 2>/dev/null)
if [[ "$SCHEMA_OUT" == "A+" ]]; then
  pass "T14b schema-table mode on prose file: A+ (no parseable rows → no findings)"
else
  fail "T14b schema-table mode on prose file: expected A+, got $SCHEMA_OUT"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 15: Stdin input works ==="
# ---------------------------------------------------------------------------
STDIN_CONTENT=$(cat << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [LOW] | Pending | foo.md | 10 | stale reference | citation removed |
| 2 | [LOW] | Pending | foo.md | 20 | another low | evidence |
EOF
)
STDIN_OUT=$(echo "$STDIN_CONTENT" | bash "$GRADE_SH" 2>/dev/null)
if [[ "$STDIN_OUT" == "B" ]]; then
  pass "T15 stdin input: 2 [LOW] Pending → B"
else
  fail "T15 stdin input: expected B, got $STDIN_OUT"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Test 16: Non-data rows (alternate table, comment) ignored ==="
# ---------------------------------------------------------------------------
EXTRA_TABLE="${TMPDIR}/extra-table.md"
cat > "$EXTRA_TABLE" << 'EOF'
| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [MINOR] | Pending | foo.md | 1 | real finding | evidence |

Some other table that happens to use the same headers:
| Column A | Column B | Column C |
|---|---|---|
| [HIGH] | [CRITICAL] | some value |
EOF
# The second table has cells that look like severity tags but the row shape
# doesn't match (cols 2+3 = "[HIGH]" and "[CRITICAL]" — "[HIGH]" is valid
# severity but "[CRITICAL]" would be parsed as Status, which is not
# Pending/Recurred, so it's skipped).
# Only the first data row is a real finding: [MINOR] Pending → A
assert_grade "T16 extra table with tag-like cells: only Pending rows counted" "A" "$EXTRA_TABLE"

# ---------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "  Tests passed: $PASS"
echo "  Tests failed: $FAIL"
if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for e in "${ERRORS[@]}"; do
        echo "  - $e"
    done
    exit 1
fi
echo ""
echo "All tests passed."
exit 0
