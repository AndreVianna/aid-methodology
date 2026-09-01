#!/usr/bin/env bash
# test-review-recall.sh -- the recall matcher and its two vacuity guards.
#
# COVERS: tests/review-recall.sh
# COVERS: tests/canonical/fixtures/recall-corpus/
#
# Every case uses its own fixture corpus and its own ledger under a temp dir, so
# no live measurement data is touched.
#
#   RC01  the status-aware matcher -- a row that no longer counts is not a find
#   RC02  removing the status filter changes the answer (the guard is real)
#   RC03  nothing seeded prints missing, never a perfect score
#   RC04  an empty ledger is a refusal path, not a clean report
#   RC05  an escaped delimiter cannot shift the columns
#   RC06  determinism

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-review-recall.sh =="

SUT="${REPO_ROOT}/tests/review-recall.sh"
FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT

# --- a two-row corpus of our own, so the real one cannot affect the result ----
mkdir -p "${FIX}/corpus/defects"
printf 'fixture one. RCSIG-ONE\n' > "${FIX}/corpus/defects/D01.md"
printf 'fixture two. RCSIG-TWO\n' > "${FIX}/corpus/defects/D02.md"
cat > "${FIX}/corpus/CATALOGUE.md" <<'EOF'
| id | scope | class | band | signature | fixture | pair |
|---|---|---|---|---|---|---|
| D01 | G | demo | MINOR | `RCSIG-ONE` | `defects/D01.md` | -- |
| D02 | G | demo | MINOR | `RCSIG-TWO` | `defects/D02.md` | -- |
EOF

HDR='| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|'

found_of() {  # found_of <ledger>
    bash "$SUT" report --ledger "$1" --corpus "${FIX}/corpus" 2>/dev/null \
      | awk '/^TOTAL/{print $3}'
}

# ===========================================================================
# RC01  A row whose Status no longer counts toward a grade is NOT a find.
#
# This is the off-by-one the script exists to prevent. `grade.sh` counts only
# Pending and Recurred; a Fixed row is history. Counting it would report a
# review as having caught a defect that was already closed before the review ran.
# ===========================================================================
cat > "${FIX}/pending.md" <<EOF
${HDR}
| 1 | [MINOR] | Pending | ${FIX}/corpus/defects/D01.md | 1 | G-01 stale, so a reader plans against it | \`RCSIG-ONE\` |
EOF
cat > "${FIX}/fixed.md" <<EOF
${HDR}
| 1 | [MINOR] | Fixed | ${FIX}/corpus/defects/D01.md | 1 | G-01 stale, so a reader plans against it | \`RCSIG-ONE\` |
EOF

assert_eq "$(found_of "${FIX}/pending.md")" "1" "RC01 a Pending row counts as found"
assert_eq "$(found_of "${FIX}/fixed.md")"   "0" "RC01 a Fixed row does NOT count as found"

# ===========================================================================
# RC02  The status filter is load-bearing.
#
# Both ledgers above are identical apart from one word. If the two produced the
# same answer, the filter would not be doing anything and RC01 would pass
# against a script that ignored Status entirely.
# ===========================================================================
if [ "$(found_of "${FIX}/pending.md")" != "$(found_of "${FIX}/fixed.md")" ]; then
    pass "RC02 Pending and Fixed give different answers -- the status filter is real"
else
    fail "RC02 Pending and Fixed give the same answer -- the status filter is not applied"
fi

# ===========================================================================
# RC03  Nothing seeded prints missing, never a perfect score.
#
# An empty denominator is not 100%. A suite that accepted a clean report here
# would let the whole measurement quietly evaporate.
# ===========================================================================
mkdir -p "${FIX}/empty-corpus"
printf '| id | scope | class | band | signature | fixture | pair |\n|---|---|---|---|---|---|---|\n' \
  > "${FIX}/empty-corpus/CATALOGUE.md"
out=$(bash "$SUT" report --ledger "${FIX}/pending.md" --corpus "${FIX}/empty-corpus" 2>&1)
assert_output_contains "$out" "missing" "RC03 an empty corpus reports missing"
assert_output_not_contains "$out" "TOTAL                          0        0" \
    "RC03 and does not report a clean zero-of-zero as if it were a result"

# ===========================================================================
# RC04  Unreadable inputs are refused, not reported clean.
# ===========================================================================
bash "$SUT" report --ledger "${FIX}/no-such-ledger.md" --corpus "${FIX}/corpus" >/dev/null 2>&1
assert_eq "$?" "2" "RC04 a missing ledger is an invocation error, not an empty report"
bash "$SUT" report --ledger "${FIX}/pending.md" --corpus "${FIX}/no-such-corpus" >/dev/null 2>&1
assert_eq "$?" "2" "RC04 a missing corpus is an invocation error"

# ===========================================================================
# RC05  An escaped delimiter in a cell cannot shift the columns.
#
# `\|` is the schema's own escape. Splitting on it unmasked moves every later
# cell along by one, so the Status check reads the Doc column and the report is
# wrong while still looking plausible.
# ===========================================================================
cat > "${FIX}/escaped.md" <<EOF
${HDR}
| 1 | [MINOR] | Pending | ${FIX}/corpus/defects/D01.md | 1 | G-01 says a \\| b, so the split shifts | \`RCSIG-ONE\` |
EOF
assert_eq "$(found_of "${FIX}/escaped.md")" "1" "RC05 an escaped pipe does not shift the Status cell"

# ===========================================================================
# RC06  Determinism.
# ===========================================================================
a=$(bash "$SUT" report --ledger "${FIX}/pending.md" --corpus "${FIX}/corpus" 2>&1)
b=$(bash "$SUT" report --ledger "${FIX}/pending.md" --corpus "${FIX}/corpus" 2>&1)
assert_eq "$a" "$b" "RC06 two consecutive runs agree"
c=$(LC_ALL=C bash "$SUT" report --ledger "${FIX}/pending.md" --corpus "${FIX}/corpus" 2>&1)
d=$(LC_ALL=en_US.UTF-8 bash "$SUT" report --ledger "${FIX}/pending.md" --corpus "${FIX}/corpus" 2>&1)
assert_eq "$c" "$d" "RC06 output does not depend on locale"

rm -rf "$FIX"
trap - EXIT

echo
test_summary
exit $?
