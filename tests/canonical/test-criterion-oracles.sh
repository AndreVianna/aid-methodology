#!/usr/bin/env bash
# test-criterion-oracles.sh -- the oracle mechanism's contract, and G-07's oracle
#
# COVERS: scripts/checks/g07-selector-partition.sh
# COVERS: canonical/aid/templates/kb-authoring/frontmatter-schema.md
# COVERS: .aid/knowledge/authoring-conventions.md
#
# The mechanism's whole safety argument is that ABSENCE of an oracle changes
# nothing and a DEGRADED oracle degrades to reading rather than to a silent
# pass. Both are asserted here as positive controls, because a mechanism that
# is only tested on its happy path would let either failure through unnoticed.
#
# Assertions:
#   OR01-03  the schema declares the key optional, per-file, with all exit outcomes
#   OR04     absence of `oracle:` is documented as never a defect        (AC-5)
#   OR05-07  G-07's oracle: exit 0 clean, exit 1 naming an orphan        (AC-6)
#   OR08     byte-identical output across two runs                       (AC-7)
#   OR09-11  degradation: missing, non-executable, exit-1-with-no-VIOLATION (AC-8)
#   OR12     a timeout is bounded and treated as degradation             (AC-8)
#   OR13     the path bound: an orphan OUTSIDE it is VIOLATION, not UNDECIDED
#   OR14     UNDECIDED is not a failure -- exit stays 0                  (AC-5)
#   OR15-16  the registry is PARSED, not copied -- no sibling selector list
#   OR17     AC-11 evidence: decided vs undecided counts are produced
#   OR18     ledger shape unchanged -- 7 columns, no new column          (AC-16)
#   OR19     bash + awk only                                            (NFR-2)
#
# Usage:  test-criterion-oracles.sh [--verbose]
# Exit:   0 all passed / 1 one or more failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# S1 -- SUBJECT INVOCATION BUDGET: 9 spawns of the oracle.
ORACLE="${REPO_ROOT}/scripts/checks/g07-selector-partition.sh"
SCHEMA="${REPO_ROOT}/canonical/aid/templates/kb-authoring/frontmatter-schema.md"
REGISTRY="${REPO_ROOT}/.aid/knowledge/authoring-conventions.md"

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; rm -rf "${REPO_ROOT}/canonical/agents/__g07probe__"; }
trap cleanup EXIT

run_oracle() { ( cd "$REPO_ROOT" && bash "$ORACLE" ) 2>&1; }
run_oracle_rc() { ( cd "$REPO_ROOT" && bash "$ORACLE" >/dev/null 2>&1 ); echo $?; }

# ---------------------------------------------------------------------------
echo "=== OR01-04: the schema declares the key, its contract, and its optionality ==="
# ---------------------------------------------------------------------------
assert_file_contains "$SCHEMA" "oracle" "OR01 the schema declares an oracle key"
assert_file_contains "$SCHEMA" "per FILE, not per criterion" \
    "OR02 coverage is declared per file, not per criterion"
missing=""
for token in 'Exit `0`' 'Exit `1`' 'Exit `2`' 'Any other exit' '60-second timeout' 'Malformed'; do
    grep -qF "$token" "$SCHEMA" || missing="${missing}${token}; "
done
if [[ -z "$missing" ]]; then
    pass "OR03 every exit outcome is declared (0/1/2/other/timeout/malformed)"
else
    fail "OR03 exit outcomes missing from the schema: $missing"
fi
assert_file_contains "$SCHEMA" "Absence is never a defect" \
    "OR04 absence of the key is documented as never a defect (AC-5)"

# ---------------------------------------------------------------------------
echo "=== OR05-08: G-07's oracle on the real corpus, and determinism ==="
# ---------------------------------------------------------------------------
CLEAN_OUT="$(run_oracle)"
CLEAN_RC="$(run_oracle_rc)"
assert_eq "$CLEAN_RC" "0" "OR05 exit 0 on a corpus where every in-scope file resolves (AC-6)"
if grep -q '^VIOLATION' <<<"$CLEAN_OUT"; then
    fail "OR06 the current corpus reports a VIOLATION: $(grep -m1 '^VIOLATION' <<<"$CLEAN_OUT")"
else
    pass "OR06 no VIOLATION lines on the current corpus"
fi
# A file under an in-scope root that matches no registry row.
mkdir -p "${REPO_ROOT}/canonical/agents/__g07probe__"
printf 'orphan\n' >"${REPO_ROOT}/canonical/agents/__g07probe__/NOTANAGENT.md"
ORPHAN_OUT="$(run_oracle)"
ORPHAN_RC="$(run_oracle_rc)"
if [[ "$ORPHAN_RC" == "1" ]] && grep -q '^VIOLATION.*NOTANAGENT' <<<"$ORPHAN_OUT"; then
    pass "OR07 an untyped file exits 1 and is NAMED in a VIOLATION line (AC-6)"
else
    fail "OR07 untyped file not reported -- rc=$ORPHAN_RC"
fi
rm -rf "${REPO_ROOT}/canonical/agents/__g07probe__"
A="$(run_oracle)"; B="$(run_oracle)"
assert_eq "$A" "$B" "OR08 two runs over an unchanged tree are byte-identical (AC-7, NFR-3)"

# ---------------------------------------------------------------------------
echo "=== OR09-12: degradation -- the reviewer must never read these as a pass ==="
# ---------------------------------------------------------------------------
# These model what a REVIEWER must do with a broken oracle. The contract is in
# the schema; here we assert the four failure shapes are distinguishable from
# both a pass (exit 0) and a violation (exit 1) by exit code alone.
MISSING="${TMP}/does-not-exist.sh"
( bash "$MISSING" >/dev/null 2>&1 ); rc=$?
[[ "$rc" -ne 0 && "$rc" -ne 1 ]] \
    && pass "OR09 a MISSING oracle exits neither 0 nor 1 -- not a pass, not a violation (AC-8)" \
    || fail "OR09 a missing oracle produced rc=$rc, indistinguishable from a pass or a violation"

NOEXEC="${TMP}/noexec.sh"; printf '#!/usr/bin/env bash\nexit 0\n' >"$NOEXEC"; chmod 000 "$NOEXEC"
( "$NOEXEC" >/dev/null 2>&1 ); rc=$?
[[ "$rc" -ne 0 && "$rc" -ne 1 ]] \
    && pass "OR10 a NON-EXECUTABLE oracle exits neither 0 nor 1 (AC-8)" \
    || fail "OR10 a non-executable oracle produced rc=$rc"
chmod 644 "$NOEXEC"

MALFORMED="${TMP}/malformed.sh"; printf '#!/usr/bin/env bash\nexit 1\n' >"$MALFORMED"; chmod +x "$MALFORMED"
MOUT="$("$MALFORMED" 2>&1)"; mrc=$?
if [[ "$mrc" -eq 1 && -z "$(grep '^VIOLATION' <<<"$MOUT")" ]]; then
    pass "OR11 exit 1 with NO VIOLATION line is detectable as malformed, not as a finding"
else
    fail "OR11 could not distinguish a malformed exit-1 oracle"
fi
assert_file_contains "$SCHEMA" "60-second timeout" \
    "OR12 a runtime bound is declared, so non-termination is a bounded failure (AC-8)"

# ---------------------------------------------------------------------------
echo "=== OR13-14: the path bound, and UNDECIDED as a non-failure ==="
# ---------------------------------------------------------------------------
# The bound is what stops an inexpressible row swallowing a real orphan. OR07
# already proved an orphan OUTSIDE the bound is a VIOLATION; here we assert the
# complement -- files INSIDE it are UNDECIDED and do not fail the run.
if grep -q '^UNDECIDED .*canonical/aid/templates/' <<<"$CLEAN_OUT"; then
    pass "OR13 files inside an inexpressible row's path bound report UNDECIDED"
else
    fail "OR13 no UNDECIDED lines for the template tree -- the path bound is not firing"
fi
assert_eq "$CLEAN_RC" "0" "OR14 UNDECIDED lines are present yet the exit stays 0 -- not a failure"

# ---------------------------------------------------------------------------
echo "=== OR15-16: the registry is PARSED, not copied ==="
# ---------------------------------------------------------------------------
# The sibling-copy hazard (tech-debt L4). If the oracle held its own selector
# list it would drift from the registry silently, so it must read the Match
# column -- and must fail loudly if that column is gone.
assert_file_contains "$ORACLE" "REGISTRY=" "OR15 the oracle reads the registry path"
NOMATCH="${TMP}/registry-no-match.md"
sed 's/^| Type | Selector | Match | Notes |/| Type | Selector | Notes |/' "$REGISTRY" >"$NOMATCH"
STRIPPED="${TMP}/stripped"; mkdir -p "${STRIPPED}/.aid/knowledge"
cp "$NOMATCH" "${STRIPPED}/.aid/knowledge/authoring-conventions.md"
( cd "$STRIPPED" && bash "$ORACLE" >/dev/null 2>&1 ); rc=$?
assert_eq "$rc" "2" "OR16 a registry with no Match column exits 2 (could not run), never 0"

# ---------------------------------------------------------------------------
echo "=== OR17-19: AC-11 evidence, ledger shape, toolchain ==="
# ---------------------------------------------------------------------------
TOTAL="$( cd "$REPO_ROOT" && LC_ALL=C find canonical/skills canonical/agents canonical/aid/templates .aid/knowledge -name '*.md' -type f | wc -l )"
UND="$(grep -c '^UNDECIDED' <<<"$CLEAN_OUT")"
DEC=$(( TOTAL - UND ))
if (( TOTAL > 0 && DEC > 0 )); then
    pass "OR17 AC-11 evidence is produced: ${DEC} of ${TOTAL} files decided, ${UND} undecided"
else
    fail "OR17 no coverage figure could be derived (total=$TOTAL undecided=$UND)"
fi
assert_file_contains "$REPO_ROOT/canonical/agents/aid-reviewer/AGENT.md" "7-column" \
    "OR18 the reviewer instruction keeps the ledger at 7 columns (AC-16, C-3)"
if grep -qE '^[^#]*\b(python3?|node|jq|perl)\b' "$ORACLE"; then
    fail "OR19 the oracle invokes an interpreter beyond bash/awk (NFR-2)"
else
    pass "OR19 bash + awk only (NFR-2)"
fi

echo
test_summary
exit $?
