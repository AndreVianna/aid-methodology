#!/usr/bin/env bash
# test-review-extraction.sh -- AC-11 (measurably shorter) and AC-12 (identical on all five profiles).
#
# AC-11 HAS THREE CLAUSES AND THE MIDDLE ONE IS THE ANTI-GAMING CLAUSE. Any "extraction" can make a
# caller shorter by moving lines into a shared file, so clause (b) requires the shared budget PLUS the
# new shared assets to come in UNDER the pre-migration budget. Without it the criterion measures
# relocation rather than reduction.
#
# The C-metric pattern and the 876 baseline are PINNED from delivery-001 and are not recomputed here --
# a metric a later delivery can retune measures nothing.
#
# Usage: bash tests/canonical/test-review-extraction.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"
cd "$REPO" || exit 2

echo "== test-review-extraction.sh =="

# --- pinned from delivery-001's BASELINE-ac11.md ----------------------------------------
B_BEFORE=876
declare -A BASE=( [aid-define]=18 [aid-specify]=14 [aid-plan]=20 [aid-detail]=21 [aid-execute]=38
                  [aid-discover]=95 [aid-describe]=10 [aid-review]=14 [shortcut-engine]=41 )
C_BEFORE=271

PAT='aid-reviewer|reviewer-brief|reviewer-dispatch|reviewer-ledger-schema|grade[.]sh|ARTIFACTS UNDER REVIEW|OUT OF SCOPE|OUT-OF-SCOPE|review-pending|Ledger lifecycle|minimum_grade|subagent_type|RUBRIC:|CONTEXT:|DELIVERABLES:'

# Callers NOT migrated, each with a stated reason. An exclusion without a reason is how a criterion
# gets met by shrinking its own scope.
#   aid-review    -- its meta-review VERIFY loop is deliberately retained (it reviews reviews)
#   aid-describe  -- its matches are references to aid-discover's brief, which it REUSES rather than
#                    owns, plus a minimum_grade read feeding a composite ready predicate alongside an
#                    essence verdict. Neither is dispatch machinery this extraction can take.
NOT_MIGRATED="aid-review aid-describe"

count_caller () {
  local target="$1" total=0 f n
  if [[ -f "$target" ]]; then
    total=$(grep -cE "$PAT" "$target" 2>/dev/null || true); [[ -z "$total" ]] && total=0
  else
    while IFS= read -r f; do
      [[ "$(basename "$f")" == "reviewer-brief.md" ]] && continue
      n=$(grep -cE "$PAT" "$f" 2>/dev/null || true); [[ -z "$n" ]] && n=0
      total=$((total + n))
    done < <(find "$target" -name '*.md' -type f 2>/dev/null)
  fi
  printf '%s' "$total"
}

# ---------------------------------------------------------------------------
# RX01 -- the two skills exist and are distinct entry points.
# ---------------------------------------------------------------------------
for s in aid-light-review aid-deep-review; do
  assert_eq "$([[ -f "canonical/skills/$s/SKILL.md" ]] && echo yes)" "yes" "RX01 $s exists"
done

light="$(cat canonical/skills/aid-light-review/SKILL.md)"
deep="$(cat canonical/skills/aid-deep-review/SKILL.md)"

# ---------------------------------------------------------------------------
# RX02-RX05 -- the light pass must leave nothing a deep pass reads as clearance.
# This is the sharp one: a U- row means "examined against a rule set", so a light
# pass writing one would make a later deep review skip units nobody adversarially
# examined -- and it would be RIGHT to, which is what makes the bug silent.
# ---------------------------------------------------------------------------
assert_output_contains "$light" "no coverage" "RX02 the light skill states it writes no coverage rows"
assert_output_contains "$light" "mistake for clearance" \
  "RX03 the light skill names the clearance hazard explicitly"
assert_output_contains "$light" "NOT a pass" "RX04 the light skill states a clean screen is not a pass"

# It must not compute a grade, and must say so.
if grep -qiE 'light-review.*(computes|reports) a grade' canonical/skills/aid-light-review/SKILL.md; then
  fail "RX05 the light skill claims to produce a grade"
else
  pass "RX05 the light skill does not claim to produce a grade"
fi

# ...and the deep skill must own the graded machinery.
for needle in "check-gaps.sh" "grade.sh" "RECONCILE" "FIX" "Circuit breaker"; do
  assert_output_contains "$deep" "$needle" "RX06 the deep skill owns '$needle'"
done

# ---------------------------------------------------------------------------
# RX07-RX09 -- AC-11 clause (b): THE ANTI-GAMING CLAUSE.
# ---------------------------------------------------------------------------
B_AFTER=$(wc -l canonical/aid/templates/reviewer-dispatch.md \
                canonical/skills/*/references/reviewer-brief.md \
                canonical/skills/aid-execute/references/reviewer-guide.md 2>/dev/null \
          | tail -1 | awk '{print $1}')
NEW=$(cat canonical/aid/templates/reviewer-brief-template.md \
          canonical/skills/aid-light-review/SKILL.md \
          canonical/skills/aid-deep-review/SKILL.md 2>/dev/null | wc -l)
SUM=$((B_AFTER + NEW))

if [[ "$SUM" -lt "$B_BEFORE" ]]; then
  pass "RX07 clause (b): shared budget + new assets ($SUM) is under the pinned baseline ($B_BEFORE)"
else
  fail "RX07 clause (b) FAILED: $SUM >= $B_BEFORE -- lines were relocated, not removed"
fi

# The six briefs must still EXIST at their paths: an inherited oracle greps them, and deleting them
# would make that oracle vacuous rather than satisfied.
briefs=$(ls canonical/skills/*/references/reviewer-brief.md 2>/dev/null | wc -l)
assert_eq "$briefs" "6" "RX08 all six per-skill briefs still exist at their paths"

# ...and each must carry ONLY its two per-skill sections.
bad_brief=0
for f in canonical/skills/*/references/reviewer-brief.md; do
  grep -q 'RUBRIC_BODY' "$f"   || { bad_brief=$((bad_brief+1)); echo "    (no RUBRIC_BODY: $f)"; }
  grep -q 'OUT_OF_SCOPE' "$f"  || { bad_brief=$((bad_brief+1)); echo "    (no OUT_OF_SCOPE: $f)"; }
  # the retired source tags must be gone -- five of six advertised them before
  grep -q 'source-tagged' "$f" && { bad_brief=$((bad_brief+1)); echo "    (still advertises source tags: $f)"; }
done
assert_eq "$bad_brief" "0" "RX09 every brief carries its two sections and no retired source tags"

# ---------------------------------------------------------------------------
# RX10-RX12 -- AC-11 clauses (a) and (c).
# ---------------------------------------------------------------------------
TOT=0; regressed=0; checked=0
for c in "${!BASE[@]}"; do
  if [[ "$c" == "shortcut-engine" ]]; then
    n=$(count_caller canonical/aid/templates/shortcut-engine.md)
  else
    n=$(count_caller "canonical/skills/$c")
  fi
  TOT=$((TOT + n))
  case " $NOT_MIGRATED " in *" $c "*) continue ;; esac
  checked=$((checked + 1))
  if [[ "$n" -ge "${BASE[$c]}" ]]; then
    regressed=$((regressed + 1)); echo "    ($c: ${BASE[$c]} -> $n, not decreased)"
  fi
done
assert_eq "$regressed" "0" "RX10 clause (a): every MIGRATED caller strictly decreased ($checked checked)"
if [[ "$checked" -ge 6 ]]; then
  pass "RX11 clause (a) inspected $checked migrated callers (not vacuous)"
else
  fail "RX11 clause (a) inspected only $checked callers -- the exclusion list is doing too much work"
fi

pct=$(( (C_BEFORE - TOT) * 100 / C_BEFORE ))
if [[ "$pct" -ge 40 ]]; then
  pass "RX12 clause (c): aggregate fell $C_BEFORE -> $TOT (${pct}%, needs >= 40%)"
else
  fail "RX12 clause (c): aggregate fell only ${pct}% ($C_BEFORE -> $TOT), needs >= 40%"
fi

# ---------------------------------------------------------------------------
# RX13-RX16 -- AC-12: identical review behaviour on all five profiles.
# This delivery owns the criterion of record, so it is asserted structurally:
# the same skills, the same manifest, and the same rule catalog in every tree.
# ---------------------------------------------------------------------------
missing=0; trees=0
for p in antigravity claude-code codex copilot-cli cursor; do
  ld=$(find "profiles/$p" -path '*skills/aid-light-review/SKILL.md' 2>/dev/null | wc -l)
  dd=$(find "profiles/$p" -path '*skills/aid-deep-review/SKILL.md'  2>/dev/null | wc -l)
  bt=$(find "profiles/$p" -name 'reviewer-brief-template.md'        2>/dev/null | wc -l)
  [[ "$ld" -eq 1 && "$dd" -eq 1 && "$bt" -eq 1 ]] || {
    missing=$((missing+1)); echo "    ($p: light=$ld deep=$dd template=$bt)"; }
  trees=$((trees+1))
done
assert_eq "$trees" "5" "RX13 all five profiles were inspected"
assert_eq "$missing" "0" "RX14 both skills and the brief template reached every profile"

# The deep skill's rendered body must carry the same load-bearing rules everywhere -- if one profile
# lost the gate or the coverage guard, review would differ by host tool, which AC-12 forbids.
drift=0
for p in antigravity claude-code codex copilot-cli cursor; do
  f=$(find "profiles/$p" -path '*skills/aid-deep-review/SKILL.md' 2>/dev/null | head -1)
  [[ -n "$f" ]] || continue
  for needle in 'check-gaps.sh' 'absence proves nothing' 'Circuit breaker'; do
    grep -q "$needle" "$f" || { drift=$((drift+1)); echo "    ($p missing: $needle)"; }
  done
done
assert_eq "$drift" "0" "RX15 the deep skill's load-bearing rules are identical in every profile"

# Panel mode must be present everywhere too -- aid-discover's four-mandate review depends on it.
pan=0
for p in antigravity claude-code codex copilot-cli cursor; do
  f=$(find "profiles/$p" -path '*skills/aid-deep-review/SKILL.md' 2>/dev/null | head -1)
  [[ -n "$f" ]] && { grep -q 'panel mode' "$f" || { pan=$((pan+1)); echo "    ($p has no panel mode)"; }; }
done
assert_eq "$pan" "0" "RX16 panel mode is present in every profile"

echo
test_summary
exit $?
