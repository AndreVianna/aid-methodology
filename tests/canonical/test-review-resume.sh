#!/usr/bin/env bash
# test-review-resume.sh -- resumability: the coverage partition, invalidation, and the stop signal.
#
# THE CENTRAL ASSERTION IS A PARTITION, NOT A COUNT.
# A resumed review must re-examine every invalidated unit and no valid one. Asserting only "it skipped
# something" passes when it skips everything; asserting only "it re-examined something" passes when it
# re-examines everything. So the keep/invalidate sets are checked to be exhaustive AND disjoint, which
# fails in both directions.
#
# Usage: bash tests/canonical/test-review-resume.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"

WB="${REPO}/canonical/aid/scripts/review/writeback-ledger.sh"
PR="${REPO}/canonical/aid/scripts/review/plan-resume.sh"
WCS="${REPO}/canonical/aid/scripts/execute/write-control-signal.sh"
GRADE="${REPO}/canonical/aid/scripts/grade.sh"

echo "== test-review-resume.sh =="
for f in "$WB" "$PR" "$WCS" "$GRADE"; do
  [[ -f "$f" ]] || { echo "FATAL: missing $f" >&2; exit 2; }
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

wb() { bash "$WB" --ledger "$L" "$@"; }
pr() { bash "$PR" --ledger "$L" "$@"; }

# Three real artifacts, so the content digests mean something.
A="$TMP/a.md"; B="$TMP/b.md"; C="$TMP/c.md"
cp "${REPO}/.aid/knowledge/authoring-conventions.md" "$A"
cp "${REPO}/.aid/knowledge/coding-standards.md"      "$B"
printf 'third artifact\n' > "$C"

# ---------------------------------------------------------------------------
# RR01-RR05 -- --list-units is the read API the planner and the reviewer share.
# ---------------------------------------------------------------------------
L="$TMP/units.md"
wb --append-unit --unit "$A" --rule-set narrative  --status Examined      >/dev/null
wb --append-unit --unit "$B" --rule-set executable --status Examined      >/dev/null
wb --append-unit --unit "$C" --rule-set narrative  --status "In Progress" >/dev/null
wb --append-unit --unit "$A" --rule-set narrative  --status Unexamined    >/dev/null

n_all=$(wb --list-units | wc -l)
assert_eq "$n_all" "4" "RR01 --list-units emits one row per coverage unit"

cols=$(wb --list-units | head -1 | awk -F'\t' '{print NF}')
assert_eq "$cols" "7" "RR02 each row carries id, status, doc, rule-set, stamp, art, rs"

n_ex=$(wb --list-units --status Examined | wc -l)
assert_eq "$n_ex" "2" "RR03 --status filters to one status"

# --remaining is the resume contract made mechanical: an interrupted unit counts as unexamined.
rem=$(wb --list-units --remaining | awk -F'\t' '{print $2}' | sort -u | tr '\n' ',')
assert_eq "$rem" "In Progress,Unexamined," "RR04 --remaining is exactly Unexamined + In Progress"

# The digests must be populated, or invalidation has nothing to compare.
blank=$(wb --list-units | awk -F'\t' '($6=="" || $7=="")' | wc -l)
assert_eq "$blank" "0" "RR05 every unit carries an art= and an rs= digest"

# ---------------------------------------------------------------------------
# RR06-RR11 -- THE PARTITION. Exhaustive and disjoint, so it fails both ways.
# ---------------------------------------------------------------------------
L="$TMP/part.md"
wb --append-unit --unit "$A" --rule-set narrative  --status Examined      >/dev/null   # U-001 keep
wb --append-unit --unit "$B" --rule-set executable --status Examined      >/dev/null   # U-002 -> change B
wb --append-unit --unit "$C" --rule-set narrative  --status "In Progress" >/dev/null   # U-003 invalid
printf '\n<!-- edited between attempts -->\n' >> "$B"

plan="$(pr 2>/dev/null)"
keeps="$(printf '%s\n' "$plan" | awk -F'\t' '$2=="keep"{print $1}'       | sort | tr '\n' ' ')"
invals="$(printf '%s\n' "$plan" | awk -F'\t' '$2=="invalidate"{print $1}' | sort | tr '\n' ' ')"

assert_eq "$keeps"  "U-001 "        "RR06 exactly the untouched unit is kept"
assert_eq "$invals" "U-002 U-003 "  "RR07 exactly the changed and interrupted units are invalidated"

# Exhaustive: every unit got a verdict.
n_units=$(wb --list-units | wc -l)
n_verdicts=$(printf '%s\n' "$plan" | grep -c $'\t')
assert_eq "$n_verdicts" "$n_units" "RR08 the plan covers EVERY unit (exhaustive)"

# Disjoint: no unit is both.
both=$(comm -12 <(printf '%s\n' "$plan" | awk -F'\t' '$2=="keep"{print $1}' | sort) \
                <(printf '%s\n' "$plan" | awk -F'\t' '$2=="invalidate"{print $1}' | sort) | wc -l)
assert_eq "$both" "0" "RR09 no unit is both kept and invalidated (disjoint)"

# Reasons must be specific, not a catch-all.
assert_output_contains "$plan" "U-002	invalidate	artifact-changed" "RR10 a changed artifact reports artifact-changed"
assert_output_contains "$plan" "U-003	invalidate	in-progress"      "RR11 an interrupted unit reports in-progress"

# ---------------------------------------------------------------------------
# RR12-RR13 -- exit codes follow the LINTER alphabet (0 clean / 1 stale / 2 usage),
# not the writer alphabet. A planner that reports staleness is a linter.
# ---------------------------------------------------------------------------
L="$TMP/clean.md"
wb --append-unit --unit "$A" --rule-set narrative --status Examined >/dev/null
pr >/dev/null 2>&1
assert_eq "$?" "0" "RR12 a plan with nothing stale exits 0"
L="$TMP/part.md"
pr >/dev/null 2>&1
assert_eq "$?" "1" "RR13 a plan with stale units exits 1"
bash "$PR" >/dev/null 2>&1
assert_eq "$?" "2" "RR14 a usage error exits 2 (distinct from a staleness finding)"

# ---------------------------------------------------------------------------
# RR15-RR17 -- AC-8's negative control: invalidation must key on CONTENT, not on
# any filesystem change. A planner that invalidated on mtime would pass a naive
# "it detected a change" test while re-examining the world on every resume.
# ---------------------------------------------------------------------------
L="$TMP/mtime.md"
cp "${REPO}/.aid/knowledge/authoring-conventions.md" "$TMP/m.md"
wb --append-unit --unit "$TMP/m.md" --rule-set narrative --status Examined >/dev/null
pr >/dev/null 2>&1
before=$?
touch "$TMP/m.md"                      # mtime moves, content does not
sleep 1
touch "$TMP/m.md"
pr >/dev/null 2>&1
assert_eq "$?" "$before" "RR15 touching a file without changing it does NOT invalidate (AC-8 control)"

# Rewriting identical bytes must also not invalidate.
cp "${REPO}/.aid/knowledge/authoring-conventions.md" "$TMP/m.md"
pr >/dev/null 2>&1
assert_eq "$?" "0" "RR16 rewriting identical content does NOT invalidate"

# ...but a one-byte change must.
printf 'x' >> "$TMP/m.md"
pr >/dev/null 2>&1
assert_eq "$?" "1" "RR17 a one-byte content change DOES invalidate"

# ---------------------------------------------------------------------------
# RR18-RR19 -- criteria change: editing a doc the rule set CITES must invalidate,
# because that is where criteria actually live. Editing an unrelated doc must not.
# ---------------------------------------------------------------------------
L="$TMP/crit.md"
cp "${REPO}/.aid/knowledge/coding-standards.md" "$TMP/y.md"
wb --append-unit --unit "$TMP/y.md" --rule-set executable --status Examined >/dev/null
pr >/dev/null 2>&1
assert_eq "$?" "0" "RR18 baseline: the unit is valid before any criteria move"

CS="${REPO}/.aid/knowledge/coding-standards.md"
cp "$CS" "$TMP/cs.bak"
printf '\n<!-- criteria moved -->\n' >> "$CS"
reason="$(pr 2>/dev/null | awk -F'\t' '{print $3}')"
cp "$TMP/cs.bak" "$CS"
assert_eq "$reason" "criteria-changed" "RR19 editing a CITED declaring document invalidates the unit"

# ...and restoring it clears the invalidation, so the digest is a real comparison.
pr >/dev/null 2>&1
assert_eq "$?" "0" "RR20 restoring the criteria document clears the invalidation"

# ---------------------------------------------------------------------------
# RR21 -- a Skipped unit is a deliberate deferral, not staleness.
# ---------------------------------------------------------------------------
L="$TMP/skip.md"
wb --append-unit --unit "$A" --rule-set narrative --status Skipped >/dev/null
assert_output_contains "$(pr 2>/dev/null)" "keep" "RR21 a Skipped unit is kept, not treated as stale"

# ---------------------------------------------------------------------------
# RR22-RR23 -- resume never moves the grade. Coverage churn is grade-inert, so
# the --explain breakdown must be byte-identical across a whole resume cycle.
# ---------------------------------------------------------------------------
L="$TMP/grade.md"
wb --append-finding --severity '[MEDIUM]' --rule NAR-03 --doc "$A" --line 1 \
   --description 'a real finding' --evidence 'e' >/dev/null
wb --append-unit --unit "$A" --rule-set narrative --status Examined >/dev/null
before_g="$(bash "$GRADE" "$L" 2>/dev/null)"
before_x="$(bash "$GRADE" --explain "$L" 2>&1)"

# Simulate a resume: invalidate a unit, re-open it, examine it again.
wb --set-status --row-id U-001 --status Unexamined >/dev/null
wb --set-status --row-id U-001 --status "In Progress" >/dev/null
wb --set-status --row-id U-001 --status Examined >/dev/null
wb --append-unit --unit "$B" --rule-set executable --status Examined >/dev/null

assert_eq "$(bash "$GRADE" "$L" 2>/dev/null)" "$before_g" "RR22 a full resume cycle does not move the grade"
assert_eq "$(bash "$GRADE" --explain "$L" 2>&1)" "$before_x" "RR23 the --explain breakdown is byte-identical"

# ---------------------------------------------------------------------------
# RR24-RR28 -- the stop signal reaches a review, and no slug escapes .control/.
# ---------------------------------------------------------------------------
CT="$TMP/ctl"; mkdir -p "$CT/.aid/works/work-999"
run_wcs() { AID_WORK_DIR="$CT/.aid/works/work-999" bash "$WCS" "$@" >/dev/null 2>&1; echo "$?"; }

assert_eq "$(run_wcs --task-id 7 --action stop)" "0" "RR24 the original task-scoped form still works"
assert_eq "$([[ -f "$CT/.aid/.control/work-999/task-007.stop" ]] && echo yes)" "yes" \
  "RR25 the task signal lands at its documented path"

assert_eq "$(run_wcs --scope review --slug discovery --action stop)" "0" "RR26 a REVIEW can now be stopped"
assert_eq "$([[ -f "$CT/.aid/.control/work-999/review-discovery.stop" ]] && echo yes)" "yes" \
  "RR27 the review signal lands at review-<slug>.stop"

bad=0
for slug in '../../../etc/passwd' 'a/b' 'a.b' 'UPPER'; do
  [[ "$(run_wcs --scope review --slug "$slug" --action stop)" == "4" ]] || { bad=$((bad+1)); echo "    (accepted: $slug)"; }
done
assert_eq "$bad" "0" "RR28 every traversal-shaped slug is refused with exit 4"
escaped=$(find "$CT" -name 'passwd*' 2>/dev/null | wc -l)
assert_eq "$escaped" "0" "RR29 nothing was written outside .aid/.control/"

# ---------------------------------------------------------------------------
# RR30-RR32 -- the FR-D5 migration: the orphaned instructions are gone.
# Checked by CONTENT anchor, not line number -- every number the spec quoted has
# drifted, because five features edited this file before this one.
# ---------------------------------------------------------------------------
cd "$REPO" || exit 2
orphan=$(grep -rn 'If re-reviewing' canonical/ 2>/dev/null | wc -l)
assert_eq "$orphan" "0" "RR30 no prompt still tells a reviewer to read a deleted scratch"

schema="$(cat canonical/aid/templates/reviewer-ledger-schema.md)"
assert_output_contains "$schema" "Attempts and reconciliation" "RR31 the schema documents the attempt model"
assert_output_contains "$schema" "absence proves nothing" "RR32 the schema states the coverage guard"

# The old reviewer-reconciles instruction must be gone from the schema's workflow.
old=$(grep -c 'read existing file. For each existing' canonical/aid/templates/reviewer-ledger-schema.md 2>/dev/null || true)
assert_eq "$old" "0" "RR33 the schema no longer tells the reviewer to reconcile"

# ---------------------------------------------------------------------------
# RR34 -- render reach.
# ---------------------------------------------------------------------------
short=0
for p in antigravity claude-code codex copilot-cli cursor; do
  n=$(find "profiles/$p" -path '*review/plan-resume.sh' 2>/dev/null | wc -l)
  [[ "$n" -eq 1 ]] || { short=$((short+1)); echo "    ($p has $n copies of plan-resume.sh)"; }
done
assert_eq "$short" "0" "RR34 plan-resume.sh reached all five profiles"

echo
test_summary
exit $?
