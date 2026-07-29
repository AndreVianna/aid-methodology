#!/usr/bin/env bash
# test-ledger-eighth-column.sh -- the Rule column, and the promise that adding it broke nothing.
#
# Two things must hold at once:
#   NFR-1  grade.sh's behaviour is unchanged -- it was edited in comments only.
#   NFR-5  a 7-column ledger written before this change still grades correctly.
# Both are asserted BEHAVIOURALLY (run the grader on real fixtures and compare grades), because a
# textual diff proves the file did not change while a behavioural test proves the change did not
# matter -- and the second is the actual promise.
#
# Usage: bash tests/canonical/test-ledger-eighth-column.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"

GRADE="${REPO}/canonical/aid/scripts/grade.sh"
SCHEMA="${REPO}/canonical/aid/templates/reviewer-ledger-schema.md"
CAT="${REPO}/canonical/aid/templates/review-rubrics"

echo "== test-ledger-eighth-column.sh =="

[[ -f "$GRADE" ]]  || { echo "FATAL: grade.sh not found" >&2; exit 2; }
[[ -f "$SCHEMA" ]] || { echo "FATAL: schema not found" >&2; exit 2; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# EC01-EC05 -- the schema declares the column and its contract.
# ---------------------------------------------------------------------------
schema="$(cat "$SCHEMA")"
assert_output_contains "$schema" '| # | Severity | Status | Rule | Doc | Line | Description | Evidence |' \
  "EC01 the schema's example table carries the 8-column header"
assert_output_contains "$schema" "8-column table is the entire ledger file" \
  "EC02 the frontmatter contract says 8 columns"
assert_output_contains "$schema" "A finding row MUST carry a rule ID" \
  "EC03 the schema states the MUST-carry rule"
assert_output_contains "$schema" "writeback-ledger.sh" \
  "EC04 the schema names writeback-ledger.sh as the enforcer"
assert_output_contains "$schema" "the header decides" \
  "EC05 the schema states the mixed-shape rule"

# The sentinel for non-finding rows must be documented.
if grep -qE '^\| A non-finding row \| `--`' "$SCHEMA"; then
  pass "EC06 the schema documents the -- sentinel for non-finding rows"
else
  fail "EC06 the schema does not document the -- sentinel"
fi

# ---------------------------------------------------------------------------
# EC07-EC12 -- grade.sh grades an 8-column ledger, and grades the 7-column
# equivalent IDENTICALLY. This pair is the NFR-5 proof.
# ---------------------------------------------------------------------------
mk8 () { printf '| # | Severity | Status | Rule | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|---|\n%s\n' "$1"; }
mk7 () { printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n%s\n' "$1"; }

# rows expressed twice, same findings, both shapes
declare -a CASES=(
  "empty|||A+"
  "one_minor|| 1 | [MINOR] | Pending | NAR-08 | a.md | 1 | x | y || 1 | [MINOR] | Pending | a.md | 1 | x | y ||A"
)

# --- case: empty ledger -> A+ in both shapes
mk8 "" > "$TMP/e8.md"; mk7 "" > "$TMP/e7.md"
g8="$(bash "$GRADE" "$TMP/e8.md" 2>/dev/null)"
g7="$(bash "$GRADE" "$TMP/e7.md" 2>/dev/null)"
assert_eq "$g8" "A+" "EC07 an empty 8-column ledger grades A+"
assert_eq "$g7" "$g8" "EC08 the 7-column equivalent grades the same"

# --- case: one HIGH pending -> D+ in both shapes
mk8 "| 1 | [HIGH] | Pending | NAR-04 | a.md | 42 | claim wrong | disk shows N |" > "$TMP/h8.md"
mk7 "| 1 | [HIGH] | Pending | a.md | 42 | claim wrong | disk shows N |"          > "$TMP/h7.md"
g8="$(bash "$GRADE" "$TMP/h8.md" 2>/dev/null)"
g7="$(bash "$GRADE" "$TMP/h7.md" 2>/dev/null)"
assert_eq "$g8" "D+" "EC09 one [HIGH] Pending in an 8-column ledger grades D+"
assert_eq "$g7" "$g8" "EC10 the 7-column equivalent grades the same"

# --- case: mixed severities and statuses; only Pending/Recurred count
rows8=$'| 1 | [CRITICAL] | Fixed | NAR-04 | a.md | 1 | fixed crit | done |\n| 2 | [MEDIUM] | Pending | NAR-03 | b.md | 2 | m1 | e |\n| 3 | [MEDIUM] | Recurred | NAR-03 | c.md | 3 | m2 | e |\n| 4 | [HIGH] | Accepted | NAR-06 | d.md | 4 | accepted | user Q1 |'
rows7=$'| 1 | [CRITICAL] | Fixed | a.md | 1 | fixed crit | done |\n| 2 | [MEDIUM] | Pending | b.md | 2 | m1 | e |\n| 3 | [MEDIUM] | Recurred | c.md | 3 | m2 | e |\n| 4 | [HIGH] | Accepted | d.md | 4 | accepted | user Q1 |'
mk8 "$rows8" > "$TMP/m8.md"; mk7 "$rows7" > "$TMP/m7.md"
g8="$(bash "$GRADE" "$TMP/m8.md" 2>/dev/null)"
g7="$(bash "$GRADE" "$TMP/m7.md" 2>/dev/null)"
assert_eq "$g8" "C" "EC11 two countable [MEDIUM] rows grade C (Fixed/Accepted excluded)"
assert_eq "$g7" "$g8" "EC12 the 7-column equivalent grades the same"

# --- the Rule column must not leak into grading: a severity token parked in Rule is ignored
mk8 "| 1 | [MINOR] | Pending | NAR-08 | a.md | 1 | x | y |"          > "$TMP/r1.md"
mk8 "| 1 | [MINOR] | Pending | [CRITICAL] | a.md | 1 | x | y |"      > "$TMP/r2.md"
g1="$(bash "$GRADE" "$TMP/r1.md" 2>/dev/null)"
g2="$(bash "$GRADE" "$TMP/r2.md" 2>/dev/null)"
assert_eq "$g2" "$g1" "EC13 a severity token in the Rule column does not affect the grade"

# --- an escaped pipe later in the row must not disturb Severity/Status parsing
mk8 '| 1 | [LOW] | Pending | NAR-03 | a.md | 1 | has a \| pipe | and \| another |' > "$TMP/p8.md"
gp="$(bash "$GRADE" "$TMP/p8.md" 2>/dev/null)"
assert_eq "$gp" "B+" "EC14 an escaped pipe in Description/Evidence does not break grading"

# ---------------------------------------------------------------------------
# EC15 -- grade.sh's executable content is unchanged from the branch point.
# Comment-only edits (NFR-1). Skipped rather than failed when the ref is absent,
# so the suite stays usable outside this work's branch topology.
# ---------------------------------------------------------------------------
BASE_REF="aid/work-003-delivery-004"
if git -C "$REPO" rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  git -C "$REPO" show "$BASE_REF:canonical/aid/scripts/grade.sh" 2>/dev/null \
    | grep -vE '^[[:space:]]*#' > "$TMP/grade-base.txt"
  grep -vE '^[[:space:]]*#' "$GRADE" > "$TMP/grade-now.txt"
  if diff -q "$TMP/grade-base.txt" "$TMP/grade-now.txt" >/dev/null 2>&1; then
    pass "EC15 grade.sh's non-comment lines are unchanged from $BASE_REF (NFR-1)"
  else
    fail "EC15 grade.sh's executable content CHANGED -- NFR-1 violated"
    diff "$TMP/grade-base.txt" "$TMP/grade-now.txt" | head -20 | sed 's/^/    /'
  fi
else
  echo "  SKIP EC15 ($BASE_REF not present)"
fi

# grade.sh must still read Severity at cols[3] and Status at cols[4] -- the reason the Rule
# column could only be inserted after Status.
assert_output_contains "$(cat "$GRADE")" 'severity = trim(cols[3])' \
  "EC16 grade.sh still reads Severity at cols[3]"
assert_output_contains "$(cat "$GRADE")" 'status   = trim(cols[4])' \
  "EC17 grade.sh still reads Status at cols[4]"

# ---------------------------------------------------------------------------
# EC18-EC20 -- the migration is complete in the declared set, and the NFR-5
# fixtures were deliberately NOT migrated.
# ---------------------------------------------------------------------------
cd "$REPO" || exit 2
stale_ref=$(grep -rn '7-column\|7 column' canonical CLAUDE.md AGENTS.md .aid/knowledge \
              --exclude=kb.html --exclude=INDEX.md 2>/dev/null \
            | grep -v 'reviewer-ledger-schema.md' | wc -l)
assert_eq "$stale_ref" "0" "EC18 no stale 7-column claim survives in the migration set"

stale_hdr=$(grep -rn '| Severity | Status | Doc |' canonical CLAUDE.md AGENTS.md .aid/knowledge \
              --exclude=kb.html --exclude=INDEX.md 2>/dev/null | wc -l)
assert_eq "$stale_hdr" "0" "EC19 no 7-column header row survives in the migration set"

# The two suites that prove NFR-5 must KEEP their 7-column fixtures. If they were migrated,
# nothing is left proving old ledgers still read.
kept=0
for s in tests/canonical/test-grade.sh tests/canonical/test-delivery-gate-aggregate.sh; do
  [[ -f "$s" ]] && grep -q '| Severity | Status | Doc |' "$s" && kept=$((kept + 1))
done
assert_eq "$kept" "2" "EC20 both NFR-5 fixture suites still carry 7-column ledgers"

# ---------------------------------------------------------------------------
# EC21 -- every rule ID cited in shipped canonical content resolves to the
# catalog. A fabricated ID in an example is the defect this work removes, so an
# example must not invent one. `KB-NN` is an explicit placeholder and is exempt
# by shape: it does not match the ID regex.
# ---------------------------------------------------------------------------
bad_id=0; seen=0
if [[ -d "$CAT" ]]; then
  known="$(grep -rhoE '^\| *`?[A-Z]{2,12}-[0-9]{2}`? *\|' "$CAT" | tr -d '|` ' | sort -u)"
  while IFS= read -r rid; do
    [[ -z "$rid" ]] && continue
    seen=$((seen + 1))
    grep -qx "$rid" <<< "$known" || { bad_id=$((bad_id+1)); echo "    (cited rule '$rid' is not in the catalog)"; }
  done < <(grep -rhoE '\| *[A-Z]{2,12}-[0-9]{2} *\|' \
             canonical/agents canonical/aid/templates canonical/skills 2>/dev/null \
           | tr -d '| ' | sort -u)
fi
assert_eq "$bad_id" "0" "EC21 every rule ID cited in canonical examples exists in the catalog ($seen distinct IDs)"

# ---------------------------------------------------------------------------
# EC22 -- the five root-agent SOURCE files carry the migrated rule.
#
# profiles/<tool>/{CLAUDE.md,AGENTS.md} are hand-authored sources, NOT generator output: the
# installer copies their AID:BEGIN/END body, in place, into a host project's own root file. Because
# re-rendering does not touch them, migrating only this repo's own root files leaves all five
# profiles shipping the old shape -- which is exactly what happened on the first pass here, and the
# reason this assertion exists.
# ---------------------------------------------------------------------------
roots=(profiles/claude-code/CLAUDE.md profiles/codex/AGENTS.md profiles/cursor/AGENTS.md
       profiles/copilot-cli/AGENTS.md profiles/antigravity/AGENTS.md)
root_stale=0; root_seen=0
for rf in "${roots[@]}"; do
  [[ -f "$rf" ]] || { root_stale=$((root_stale+1)); echo "    ($rf missing)"; continue; }
  root_seen=$((root_seen + 1))
  grep -q 'Use the 8-column' "$rf" || { root_stale=$((root_stale+1)); echo "    ($rf still claims 7 columns)"; }
  grep -q 'Status | Rule | Doc' "$rf" || { root_stale=$((root_stale+1)); echo "    ($rf shape line not migrated)"; }
done
assert_eq "$root_stale" "0" "EC22 all $root_seen root-agent sources carry the 8-column rule"

# The edit must sit INSIDE the AID-managed region; outside it is the adopter's own content.
outside=0
for rf in "${roots[@]}"; do
  [[ -f "$rf" ]] || continue
  awk '/<!-- AID:BEGIN -->/{f=1} f{print} /<!-- AID:END -->/{f=0}' "$rf" \
    | grep -q 'Use the 8-column' || { outside=$((outside+1)); echo "    ($rf: rule is outside AID:BEGIN/END)"; }
done
assert_eq "$outside" "0" "EC23 the rule sits inside the AID-managed region in every root-agent source"

echo
test_summary
exit $?
