#!/usr/bin/env bash
# slice-requirements.sh -- print the slice of REQUIREMENTS.md that ONE task traces to,
# instead of the whole document.
#
# Why this exists:
#   Every task execution loads a statement of intent to know what it is building. When
#   that statement is the whole of REQUIREMENTS.md, a work with 16 tasks reads the whole
#   document 16 times, and the cost scales with task count while a gate's does not. The
#   modelled saving on a 3-feature/16-task work is ~1.6MB, which is the largest single
#   line left in the budget once the review loop is scoped.
#
#   A task already declares what it traces to. Its DETAIL.md carries
#   `**Source:** feature-NNN-{name} -> delivery-NNN -> AC-N[, AC-N]`, so the slice is
#   derivable and needs no new field, no map to maintain, and no judgment at read time.
#   Before that `AC-N` citation existed a slice could only have been guessed at; it is
#   the reason this is possible at all.
#
#   The slice is:
#     - the task's own feature section from `## 11 Features`  (the technical spec it
#       implements against)
#     - the `AC-N` entries from `## 9 Acceptance Criteria` that its Source names
#     - the identity block, always -- four lines that name what the work IS, without
#       which a slice reads as an orphaned fragment
#
# A task whose Source names NO criterion is an error, not an empty slice. That is the
# same argument the wave derivation makes: silently returning nothing is
# indistinguishable from correctly returning nothing, and here it would ground a task
# on the identity block alone while looking like it worked.
#
# Usage:
#   slice-requirements.sh <work-dir> <task-id>     Print the slice to stdout.
#   slice-requirements.sh <work-dir> <task-id> --list-ids
#                                                  Print just the AC ids it resolved,
#                                                  one per line (for callers that only
#                                                  need to know what a task claims).
#
# Read-only. Never writes.
# Dependencies: bash + awk only -- a core-path script, and core AID installs assume
# neither node nor python.

set -uo pipefail

WORK_DIR="${1:-}"
TASK_ID="${2:-}"
MODE="${3:-slice}"

if [[ -z "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
    echo "slice-requirements.sh: usage: slice-requirements.sh <work-dir> <task-id> [--list-ids]" >&2
    exit 2
fi
if [[ -z "$TASK_ID" ]]; then
    echo "slice-requirements.sh: a task id is required (e.g. task-003 or 3)" >&2
    exit 2
fi
if [[ "$MODE" != "slice" && "$MODE" != "--list-ids" ]]; then
    echo "slice-requirements.sh: unknown mode '$MODE' (expected --list-ids or nothing)" >&2
    exit 2
fi

# Accept task-003, 003 or 3 -- callers pass whichever they have, and rejecting a bare
# number would push zero-padding logic into every one of them.
digits="${TASK_ID##*[!0-9]}"
[[ -z "$digits" ]] && { echo "slice-requirements.sh: '$TASK_ID' contains no task number" >&2; exit 2; }
padded="$(printf '%03d' "$((10#$digits))")"

REQ="${WORK_DIR}/REQUIREMENTS.md"
[[ -f "$REQ" ]] || { echo "slice-requirements.sh: no REQUIREMENTS.md in ${WORK_DIR}" >&2; exit 2; }

# Both layouts: flat (tasks/ under the work root) and nested (deliveries/*/tasks/).
DETAIL=""
for cand in "${WORK_DIR}/tasks/task-${padded}/DETAIL.md" \
            "${WORK_DIR}"/deliveries/delivery-*/tasks/task-${padded}/DETAIL.md; do
    [[ -f "$cand" ]] && { DETAIL="$cand"; break; }
done
[[ -n "$DETAIL" ]] || { echo "slice-requirements.sh: no DETAIL.md for task-${padded} under ${WORK_DIR}" >&2; exit 2; }

# --- what the task claims --------------------------------------------------------
# Ids are EXTRACTED rather than the field cleaned, for the same reason derive-waves.sh
# extracts task ids: the separator varies (comma, space, "and") and extraction treats
# every spelling identically without enumerating them.
AC_IDS="$(awk '
    /^\*\*Source:\*\*/ {
        rest = $0
        while (match(rest, /AC-[0-9]+/)) {
            print substr(rest, RSTART, RLENGTH)
            rest = substr(rest, RSTART + RLENGTH)
        }
        exit
    }' "$DETAIL" | sort -u -V)"

FEATURE="$(awk '
    /^\*\*Source:\*\*/ {
        if (match($0, /feature-[0-9]+/)) {
            print substr($0, RSTART + 8, RLENGTH - 8)
        }
        exit
    }' "$DETAIL")"

if [[ -z "$AC_IDS" ]]; then
    echo "slice-requirements.sh: task-${padded} cites no AC-N in its **Source:** line -- cannot slice" >&2
    echo "slice-requirements.sh: (a task with no criterion has nothing to be judged against; fix the DETAIL)" >&2
    exit 3
fi

if [[ "$MODE" == "--list-ids" ]]; then
    printf '%s\n' "$AC_IDS"
    exit 0
fi

# --- the slice -------------------------------------------------------------------
awk -v ids="$(printf '%s ' $AC_IDS)" -v feat="$FEATURE" '
    BEGIN {
        n = split(ids, a, " ")
        for (i = 1; i <= n; i++) if (a[i] != "") want[a[i]] = 1
    }

    # Identity block: the first bullets before section 1. Four lines that say what the
    # work IS -- a slice without them reads as an orphaned fragment.
    /^# / && !seen_h1 { print; seen_h1 = 1; next }
    /^- \*\*(Name|Description):\*\*/ && !in_sec { print; next }

    /^## / {
        in_sec = 1
        sec = tolower($0)
        in_ac   = (sec ~ /^## *9\./)
        in_feat = (sec ~ /^## *11\./)
        ac_open = 0
        feat_open = 0
        next
    }

    # § 9: keep only the criteria this task cites, including their continuation lines.
    in_ac {
        if ($0 ~ /^- \*\*AC-[0-9]+\*\*/) {
            match($0, /AC-[0-9]+/)
            id = substr($0, RSTART, RLENGTH)
            ac_open = (id in want)
            if (ac_open && !ac_hdr) { print ""; print "## 9. Acceptance Criteria (sliced)"; print ""; ac_hdr = 1 }
        } else if ($0 ~ /^- /) {
            ac_open = 0            # a different bullet ends the criterion
        }
        if (ac_open) print
        next
    }

    # § 11: keep only this task the feature section it traces to.
    in_feat {
        if ($0 ~ /^### /) {
            feat_open = (feat != "" && index(tolower($0), "feature " feat) > 0) ||
                        (feat != "" && index($0, "Feature " feat) > 0)
            if (feat_open && !feat_hdr) { print ""; print "## 11. Features (sliced)"; print ""; feat_hdr = 1 }
        }
        if (feat_open) print
        next
    }
' "$REQ"
