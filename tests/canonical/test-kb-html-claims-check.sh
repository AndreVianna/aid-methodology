#!/usr/bin/env bash
# test-kb-html-claims-check.sh -- canonical test suite for kb-html-claims-check.sh.
#
# Three fixtures, one per outcome the gate can reach:
#   KH01  a tour whose project claims CONTRADICT the KB   -> finding, exit 1
#   KH02  a tour whose project claims AGREE with the KB   -> no finding, exit 0
#   KH03  a tour from which NO claim can be extracted     -> exit 1, not a quiet pass
#
# KH03 is the one worth stating plainly. A check that matches nothing produces
# output indistinguishable from a clean bill of health, so "extracted zero
# claims" must be a failure. Without KH03 the suite would pass against a script
# whose extractors had silently stopped matching.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-kb-html-claims-check.sh =="

CHECK="${REPO_ROOT}/canonical/aid/scripts/summarize/kb-html-claims-check.sh"
TEMPLATES="${REPO_ROOT}/canonical/aid/templates"

if [[ ! -f "$CHECK" ]]; then
    fail "setup -- check script not found at $CHECK"
    test_summary
    exit $?
fi

FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT

# ---------------------------------------------------------------------------
# A self-contained KB the fixtures are judged against. The suite builds its own
# corpus rather than pointing at .aid/knowledge, so a real KB edit can never
# turn this suite red or green by accident.
# ---------------------------------------------------------------------------
mkdir -p "${FIX}/kb"
cat > "${FIX}/kb/architecture.md" <<'KB'
---
kb-category: primary
---
# Architecture

Each work tracks its lifecycle in STATE.yml. A delivery's STATE.yml carries the
gate grade. Task state lives in a per-task STATE.yml.
KB

run_check() {
    # $1 = html path; remaining args passed through
    local html="$1"; shift
    bash "$CHECK" "$html" --kb-dir "${FIX}/kb" --template-dir "$TEMPLATES" "$@" 2>&1
}

# ===========================================================================
# KH01  Claims that CONTRADICT the KB -> a finding, exit 1
#
# The tour names STATE.md throughout and STATE.yml never, while the canonical
# template is work-state-template.yml. That is the rename-not-followed case.
# ===========================================================================
cat > "${FIX}/contradicts.html" <<'HTML'
<html><body>
<h1>Project tour</h1>
<p>Every work records its lifecycle in STATE.md.</p>
<p>A delivery's STATE.md carries the gate grade, and each task has its own STATE.md.</p>
</body></html>
HTML

out=$(run_check "${FIX}/contradicts.html"); code=$?
assert_eq "$code" "1" "KH01 contradicting tour -- exit 1"
assert_output_contains "$out" "STATE.md"    "KH01 contradicting tour -- names the stale artifact"
assert_output_contains "$out" "STATE.yml"   "KH01 contradicting tour -- names the current artifact"
assert_output_contains "$out" "[FAIL]"      "KH01 contradicting tour -- reports a finding"

# ===========================================================================
# KH02  Claims that AGREE with the KB -> no finding, exit 0
#
# Same shape as KH01 with the current spelling. If this fixture also produced a
# finding, the check would be flagging correct tours and its output would be
# worthless.
# ===========================================================================
cat > "${FIX}/agrees.html" <<'HTML'
<html><body>
<h1>Project tour</h1>
<p>Every work records its lifecycle in STATE.yml.</p>
<p>A delivery's STATE.yml carries the gate grade, and each task has its own STATE.yml.</p>
<p>Grade: A+</p>
</body></html>
HTML

out=$(run_check "${FIX}/agrees.html"); code=$?
assert_eq "$code" "0" "KH02 agreeing tour -- exit 0"
assert_output_not_contains "$out" "[FAIL]" "KH02 agreeing tour -- no finding"
assert_output_contains "$out" "PASS"       "KH02 agreeing tour -- reports PASS"

# ===========================================================================
# KH03  NO claim extractable -> exit 1, never a quiet pass
# ===========================================================================
cat > "${FIX}/empty.html" <<'HTML'
<html><body><p>Nothing here resembles a project claim.</p></body></html>
HTML

out=$(run_check "${FIX}/empty.html"); code=$?
assert_eq "$code" "1" "KH03 zero-claim tour -- exit 1, not a quiet pass"
assert_output_contains "$out" "zero claims" "KH03 zero-claim tour -- says why it failed"
assert_output_not_contains "$out" "PASS"    "KH03 zero-claim tour -- does not report PASS"

# ===========================================================================
# KH04  A missing direction oracle is loud, not a skipped class.
#
# Claim class 1 needs the canonical templates to know which spelling is current.
# If that directory cannot be found the class has no oracle, and skipping it
# silently would turn KH01's fixture into a pass.
# ===========================================================================
out=$(bash "$CHECK" "${FIX}/contradicts.html" --kb-dir "${FIX}/kb" \
        --template-dir "${FIX}/no-such-dir" 2>&1); code=$?
assert_eq "$code" "2" "KH04 missing template dir -- exit 2"
assert_output_contains "$out" "template dir not found" "KH04 missing template dir -- says so"

# ===========================================================================
# KH05  Determinism -- two consecutive runs are byte-identical.
# ===========================================================================
a=$(run_check "${FIX}/contradicts.html")
b=$(run_check "${FIX}/contradicts.html")
assert_eq "$a" "$b" "KH05 two consecutive runs are byte-identical"

c=$(LC_ALL=C run_check "${FIX}/contradicts.html")
d=$(LC_ALL=en_US.UTF-8 run_check "${FIX}/contradicts.html")
assert_eq "$c" "$d" "KH05 output does not depend on locale"

rm -rf "$FIX"
trap - EXIT

echo
test_summary
exit $?
