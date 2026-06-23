#!/usr/bin/env bash
# test-teachback-fixtures.sh -- AC1 teach-back regression suite (f012 TEST-C).
#
# Exercises f005's shipped kb-teachback-questions.sh + f004's shipped closure-check.sh
# over the task-037 teachback/pass-kb and teachback/fail-kb fixtures and asserts
# V-C1..V-C4 from feature-012 SPEC TEST-C.
#
# Assertions:
#   T01  V-C1a  kb-teachback-questions.sh over pass-kb candidate-concepts.md emits
#               "What is X?" for every Spread>=2 Term:
#               TokenRouter (spread=2), DispatchQueue (spread=2), PriorityBand (spread=2).
#   T02  V-C1b  The synthesis-tagged concepts are also emitted:
#               "What is dispatch-acknowledgement contract?"
#               "What is event-fanout contract?"
#   T03  V-C1c  The fixed engine question is present:
#               "Explain how this system works, in its own language."
#   T04  V-C1d  Determinism: re-run over the same fixture copy is byte-identical (diff clean).
#   T05  V-C2   closure-check.sh over pass-kb reports ZERO ungrounded terms (PASS substrate):
#               output (a) has no data rows beyond the header.
#   T06  V-C3   closure-check.sh over fail-kb reports TokenRouter as ungrounded (FAIL
#               substrate -- LEXICAL channel): output (a) contains a row for "tokenrouter"
#               (closure-check lowercases terms).
#   T07  V-C4   The V-C3 ungrounded term (TokenRouter) is a member of the V-C1 question set:
#               the FAIL is on a required teach-back question, not a noise term.
#   T08  Engine-narration boundary: the suite does NOT mechanically assert an
#               engine-narration FAIL. The fixed engine question's presence in the question
#               set (T03) is the only mechanical substrate asserted here. The engine-narration
#               PASS/FAIL is irreducibly LLM judgment (f005 SPEC L434-435; no shipped script
#               returns this verdict) -- exercised + anchored at runtime by the M4 reviewer
#               over the fail-KB, NOT a CI assertion.
#   T09  V-C3-SYNTHESIS  closure-check.sh over fail-kb reports the SYNTHESIS-CLASS concept
#               "event-fanout contract" as ungrounded (FAIL substrate -- NON-LEXICAL channel).
#               This is the direct regression guard for the whole-work thesis: the engine
#               catches a load-bearing CONCEPTUAL miss with no recurring coined token.
#               event-fanout contract is a synthesis row in candidate-concepts.md (Source=synthesis)
#               and is used in the fail-kb DispatchQueue prose, but has NO spine heading in
#               fail-kb. closure-check output (a) MUST report it as ungrounded.
#               The pass-kb defines it (### event-fanout contract) so pass-kb output (a) stays
#               empty. This is the non-lexical analog of V-C3 (T06 asserts the lexical case).
#   ISO-CANARY  Real HOME gained no .aid dirs during the suite run.
#
# Mechanical-vs-judgment boundary (load-bearing):
#   The engine-narration limb is NOT a mechanical CI assertion. The fixed engine question
#   ("Explain how this system works, in its own language.") is EMITTED by the generator
#   (asserted T03) and is a MEMBER of the question set (asserted T07 cross-check covers
#   only the lexical ungrounded term; the engine question is always present). The actual
#   narration PASS/FAIL is LLM judgment exercised at runtime (M4 reviewer), not CI-scored.
#   This suite asserts BOTH the MECHANICAL LEXICAL and MECHANICAL SYNTHESIS substrates:
#     - Question set is generated deterministically (T01-T04, V-C1)
#     - pass-kb is fully closed (lexical + synthesis): zero ungrounded (T05, V-C2)
#     - fail-kb is lexically unclosed: TokenRouter ungrounded (T06, V-C3)
#     - fail-kb is synthesis-unclosed: event-fanout contract ungrounded (T09, V-C3-SYNTHESIS)
#     - The lexical ungrounded term is a question-set member (T07, V-C4)
#
# Isolation discipline:
#   HOME pinned to throwaway dir; real-HOME .aid canary (snapshot before/after);
#   explicit fixture paths via mktemp copy; committed fixture never mutated;
#   repo root never used as script root.
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# Follows test-doc-set-mapping.sh pattern: set -u, source ../lib/assert.sh,
# numbered T01.. assertions, mktemp -d scratch, trap EXIT, test_summary + exit $?.
#
# Usage:
#   bash tests/canonical/test-teachback-fixtures.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
TEACHBACK_QUESTIONS="${REPO}/canonical/aid/scripts/kb/kb-teachback-questions.sh"
CLOSURE_CHECK="${REPO}/canonical/aid/scripts/kb/closure-check.sh"
FIXTURES_BASE="${SCRIPT_DIR}/fixtures/kb-essence/teachback"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-teachback-fixtures.sh =="

# ---------------------------------------------------------------------------
# Guard: required scripts and fixture directories must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$TEACHBACK_QUESTIONS" ]]; then
  echo "FATAL: kb-teachback-questions.sh not found at $TEACHBACK_QUESTIONS" >&2
  exit 2
fi

if [[ ! -f "$CLOSURE_CHECK" ]]; then
  echo "FATAL: closure-check.sh not found at $CLOSURE_CHECK" >&2
  exit 2
fi

if [[ ! -d "${FIXTURES_BASE}/pass-kb" ]]; then
  echo "FATAL: pass-kb fixture not found at ${FIXTURES_BASE}/pass-kb" >&2
  exit 2
fi

if [[ ! -d "${FIXTURES_BASE}/fail-kb" ]]; then
  echo "FATAL: fail-kb fixture not found at ${FIXTURES_BASE}/fail-kb" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Global tmp dir: all scratch copies land here; cleaned on EXIT.
# ---------------------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# HOME pin: all home-relative writes land in a throwaway dir.
# Snapshot the real HOME .aid dirs BEFORE the suite (the real HOME may already
# contain .aid dirs under CI -- per [[ci-runs-as-root-repo-under-home]]).
# ---------------------------------------------------------------------------
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

# ---------------------------------------------------------------------------
# Fixture setup: copy teachback fixtures to mktemp scratch so we never mutate
# the committed fixture tree. Every script invocation uses the scratch copy.
# ---------------------------------------------------------------------------
PASS_KB_SCRATCH="${TMP}/pass-kb"
FAIL_KB_SCRATCH="${TMP}/fail-kb"
cp -r "${FIXTURES_BASE}/pass-kb" "${PASS_KB_SCRATCH}"
cp -r "${FIXTURES_BASE}/fail-kb" "${FAIL_KB_SCRATCH}"

PASS_CONCEPTS="${PASS_KB_SCRATCH}/generated/candidate-concepts.md"
PASS_SPINE="${PASS_KB_SCRATCH}/knowledge/domain-glossary.md"
PASS_KB_DIR="${PASS_KB_SCRATCH}/knowledge"

FAIL_CONCEPTS="${FAIL_KB_SCRATCH}/generated/candidate-concepts.md"
FAIL_SPINE="${FAIL_KB_SCRATCH}/knowledge/domain-glossary.md"
FAIL_KB_DIR="${FAIL_KB_SCRATCH}/knowledge"

# ---------------------------------------------------------------------------
# T01-T04: V-C1 -- question-set generation is deterministic and correct.
#
# kb-teachback-questions.sh over pass-kb/generated/candidate-concepts.md must emit:
#   "What is DispatchQueue?"         (harvest, spread=2)
#   "What is PriorityBand?"          (harvest, spread=2)
#   "What is TokenRouter?"           (harvest, spread=2)
#   "What is dispatch-acknowledgement contract?" (synthesis)
#   "Explain how this system works, in its own language."
#
# Re-run must be byte-identical (V-C1 determinism requirement).
# ---------------------------------------------------------------------------
echo ""
echo "=== T01-T04: V-C1 question-set generation ==="

QSET_OUT_1="${TMP}/qset-run1.txt"
QSET_OUT_2="${TMP}/qset-run2.txt"

bash "$TEACHBACK_QUESTIONS" --concepts "$PASS_CONCEPTS" > "$QSET_OUT_1" 2>/dev/null
QSET_CONTENT=$(cat "$QSET_OUT_1")

# T01: V-C1a -- Spread>=2 harvest terms each generate a "What is X?" question.
if echo "$QSET_CONTENT" | grep -qF "What is TokenRouter?"; then
  pass "T01a V-C1a spread=2 term TokenRouter generates question"
else
  fail "T01a V-C1a spread=2 term TokenRouter -- 'What is TokenRouter?' not in output"
fi

if echo "$QSET_CONTENT" | grep -qF "What is DispatchQueue?"; then
  pass "T01b V-C1a spread=2 term DispatchQueue generates question"
else
  fail "T01b V-C1a spread=2 term DispatchQueue -- 'What is DispatchQueue?' not in output"
fi

if echo "$QSET_CONTENT" | grep -qF "What is PriorityBand?"; then
  pass "T01c V-C1a spread=2 term PriorityBand generates question"
else
  fail "T01c V-C1a spread=2 term PriorityBand -- 'What is PriorityBand?' not in output"
fi

# T02: V-C1b -- synthesis-tagged concepts generate "What is X?" questions.
# Both synthesis rows in pass-kb candidate-concepts.md must produce questions.
if echo "$QSET_CONTENT" | grep -qF "What is dispatch-acknowledgement contract?"; then
  pass "T02a V-C1b synthesis concept dispatch-acknowledgement contract generates question"
else
  fail "T02a V-C1b synthesis concept -- 'What is dispatch-acknowledgement contract?' not in output"
fi

if echo "$QSET_CONTENT" | grep -qF "What is event-fanout contract?"; then
  pass "T02b V-C1b synthesis concept event-fanout contract generates question (non-lexical channel regression guard)"
else
  fail "T02b V-C1b synthesis concept -- 'What is event-fanout contract?' not in output (non-lexical channel may not emit synthesis questions)"
fi

# T03: V-C1c -- fixed engine question is present.
ENGINE_QUESTION="Explain how this system works, in its own language."
if echo "$QSET_CONTENT" | grep -qF "$ENGINE_QUESTION"; then
  pass "T03 V-C1c fixed engine question is present in question set"
else
  fail "T03 V-C1c fixed engine question not found -- expected: '$ENGINE_QUESTION'"
fi

# T04: V-C1d -- re-run is byte-identical (determinism).
bash "$TEACHBACK_QUESTIONS" --concepts "$PASS_CONCEPTS" > "$QSET_OUT_2" 2>/dev/null

if diff "$QSET_OUT_1" "$QSET_OUT_2" > /dev/null 2>&1; then
  pass "T04 V-C1d question-set re-run is byte-identical (determinism)"
else
  fail "T04 V-C1d question-set re-run differs between runs (determinism violated)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- diff run1 vs run2 ---"
    diff "$QSET_OUT_1" "$QSET_OUT_2" || true
  fi
fi

# ---------------------------------------------------------------------------
# T05: V-C2 -- closure-check.sh over pass-kb reports ZERO ungrounded (PASS substrate).
#
# Every candidate concept (TokenRouter, DispatchQueue, PriorityBand,
# dispatch-acknowledgement contract) is defined in pass-kb's spine.
# closure-check output (a) must have no data rows (only header).
# ---------------------------------------------------------------------------
echo ""
echo "=== T05: V-C2 pass-kb closure PASS substrate ==="

PASS_OUTPUT_A="${TMP}/pass-output-a.md"

PASS_OUTPUT_B="${TMP}/pass-output-b.md"
PASS_OUTPUT_C="${TMP}/pass-output-c.md"
bash "$CLOSURE_CHECK" \
  --concepts "$PASS_CONCEPTS" \
  --spine    "$PASS_SPINE" \
  --kb-dir   "$PASS_KB_DIR" \
  --output-a "$PASS_OUTPUT_A" \
  --output-b "$PASS_OUTPUT_B" \
  --output-c "$PASS_OUTPUT_C" \
  2>/dev/null

# The output (a) table has a header row (| term | used-in-doc | anchor |) and a
# separator row (|------|...). Data rows (ungrounded terms) are pipe-delimited lines
# that are neither the header nor the separator. A PASS means zero data rows.
#
# Format of output (a):
#   ## Output (a): Ungrounded / Un-closed Concept Set
#
#   | term | used-in-doc | anchor |
#   |------|-------------|--------|
#   (data rows here if any ungrounded terms)
#
# Count data rows: pipe-delimited lines that are not the header (contains "term |")
# and not the separator (starts with |---).
UNGROUNDED_DATA_ROWS=$(grep '^|' "$PASS_OUTPUT_A" 2>/dev/null \
  | grep -v '^| term ' \
  | grep -v '^|---' \
  | wc -l | tr -d ' ')

if [[ "$UNGROUNDED_DATA_ROWS" -eq 0 ]]; then
  pass "T05 V-C2 pass-kb closure-check output (a) is empty -- zero ungrounded terms (PASS substrate)"
else
  fail "T05 V-C2 pass-kb closure-check output (a) has $UNGROUNDED_DATA_ROWS ungrounded term row(s) (expected 0)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- output (a) ---"
    cat "$PASS_OUTPUT_A"
    echo "---"
  fi
fi

# ---------------------------------------------------------------------------
# T06: V-C3 -- closure-check.sh over fail-kb reports TokenRouter as ungrounded (FAIL substrate).
#
# fail-kb/knowledge/domain-glossary.md defines DispatchQueue, PriorityBand, and
# dispatch-acknowledgement contract, but OMITS TokenRouter.
# The domain-glossary.md body USES "TokenRouter" in the other concept definitions,
# so closure-check must report it as ungrounded.
#
# closure-check lowercases terms for matching, so the ungrounded row contains
# "tokenrouter" (not "TokenRouter").
# ---------------------------------------------------------------------------
echo ""
echo "=== T06: V-C3 fail-kb closure FAIL substrate ==="

FAIL_OUTPUT_A="${TMP}/fail-output-a.md"

FAIL_OUTPUT_B="${TMP}/fail-output-b.md"
FAIL_OUTPUT_C="${TMP}/fail-output-c.md"
bash "$CLOSURE_CHECK" \
  --concepts "$FAIL_CONCEPTS" \
  --spine    "$FAIL_SPINE" \
  --kb-dir   "$FAIL_KB_DIR" \
  --output-a "$FAIL_OUTPUT_A" \
  --output-b "$FAIL_OUTPUT_B" \
  --output-c "$FAIL_OUTPUT_C" \
  2>/dev/null

# Closure-check lowercases terms in output (a); check for "tokenrouter".
if grep -qi 'tokenrouter' "$FAIL_OUTPUT_A" 2>/dev/null; then
  pass "T06 V-C3 fail-kb closure-check output (a) contains tokenrouter (FAIL substrate -- TokenRouter is ungrounded)"
else
  fail "T06 V-C3 fail-kb closure-check output (a) does NOT contain tokenrouter (expected ungrounded term)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- output (a) ---"
    cat "$FAIL_OUTPUT_A"
    echo "---"
  fi
fi

# ---------------------------------------------------------------------------
# T07: V-C4 -- the V-C3 ungrounded term (TokenRouter) is a member of the V-C1
#              question set.
#
# The FAIL is on a required teach-back question, not a noise term.
# We check that the question set contains "What is TokenRouter?" (case-sensitive
# as emitted by kb-teachback-questions.sh, which preserves the Term column's
# original casing from candidate-concepts.md).
# ---------------------------------------------------------------------------
echo ""
echo "=== T07: V-C4 ungrounded term is a question-set member ==="

if grep -qF "What is TokenRouter?" "$QSET_OUT_1" 2>/dev/null; then
  pass "T07 V-C4 TokenRouter (V-C3 ungrounded term) is a member of the V-C1 question set -- FAIL is on a required question"
else
  fail "T07 V-C4 'What is TokenRouter?' not found in question set -- expected the ungrounded term to be a required question"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- question set ---"
    cat "$QSET_OUT_1"
    echo "---"
  fi
fi

# ---------------------------------------------------------------------------
# T08: Engine-narration boundary verification (documentation assertion).
#
# The suite does NOT mechanically assert an engine-narration FAIL.
# This assertion confirms that the mechanical substrate IS asserted (T03:
# the engine question is present in the question set) while the engine-narration
# PASS/FAIL verdict is NOT mechanically scored.
#
# Mechanically: verify the engine question IS in the question set (the only
# mechanical engine-substrate asserted here -- its presence as a question-set
# member). The actual narration verdict is LLM judgment (runtime M4 reviewer).
# ---------------------------------------------------------------------------
echo ""
echo "=== T08: Engine-narration boundary (mechanical substrate only) ==="

# Mechanical substrate: engine question is a member of the generated question set.
# (T03 already passed this check; T08 re-confirms it as the explicit boundary statement.)
if grep -qF "Explain how this system works, in its own language." "$QSET_OUT_1" 2>/dev/null; then
  pass "T08 Engine-narration mechanical substrate: fixed engine question is a question-set member (T03 confirmed; V-C1c)"
else
  fail "T08 Engine-narration mechanical substrate: fixed engine question not in question set"
fi

# ---------------------------------------------------------------------------
# T09: V-C3-SYNTHESIS -- closure-check.sh over fail-kb reports the SYNTHESIS-CLASS
#       concept "event-fanout contract" as ungrounded (NON-LEXICAL channel FAIL substrate).
#
# This is the direct regression guard for the whole-work thesis: the closure engine catches
# a load-bearing CONCEPTUAL miss even when the concept has no recurring coined token.
#
# fail-kb/generated/candidate-concepts.md row 5 (Source=synthesis):
#   | 5 | synthesis | `event-fanout contract` | ...
# fail-kb/knowledge/domain-glossary.md DispatchQueue prose USES "event-fanout contract"
# but there is NO "### event-fanout contract" heading in the spine.
# closure-check output (a) MUST report "event-fanout contract" as ungrounded.
#
# Cross-check (pass-kb): pass-kb defines "### event-fanout contract" in its spine,
# so pass-kb output (a) has ZERO ungrounded terms (already confirmed by T05).
#
# This is the non-lexical analog of V-C3 (T06 asserts the lexical TokenRouter case;
# T09 asserts the synthesis-class event-fanout contract case).
# ---------------------------------------------------------------------------
echo ""
echo "=== T09: V-C3-SYNTHESIS -- synthesis-class concept is ungrounded in fail-kb ==="

# FAIL_OUTPUT_A was produced in T06 above -- re-use it.
if grep -qiF "event-fanout contract" "$FAIL_OUTPUT_A" 2>/dev/null; then
  pass "T09 V-C3-SYNTHESIS -- fail-kb closure-check output (a) contains 'event-fanout contract' as ungrounded (SYNTHESIS-CLASS closure-FAIL regression guard ACTIVE; non-lexical channel catches conceptual spine omission)"
else
  fail "T09 V-C3-SYNTHESIS -- fail-kb closure-check output (a) does NOT contain 'event-fanout contract' (SYNTHESIS-CLASS closure-FAIL guard BROKEN -- non-lexical channel failed to catch synthesis concept omission from spine)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- output (a) ---"
    cat "$FAIL_OUTPUT_A"
    echo "---"
  fi
fi

# ---------------------------------------------------------------------------
# Isolation canary: confirm no real repo was touched.
# ---------------------------------------------------------------------------
echo ""
echo "=== Isolation canary: real HOME untouched ==="

_CANARY_AFTER="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
if [[ "${_CANARY_AFTER}" == "${_CANARY_BEFORE}" ]]; then
  pass "ISO-CANARY-01 real HOME (${REAL_HOME}) gained no .aid dirs (no scan escaped throwaway HOME)"
else
  _CANARY_NEW="$(comm -13 <(printf '%s\n' "${_CANARY_BEFORE}") <(printf '%s\n' "${_CANARY_AFTER}") 2>/dev/null || true)"
  fail "ISO-CANARY-01 real HOME blast surface: NEW .aid dirs appeared under ${REAL_HOME}: ${_CANARY_NEW}"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
test_summary
exit $?
