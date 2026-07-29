#!/usr/bin/env bash
# test-writeback-ledger.sh -- the surgical ledger writer and the three row kinds.
#
# The headline property is AC-9: adding coverage and gap rows must not move the grade, nor the
# --explain breakdown. That is asserted by RUNNING grade.sh either side of each write, not by reading
# the parser -- a claim about inertness is only worth what the grader says.
#
# Usage: bash tests/canonical/test-writeback-ledger.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"

WB="${REPO}/canonical/aid/scripts/review/writeback-ledger.sh"
GRADE="${REPO}/canonical/aid/scripts/grade.sh"

echo "== test-writeback-ledger.sh =="

[[ -f "$WB" ]]    || { echo "FATAL: writeback-ledger.sh not found at $WB" >&2; exit 2; }
[[ -f "$GRADE" ]] || { echo "FATAL: grade.sh not found" >&2; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

wb () { bash "$WB" "$@"; }
g  () { bash "$GRADE" "$1" 2>/dev/null; }
rows () {   # count data rows (skip header + separator)
  awk '/^\|/ {
    if ($0 ~ /^\|[ \t:|-]+\|$/) next
    id = $2; n = split($0, c, "|"); id = c[2]; gsub(/[ `]/, "", id)
    if (id == "#") next
    k++
  } END { print k + 0 }' "$1"
}

new_ledger () {   # $1 = path; seed one finding so the grade is non-trivial
  wb --ledger "$1" --append-finding --severity '[MEDIUM]' --rule NAR-03 --doc seed.md \
     --line 1 --description 'seed finding' --evidence 'seeded' >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# WL01-WL04 -- creation, ID assignment, and the 8-column header.
# ---------------------------------------------------------------------------
L="$TMP/a.md"
out="$(wb --ledger "$L" --append-finding --severity '[HIGH]' --rule KB-22 --doc foo.md --line 42 \
          --description 'claim wrong' --evidence 'disk shows 9' 2>&1)"
assert_eq "$?" "0" "WL01 --append-finding creates the ledger when absent"
assert_output_contains "$(head -1 "$L")" '| # | Severity | Status | Rule | Doc | Line | Description | Evidence |' \
  "WL02 a created ledger carries the 8-column header"
assert_output_contains "$out" "appended finding 1" "WL03 the first finding is row 1"

wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 --doc bar.md \
   --description 'second' --evidence 'e' >/dev/null
assert_output_contains "$(wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 \
   --doc baz.md --description 'third' --evidence 'e' 2>&1)" "appended finding 3" \
  "WL04 row numbers are script-assigned and monotonic"

# ---------------------------------------------------------------------------
# WL05-WL08 -- AC-9: coverage and gap rows are grade-inert, proved by the grader.
# ---------------------------------------------------------------------------
L="$TMP/b.md"; new_ledger "$L"
before="$(g "$L")"
before_explain="$(bash "$GRADE" --explain "$L" 2>&1)"

wb --ledger "$L" --append-unit --unit seed.md --rule-set narrative --status Examined >/dev/null
assert_eq "$(g "$L")" "$before" "WL05 appending a coverage row does not change the grade (AC-9)"

wb --ledger "$L" --append-gap --gap-key no-std --doc seed.md \
   --description 'no standard declared' --resolution '/aid-update-kb coding-standards' >/dev/null
assert_eq "$(g "$L")" "$before" "WL06 appending a gap row does not change the grade (AC-9)"

wb --ledger "$L" --set-status --row-id U-001 --status Skipped >/dev/null
assert_eq "$(g "$L")" "$before" "WL07 re-statusing a coverage row does not change the grade (AC-9)"

after_explain="$(bash "$GRADE" --explain "$L" 2>&1)"
assert_eq "$after_explain" "$before_explain" "WL08 the --explain breakdown is unchanged too (AC-9)"

# The status words that LOOK grade-bearing must still be inert.
L="$TMP/b2.md"; new_ledger "$L"
before="$(g "$L")"
wb --ledger "$L" --append-unit --unit x.md --rule-set narrative --status "In Progress" >/dev/null
assert_eq "$(g "$L")" "$before" "WL09 a coverage row reading 'In Progress' is still inert"

# ---------------------------------------------------------------------------
# WL10-WL13 -- AC-3 enforcement and its single exemption.
# ---------------------------------------------------------------------------
L="$TMP/c.md"; new_ledger "$L"
wb --ledger "$L" --append-finding --severity '[LOW]' --doc a.md --description 'x' --evidence 'y' >/dev/null 2>&1
assert_eq "$?" "4" "WL10 a finding with no rule ID is rejected (exit 4)"

wb --ledger "$L" --append-finding --severity '[LOW]' --rule 'lowercase-01' --doc a.md \
   --description 'x' --evidence 'y' >/dev/null 2>&1
assert_eq "$?" "4" "WL11 a malformed rule ID is rejected (exit 4)"

wb --ledger "$L" --append-finding --severity '[LOW]' --rule '--' --doc a.md \
   --description 'x' --evidence 'y' >/dev/null 2>&1
assert_eq "$?" "4" "WL12 '--' in Rule is rejected on a grade-bearing finding (exit 4)"

# The interim OOS exemption is RETIRED. An unmatched artifact class is a [GAP:CRITERIA] gap row now,
# so an ungrounded finding must be unwritable at EVERY status -- including the one that used to be
# the escape hatch.
wb --ledger "$L" --append-finding --severity '[LOW]' --status OOS --doc a.md \
   --description 'unmatched artifact class' --evidence 'no rule set routes here' >/dev/null 2>&1
assert_eq "$?" "4" "WL13 a Status=OOS row may NO LONGER carry '--' in Rule (exemption retired)"

for st in Pending Fixed Recurred Accepted OOS Invalid; do
  wb --ledger "$L" --append-finding --severity '[LOW]' --status "$st" --rule '--' --doc a.md \
     --description 'x' --evidence 'y' >/dev/null 2>&1
  [[ "$?" -eq 4 ]] || fail "WL13b an ungrounded finding is writable at status $st"
done
pass "WL13b an ungrounded finding is unwritable at every status"

# ---------------------------------------------------------------------------
# WL14-WL17 -- --set-status is surgical: one cell, no renumbering, byte-stable.
# ---------------------------------------------------------------------------
L="$TMP/d.md"
wb --ledger "$L" --append-finding --severity '[HIGH]' --rule KB-22 --doc f1.md --line 4 \
   --description 'first' --evidence 'e1' >/dev/null
wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 --doc f2.md --line 5 \
   --description 'second' --evidence 'e2' >/dev/null
wb --ledger "$L" --append-unit --unit f1.md --rule-set narrative >/dev/null
cp "$L" "$TMP/d.before"

row_before="$(grep '^| 1 |' "$TMP/d.before")"
wb --ledger "$L" --set-status --row-id 1 --status Fixed >/dev/null
row_after="$(grep '^| 1 |' "$L")"

# every line except the target must be byte-identical
changed="$(diff "$TMP/d.before" "$L" | grep -c '^[<>]')"
assert_eq "$changed" "2" "WL14 --set-status changes exactly one line (one < and one >)"

# ...and WITHIN that line, only the Status cell may differ. Counting changed LINES is not enough:
# a bug that clobbers another cell of the same row still changes exactly one line, and a
# negative control proved this assertion was missing.
diff_cells=0
for i in 2 3 4 5 6 7 8 9; do
  b="$(printf '%s' "$row_before" | awk -F'|' -v i="$i" '{print $i}')"
  a="$(printf '%s' "$row_after"  | awk -F'|' -v i="$i" '{print $i}')"
  if [[ "$b" != "$a" ]]; then
    diff_cells=$((diff_cells + 1))
    [[ "$i" -eq 4 ]] || echo "    (cell $i changed: '$b' -> '$a')"
  fi
done
assert_eq "$diff_cells" "1" "WL15 exactly ONE cell changed in the target row, and it is Status"

assert_eq "$(rows "$L")" "3" "WL16 --set-status does not add or remove rows"
assert_output_contains "$(grep '| 2 |' "$L")" '| second |' "WL17 the untouched row keeps its cells verbatim"
assert_eq "$(wb --ledger "$L" --row-id 1 --get-status)" "Fixed" "WL18 --get-status reads the new value back"

# Status is validated against the TARGET ROW'S KIND.
wb --ledger "$L" --set-status --row-id U-001 --status Recurred >/dev/null 2>&1
assert_eq "$?" "4" "WL19 a finding status on a coverage row is rejected (exit 4)"
wb --ledger "$L" --set-status --row-id 1 --status Examined >/dev/null 2>&1
assert_eq "$?" "4" "WL20 a coverage status on a finding row is rejected (exit 4)"

# ---------------------------------------------------------------------------
# WL20-WL22 -- gap idempotence on the key.
# ---------------------------------------------------------------------------
L="$TMP/e.md"; new_ledger "$L"
wb --ledger "$L" --append-gap --gap-key dup-key --doc a.sh --description 'first sighting' \
   --resolution '/aid-update-kb coding-standards' >/dev/null
n1="$(rows "$L")"
out="$(wb --ledger "$L" --append-gap --gap-key dup-key --doc a.sh --description 'again' \
          --resolution '/aid-update-kb coding-standards' 2>&1)"
assert_eq "$(rows "$L")" "$n1" "WL20 a repeated gap key appends no new row"
assert_output_contains "$out" "resume=2" "WL21 a repeated gap key reports the incremented recurrence"
assert_output_contains "$(grep '| G-001 |' "$L")" "resume=2" "WL22 the recurrence counter is written to the row"

# A DIFFERENT key must still create a new row.
wb --ledger "$L" --append-gap --gap-key other-key --doc b.sh --description 'other' \
   --resolution '/aid-update-kb x' >/dev/null
assert_output_contains "$(grep -c '^| G-' "$L")" "2" "WL23 a different gap key creates a second gap row"

# ---------------------------------------------------------------------------
# WL24-WL27 -- input hygiene.
# ---------------------------------------------------------------------------
L="$TMP/f.md"; new_ledger "$L"
wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 --doc a.md \
   --description "$(printf 'one\ntwo')" --evidence 'e' >/dev/null 2>&1
assert_eq "$?" "4" "WL24 a raw newline is rejected (exit 4)"

wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 --doc a.md \
   --description 'has a | pipe' --evidence 'and | another' >/dev/null
assert_output_contains "$(grep 'has a' "$L")" 'has a \| pipe' "WL25 a pipe is escaped, not rejected"

# ...and the escape must not disturb the grader. Compare against the SAME findings written without
# pipes -- an earlier version compared g "$L" to itself, which is true for any input and proved
# nothing.
LP="$TMP/f-pipes.md"; LN="$TMP/f-nopipes.md"
wb --ledger "$LP" --append-finding --severity '[MEDIUM]' --rule NAR-03 --doc a.md \
   --description 'has a | pipe' --evidence 'and | another' >/dev/null
wb --ledger "$LN" --append-finding --severity '[MEDIUM]' --rule NAR-03 --doc a.md \
   --description 'has no pipe' --evidence 'nor another' >/dev/null
assert_eq "$(g "$LP")" "$(g "$LN")" "WL26 escaped pipes grade identically to the pipe-free equivalent"

wb --ledger "$L" --append-finding --severity 'HIGH' --rule NAR-08 --doc a.md \
   --description 'x' --evidence 'y' >/dev/null 2>&1
assert_eq "$?" "4" "WL27 an unbracketed severity is rejected (exit 4)"

# ---------------------------------------------------------------------------
# WL28-WL30 -- error paths.
# ---------------------------------------------------------------------------
wb --ledger "$TMP/absent.md" --set-status --row-id 1 --status Fixed >/dev/null 2>&1
assert_eq "$?" "1" "WL28 --set-status on a missing ledger exits 1"

L="$TMP/g.md"; new_ledger "$L"
wb --ledger "$L" --set-status --row-id 99 --status Fixed >/dev/null 2>&1
assert_eq "$?" "7" "WL29 an unknown --row-id exits 7"

wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 --doc a.md \
   --description 'x' >/dev/null 2>&1
assert_eq "$?" "5" "WL30 a missing required argument exits 5"

# ---------------------------------------------------------------------------
# WL31-WL33 -- NFR-5: a 7-column ledger still works, and --rule is refused on it.
# ---------------------------------------------------------------------------
L="$TMP/h7.md"
printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [HIGH] | Pending | a.md | 1 | old row | e |\n' > "$L"
before="$(g "$L")"
wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 --doc b.md \
   --description 'x' --evidence 'y' >/dev/null 2>&1
assert_eq "$?" "4" "WL31 --rule against a 7-column ledger is refused (exit 4)"
assert_eq "$(g "$L")" "$before" "WL32 the refused write left the 7-column ledger untouched"
wb --ledger "$L" --append-unit --unit a.md --rule-set narrative >/dev/null 2>&1
assert_eq "$(g "$L")" "$before" "WL33 a coverage row in a 7-column ledger is still grade-inert"

# ---------------------------------------------------------------------------
# WL34-WL35 -- CRLF invariance. A ledger written on Windows must stay CRLF.
# ---------------------------------------------------------------------------
L="$TMP/crlf.md"
printf '| # | Severity | Status | Rule | Doc | Line | Description | Evidence |\r\n|---|---|---|---|---|---|---|---|\r\n| 1 | [HIGH] | Pending | KB-22 | a.md | 1 | crlf row | e |\r\n' > "$L"
wb --ledger "$L" --append-finding --severity '[LOW]' --rule NAR-08 --doc b.md \
   --description 'added' --evidence 'e' >/dev/null 2>&1
crlf_lines="$(grep -c $'\r$' "$L" || true)"
total_lines="$(wc -l < "$L")"
assert_eq "$crlf_lines" "$total_lines" "WL34 every line keeps its CRLF terminator after a write"
assert_output_contains "$(cat "$L")" "added" "WL35 the appended row is present in the CRLF ledger"

# ---------------------------------------------------------------------------
# WL36 -- the schema documents the three row kinds.
# ---------------------------------------------------------------------------
SCHEMA="${REPO}/canonical/aid/templates/reviewer-ledger-schema.md"
sch="$(cat "$SCHEMA")"
assert_output_contains "$sch" "## Row kinds" "WL36 the schema documents the row kinds"
assert_output_contains "$sch" "Grade inertness" "WL37 the schema explains grade inertness"
assert_output_contains "$sch" "writeback-ledger.sh" "WL38 the schema names the helper as the row writer"

# ---------------------------------------------------------------------------
# WL39 -- no heredoc ledger write survives anywhere in the canonical tree.
# ---------------------------------------------------------------------------
cd "$REPO" || exit 2
hd=$(grep -rn 'LEDGEREOF' canonical .aid/knowledge CLAUDE.md AGENTS.md 2>/dev/null | wc -l)
assert_eq "$hd" "0" "WL39 no LEDGEREOF heredoc marker survives"
hd2=$(grep -rnE 'cat >>?[^|]*review-pending' canonical .aid/knowledge 2>/dev/null | wc -l)
assert_eq "$hd2" "0" "WL40 no 'cat >' against a review-pending path survives"

# ---------------------------------------------------------------------------
# WL41 -- the helper reached every rendered profile AND runs from there.
# The manifest's aid/scripts/ mapping is directory-level, but a brand-new child
# directory has never exercised it, so this is confirmed by rendering.
# ---------------------------------------------------------------------------
missing=0
for p in antigravity claude-code codex copilot-cli cursor; do
  n=$(find "profiles/$p" -path '*aid/scripts/review/writeback-ledger.sh' 2>/dev/null | wc -l)
  [[ "$n" -eq 1 ]] || { missing=$((missing+1)); echo "    ($p has $n copies of the helper)"; }
done
assert_eq "$missing" "0" "WL41 the review/ directory reached all five profiles"

rendered="profiles/claude-code/.claude/aid/scripts/review/writeback-ledger.sh"
if [[ -f "$rendered" ]]; then
  RT="$(mktemp -d)"
  bash "$rendered" --ledger "$RT/l.md" --append-finding --severity '[LOW]' --rule NAR-08 \
       --doc a.md --description 'from the render' --evidence 'e' >/dev/null 2>&1
  ok=$?
  rm -rf "$RT"
  assert_eq "$ok" "0" "WL42 the rendered copy runs and resolves its siblings"
else
  fail "WL42 rendered helper not found"
fi

echo
test_summary
exit $?
