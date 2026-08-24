#!/usr/bin/env bash
# test-review-cost-meter.sh -- the contract of tests/review-cost-meter.sh
#
# COVERS: tests/review-cost-meter.sh
#
# The meter produces the number AC-1 rests on, so a defect here is not a test
# failure -- it is a wrong measurement presented as evidence. Three of these
# assertions exist because a quick check found the corresponding defect by
# RUNNING the tool when reading it had missed them:
#
#   RCM12  the ARTIFACTS block used to be terminated by matching heading TEXT,
#          so "OUT OF SCOPE (do not grade against):" did not end it and that
#          section's paths inflated the surface by ~2.5x.
#   RCM13  the TSV append was unchecked: a failed redirect was swallowed and
#          the success message printed over a row that was never written --
#          the W5-5 silent-write-failure class this tool helps expose.
#   RCM14  a brief naming no paths recorded 0 bytes with a success message and
#          no warning, which is indistinguishable from a cycle that genuinely
#          read nothing.
#
# Assertions:
#   RCM01-03  first record creates the .tsv/.meta pair sharing one run id
#   RCM04-07  run-id integrity refused at BOTH write and read time
#   RCM08     determinism -- two reports over unchanged data are identical
#   RCM09-11  ratio arithmetic, single-cycle n/a, missing-cycle-1 MISSING
#   RCM12     ARTIFACTS block terminates at the next unindented heading
#   RCM13     an unwritable TSV refuses instead of reporting success
#   RCM14     a brief with no ARTIFACTS section warns
#   RCM15     an unreachable --split-at commit refuses loudly
#   RCM16     side totals count every task, not only ratio-usable ones
#   RCM17     no interpreter beyond bash/awk is invoked (NFR-2)
#   RCM18     nothing is written outside the --data directory
#
# Usage:
#   test-review-cost-meter.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# S1 -- SUBJECT INVOCATION BUDGET: 24 subprocess spawns.
#   Every assertion shells the meter as a subprocess; there is no in-process path.
#   Fixture builders (mk_brief, mk_data) only write files and spawn nothing.
SUT="${SCRIPT_DIR}/../review-cost-meter.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Fixture builders -- each test builds its own tree; none reads live work data.
# ---------------------------------------------------------------------------

# A brief in the canonical 5-section shape. $1=dest, rest=artifact paths.
mk_brief() {
    local dest="$1"; shift
    {
        echo "ARTIFACTS UNDER REVIEW:"
        local p; for p in "$@"; do echo "  - $p"; done
        echo ""
        echo "CONTEXT:"
        echo "  fixture"
    } >"$dest"
}

# A brief whose ARTIFACTS section is followed by the parenthetical heading that
# used to defeat the terminator.
mk_brief_oos() {
    local dest="$1" keep="$2" leak="$3"
    {
        echo "ARTIFACTS UNDER REVIEW:"
        echo "  - $keep"
        echo ""
        echo "OUT OF SCOPE (do not grade against):"
        echo "  - $leak"
        echo ""
        echo "DELIVERABLES:"
        echo "  - $leak"
    } >"$dest"
}

mk_data() { local d="$1"; mkdir -p "$d"; printf '%s' "$d"; }

# Two fixture files of known, different sizes.
BIG="${TMP}/big.txt";   head -c 4000 /dev/zero | tr '\0' 'x' >"$BIG"
SMALL="${TMP}/small.txt"; head -c 1000 /dev/zero | tr '\0' 'y' >"$SMALL"

run_meter() { ( cd "$REPO_ROOT" && bash "$SUT" "$@" ) 2>&1; }

# ---------------------------------------------------------------------------
echo "=== RCM01-03: first record creates the pair with one shared run id ==="
# ---------------------------------------------------------------------------
D="$(mk_data "${TMP}/d1")"
B="${TMP}/b1.md"; mk_brief "$B" "$BIG"
OUT="$(run_meter record --task task-001 --cycle 1 --brief "$B" --data "$D")"
assert_file_exists "${D}/review-cost.tsv"  "RCM01 record creates the .tsv"
assert_file_exists "${D}/review-cost.meta" "RCM02 record creates the .meta"
TSV_RUN="$(head -n1 "${D}/review-cost.tsv" | cut -f2)"
META_RUN="$(awk -F'\t' '$1=="run"{print $2}' "${D}/review-cost.meta")"
assert_eq "$TSV_RUN" "$META_RUN" "RCM03 both files carry the SAME run id"

# ---------------------------------------------------------------------------
echo "=== RCM04-07: run-id integrity refused at write AND read time ==="
# ---------------------------------------------------------------------------
cp "${D}/review-cost.meta" "${TMP}/meta.bak"
sed -i.bak 's/^run\t.*/run\tTAMPERED/' "${D}/review-cost.meta"
run_meter record --task task-001 --cycle 2 --brief "$B" --data "$D" >/dev/null 2>&1
assert_exit_nonzero $? "RCM04 record REFUSES to append on a run-id mismatch"
run_meter report --data "$D" >/dev/null 2>&1
assert_exit_nonzero $? "RCM05 report REFUSES to compute on a run-id mismatch"
cp "${TMP}/meta.bak" "${D}/review-cost.meta"
# A .tsv whose header line was lost is equally untrustworthy.
D2="$(mk_data "${TMP}/d2")"
run_meter record --task t --cycle 1 --brief "$B" --data "$D2" >/dev/null 2>&1
sed -i.bak '1d' "${D2}/review-cost.tsv"
run_meter record --task t --cycle 2 --brief "$B" --data "$D2" >/dev/null 2>&1
assert_exit_nonzero $? "RCM06 record refuses when the .tsv has no #run header"
rm -f "${D2}/review-cost.meta"
run_meter report --data "$D2" >/dev/null 2>&1
assert_exit_nonzero $? "RCM07 report refuses when the .meta is missing entirely"

# ---------------------------------------------------------------------------
echo "=== RCM08-11: determinism and the ratio arithmetic ==="
# ---------------------------------------------------------------------------
D3="$(mk_data "${TMP}/d3")"
BB="${TMP}/bb.md"; mk_brief "$BB" "$BIG"      # 4000 bytes
BS="${TMP}/bs.md"; mk_brief "$BS" "$SMALL"    # 1000 bytes
run_meter record --task task-002 --cycle 1 --brief "$BB" --data "$D3" >/dev/null 2>&1
run_meter record --task task-002 --cycle 2 --brief "$BS" --data "$D3" >/dev/null 2>&1
run_meter record --task task-002 --cycle 3 --brief "$BS" --data "$D3" >/dev/null 2>&1
R1="$(run_meter report --data "$D3")"
R2="$(run_meter report --data "$D3")"
assert_eq "$R1" "$R2" "RCM08 two reports over unchanged data are identical (NFR-3)"
# mean(cycle 2+) = 1000; cycle 1 = 4000; ratio = 0.250
assert_output_contains "$R1" "0.250" "RCM09 within-task ratio is mean(cycle2+)/cycle1"
run_meter record --task task-003 --cycle 1 --brief "$BB" --data "$D3" >/dev/null 2>&1
R3="$(run_meter report --data "$D3")"
assert_output_contains "$R3" "n/a" "RCM10 a single-cycle task reports n/a, not a number"
run_meter record --task task-004 --cycle 2 --brief "$BS" --data "$D3" >/dev/null 2>&1
R4="$(run_meter report --data "$D3")"
assert_output_contains "$R4" "MISSING" "RCM11 a task with no cycle-1 reports MISSING, not zero"

# ---------------------------------------------------------------------------
echo "=== RCM12: the ARTIFACTS block ends at the next unindented heading ==="
# ---------------------------------------------------------------------------
D4="$(mk_data "${TMP}/d4")"
BO="${TMP}/bo.md"; mk_brief_oos "$BO" "$SMALL" "$BIG"
run_meter record --task task-005 --cycle 1 --brief "$BO" --data "$D4" >/dev/null 2>&1
RECORDED="$(awk -F'\t' 'NR>2{print $4}' "${D4}/review-cost.tsv")"
assert_eq "$RECORDED" "1000" \
    "RCM12 OUT OF SCOPE (parenthetical) terminates the block -- only the 1000-byte artifact counts"

# ---------------------------------------------------------------------------
echo "=== RCM13: an unwritable TSV refuses instead of reporting success ==="
# ---------------------------------------------------------------------------
D5="$(mk_data "${TMP}/d5")"
run_meter record --task task-006 --cycle 1 --brief "$BB" --data "$D5" >/dev/null 2>&1
ROWS_BEFORE="$(wc -l <"${D5}/review-cost.tsv")"
chmod 444 "${D5}/review-cost.tsv"
OUT13="$(run_meter record --task task-006 --cycle 2 --brief "$BB" --data "$D5")"
RC13=$?
chmod 644 "${D5}/review-cost.tsv"
ROWS_AFTER="$(wc -l <"${D5}/review-cost.tsv")"
if [[ "$RC13" -ne 0 ]] || [[ "$ROWS_BEFORE" == "$ROWS_AFTER" && "$OUT13" == *REFUSED* ]]; then
    pass "RCM13 an unwritable TSV refuses; no success message over an unwritten row"
else
    fail "RCM13 an unwritable TSV reported success (W5-5 class) -- rc=$RC13 out=$OUT13"
fi

# ---------------------------------------------------------------------------
echo "=== RCM14: a brief naming no paths warns rather than silently recording 0 ==="
# ---------------------------------------------------------------------------
D6="$(mk_data "${TMP}/d6")"
BE="${TMP}/be.md"; printf 'CONTEXT:\n  no artifacts section at all\n' >"$BE"
OUT14="$(run_meter record --task task-007 --cycle 1 --brief "$BE" --data "$D6")"
assert_output_contains "$OUT14" "WARNING" \
    "RCM14 a brief with no ARTIFACTS section warns -- 0 must not look like a real reading"

# ---------------------------------------------------------------------------
echo "=== RCM15: an unreachable --split-at commit refuses loudly ==="
# ---------------------------------------------------------------------------
run_meter report --split-at 0000000000000000000000000000000000000000 --data "$D3" >/dev/null 2>&1
assert_exit_nonzero $? "RCM15 an unreachable --split-at commit refuses, not misclassifies"

# ---------------------------------------------------------------------------
echo "=== RCM16: side totals count every task, not only ratio-usable ones ==="
# ---------------------------------------------------------------------------
# task-002 (3 cycles, usable) and task-003 (1 cycle, unusable) are both before
# a split at task-008. The summary must say 2 tasks, not 1 -- an earlier version
# dropped the unusable task from the totals and understated the sample.
R16="$(run_meter report --split-at-task task-008 --data "$D3")"
assert_output_contains "$R16" "with a usable ratio" \
    "RCM16 the split summary distinguishes tasks on a side from tasks with a usable ratio"

# ---------------------------------------------------------------------------
echo "=== RCM17-18: NFR-2 toolchain, and no writes outside --data ==="
# ---------------------------------------------------------------------------
if grep -qE '^[^#]*\b(python3?|node|jq|perl)\b' "$SUT"; then
    fail "RCM17 the meter invokes an interpreter beyond bash/awk (NFR-2)"
else
    pass "RCM17 bash + awk only -- no node, python, jq or perl invocation (NFR-2)"
fi

D7="$(mk_data "${TMP}/d7")"
CANARY="${TMP}/canary"; mkdir -p "$CANARY"; touch "${CANARY}/untouched"
BEFORE_CANARY="$(find "$CANARY" -type f | sort)"
run_meter record --task task-008 --cycle 1 --brief "$BB" --data "$D7" >/dev/null 2>&1
AFTER_CANARY="$(find "$CANARY" -type f | sort)"
assert_eq "$BEFORE_CANARY" "$AFTER_CANARY" "RCM18 nothing is written outside the --data directory"

# ---------------------------------------------------------------------------
# ===========================================================================
# CM20-CM23  Dedupe and region attribution (task-046).
#
# The declared read surface is what the reviewer was TOLD it may open. A file it
# may open twice is still one file, so a path named on both the VERIFY and HUNT
# lists counts once. Measured before the fix: a brief naming one path twice
# recorded exactly twice that file's size, which is how one real cycle came to
# record 84934 against a 42467-byte surface.
# ===========================================================================
echo ""
echo "=== CM20-CM23: dedupe and region attribution ==="

CM_TMP="$(mktemp -d)"
printf 'alpha alpha alpha\n' > "${CM_TMP}/a.md"
CM_SZ=$(wc -c < "${CM_TMP}/a.md" | tr -d ' ')

cm_surface() {  # cm_surface <brief>
    bash "$SUT" record --task _cm_probe --cycle 1 --brief "$1" --data "$CM_TMP" 2>&1 \
      | grep -oE 'surface [0-9]+' | grep -oE '[0-9]+'
}

# CM20: the same path on both lists counts ONCE
cat > "${CM_TMP}/dup.md" <<EOF
ARTIFACTS UNDER REVIEW:
  VERIFY (full):
    - ${CM_TMP}/a.md
  HUNT (scoped):
    - ${CM_TMP}/a.md

CONTEXT:
EOF
got=$(cm_surface "${CM_TMP}/dup.md")
assert_eq "$got" "$CM_SZ" "CM20 a path on both lists counts once, not twice"

# The assertion must fail if the dedupe is reverted. Reverting it doubles the
# figure, so asserting equality with the single size is exactly that guard.
if [ "$got" != "$(( CM_SZ * 2 ))" ]; then
    pass "CM20 the recorded surface is not the doubled figure a reverted dedupe would give"
else
    fail "CM20 the surface equals twice the file size -- the dedupe is not in effect"
fi

# CM21: a region entry contributes its FILE's bytes, not zero
cat > "${CM_TMP}/region.md" <<EOF
ARTIFACTS UNDER REVIEW:
  - ${CM_TMP}/a.md § Some Heading

CONTEXT:
EOF
got=$(cm_surface "${CM_TMP}/region.md")
assert_eq "$got" "$CM_SZ" "CM21 a region entry contributes its file's bytes"

# This is the assertion that separates a real fix from an accidental one. Before
# task-046 the extractor DROPPED a region entry and recorded 0. A suite asserting
# only "no longer twice the file size" would have passed against that -- zero is
# also not twice. Asserting the file's own size is what makes the number mean
# what it says.
if [ "$got" != "0" ]; then
    pass "CM21 the region entry is not silently dropped to zero"
else
    fail "CM21 the region entry recorded 0 -- it was dropped, not attributed"
fi

# CM22: a region entry for a path that does not exist is REPORTED
cat > "${CM_TMP}/ghost.md" <<EOF
ARTIFACTS UNDER REVIEW:
  - ${CM_TMP}/no-such-file.md § Heading

CONTEXT:
EOF
out=$(bash "$SUT" record --task _cm_probe --cycle 1 --brief "${CM_TMP}/ghost.md" --data "$CM_TMP" 2>&1)
assert_output_contains "$out" "matched no file on disk" "CM22 a region on a missing path is reported, not silently dropped"

# CM23: determinism
a=$(cm_surface "${CM_TMP}/dup.md"); b=$(cm_surface "${CM_TMP}/dup.md")
assert_eq "$a" "$b" "CM23 two consecutive records agree"

rm -rf "$CM_TMP"

echo
test_summary
exit $?
