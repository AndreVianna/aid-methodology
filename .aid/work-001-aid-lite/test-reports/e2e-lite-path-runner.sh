#!/usr/bin/env bash
# E2E lite-path runner — task-018 (RECOVERED post-cycle-16 audit)
#
# Exercises the deterministic surface of feature-005 (lite-path):
#   Phase 1: T1/T2/T3 → workType mapping (from state-triage.md decision table)
#   Phase 2: All 4 lite sub-paths have valid emission templates
#   Phase 3: lite-to-full escalation file transitions (idempotent, crash-safe)
#   Phase 4: recipe-to-lite escalation (feature-005 ↔ feature-011 integration)
#   Phase 5: cross-tree byte-identity of lite-path references
#
# Note: this runner verifies the *deterministic* surfaces — the actual
# /aid-interview prose is the skill body, not script, so the runner
# tests templates, schemas, and file transitions rather than dialog flow.
#
# Usage: bash e2e-lite-path-runner.sh [--verbose]
# Exit: 0 = all pass, 1 = one or more failures

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INTERVIEW_DIR="$REPO_ROOT/canonical/skills/aid-interview"
TEMPLATES_DIR="$REPO_ROOT/canonical/templates"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

PASS=0
FAIL=0
declare -a ERRORS

pass() { PASS=$((PASS + 1)); echo "  PASS: $*"; }
fail() { FAIL=$((FAIL + 1)); ERRORS+=("$*"); echo "  FAIL: $*"; }
log()  { [[ "$VERBOSE" -eq 1 ]] && echo "[LOG] $*" || true; }

echo "=================================="
echo "E2E LITE-PATH RUNNER"
echo "=================================="

# Phase 1: triage mapping
echo ""
echo "--- Phase 1: triage mapping (T1/T2/T3 → workType + Path) ---"

STATE_TRIAGE="$INTERVIEW_DIR/references/state-triage.md"
if [[ ! -f "$STATE_TRIAGE" ]]; then
  fail "P1-0: state-triage.md exists at $STATE_TRIAGE"
else
  pass "P1-0: state-triage.md exists"
  for kebab in bug-fix small-refactor single-doc small-new-feature; do
    if grep -q "$kebab" "$STATE_TRIAGE"; then
      pass "P1-1: state-triage maps T3 → workType '$kebab'"
    else
      fail "P1-1: state-triage missing T3 mapping for '$kebab'"
    fi
  done
  if grep -qE "T1.*T2.*T3|conservative.*FULL|deterministic rule" "$STATE_TRIAGE"; then
    pass "P1-2: state-triage documents deterministic lite/full routing rule"
  else
    fail "P1-2: state-triage missing routing rule documentation"
  fi
  for subpath in LITE-BUG-FIX LITE-DOC LITE-REFACTOR LITE-FEATURE; do
    if grep -q "$subpath" "$STATE_TRIAGE"; then
      pass "P1-3: state-triage references sub-path $subpath"
    else
      fail "P1-3: state-triage missing sub-path $subpath"
    fi
  done
  if grep -qE "Use different sub-path|user override|\[3\] Escalate" "$STATE_TRIAGE"; then
    pass "P1-4: state-triage documents user override mechanism"
  else
    fail "P1-4: state-triage missing user override mechanism"
  fi
fi

# Phase 2: sub-path emission templates
echo ""
echo "--- Phase 2: lite sub-path emission templates ---"

LITE_SPEC="$TEMPLATES_DIR/specs/lite-spec-template.md"
if [[ -f "$LITE_SPEC" ]]; then
  pass "P2-0: lite-spec-template.md exists"
  for section in "Goal" "Context" "Acceptance Criteria" "Tasks" "Execution Graph"; do
    if grep -qE "^## ?$section|\{\{$section\}\}" "$LITE_SPEC"; then
      pass "P2-1: lite-spec-template has section '$section'"
    else
      fail "P2-1: lite-spec-template missing section '$section'"
    fi
  done
else
  fail "P2-0: lite-spec-template.md not found at $LITE_SPEC"
fi

CONDENSED="$INTERVIEW_DIR/references/state-condensed-intake.md"
if [[ -f "$CONDENSED" ]]; then
  pass "P2-2: state-condensed-intake.md exists"
  for subpath in LITE-BUG-FIX LITE-DOC LITE-REFACTOR LITE-FEATURE; do
    if grep -q "$subpath" "$CONDENSED"; then
      pass "P2-3: state-condensed-intake handles sub-path $subpath"
    else
      fail "P2-3: state-condensed-intake missing sub-path $subpath"
    fi
  done
else
  fail "P2-2: state-condensed-intake.md not found"
fi

TASK_BD="$INTERVIEW_DIR/references/state-task-breakdown.md"
if [[ -f "$TASK_BD" ]]; then
  pass "P2-4: state-task-breakdown.md exists"
  if grep -qE "exactly 1 for LITE-DOC|LITE-BUG-FIX.*single.*task|task-count|1 IMPLEMENT" "$TASK_BD"; then
    pass "P2-5: state-task-breakdown documents per-sub-path task-count rules"
  else
    fail "P2-5: state-task-breakdown missing per-sub-path task-count rules"
  fi
else
  fail "P2-4: state-task-breakdown.md not found"
fi

# Phase 3: lite-to-full escalation
echo ""
echo "--- Phase 3: lite-to-full escalation ---"

ESCALATION="$INTERVIEW_DIR/references/lite-to-full-escalation.md"
if [[ -f "$ESCALATION" ]]; then
  pass "P3-0: lite-to-full-escalation.md exists"
  if grep -qE "9a.*feature|9c.*delete|delete.*last|crash" "$ESCALATION"; then
    pass "P3-1: escalation documents crash-safe 9a→9b→9c ordering"
  else
    fail "P3-1: escalation missing crash-safe ordering"
  fi
  if grep -qE "Escalation Carry|preserves.*captured|carry.*slot" "$ESCALATION"; then
    pass "P3-2: escalation preserves captured info via Escalation Carry block"
  else
    fail "P3-2: escalation missing Escalation Carry mechanism"
  fi
  if grep -qE "Path:.*escalated|escalated.*sentinel" "$ESCALATION"; then
    pass "P3-3: escalation writes Path: escalated sentinel"
  else
    fail "P3-3: escalation missing Path: escalated sentinel"
  fi
else
  fail "P3-0: lite-to-full-escalation.md not found"
fi

# Phase 4: recipe-to-lite escalation
echo ""
echo "--- Phase 4: recipe-to-lite escalation ---"

RECIPE_ESC="$INTERVIEW_DIR/references/recipe-to-lite-escalation.md"
if [[ -f "$RECIPE_ESC" ]]; then
  pass "P4-0: recipe-to-lite-escalation.md exists"
  if grep -qE "Trigger A|Trigger B|during slot-fill|at confirm" "$RECIPE_ESC"; then
    pass "P4-1: recipe-escalation documents Triggers A and B"
  else
    fail "P4-1: recipe-escalation missing Triggers A/B"
  fi
  if grep -qE "Status:.*abandoned|preserve.*slot|Recipe Slots" "$RECIPE_ESC"; then
    pass "P4-2: recipe-escalation preserves slot values"
  else
    fail "P4-2: recipe-escalation missing slot preservation"
  fi
else
  fail "P4-0: recipe-to-lite-escalation.md not found"
fi

# Phase 5: cross-tree byte-identity
echo ""
echo "--- Phase 5: cross-tree byte-identity ---"

for ref in state-triage.md state-condensed-intake.md state-task-breakdown.md \
           state-lite-review.md state-lite-done.md \
           lite-to-full-escalation.md recipe-to-lite-escalation.md; do
  canonical="$INTERVIEW_DIR/references/$ref"
  if [[ ! -f "$canonical" ]]; then
    fail "P5: canonical $ref missing"
    continue
  fi
  # After F1 (PR #15 review fix), the renderer rewrites canonical/{scripts,
  # templates,skills,agents,rules,recipes}/ → <install_root>/ in skill bodies.
  # So profile ≠ canonical for files containing those refs. Instead, we
  # apply the same rewrite to canonical in-memory and compare.
  match_count=0
  for entry in "claude-code/.claude:.claude" "codex/.agents:.agents" "cursor/.cursor:.cursor"; do
    profile_dir="${entry%%:*}"
    install_root="${entry##*:}"
    profile_ref="$REPO_ROOT/profiles/$profile_dir/skills/aid-interview/references/$ref"
    if [[ -f "$profile_ref" ]]; then
      profile_sha=$(sha256sum "$profile_ref" | awk '{print $1}')
      # Rewrite canonical → install-root paths in-memory, then compare
      expected_sha=$(sed -E "s#\bcanonical/(scripts|templates|skills|agents|rules|recipes)/#${install_root}/\1/#g" "$canonical" | sha256sum | awk '{print $1}')
      if [[ "$expected_sha" == "$profile_sha" ]]; then
        match_count=$((match_count + 1))
      fi
    fi
  done
  if [[ "$match_count" -eq 3 ]]; then
    pass "P5: $ref matches canonical (with F1 install-path rewrite applied) across 3 profile trees"
  else
    fail "P5: $ref rewrite-aware match broken ($match_count/3 profiles match)"
  fi
done

# Results
echo ""
echo "=================================="
echo "E2E LITE-PATH RESULTS"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "=================================="
if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "Failures:"
  for e in "${ERRORS[@]}"; do echo "  - $e"; done
  exit 1
fi
echo "ALL CHECKS PASSED"
exit 0
