#!/usr/bin/env bash
# test-deferred-tests.sh - Feature 002 deferred-tests list (section 8, groups DT-01 and DT-02).
#
# COVERS: tests/conversation/deferred.tsv
# COVERS: tests/conversation/samples/
# COVERS: canonical/skills/
#
#   DT-01  every row has a criterion (covers) and a waiting_for; a sample row names an existing
#          file under tests/conversation/samples/; a skill: row matches at least one folder
#          under canonical/skills/
#   DT-02  with AID_RELEASE_CHECK=1 the list must be empty
#
# The list is tests/conversation/deferred.tsv (tab-separated; header: test, covers, waiting_for,
# needs). A row's test is samples/<folder>/<id> or skill:<name or glob>.
#
# Usage:
#   bash test-deferred-tests.sh [-v] [DT-01|DT-02]     # a group name runs that group only
# Exit codes: 0 all pass / 1 any fail / 2 bad usage.

set -uo pipefail

VERBOSE=0
GROUP=""
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        DT-0[12]) GROUP="$arg" ;;
        *) echo "usage: $0 [-v] [DT-01|DT-02]" >&2; exit 2 ;;
    esac
done

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

DEFERRED_TSV="tests/conversation/deferred.tsv"
SAMPLES_DIR="tests/conversation/samples"
SKILLS_DIR="canonical/skills"
HEADER=$'test\tcovers\twaiting_for\tneeds'

wants() { [[ -z "$GROUP" || "$GROUP" == "$1" ]]; }

G_NAME=""; G_FAIL0=0; G_PASS0=0
group_begin() {
    G_NAME="$1"; G_FAIL0=$FAIL; G_PASS0=$PASS
    echo "=== $1 ==="
}
group_end() {
    local f=$((FAIL - G_FAIL0)) p=$((PASS - G_PASS0))
    if [[ $f -eq 0 ]]; then
        echo "  -> $G_NAME: all $p check(s) passed"
    else
        echo "  -> $G_NAME: $f failed, $p passed"
    fi
}

# Number of data rows (every non-blank line after the header).
row_count() {
    [[ -f "$DEFERRED_TSV" ]] || { echo 0; return; }
    tail -n +2 "$DEFERRED_TSV" | tr -d '\r' | grep -c -v '^[[:space:]]*$' || true
}

# ---------------------------------------------------------------------------
# DT-01: every row is well formed and names what it waits for.
# ---------------------------------------------------------------------------
run_dt01() {
    group_begin "DT-01 rows of $DEFERRED_TSV"
    if [[ ! -f "$DEFERRED_TSV" ]]; then
        fail "DT-01 $DEFERRED_TSV is missing"
        group_end
        return
    fi

    local header line_no=0 line ntab test covers waiting needs rest
    local samples=0 skills=0 d matched
    header=$(head -n 1 "$DEFERRED_TSV" | tr -d '\r')
    if [[ "$header" == "$HEADER" ]]; then
        pass "DT-01 header is test, covers, waiting_for, needs"
    else
        fail "DT-01 header is '$header', expected 'test<TAB>covers<TAB>waiting_for<TAB>needs'"
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        line_no=$((line_no + 1))
        [[ $line_no -eq 1 ]] && continue
        line=${line%$'\r'}
        [[ -z "${line//[[:space:]]/}" ]] && continue

        ntab=$(printf '%s' "$line" | tr -cd '\t' | wc -c)
        if [[ $ntab -ne 3 ]]; then
            fail "DT-01 line $line_no has $((ntab + 1)) column(s), expected 4 (test, covers, waiting_for, needs)"
            continue
        fi
        test=${line%%$'\t'*}; rest=${line#*$'\t'}
        covers=${rest%%$'\t'*}; rest=${rest#*$'\t'}
        waiting=${rest%%$'\t'*}; needs=${rest#*$'\t'}

        if [[ -z "${covers//[[:space:]]/}" ]]; then
            fail "DT-01 row '$test' has no criterion (covers)"
        fi
        if [[ -z "${waiting//[[:space:]]/}" ]]; then
            fail "DT-01 row '$test' has no waiting_for"
        fi

        case "$test" in
            samples/*)
                samples=$((samples + 1))
                if [[ -f "$SAMPLES_DIR/${test#samples/}.md" ]]; then
                    pass "DT-01 sample $test names an existing file"
                else
                    fail "DT-01 sample row '$test' names a missing file $SAMPLES_DIR/${test#samples/}.md"
                fi
                ;;
            skill:?*)
                skills=$((skills + 1))
                matched=0
                for d in $SKILLS_DIR/${test#skill:}; do
                    [[ -d "$d" ]] && matched=1
                done
                if [[ $matched -eq 1 ]]; then
                    pass "DT-01 skill row '$test' matches a folder under $SKILLS_DIR/"
                else
                    fail "DT-01 skill row '$test' matches no folder under $SKILLS_DIR/"
                fi
                ;;
            *)
                fail "DT-01 row '$test' is neither samples/<id> nor skill:<name>"
                ;;
        esac
    done < "$DEFERRED_TSV"

    pass "DT-01 rows read: $samples sample row(s), $skills skill row(s)"
    group_end
}

# ---------------------------------------------------------------------------
# DT-02: the list must be empty for a release.
# ---------------------------------------------------------------------------
run_dt02() {
    group_begin "DT-02 release: the deferred list is empty under AID_RELEASE_CHECK=1"
    local n
    n=$(row_count)
    if [[ "${AID_RELEASE_CHECK:-0}" == "1" && $n -gt 0 ]]; then
        fail "DT-02 deferred list has $n row(s) under AID_RELEASE_CHECK=1; it must be empty for a release"
    else
        pass "DT-02 deferred list has $n row(s) (AID_RELEASE_CHECK=${AID_RELEASE_CHECK:-0})"
    fi
    group_end
}

# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------
echo "=== Deferred tests (Feature 002 section 8) ==="

wants DT-01 && run_dt01
wants DT-02 && run_dt02

test_summary
exit $?
