#!/usr/bin/env bash
# derive-waves.sh -- derive the `wave-map` blocks in PLAN.md from the dependency
# tables already written above them.
#
# Why this exists:
#   A wave-map is a topological sort of the `| Task | Depends On |` table that
#   sits directly above it in the same file. It carries no information the table
#   does not already carry. Asking an agent to compute it by hand -- and then to
#   run a manual "does every task appear in exactly one wave" self-check -- spends
#   tokens on arithmetic and can silently get it wrong. A script cannot.
#
#   The output format is fixed by the dashboard reader
#   (dashboard/reader/parsers.py, PF-5a) and reproduced exactly:
#     ```wave-map
#     delivery: NNN
#     wave 1: task-001
#     wave 2: task-002, task-003
#     ```
#
#   Note on "parallel sub-lanes": the reader assigns `task_lane_map[tid] = N`
#   from the wave NUMBER, so two `wave 2:` lines are indistinguishable from one
#   `wave 2:` line holding the same tasks. Splitting a wave into sub-lanes
#   changes nothing downstream, so this script emits ONE line per wave. That
#   also removes a judgment call ("do these represent distinct execution
#   tracks?") that never had an observable consequence.
#
# Usage:
#   derive-waves.sh <plan.md>            Print the derived wave-map blocks.
#   derive-waves.sh <plan.md> --check    Compare derived blocks against the ones
#                                        present in the file. Exit 0 if every
#                                        delivery agrees, 1 on any mismatch
#                                        (printing the difference), 2 on a
#                                        malformed graph (cycle, or a task the
#                                        table never defines).
#
# Read-only: never writes to <plan.md>.
# Dependencies: bash + awk only (no node, no python -- this is a core-path
# script, and core AID installs assume neither).

set -uo pipefail

PLAN="${1:-}"
MODE="${2:-emit}"

if [[ -z "$PLAN" || ! -f "$PLAN" ]]; then
    echo "derive-waves.sh: usage: derive-waves.sh <plan.md> [--check]" >&2
    exit 2
fi
if [[ "$MODE" != "emit" && "$MODE" != "--check" ]]; then
    echo "derive-waves.sh: unknown mode '$MODE' (expected --check or nothing)" >&2
    exit 2
fi

# Emit the derived blocks. One awk pass: collect each delivery's dependency
# table, then Kahn-sort it into waves.
derive() {
    awk '
    function norm(s) {
        gsub(/^[ \t]+|[ \t]+$/, "", s)
        return tolower(s)
    }
    # Flush the delivery currently being collected: Kahn-sort and print.
    function flush() {
        if (cur == "") return
        printf "```wave-map\ndelivery: %s\n", cur

        for (t in dep) seen[t] = 1
        wave = 0
        placed = 0
        total = ntask
        while (placed < total) {
            wave++
            line = ""
            n = 0
            # A task is ready when every dependency it names is either already
            # assigned to an earlier wave, or is not a task of THIS delivery at
            # all (deliveries run in series, so such a dep is already satisfied).
            for (i = 1; i <= ntask; i++) {
                t = order[i]
                if (assigned[t]) continue
                ready = 1
                nd = split(dep[t], d, ",")
                for (j = 1; j <= nd; j++) {
                    x = norm(d[j])
                    if (x == "") continue
                    if (!(x in dep)) continue          # foreign / earlier delivery
                    if (!assigned[x] || assigned[x] >= wave) { ready = 0; break }
                }
                if (ready) { pick[++n] = t }
            }
            if (n == 0) {
                printf "derive-waves.sh: delivery %s has a dependency cycle or an undefined task\n", cur > "/dev/stderr"
                exit 2
            }
            for (i = 1; i <= n; i++) {
                assigned[pick[i]] = wave
                line = (line == "" ? pick[i] : line ", " pick[i])
                placed++
            }
            printf "wave %d: %s\n", wave, line
        }
        print "```"
        print ""

        # reset per-delivery state
        delete dep; delete assigned; delete order; delete pick; delete seen
        ntask = 0
        cur = ""
    }

    # A delivery execution-graph heading, matched exactly as the reader matches
    # it (dashboard/reader/parsers.py _re_delivery_section).
    tolower($0) ~ /^###[ \t]+delivery-[0-9]+[ \t]+execution[ \t]+graph/ {
        flush()
        s = tolower($0)
        match(s, /delivery-[0-9]+/)
        cur = substr(s, RSTART + 9, RLENGTH - 9)
        next
    }
    # Any other heading at ## or ### level ends the current delivery.
    /^###?[ \t]/ { flush(); next }

    # Dependency rows: TWO OR MORE cells whose first cell is exactly a task id.
    #
    # Two or more, not exactly two: the column count varies between real plans.
    # A `| Task | Depends On |` table and a
    # `| Task | Depends On | Gate wave | Lane |` table both occur among the works
    # in this repo, and only the first two columns carry the graph.
    #
    # The "first cell is exactly a task id" test is what excludes the header row,
    # the `|---|---|` separator, and the single-cell "Can Be Done In Parallel"
    # table (whose cells hold lists like `task-002, task-005`, never a bare id).
    cur != "" && /^[ \t]*\|/ {
        row = $0
        sub(/^[ \t]*\|/, "", row)
        sub(/\|[ \t]*$/, "", row)
        nf = split(row, cell, "|")
        if (nf < 2) next
        task = norm(cell[1])
        if (task !~ /^task-[0-9]+$/) next

        # Read dependencies by EXTRACTING task ids rather than by cleaning the
        # cell. "no dependencies" is written variously as an em dash, an en dash,
        # `--`, `-`, `none`, or an empty cell; extraction treats every one of
        # them identically (no ids found = no dependencies) without needing to
        # enumerate them or match multibyte dash sequences in a regex.
        deps = ""
        rest = tolower(cell[2])
        while (match(rest, /task-[0-9]+/)) {
            id = substr(rest, RSTART, RLENGTH)
            deps = (deps == "" ? id : deps "," id)
            rest = substr(rest, RSTART + RLENGTH)
        }
        if (!(task in dep)) { order[++ntask] = task }
        dep[task] = deps
        next
    }
    END { flush() }
    ' "$PLAN"
}

# Extract the wave-map blocks already present in the file, normalized the same
# way derive() prints them, so a comparison is textual and exact.
existing() {
    awk '
    /^```wave-map[ \t]*$/ { inb = 1; print; next }
    inb && /^```[ \t]*$/   { inb = 0; print; print ""; next }
    inb { gsub(/[ \t]+$/, ""); print; next }
    ' "$PLAN"
}

if [[ "$MODE" == "emit" ]]; then
    derive
    exit $?
fi

# --check
d_out="$(derive)" || exit 2
e_out="$(existing)"

if [[ "$d_out" == "$e_out" ]]; then
    echo "derive-waves.sh: OK -- every wave-map in $PLAN matches its dependency table"
    exit 0
fi

echo "derive-waves.sh: MISMATCH -- the wave-maps in $PLAN disagree with their dependency tables"
echo "--- authored (in the file)"
echo "$e_out"
echo "--- derived (from the Depends On tables)"
echo "$d_out"
exit 1
