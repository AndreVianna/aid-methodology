#!/usr/bin/env bash
# test-gap-gate-wiring.sh -- the totality oracle for the criteria-gap gate.
#
# THE POINT OF THIS SUITE IS THAT IT HAS NO EXCLUSION LIST.
# It derives its file set from disk -- every file that INVOKES grade.sh -- and requires each one to
# mention check-gaps.sh at an earlier line. So a grade site added next year fails this suite the day
# it lands, without anyone remembering to update a list. An enumerated site set would rot on the
# first new skill; that is the failure mode this shape exists to avoid.
#
# WHY THE PATTERN CARRIES `bash `
# Matching a bare `canonical/aid/scripts/grade.sh` also matches prose ("the calculation lives in
# grade.sh"), see-also lines, and reviewer briefs that merely name the grader. Ten such files exist.
# Demanding a gate call inside a sentence would be nonsense, so an invocation is identified by the
# `bash ` prefix that makes it one.
#
# Usage: bash tests/canonical/test-gap-gate-wiring.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"

cd "$REPO" || exit 2

GRADE_PAT='bash canonical/aid/scripts/grade\.sh'
GATE='canonical/aid/scripts/review/check-gaps.sh'

echo "== test-gap-gate-wiring.sh =="

# ---------------------------------------------------------------------------
# GW01 -- the derived site set is non-empty. Without this the whole suite could
# pass by inspecting nothing, which is how three assertions in this work's
# earlier deliveries shipped vacuous.
# ---------------------------------------------------------------------------
mapfile -t SITES < <(grep -rln "$GRADE_PAT" canonical/ 2>/dev/null | sort)
# FLOOR LOWERED 15 -> 8 by delivery-012. Grading is now centralised in /aid-deep-review, so far fewer
# files invoke grade.sh directly -- that is the extraction working, not the pattern breaking. The floor
# still exists because a sweep over zero files would pass vacuously.
if [[ "${#SITES[@]}" -ge 8 ]]; then
  pass "GW01 the derived site set holds ${#SITES[@]} files (not vacuous)"
else
  fail "GW01 the derived site set holds only ${#SITES[@]} files -- the pattern is broken"
fi

# ---------------------------------------------------------------------------
# GW02 -- TOTALITY. Every invoking file mentions the gate, at an EARLIER line
# than its first grade call. Line order matters: a gate documented below the
# grade it is supposed to guard reads as an afterthought and would run too late.
# ---------------------------------------------------------------------------
missing=0; misordered=0
for f in "${SITES[@]}"; do
  gate_line="$(grep -n 'check-gaps\.sh' "$f" 2>/dev/null | head -1 | cut -d: -f1)"
  grade_line="$(grep -n "$GRADE_PAT" "$f" 2>/dev/null | head -1 | cut -d: -f1)"
  if [[ -z "$gate_line" ]]; then
    missing=$((missing + 1)); echo "    (no gate: $f)"
  elif [[ "$gate_line" -gt "$grade_line" ]]; then
    misordered=$((misordered + 1)); echo "    (gate at $gate_line is AFTER grade at $grade_line: $f)"
  fi
done
assert_eq "$missing"    "0" "GW02 every file invoking grade.sh also mentions the gate"
assert_eq "$misordered" "0" "GW03 the gate is mentioned before the grade call it guards"

# ---------------------------------------------------------------------------
# GW04 -- the two sites most easily forgotten are covered by name. Named
# explicitly because omitting either has an outsized consequence, and a total
# sweep alone would not say WHICH site regressed.
# ---------------------------------------------------------------------------
# GATED DIRECTLY *OR* BY DELEGATION. delivery-012 extracted review into /aid-deep-review, which runs the
# gap gate before the grader -- so a site that delegates to it IS gated, and requiring a direct
# check-gaps.sh call would force every caller to re-implement the thing that was just extracted.
#
# The invariant is unchanged: no grade may be computed over an open criteria gap. What changed is who
# computes the grade.
gated_somehow () {   # $1 = file, $2 = assertion label
  local f="$1" label="$2"
  if grep -q "$GATE" "$f" 2>/dev/null; then
    pass "$label (gates directly)"
  elif grep -q 'aid-deep-review' "$f" 2>/dev/null; then
    pass "$label (delegates to /aid-deep-review, which gates)"
  else
    fail "$label -- neither gates directly nor delegates"
  fi
}

# The Lite path: every shortcut skill grades through the engine, so an ungated engine would let the whole
# Lite path grade over an open gap.
gated_somehow canonical/aid/templates/shortcut-engine.md "GW04 the Lite path's shortcut engine is gated"

# aid-execute's delivery gate is where a delivery is actually accepted.
gated_somehow canonical/skills/aid-execute/references/state-delivery-gate.md \
  "GW05 aid-execute's DELIVERY-GATE is gated"

# The two machine-validator sites cannot produce a G- row today. Their call is a cheap exit-0
# invariant, and wiring them is what makes the sweep TOTAL -- a partial wiring needs an exclusion
# list, and exclusion lists rot.
gated_somehow canonical/skills/aid-summarize/references/state-validate.md \
  "GW06 aid-summarize's VALIDATE is gated (exit-0 invariant)"
gated_somehow canonical/skills/aid-deploy/references/state-verifying.md \
  "GW07 aid-deploy's VERIFYING is gated (exit-0 invariant)"

# ---------------------------------------------------------------------------
# GW08 -- every emitted gate command is well formed. A wiring pass that
# produced `--ledger <path>`.` would be syntactically wrong yet still satisfy a
# mere "mentions the gate" check -- which is exactly what happened on the first
# attempt here, from a greedy \S+ swallowing the closing backtick.
# ---------------------------------------------------------------------------
malformed=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  malformed=$((malformed + 1))
  echo "    (malformed: ${line:0:120})"
done < <(grep -rhn 'check-gaps\.sh' canonical/ 2>/dev/null \
         | grep -E 'check-gaps\.sh[^`]*--ledger [^ ]*(`\.|`,|\.`)' || true)
assert_eq "$malformed" "0" "GW08 no emitted gate command carries markup in its --ledger argument"

# Every gate invocation must actually pass --ledger; a bare call would exit 2 (usage) and be read as
# a failure rather than a clean gate.
bad_args=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # a line that names the script as a path reference (see-also, prose) needs no --ledger
  [[ "$line" == *"bash canonical/aid/scripts/review/check-gaps.sh"* ]] || continue
  [[ "$line" == *"--ledger"* ]] || { bad_args=$((bad_args + 1)); echo "    (no --ledger: ${line:0:110})"; }
done < <(grep -rh 'check-gaps\.sh' canonical/ 2>/dev/null || true)
assert_eq "$bad_args" "0" "GW09 every gate INVOCATION passes --ledger"

# ---------------------------------------------------------------------------
# GW10 -- grade.sh is untouched by this wiring (NFR-1).
# ---------------------------------------------------------------------------
gate_in_grader=$(grep -c 'check-gaps' canonical/aid/scripts/grade.sh 2>/dev/null || true)
assert_eq "$gate_in_grader" "0" "GW10 grade.sh does not reference the gate (NFR-1)"

# ...and assert it the authoritative way, against git rather than by byte-comparing a `git show` blob
# to the working tree. That comparison reports a difference from line-ending handling alone, which
# looks exactly like an NFR-1 violation and is not one. `git diff` applies the repo's own filters, so
# it answers the question that actually matters.
if git rev-parse --verify aid/work-003-delivery-006 >/dev/null 2>&1; then
  n=$(git diff --name-only aid/work-003-delivery-006 -- canonical/aid/scripts/grade.sh | wc -l)
  assert_eq "$n" "0" "GW15 git reports grade.sh unchanged since the gate work began (NFR-1)"
else
  echo "  SKIP GW15 (baseline ref absent)"
fi

# ---------------------------------------------------------------------------
# GW11 -- the gate behaves: it fires on an open criteria gap and ONLY on one.
# Asserted by running it, because a wiring suite that never executes the thing
# it wires proves only that a string is present.
# ---------------------------------------------------------------------------
CG="canonical/aid/scripts/review/check-gaps.sh"
WB="canonical/aid/scripts/review/writeback-ledger.sh"
if [[ -f "$CG" && -f "$WB" ]]; then
  T="$(mktemp -d)"
  mk () {  # $1=file $2=discriminator
    bash "$WB" --ledger "$1" --append-gap --gap-key 'k/one' --doc a.sh \
         --description "$2 nothing declares this" --resolution '/aid-update-kb x' >/dev/null 2>&1
  }
  mk "$T/block.md" '[GAP:CRITERIA]'
  mk "$T/nb.md"    '[GAP:CRITERIA:NB]'
  mk "$T/ev.md"    '[GAP:EVIDENCE]'

  bash "$CG" --ledger "$T/block.md" >/dev/null 2>&1
  assert_eq "$?" "1" "GW11 the gate fires on an open [GAP:CRITERIA] row"
  bash "$CG" --ledger "$T/nb.md" >/dev/null 2>&1
  assert_eq "$?" "0" "GW12 the gate does NOT fire on [GAP:CRITERIA:NB]"
  bash "$CG" --ledger "$T/ev.md" >/dev/null 2>&1
  assert_eq "$?" "0" "GW13 the gate does NOT fire on [GAP:EVIDENCE]"
  rm -rf "$T"
else
  fail "GW11 gap scripts not found -- cannot verify behaviour"
fi

# ---------------------------------------------------------------------------
# GW14 -- the wiring reached the rendered profiles.
# ---------------------------------------------------------------------------
short=0
for p in antigravity claude-code codex copilot-cli cursor; do
  n=$(grep -rl 'check-gaps\.sh' "profiles/$p" 2>/dev/null | wc -l)
  [[ "$n" -ge 15 ]] || { short=$((short + 1)); echo "    ($p mentions the gate in only $n files)"; }
done
assert_eq "$short" "0" "GW14 the wiring reached all five profiles"

echo
test_summary
exit $?
