#!/usr/bin/env bash
# test-state-review-surface.sh -- work-009-refactor task-013. The `filter_reviewable_artifacts`
# function (canonical/aid/templates/reviewer-dispatch.md § ARTIFACTS UNDER REVIEW ->
# `filter_reviewable_artifacts` -- the filter) computes the reviewable-artifact surface a
# reviewer dispatch builds for a work-tree diff/produced-file list. It MUST drop every
# state-file path -- STATE.md (legacy) or STATE.yml, at the work root,
# deliveries/delivery-NNN/, or deliveries/delivery-NNN/tasks/task-NNN/ -- and pass every
# authored artifact through unchanged, so state churn in a reviewed diff is never graded and
# never even logged as an OOS row. This is the sibling suite to
# tests/canonical/test-kb-review-surface.sh (RS03's shape, applied to the work-tree filter
# instead of the KB's `list_reviewable`); that suite is untouched by this one.
#
#   SR00 extraction of filter_reviewable_artifacts() from reviewer-dispatch.md succeeds
#   SR01-SR06 drops all six state-file path shapes (three levels x .md/.yml)
#   SR07-SR11 keeps all five authored-artifact shapes
#   SR12-SR14 near-miss basenames survive (not dropped by a loose match)
#   SR15 flattened-layout task-level path (no deliveries/ wrapper) is also dropped --
#        the match is basename-only, so it holds regardless of layout
#   SR16 an all-state-files input exits 0 with empty output (the `|| true` is load-bearing:
#        `grep -v` alone would exit 1 on no output and abort a `set -euo pipefail` caller)
#   SR17 static: no brief template names a state file inside an ARTIFACTS block
#        (reviewer-dispatch.md, every per-skill reviewer-brief.md, shortcut-engine.md § GATE)
#
# Deliberately NOT asserted here: anything about `.aid/knowledge/STATE.md`. The filter does
# match it by basename (harmless, since that path is never a member of a work-tree artifact
# list), but its exclusion is owned by `list_reviewable` in doc-set-resolve.md and is covered
# by test-kb-review-surface.sh RS03 -- this suite does not take that ownership over.
#
# Auto-discovered by tests/run-all.sh. Usage: bash test-state-review-surface.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u
VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
DISPATCH_DOC="${REPO}/canonical/aid/templates/reviewer-dispatch.md"
SHORTCUT_DOC="${REPO}/canonical/aid/templates/shortcut-engine.md"
source "${SCRIPT_DIR}/../lib/assert.sh"
echo "== test-state-review-surface.sh =="
[[ -f "$DISPATCH_DOC" ]] || { echo "FATAL: reviewer-dispatch.md not found at $DISPATCH_DOC" >&2; exit 2; }
[[ -f "$SHORTCUT_DOC" ]] || { echo "FATAL: shortcut-engine.md not found at $SHORTCUT_DOC" >&2; exit 2; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# Extract the CANONICAL filter_reviewable_artifacts() definition from the doc and source it, so
# this suite guards against drift between the doc and the asserted behavior -- a re-implemented
# copy of the regex here would be worthless: it would keep passing even if the doc's function
# changed underneath it.
WRAP="$TMP/filter_reviewable_artifacts.sh"
{ echo '#!/usr/bin/env bash'
  awk '/^filter_reviewable_artifacts\(\) \{/{p=1} p{print} p && /^\}/{exit}' "$DISPATCH_DOC"
} > "$WRAP"
# shellcheck source=/dev/null
source "$WRAP"
EXTRACTED_BODY="$(sed -n '2,$p' "$WRAP")"
if declare -F filter_reviewable_artifacts >/dev/null && [[ -n "${EXTRACTED_BODY// /}" ]]; then
  pass "SR00 extracted filter_reviewable_artifacts() from reviewer-dispatch.md (non-empty)"
else
  fail "SR00 could not extract filter_reviewable_artifacts() from reviewer-dispatch.md -- extraction yielded nothing; suite cannot proceed"
  test_summary; exit 1
fi

# Build one input list covering every case, invoke the extracted filter ONCE (S1), then assert
# many times against the captured output (S2) via exact whole-line matches.
INPUT=$'STATE.md\n'
INPUT+=$'STATE.yml\n'
INPUT+=$'deliveries/delivery-001/STATE.md\n'
INPUT+=$'deliveries/delivery-001/STATE.yml\n'
INPUT+=$'deliveries/delivery-001/tasks/task-001/STATE.md\n'
INPUT+=$'deliveries/delivery-001/tasks/task-001/STATE.yml\n'
INPUT+=$'REQUIREMENTS.md\n'
INPUT+=$'SPEC.md\n'
INPUT+=$'PLAN.md\n'
INPUT+=$'BLUEPRINT.md\n'
INPUT+=$'tasks/task-001/DETAIL.md\n'
INPUT+=$'STATE.md.bak\n'
INPUT+=$'work-state-template.yml\n'
INPUT+=$'MY-STATE.md\n'
INPUT+=$'tasks/task-001/STATE.md\n'

OUT="$(printf '%s' "$INPUT" | filter_reviewable_artifacts)"
[[ "$VERBOSE" -eq 1 ]] && { echo "--- filter_reviewable_artifacts output ---"; printf '%s\n' "$OUT"; }
has() { grep -qxF "$1" <<<"$OUT"; }

# SR01-SR06: drops all six state-file path shapes (three levels x .md/.yml)
has "STATE.md" && fail "SR01 STATE.md at work root leaked into the reviewable surface" \
                || pass "SR01 drops STATE.md at work root"

has "STATE.yml" && fail "SR02 STATE.yml at work root leaked into the reviewable surface" \
                || pass "SR02 drops STATE.yml at work root"

has "deliveries/delivery-001/STATE.md" && fail "SR03 delivery-level STATE.md leaked into the reviewable surface" \
                                        || pass "SR03 drops STATE.md at deliveries/delivery-NNN/"

has "deliveries/delivery-001/STATE.yml" && fail "SR04 delivery-level STATE.yml leaked into the reviewable surface" \
                                         || pass "SR04 drops STATE.yml at deliveries/delivery-NNN/"

has "deliveries/delivery-001/tasks/task-001/STATE.md" && fail "SR05 task-level STATE.md (full layout) leaked into the reviewable surface" \
                                                        || pass "SR05 drops STATE.md at deliveries/delivery-NNN/tasks/task-NNN/ (full layout)"

has "deliveries/delivery-001/tasks/task-001/STATE.yml" && fail "SR06 task-level STATE.yml (full layout) leaked into the reviewable surface" \
                                                         || pass "SR06 drops STATE.yml at deliveries/delivery-NNN/tasks/task-NNN/ (full layout)"

# SR07-SR11: keeps all five authored-artifact shapes
has "REQUIREMENTS.md" && pass "SR07 keeps REQUIREMENTS.md" \
                       || fail "SR07 dropped authored artifact REQUIREMENTS.md"

has "SPEC.md" && pass "SR08 keeps SPEC.md" \
              || fail "SR08 dropped authored artifact SPEC.md"

has "PLAN.md" && pass "SR09 keeps PLAN.md" \
              || fail "SR09 dropped authored artifact PLAN.md"

has "BLUEPRINT.md" && pass "SR10 keeps BLUEPRINT.md" \
                    || fail "SR10 dropped authored artifact BLUEPRINT.md"

has "tasks/task-001/DETAIL.md" && pass "SR11 keeps tasks/task-NNN/DETAIL.md" \
                                || fail "SR11 dropped authored artifact tasks/task-NNN/DETAIL.md"

# SR12-SR14: near-miss basenames must survive -- the match is exact-basename, not a loose
# substring/prefix match on "STATE"
has "STATE.md.bak" && pass "SR12 near-miss STATE.md.bak survives (exact-basename match, not substring)" \
                    || fail "SR12 near-miss STATE.md.bak was wrongly dropped"

has "work-state-template.yml" && pass "SR13 near-miss work-state-template.yml survives" \
                               || fail "SR13 near-miss work-state-template.yml was wrongly dropped"

has "MY-STATE.md" && pass "SR14 near-miss MY-STATE.md survives (basename is MY-STATE.md, not STATE.md)" \
                   || fail "SR14 near-miss MY-STATE.md was wrongly dropped"

# SR15: the match is on basename alone, so a flattened-layout task path (no deliveries/
# wrapper) is dropped identically to the full-layout path above -- the filter's behavior does
# not depend on which layout produced the path.
has "tasks/task-001/STATE.md" && fail "SR15 flattened-layout task-level STATE.md leaked into the reviewable surface" \
                                || pass "SR15 drops STATE.md at tasks/task-NNN/ (flattened layout, no deliveries/ wrapper) -- basename match is layout-independent"

# SR16: an all-state-files change set -- the most common commit shape in this pipeline, since
# every writeback-state.sh write produces one -- must exit 0 with empty output under a
# set -euo pipefail caller. `grep -v` alone exits 1 on no output; the doc's `|| true` is what
# fixes it.
ALL_STATE=$'STATE.md\nSTATE.yml\ndeliveries/delivery-001/STATE.md\ndeliveries/delivery-001/STATE.yml\n'
if ( set -euo pipefail; RS="$(printf '%s' "$ALL_STATE" | filter_reviewable_artifacts)"; [ -z "$RS" ] ); then
  pass "SR16 all-state-files input -> exit 0 + empty output (no set -euo pipefail abort)"
else
  fail "SR16 all-state-files input aborted the pipefail caller or emitted output"
fi

# SR17: static assertion -- no brief template names a state file inside an ARTIFACTS block.
# Two block shapes are in play:
#   style A -- a bare "ARTIFACTS UNDER REVIEW:" line (reviewer-dispatch.md's template/worked
#              example, and every per-skill reviewer-brief.md), terminated by a blank line.
#   style B -- a bold "- **ARTIFACTS UNDER REVIEW:**" bullet (shortcut-engine.md's hand-crafted
#              one-off briefs), terminated by the next "- **" bullet.
# Extraction, not a hardcoded expectation list: this fails the moment a brief is edited to name
# a state file inside its own ARTIFACTS block, regardless of which file it happens in.
extract_style_a() {
  awk '/^ARTIFACTS UNDER REVIEW:/{p=1; print; next} p && /^$/{p=0; next} p{print}' "$1"
}
extract_gate_section() {
  awk '/^## State: GATE/{p=1} p{print} /^## State: APPROVAL-HALT/{exit}' "$1"
}
extract_style_b() {
  awk '/^- \*\*ARTIFACTS UNDER REVIEW:\*\*/{p=1; print; next} p && /^- \*\*/{p=0} p{print}'
}

BRIEF_TEMPLATES=(
  "${REPO}/canonical/skills/aid-define/references/reviewer-brief.md"
  "${REPO}/canonical/skills/aid-detail/references/reviewer-brief.md"
  "${REPO}/canonical/skills/aid-discover/references/reviewer-brief.md"
  "${REPO}/canonical/skills/aid-execute/references/reviewer-brief.md"
  "${REPO}/canonical/skills/aid-plan/references/reviewer-brief.md"
  "${REPO}/canonical/skills/aid-specify/references/reviewer-brief.md"
)

STATIC_LEAK=0
STATIC_CHECKED=0

# reviewer-dispatch.md itself: the 5-section template block plus the worked-example block --
# extract_style_a's while-loop captures every occurrence in the file.
DISPATCH_BLOCK="$(awk '/^ARTIFACTS UNDER REVIEW:/{p=1; print; next} p && /^$/{p=0; next} p{print}' "$DISPATCH_DOC")"
if [[ -z "$DISPATCH_BLOCK" ]]; then
  fail "SR17 could not extract any ARTIFACTS UNDER REVIEW block from reviewer-dispatch.md"
  STATIC_LEAK=1
else
  STATIC_CHECKED=$((STATIC_CHECKED + 1))
  if grep -qE 'STATE\.(md|yml)' <<<"$DISPATCH_BLOCK"; then
    fail "SR17 reviewer-dispatch.md names a state file inside its own ARTIFACTS UNDER REVIEW block"
    STATIC_LEAK=1
  fi
fi

for brief in "${BRIEF_TEMPLATES[@]}"; do
  [[ -f "$brief" ]] || { fail "SR17 expected reviewer-brief.md not found: $brief"; STATIC_LEAK=1; continue; }
  BLOCK="$(extract_style_a "$brief")"
  if [[ -z "$BLOCK" ]]; then
    fail "SR17 could not extract an ARTIFACTS UNDER REVIEW block from $brief"
    STATIC_LEAK=1
    continue
  fi
  STATIC_CHECKED=$((STATIC_CHECKED + 1))
  if grep -qE 'STATE\.(md|yml)' <<<"$BLOCK"; then
    fail "SR17 $brief names a state file inside its own ARTIFACTS UNDER REVIEW block"
    STATIC_LEAK=1
  fi
done

GATE_SLICE="$(extract_gate_section "$SHORTCUT_DOC")"
GATE_BLOCK="$(extract_style_b <<<"$GATE_SLICE")"
if [[ -z "$GATE_BLOCK" ]]; then
  fail "SR17 could not extract any ARTIFACTS UNDER REVIEW bullet from shortcut-engine.md § GATE"
  STATIC_LEAK=1
else
  STATIC_CHECKED=$((STATIC_CHECKED + 1))
  if grep -qE 'STATE\.(md|yml)' <<<"$GATE_BLOCK"; then
    fail "SR17 shortcut-engine.md § GATE names a state file inside an ARTIFACTS UNDER REVIEW bullet"
    STATIC_LEAK=1
  fi
fi

[[ "$VERBOSE" -eq 1 ]] && echo "[LOG] SR17 checked $STATIC_CHECKED ARTIFACTS UNDER REVIEW block(s) across reviewer-dispatch.md + ${#BRIEF_TEMPLATES[@]} reviewer-brief.md file(s) + shortcut-engine.md § GATE"

if [[ "$STATIC_LEAK" -eq 0 ]]; then
  pass "SR17 no brief template names a state file inside an ARTIFACTS UNDER REVIEW block ($STATIC_CHECKED block(s) checked)"
fi

test_summary
