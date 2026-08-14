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
#   derive-waves.sh <plan.md> --write    Replace the wave-map blocks in the file,
#                                        in place. IDEMPOTENT: existing blocks are
#                                        removed first, so re-running after fixing
#                                        a dependency table is safe and running
#                                        twice changes nothing. Use this, never
#                                        shell append -- `>> plan.md` DUPLICATES
#                                        blocks on any plan that already has them.
#   derive-waves.sh <plan.md> --check    Compare derived blocks against the ones
#                                        present in the file. Exit 0 if every
#                                        delivery agrees, 1 on any mismatch
#                                        (printing the difference), 2 on a
#                                        malformed graph (cycle, or a task the
#                                        table never defines).
#
# Read-only unless --write is given.
# Dependencies: bash + awk only (no node, no python -- this is a core-path
# script, and core AID installs assume neither).

set -uo pipefail

PLAN="${1:-}"
MODE="${2:-emit}"

if [[ -z "$PLAN" || ! -f "$PLAN" ]]; then
    echo "derive-waves.sh: usage: derive-waves.sh <plan.md> [--check]" >&2
    exit 2
fi
if [[ "$MODE" != "emit" && "$MODE" != "--check" && "$MODE" != "--write" ]]; then
    echo "derive-waves.sh: unknown mode '$MODE' (expected --write, --check, or nothing)" >&2
    exit 2
fi

# Emit the derived blocks. One awk pass: collect each delivery's dependency
# table, then Kahn-sort it into waves.
derive() {
    awk "$AWK_DERIVE" "${1:-$PLAN}"
}

AWK_DERIVE='
    function norm(s) {
        gsub(/^[ \t]+|[ \t]+$/, "", s)
        return tolower(s)
    }
    # Flush the delivery currently being collected: Kahn-sort and print.
    function flush() {
        if (cur == "") return
        # A delivery section with no dependency rows yields nothing. Emitting a
        # bare `delivery: NNN` block with no wave lines would map no tasks and
        # only confuse a reader comparing derived against authored output.
        if (ntask == 0) { cur = ""; return }
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
'

# Extract the wave-map blocks already present in a file, normalized the same way
# derive() prints them, so a comparison is textual and exact.
existing() {
    awk '
    /^```wave-map[ \t]*$/ { inb = 1; print; next }
    inb && /^```[ \t]*$/   { inb = 0; print; print ""; next }
    inb { gsub(/[ \t]+$/, ""); print; next }
    ' "${1:-$PLAN}"
}

# The single comparison both --check and --write use. Command substitution
# normalizes trailing newlines on BOTH sides identically, which a diff of two
# process substitutions does not.
agrees() {
    [[ "$(derive "$1")" == "$(existing "$1")" ]]
}

if [[ "$MODE" == "emit" ]]; then
    derive
    exit $?
fi

if [[ "$MODE" == "--write" ]]; then
    # Derive BEFORE touching the file, so a malformed graph leaves the plan
    # untouched rather than half-rewritten.
    d_out="$(derive)" || exit 2

    tmp="$(mktemp)" || exit 2
    blocks="$(mktemp)" || exit 2
    trap 'rm -f "$tmp" "$blocks"' EXIT
    printf '%s\n' "$d_out" > "$blocks"

    # Splice each derived block back into ITS OWN delivery section rather than
    # appending all of them at the end. Position carries no meaning to the reader
    # (it keys off the `delivery:` line), but a wave-map belongs next to the
    # dependency table it was derived from, and moving them would be a gratuitous
    # reorganization of a file a human reads.
    #
    # Existing blocks are dropped as they are encountered, which is what makes
    # --write idempotent.
    awk -v blockfile="$blocks" '
    BEGIN {
        # Load the derived blocks, keyed by delivery number.
        d = ""
        while ((getline line < blockfile) > 0) {
            if (line ~ /^```wave-map[ \t]*$/) { pending = line; continue }
            if (line ~ /^delivery:[ \t]*[0-9]+[ \t]*$/) {
                d = line; sub(/^delivery:[ \t]*/, "", d); sub(/[ \t]*$/, "", d)
                block[d] = pending "\n" line
                continue
            }
            if (d != "" && line ~ /^```[ \t]*$/) { block[d] = block[d] "\n" line; d = ""; continue }
            if (d != "" && line != "") { block[d] = block[d] "\n" line }
        }
        close(blockfile)
    }
    # Emit the current delivery block (once) before leaving its section.
    # `spaced` adds the blank line that separates the block from whatever heading
    # follows it -- restoring the blank that removing the old block consumed. At
    # EOF there is nothing to separate from, so the caller passes 0 and no
    # trailing blank is introduced.
    function emit(spaced) {
        if (cur != "" && !done[cur] && (cur in block)) {
            print block[cur]
            if (spaced) print ""
            done[cur] = 1
        }
        cur = ""
    }
    # Suppress any wave-map block already in the file.
    /^```wave-map[ \t]*$/ { inb = 1; next }
    inb && /^```[ \t]*$/  { inb = 0; skipblank = 1; next }
    inb { next }
    # Swallow exactly one blank line left behind by a removed block.
    skipblank && /^[ \t]*$/ { skipblank = 0; next }
    { skipblank = 0 }

    tolower($0) ~ /^###[ \t]+delivery-[0-9]+[ \t]+execution[ \t]+graph/ {
        emit(1)
        s = tolower($0); match(s, /delivery-[0-9]+/)
        cur = substr(s, RSTART + 9, RLENGTH - 9)
        print; next
    }
    /^###?[ \t]/ { emit(1); print; next }
    { print }
    END { emit(0) }
    ' "$PLAN" > "$tmp"

    # Verify before replacing the original: the file we are about to install must
    # pass its own --check. A rewrite that would not is a bug in this script, and
    # the plan is safer left alone.
    if ! agrees "$tmp"; then
        echo "derive-waves.sh: refusing to write -- the rewritten file would not pass its own --check" >&2
        exit 2
    fi

    cat "$tmp" > "$PLAN"
    n="$(grep -c '^```wave-map' "$PLAN" || true)"
    echo "derive-waves.sh: wrote ${n} wave-map block(s) to $PLAN"
    exit 0
fi

# --check
d_out="$(derive)" || exit 2
e_out="$(existing)"

if agrees "$PLAN"; then
    echo "derive-waves.sh: OK -- every wave-map in $PLAN matches its dependency table"
    exit 0
fi

echo "derive-waves.sh: MISMATCH -- the wave-maps in $PLAN disagree with their dependency tables"
echo "--- authored (in the file)"
echo "$e_out"
echo "--- derived (from the Depends On tables)"
echo "$d_out"
exit 1
