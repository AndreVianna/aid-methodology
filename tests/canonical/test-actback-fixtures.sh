#!/usr/bin/env bash
# test-actback-fixtures.sh -- AC16 act-back regression suite (f012/f013 TEST-V-E family).
#
# Exercises delivery-005's shipped kb-actback-task.sh over the task-039 act-back fixture
# corpus (tests/canonical/fixtures/kb-essence/actback/) and asserts V-E1..V-E3 from
# feature-012 SPEC (the V-E family alongside V-A..V-D).
#
# Assertions:
#   T01  V-E1a  kb-actback-task.sh over the representative-task spec fixture emits the
#               recorded expected/task-spec.txt golden; diff is clean.
#   T02  V-E1b  Re-run over the same fixture copy is byte-identical (determinism).
#   T03  V-E2   Presence check over actback-pass-kb reports all expected operational
#               classes as PRESENT (scoped per the owning-table):
#                 coding-standards.md Conventions => present
#                 domain-glossary.md  Invariants  => present
#                 schemas.md          Contracts   => present
#                 tech-debt.md        Gotchas     => present
#   T04  V-E3   Presence check over actback-fail-kb reports the same expected classes
#               as ABSENT (the buried/omitted shape -- the structural cause of an
#               act-back sufficiency FAIL):
#                 coding-standards.md Conventions => absent
#                 domain-glossary.md  Invariants  => absent
#                 schemas.md          Contracts   => absent
#                 tech-debt.md        Gotchas     => absent
#   T05  V-E boundary  The suite does NOT mechanically assert M6 plan success or
#               flag well-foundedness (irreducible LLM judgment, the operational
#               analog of V-C's engine-narration limb). The mechanical substrate
#               asserted is V-E1/V-E2/V-E3 only. This assertion documents the boundary.
#   ISO-CANARY  Real HOME gained no .aid dirs during the suite run.
#
# Mechanical-vs-judgment boundary (load-bearing):
#   The judgment half is NOT a mechanical CI assertion. Whether the clean-context M6
#   reviewer's plan succeeds over actback-pass-kb, and whether its insufficiency flags
#   over actback-fail-kb are well-founded, are IRREDUCIBLY LLM judgment (the operational
#   analog of teach-back's engine-narration limb; f005 SPEC L434-435). CI asserts only:
#     - V-E1: task spec is deterministic and byte-matches the golden (T01, T02)
#     - V-E2: pass-kb presence check reports all expected classes present (T03)
#     - V-E3: fail-kb presence check reports the same classes absent (T04)
#   The M6 plan-success/flag verdict is runtime-anchored in f012's Judgment-Boundary
#   table (AC16 row) and NOT scored here.
#
# Isolation discipline:
#   HOME pinned to throwaway dir; real-HOME .aid canary (snapshot before/after,
#   because real HOME may already hold .aid dirs under CI per
#   [[ci-runs-as-root-repo-under-home]]); explicit fixture paths via mktemp copy;
#   committed fixture never mutated; repo root never used as script root.
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
# Follows test-doc-set-mapping.sh pattern: set -u, source ../lib/assert.sh,
# numbered T01.. assertions, mktemp -d scratch, trap EXIT, test_summary + exit $?.
#
# Usage:
#   bash tests/canonical/test-actback-fixtures.sh [--verbose]
#   HOME=$(mktemp -d) bash tests/canonical/test-actback-fixtures.sh
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
SUT="${REPO}/canonical/aid/scripts/kb/kb-actback-task.sh"
FIXTURES_BASE="${SCRIPT_DIR}/fixtures/kb-essence/actback"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-actback-fixtures.sh =="

# ---------------------------------------------------------------------------
# Guard: required script and fixture directories must exist
# ---------------------------------------------------------------------------
if [[ ! -f "$SUT" ]]; then
  echo "FATAL: kb-actback-task.sh not found at $SUT" >&2
  exit 2
fi

if [[ ! -d "${FIXTURES_BASE}/representative-task-fixture" ]]; then
  echo "FATAL: representative-task-fixture not found at ${FIXTURES_BASE}/representative-task-fixture" >&2
  exit 2
fi

if [[ ! -f "${FIXTURES_BASE}/representative-task-fixture/doc-set.tsv" ]]; then
  echo "FATAL: representative-task-fixture/doc-set.tsv not found" >&2
  exit 2
fi

if [[ ! -f "${FIXTURES_BASE}/representative-task-fixture/expected/task-spec.txt" ]]; then
  echo "FATAL: representative-task-fixture/expected/task-spec.txt not found" >&2
  exit 2
fi

if [[ ! -d "${FIXTURES_BASE}/actback-pass-kb/knowledge" ]]; then
  echo "FATAL: actback-pass-kb/knowledge not found at ${FIXTURES_BASE}/actback-pass-kb/knowledge" >&2
  exit 2
fi

if [[ ! -d "${FIXTURES_BASE}/actback-fail-kb/knowledge" ]]; then
  echo "FATAL: actback-fail-kb/knowledge not found at ${FIXTURES_BASE}/actback-fail-kb/knowledge" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Global tmp dir + isolation: all scratch copies land here; cleaned on EXIT.
# HOME pinned to a throwaway dir BEFORE any script invocation.
# ---------------------------------------------------------------------------
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# HOME pin: point HOME at a throwaway dir to prevent .aid/ leakage.
# Snapshot the real HOME .aid dirs BEFORE the suite (real HOME may already contain
# .aid dirs under CI -- per [[ci-runs-as-root-repo-under-home]]).
REAL_HOME="${HOME}"
_CANARY_BEFORE="$(find "${REAL_HOME}" -maxdepth 6 -name '.aid' -type d 2>/dev/null | sort || true)"
export HOME="${TMP}/fakehome"
mkdir -p "${HOME}"

# ---------------------------------------------------------------------------
# Fixture setup: copy the committed fixture trees into mktemp scratch so we
# never mutate the committed fixture. The doc-set TSV is shared by all three
# fixture shapes (representative-task / pass-kb / fail-kb use the same doc list).
# ---------------------------------------------------------------------------
REP_SCRATCH="${TMP}/rep-task"
PASS_SCRATCH="${TMP}/actback-pass-kb"
FAIL_SCRATCH="${TMP}/actback-fail-kb"

cp -r "${FIXTURES_BASE}/representative-task-fixture" "${REP_SCRATCH}"
cp -r "${FIXTURES_BASE}/actback-pass-kb"             "${PASS_SCRATCH}"
cp -r "${FIXTURES_BASE}/actback-fail-kb"             "${FAIL_SCRATCH}"

REP_DOC_SET="${REP_SCRATCH}/doc-set.tsv"
REP_KB_DIR="${REP_SCRATCH}/kb"
GOLDEN="${REP_SCRATCH}/expected/task-spec.txt"

PASS_KB_DIR="${PASS_SCRATCH}/knowledge"
FAIL_KB_DIR="${FAIL_SCRATCH}/knowledge"

# ---------------------------------------------------------------------------
# T01: V-E1a -- kb-actback-task.sh over the representative-task spec fixture
#               emits the recorded expected/task-spec.txt golden; diff is clean.
#
# The representative-task fixture carries doc-set.tsv (schemas.md + coding-
# standards.md + domain-glossary.md + tech-debt.md; schemas.md triggers the
# "contract" task shape heuristic) and the kb/ docs the script scans.
# The golden at expected/task-spec.txt records the byte-reproducible output.
# ---------------------------------------------------------------------------
echo ""
echo "=== T01: V-E1a task spec matches recorded golden ==="

TASK_OUT_1="${TMP}/task-run1.txt"

bash "$SUT" task \
  --doc-set "$REP_DOC_SET" \
  --kb-dir  "$REP_KB_DIR" \
  > "$TASK_OUT_1" 2>/dev/null

if diff "$TASK_OUT_1" "$GOLDEN" > /dev/null 2>&1; then
  pass "T01 V-E1a kb-actback-task.sh output matches recorded golden (expected/task-spec.txt)"
else
  fail "T01 V-E1a kb-actback-task.sh output does NOT match recorded golden"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- diff actual vs golden ---"
    diff "$TASK_OUT_1" "$GOLDEN" || true
    echo "---"
  fi
fi

# ---------------------------------------------------------------------------
# T02: V-E1b -- Re-run over the same fixture copy is byte-identical (determinism).
#
# Two sequential runs over the same mktemp fixture copy must produce identical
# output (NFR-3). This asserts the mechanical half of V-E1: the task-selection
# substrate is byte-reproducible. The judgment half (is the task well-formed /
# representative for this project shape) is runtime-anchored, NOT asserted here.
# ---------------------------------------------------------------------------
echo ""
echo "=== T02: V-E1b task spec re-run is byte-identical (determinism) ==="

TASK_OUT_2="${TMP}/task-run2.txt"

bash "$SUT" task \
  --doc-set "$REP_DOC_SET" \
  --kb-dir  "$REP_KB_DIR" \
  > "$TASK_OUT_2" 2>/dev/null

if diff "$TASK_OUT_1" "$TASK_OUT_2" > /dev/null 2>&1; then
  pass "T02 V-E1b task spec re-run is byte-identical (determinism satisfied)"
else
  fail "T02 V-E1b task spec re-run differs between runs (determinism violated)"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- diff run1 vs run2 ---"
    diff "$TASK_OUT_1" "$TASK_OUT_2" || true
    echo "---"
  fi
fi

# ---------------------------------------------------------------------------
# T03: V-E2 -- Presence check over actback-pass-kb reports all expected
#              operational classes as PRESENT (scoped per the owning-table).
#
# The actback-pass-kb carries named first-class sections in every expected-owner
# doc. The check, scoped per the owning-table in concern-model.md, must report:
#   coding-standards.md Conventions => present
#   domain-glossary.md  Invariants  => present
#   schemas.md          Contracts   => present
#   tech-debt.md        Gotchas     => present
#
# (The doc-set TSV is the same as the representative-task fixture; it lists
#  coding-standards.md, domain-glossary.md, schemas.md, tech-debt.md.)
# ---------------------------------------------------------------------------
echo ""
echo "=== T03: V-E2 pass-kb presence check -- all expected classes present ==="

PASS_CHECK_OUT="${TMP}/pass-check.txt"

bash "$SUT" check \
  --doc-set "$REP_DOC_SET" \
  --kb-dir  "$PASS_KB_DIR" \
  > "$PASS_CHECK_OUT" 2>/dev/null

# coding-standards.md Conventions => present
row=$(grep -F "coding-standards.md" "$PASS_CHECK_OUT" | grep -F "Conventions" || true)
if echo "$row" | grep -qF "present"; then
  pass "T03a V-E2 pass-kb coding-standards.md Conventions => present"
else
  fail "T03a V-E2 pass-kb coding-standards.md Conventions expected 'present', got: '$row'"
  [[ "$VERBOSE" -eq 1 ]] && cat "$PASS_CHECK_OUT"
fi

# domain-glossary.md Invariants => present
row=$(grep -F "domain-glossary.md" "$PASS_CHECK_OUT" | grep -F "Invariants" || true)
if echo "$row" | grep -qF "present"; then
  pass "T03b V-E2 pass-kb domain-glossary.md Invariants => present"
else
  fail "T03b V-E2 pass-kb domain-glossary.md Invariants expected 'present', got: '$row'"
  [[ "$VERBOSE" -eq 1 ]] && cat "$PASS_CHECK_OUT"
fi

# schemas.md Contracts => present
row=$(grep -F "schemas.md" "$PASS_CHECK_OUT" | grep -F "Contracts" || true)
if echo "$row" | grep -qF "present"; then
  pass "T03c V-E2 pass-kb schemas.md Contracts => present"
else
  fail "T03c V-E2 pass-kb schemas.md Contracts expected 'present', got: '$row'"
  [[ "$VERBOSE" -eq 1 ]] && cat "$PASS_CHECK_OUT"
fi

# tech-debt.md Gotchas => present
row=$(grep -F "tech-debt.md" "$PASS_CHECK_OUT" | grep -F "Gotchas" || true)
if echo "$row" | grep -qF "present"; then
  pass "T03d V-E2 pass-kb tech-debt.md Gotchas => present"
else
  fail "T03d V-E2 pass-kb tech-debt.md Gotchas expected 'present', got: '$row'"
  [[ "$VERBOSE" -eq 1 ]] && cat "$PASS_CHECK_OUT"
fi

# Confirm NO "absent" rows appear in the pass-kb check output
if grep -qF "absent" "$PASS_CHECK_OUT" 2>/dev/null; then
  _absent_rows=$(grep -cF "absent" "$PASS_CHECK_OUT" 2>/dev/null || true)
  fail "T03e V-E2 pass-kb presence check has absent row(s) (expected 0 for the PASS shape; count=${_absent_rows})"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- pass-kb presence check output ---"
    cat "$PASS_CHECK_OUT"
    echo "---"
  fi
else
  pass "T03e V-E2 pass-kb presence check has zero absent rows (fully sufficient KB shape)"
fi

# ---------------------------------------------------------------------------
# T04: V-E3 -- Presence check over actback-fail-kb reports the same expected
#              classes as ABSENT (the buried/omitted shape).
#
# The actback-fail-kb carries the same docs but WITHOUT the named operational
# sections (guidance is buried in prose paragraphs). The check must report:
#   coding-standards.md Conventions => absent
#   domain-glossary.md  Invariants  => absent
#   schemas.md          Contracts   => absent
#   tech-debt.md        Gotchas     => absent
#
# This is the structural cause of an act-back sufficiency FAIL: the M6 reviewer
# cannot grep for these sections and must guess or reach for source.
# The M6 reviewer's judgment ("are these flags well-founded?") is runtime-anchored
# -- not asserted here. This suite asserts only the MECHANICAL structural absence.
# ---------------------------------------------------------------------------
echo ""
echo "=== T04: V-E3 fail-kb presence check -- expected classes reported absent ==="

FAIL_CHECK_OUT="${TMP}/fail-check.txt"

bash "$SUT" check \
  --doc-set "$REP_DOC_SET" \
  --kb-dir  "$FAIL_KB_DIR" \
  > "$FAIL_CHECK_OUT" 2>/dev/null

# coding-standards.md Conventions => absent
row=$(grep -F "coding-standards.md" "$FAIL_CHECK_OUT" | grep -F "Conventions" || true)
if echo "$row" | grep -qF "absent"; then
  pass "T04a V-E3 fail-kb coding-standards.md Conventions => absent (structural FAIL cause)"
else
  fail "T04a V-E3 fail-kb coding-standards.md Conventions expected 'absent', got: '$row'"
  [[ "$VERBOSE" -eq 1 ]] && cat "$FAIL_CHECK_OUT"
fi

# domain-glossary.md Invariants => absent
row=$(grep -F "domain-glossary.md" "$FAIL_CHECK_OUT" | grep -F "Invariants" || true)
if echo "$row" | grep -qF "absent"; then
  pass "T04b V-E3 fail-kb domain-glossary.md Invariants => absent"
else
  fail "T04b V-E3 fail-kb domain-glossary.md Invariants expected 'absent', got: '$row'"
  [[ "$VERBOSE" -eq 1 ]] && cat "$FAIL_CHECK_OUT"
fi

# schemas.md Contracts => absent
row=$(grep -F "schemas.md" "$FAIL_CHECK_OUT" | grep -F "Contracts" || true)
if echo "$row" | grep -qF "absent"; then
  pass "T04c V-E3 fail-kb schemas.md Contracts => absent"
else
  fail "T04c V-E3 fail-kb schemas.md Contracts expected 'absent', got: '$row'"
  [[ "$VERBOSE" -eq 1 ]] && cat "$FAIL_CHECK_OUT"
fi

# tech-debt.md Gotchas => absent
row=$(grep -F "tech-debt.md" "$FAIL_CHECK_OUT" | grep -F "Gotchas" || true)
if echo "$row" | grep -qF "absent"; then
  pass "T04d V-E3 fail-kb tech-debt.md Gotchas => absent"
else
  fail "T04d V-E3 fail-kb tech-debt.md Gotchas expected 'absent', got: '$row'"
  [[ "$VERBOSE" -eq 1 ]] && cat "$FAIL_CHECK_OUT"
fi

# Confirm NO "present" rows appear in the fail-kb check output
# (for the expected-owner docs only -- none of them carry named sections).
if grep -qF "present" "$FAIL_CHECK_OUT" 2>/dev/null; then
  _present_rows=$(grep -cF "present" "$FAIL_CHECK_OUT" 2>/dev/null || true)
  fail "T04e V-E3 fail-kb presence check has present row(s) (expected 0 for the FAIL shape; count=${_present_rows})"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- fail-kb presence check output ---"
    cat "$FAIL_CHECK_OUT"
    echo "---"
  fi
else
  pass "T04e V-E3 fail-kb presence check has zero present rows (fully insufficient KB shape)"
fi

# ---------------------------------------------------------------------------
# T05: V-E judgment boundary (documentation assertion).
#
# This assertion explicitly documents that the suite does NOT mechanically
# score M6 plan success or flag well-foundedness. The mechanical substrate
# asserted is V-E1/V-E2/V-E3 (T01-T04). The judgment half is runtime-anchored.
#
# Mechanically: confirm the task spec contains "Task shape: contract" (the
# representative task is well-formed for this fixture's doc-set profile).
# This is the ONLY judgment-substrate assertion here -- the task shape is
# deterministic (schema-driven heuristic, same TSV -> same shape). Whether
# the agent's plan using this spec actually succeeds is LLM judgment (M6
# clean-context reviewer at runtime), NOT asserted in CI.
# ---------------------------------------------------------------------------
echo ""
echo "=== T05: V-E boundary -- mechanical substrate only, judgment left runtime-anchored ==="

# Mechanical substrate: task spec declares the expected shape for this fixture.
if grep -qF "Task shape: contract" "$TASK_OUT_1" 2>/dev/null; then
  pass "T05 V-E boundary: task spec is well-formed (Task shape: contract); M6 plan-success and flag well-foundedness are LLM judgment -- NOT asserted here"
else
  fail "T05 V-E boundary: task spec does not declare 'Task shape: contract' -- representative task may not be well-formed for this fixture"
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo "--- task spec output ---"
    cat "$TASK_OUT_1"
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
