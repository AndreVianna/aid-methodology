#!/usr/bin/env bash
# review-recall.sh -- what fraction of seeded defects a review actually found.
#
# WHAT IT REPLACES, MEASURED
#
# Recall is found/seeded, so computing it by hand means deciding, for each seeded
# defect, whether any ledger row reports it. The trap is not the labour. It is
# that the obvious way to count what a ledger FOUND is wrong:
#
#   $ L=.aid/works/.../delivery-001/tasks/task-025/FINDINGS.md
#   $ grep -cE '^\|[[:space:]]*[0-9]+[[:space:]]*\|' "$L"          # naive
#   5
#   $ awk -F'|' '/^\|[[:space:]]*[0-9]+[[:space:]]*\|/{gsub(/ /,"",$4);
#       if ($4=="Pending"||$4=="Recurred") n++} END{print n+0}' "$L"  # status-aware
#   0
#
# `grade.sh` counts only Pending and Recurred; a Fixed row is history. Across the
# 21 reviewer ledgers this work produced, 17 disagree, 4 are empty, and NOT ONE
# non-empty ledger agrees. So the naive count is not sometimes wrong -- on this
# corpus it is wrong every time it says anything, and it errs in the direction
# that flatters, reporting closed findings as caught.
#
# That is what this removes: not typing, a default-wrong answer that looks right.
#
# THE NFR-3 FLOOR (task-036, agreed before the measurement)
#   At least 20 seeded defects against at least 90 real ledger rows.
#   Measured at merge: 20 seeded, 114 rows. Clears both.
#
#   $ grep -cE '^\| D[0-9]+ \|' tests/canonical/fixtures/recall-corpus/CATALOGUE.md
#   $ find .aid/works -name FINDINGS.md -exec grep -chE '^\|[[:space:]]*[0-9]+[[:space:]]*\|' {} \; | awk '{s+=$1} END{print s}'
#
# THIS IS OBSERVE-ONLY, NOT AN ORACLE. It reports a number per criterion scope,
# not a verdict per file, so it decides no file and produces no ledger row. Read
# it and act on it; do not file it. See frontmatter-schema.md § oracle.
#
# Usage:
#   review-recall.sh report --ledger <path> [--corpus <dir>]
#
# Exit: 0 report written / 2 invocation error.

set -uo pipefail

PROG="${0##*/}"
SUB="${1:-}"; shift 2>/dev/null || true
LEDGER=""
CORPUS="tests/canonical/fixtures/recall-corpus"

while [ $# -gt 0 ]; do
    case "$1" in
        --ledger) LEDGER="${2:-}"; shift 2 ;;
        --corpus) CORPUS="${2:-}"; shift 2 ;;
        -h|--help) sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0"; exit 0 ;;
        *) echo "$PROG: unknown argument: $1" >&2; exit 2 ;;
    esac
done

[ "$SUB" = "report" ] || { echo "$PROG: usage: $PROG report --ledger <path>" >&2; exit 2; }
[ -n "$LEDGER" ]      || { echo "$PROG: --ledger is required" >&2; exit 2; }
[ -r "$LEDGER" ]      || { echo "$PROG: cannot read ledger: $LEDGER" >&2; exit 2; }
[ -d "$CORPUS" ]      || { echo "$PROG: not a directory: $CORPUS" >&2; exit 2; }

CATALOGUE="${CORPUS}/CATALOGUE.md"
[ -r "$CATALOGUE" ]   || { echo "$PROG: cannot read catalogue: $CATALOGUE" >&2; exit 2; }

# --- the ledger's counting rows -----------------------------------------------
# A row counts as a finding only when its Status is one that still counts toward
# a grade. Pending and Recurred, matching grade.sh. Anything else is history.
#
# Escaped pipes are masked BEFORE splitting. A `\|` inside a Description is the
# schema's own escape, and splitting on it would shift every later cell by one --
# so the Status check would read the Doc column and the whole report would be
# wrong in a way that still produced plausible numbers.
rows_file="$(mktemp)"
trap 'rm -f "$rows_file"' EXIT

awk '
    /^\|[[:space:]]*[0-9]+[[:space:]]*\|/ {
        line = $0
        gsub(/\\\|/, "\001", line)          # mask the escape
        n = split(line, c, "|")
        if (n < 8) next
        status = c[4]; doc = c[5]; desc = c[7]; evid = c[8]
        gsub(/^[ \t]+|[ \t]+$/, "", status)
        gsub(/^[ \t]+|[ \t]+$/, "", doc)
        if (status != "Pending" && status != "Recurred") next
        gsub(/\001/, "\\|", desc); gsub(/\001/, "\\|", evid)
        print doc "\t" desc " " evid
    }
' "$LEDGER" > "$rows_file"

# --- walk the catalogue -------------------------------------------------------
declare -A seeded=() found=()
scopes=""
total_seeded=0; total_found=0

while IFS= read -r row; do
    id=$(printf '%s' "$row"    | awk -F'|' '{gsub(/ /,"",$2); print $2}')
    scope=$(printf '%s' "$row" | awk -F'|' '{gsub(/[ `]/,"",$3); print $3}')
    sig=$(printf '%s' "$row"   | awk -F'|' '{gsub(/[ `]/,"",$6); print $6}')
    fix=$(printf '%s' "$row"   | awk -F'|' '{gsub(/[ `]/,"",$7); print $7}')
    [ -n "$id" ] || continue
    [ -n "$scope" ] || scope="--"

    case " $scopes " in *" $scope "*) ;; *) scopes="$scopes $scope" ;; esac
    seeded[$scope]=$(( ${seeded[$scope]:-0} + 1 ))
    total_seeded=$(( total_seeded + 1 ))

    # A row FINDS a defect when its document matches the fixture and its text
    # carries the signature. Both, not either: a signature alone could appear in
    # a row about a different file.
    if awk -F'\t' -v f="$fix" -v s="$sig" '
            index($1, f) > 0 && index($2, s) > 0 { hit=1 }
            END { exit hit ? 0 : 1 }' "$rows_file"; then
        found[$scope]=$(( ${found[$scope]:-0} + 1 ))
        total_found=$(( total_found + 1 ))
    fi
done < <(grep -E '^\| D[0-9]+ \|' "$CATALOGUE")

# --- report -------------------------------------------------------------------
# Raw counts, never a stored ratio. A ratio hides which half moved: 3/6 and 30/60
# print the same and mean very different things about a corpus.
printf '%-24s %8s %8s\n' "scope" "seeded" "found"
printf '%-24s %8s %8s\n' "------------------------" "--------" "--------"

for s in $(printf '%s\n' $scopes | LC_ALL=C sort); do
    sd=${seeded[$s]:-0}; fd=${found[$s]:-0}
    if [ "$sd" -eq 0 ]; then
        printf '%-24s %8s %8s   missing\n' "$s" "0" "--"
    else
        printf '%-24s %8s %8s\n' "$s" "$sd" "$fd"
    fi
done

printf '%-24s %8s %8s\n' "------------------------" "--------" "--------"
if [ "$total_seeded" -eq 0 ]; then
    # An empty denominator is not a perfect score. Nothing was seeded, so nothing
    # was measured, and reporting that as complete would be the exact vacuity a
    # recall figure exists to expose.
    printf '%-24s %8s %8s   missing\n' "TOTAL" "0" "--"
    echo "$PROG: nothing seeded -- this is a missing measurement, not a perfect score." >&2
else
    printf '%-24s %8s %8s\n' "TOTAL" "$total_seeded" "$total_found"
fi

exit 0
