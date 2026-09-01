#!/usr/bin/env bash
# test-slice-requirements.sh -- unit tests for slice-requirements.sh.
#
# The script prints the slice of REQUIREMENTS.md that ONE task traces to, so a task
# execution grounds on what it implements instead of on the whole document. With the
# review loop scoped, per-task grounding is the largest remaining line in the cost
# model, and it is the one that scales with task count.
#
# What these assertions are really protecting: a slice is only safe if it is COMPLETE
# for what the task claims. Dropping a cited criterion would make a task look satisfied
# against criteria it never saw, which is worse than reading too much. So the suite
# checks inclusion at least as hard as exclusion.
#
# Usage: bash tests/canonical/test-slice-requirements.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

SCRIPT="${REPO_ROOT}/canonical/aid/scripts/execute/slice-requirements.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "== slice-requirements.sh tests =="

[[ -f "$SCRIPT" ]] || { echo "FATAL: script not found at $SCRIPT" >&2; exit 2; }

# --- fixture ---------------------------------------------------------------------
make_req() {
    cat > "$1/REQUIREMENTS.md" <<'EOF'
# Requirements

- **Name:** Fixture Work
- **Description:** A fixture for slicing.

## 1. Objective

Objective prose that no slice should carry.

## 5. Functional Requirements

- **FR-1** Something.
- **FR-2** Something else.

## 9. Acceptance Criteria

- **AC-1** First criterion, one line.
- **AC-2** Second criterion, which wraps
  onto a continuation line that must travel with it.
- **AC-3** Third criterion.
- **AC-10** Tenth criterion -- shares a prefix with AC-1.

## 10. Priority

Priority prose that no slice should carry.

## 11. Features

### Feature 001 — Alpha

- **Criteria:** AC-1

#### Description

Alpha's description.

### Feature 002 — Beta

- **Criteria:** AC-2, AC-3

#### Description

Beta's description.
EOF
}

make_task() {   # <work> <padded-id> <source-line>
    mkdir -p "$1/tasks/task-$2"
    printf '# task-%s\n\n**Type:** IMPLEMENT\n\n**Source:** %s\n\n**Depends on:** --\n' "$2" "$3" \
        > "$1/tasks/task-$2/DETAIL.md"
}

W="${TMP}/work-900"
mkdir -p "$W"
make_req "$W"
make_task "$W" 001 "feature-001-alpha -> delivery-001 -> AC-1"
make_task "$W" 002 "feature-002-beta -> delivery-001 -> AC-2, AC-3"
make_task "$W" 003 "feature-002-beta -> delivery-001"
make_task "$W" 004 "feature-001-alpha -> delivery-001 -> AC-10"

# --- SR01: the cited criterion is present ----------------------------------------
out="$(bash "$SCRIPT" "$W" task-001 2>&1)"
assert_exit_zero "$?" "SR01 slicing a well-formed task exits 0"
assert_output_contains "$out" "AC-1** First criterion" "SR02 the cited criterion is in the slice"

# --- SR03: everything NOT cited is absent ----------------------------------------
assert_output_not_contains "$out" "AC-3" "SR03a an uncited criterion is excluded"
assert_output_not_contains "$out" "Objective prose" "SR03b § 1 prose is excluded"
assert_output_not_contains "$out" "Priority prose" "SR03c § 10 prose is excluded"
assert_output_not_contains "$out" "Beta's description" "SR03d another feature's section is excluded"

# --- SR04: the identity block always travels -------------------------------------
# Without it the slice is an orphaned fragment: criteria with no statement of what the
# work is. Four lines, and they are what make a slice readable on its own.
assert_output_contains "$out" "**Name:** Fixture Work" "SR04 the identity block travels with every slice"

# --- SR05: prefix collision -- AC-1 must not drag in AC-10 -----------------------
# The ids are matched as whole tokens, not as substrings. A naive `grep AC-1` pulls
# AC-10, AC-11 and so on, which would silently WIDEN the slice -- the failure mode that
# looks like everything working.
assert_output_not_contains "$out" "Tenth criterion" "SR05 AC-1 does not match AC-10 by prefix"
out10="$(bash "$SCRIPT" "$W" 004 2>&1)"
assert_output_contains "$out10" "Tenth criterion" "SR06 AC-10 resolves to its own criterion"
assert_output_not_contains "$out10" "First criterion, one line" "SR07 AC-10 does not drag in AC-1"

# --- SR08: a wrapped criterion keeps its continuation line -----------------------
# Truncating at the first line would hand the task half a criterion while looking
# complete, which is the dangerous direction for a slice to be wrong in.
out2="$(bash "$SCRIPT" "$W" 002 2>&1)"
assert_output_contains "$out2" "onto a continuation line that must travel with it" \
    "SR08 a wrapped criterion keeps its continuation line"

# --- SR09: multiple citations all resolve ----------------------------------------
assert_output_contains "$out2" "Second criterion" "SR09a first of two cited criteria present"
assert_output_contains "$out2" "Third criterion" "SR09b second of two cited criteria present"
assert_output_contains "$out2" "Beta's description" "SR09c the task's own feature section is present"

# --- SR10: id listing --------------------------------------------------------------
ids="$(bash "$SCRIPT" "$W" 002 --list-ids 2>&1)"
assert_output_contains "$ids" "AC-2" "SR10a --list-ids reports the first id"
assert_output_contains "$ids" "AC-3" "SR10b --list-ids reports the second id"
assert_eq "$(printf '%s\n' "$ids" | grep -c .)" "2" "SR10c --list-ids reports exactly the cited ids"

# --- SR11: a task citing no criterion is an ERROR --------------------------------
# Not an empty slice. Silently returning the identity block alone is indistinguishable
# from correctly returning a small slice, and would ground the task on nothing while
# appearing to work.
bash "$SCRIPT" "$W" 003 >/dev/null 2>&1
assert_exit_eq "$?" 3 "SR11 a task citing no AC-N exits 3 rather than yielding an empty slice"

# --- SR12: argument handling ------------------------------------------------------
bash "$SCRIPT" "$W" 999 >/dev/null 2>&1
assert_exit_eq "$?" 2 "SR12a an absent task exits 2"
bash "$SCRIPT" "${TMP}/nope" 001 >/dev/null 2>&1
assert_exit_eq "$?" 2 "SR12b an absent work dir exits 2"
bash "$SCRIPT" "$W" >/dev/null 2>&1
assert_exit_eq "$?" 2 "SR12c a missing task id exits 2"

# Bare, padded and prefixed ids are all accepted -- callers pass whichever they hold,
# and rejecting one form pushes zero-padding into every caller.
for form in 1 001 task-001; do
    bash "$SCRIPT" "$W" "$form" >/dev/null 2>&1
    assert_exit_zero "$?" "SR13 task id form '${form}' is accepted"
done

# --- SR14: the nested layout ------------------------------------------------------
N="${TMP}/work-901"
mkdir -p "$N/deliveries/delivery-002/tasks/task-007"
make_req "$N"
printf '**Source:** feature-002-beta -> delivery-002 -> AC-3\n' \
    > "$N/deliveries/delivery-002/tasks/task-007/DETAIL.md"
outn="$(bash "$SCRIPT" "$N" 7 2>&1)"
assert_exit_zero "$?" "SR14a the nested deliveries/ layout resolves"
assert_output_contains "$outn" "Third criterion" "SR14b the nested task's criterion is sliced"

# --- SR15: the slice is materially smaller ---------------------------------------
# The whole point. Asserted as a ratio rather than a byte count, which moves whenever
# the fixture is edited.
full_b=$(wc -c < "$W/REQUIREMENTS.md")
slice_b=$(bash "$SCRIPT" "$W" 001 2>/dev/null | wc -c)
if (( slice_b * 2 < full_b )); then
    pass "SR15 a one-criterion slice is less than half the document (${slice_b} < ${full_b}/2)"
else
    fail "SR15 the slice must be materially smaller — got ${slice_b} of ${full_b}"
fi

# --- SR16: read-only ---------------------------------------------------------------
# A grounding helper that mutated the work would be a far worse bug than any it saves.
before="$(find "$W" -type f -exec sha256sum {} + | sort | sha256sum)"
bash "$SCRIPT" "$W" 001 >/dev/null 2>&1
bash "$SCRIPT" "$W" 002 --list-ids >/dev/null 2>&1
after="$(find "$W" -type f -exec sha256sum {} + | sort | sha256sum)"
assert_eq "$after" "$before" "SR16 the script writes nothing"

echo ""
test_summary
exit $?
