#!/usr/bin/env bash
# compute-block-radius.sh — BFS transitive-descendant computation for FR6
# failure-block-radius (feature-009-parallel-task-execution).
#
# Given a failed task and an Execution Graph (Depends On table from PLAN.md
# or the work-root SPEC.md), computes the complete set of tasks that
# transitively depend on the failed task — the "block-radius". Every task in
# the block-radius must be marked Blocked because it cannot run without the
# failed task's output.
#
# Usage:
#   compute-block-radius.sh --failed-task NNN --plan-file PATH
#       Read the Execution Graph from PATH (PLAN.md or SPEC.md).
#       Print one task-NNN per line to stdout. Exit 0 on success.
#
#   compute-block-radius.sh --failed-task NNN --graph-file PATH
#       Read a pre-computed reverse-graph snapshot (TSV: dependent TAB ancestor).
#       Avoids re-parsing PLAN.md when called from a pool loop that already
#       parsed the graph. Exit 0 on success.
#
#   compute-block-radius.sh -h | --help
#       Print this help and exit.
#
# Output:
#   One task-NNN per line (newline-separated, no trailing newline), sorted by
#   task number ascending. Empty output means the failed task has no dependents.
#
# Exit codes:
#   0  success (block-radius printed to stdout; may be empty)
#   1  required argument missing or file not found
#   2  failed task not found in graph (warn but succeed with empty set)
#   4  invalid argument value
#   5  missing required argument
#
# BFS Algorithm:
#   Input:  failed_id         — task-NNN that failed
#           reverse_graph     — map: task → [tasks that directly depend on it]
#   Output: blocked_set       — all transitive descendants of failed_id
#
#   queue    <- [failed_id]
#   visited  <- {failed_id}
#   blocked_set <- {}
#
#   while queue is non-empty:
#     current <- dequeue(queue)
#     for each dependent D in reverse_graph[current]:
#       if D not in visited:
#         visited <- visited union {D}
#         blocked_set <- blocked_set union {D}
#         enqueue(queue, D)
#
#   return blocked_set  // does NOT include failed_id itself
#
# Properties:
#   - The failed task itself is NOT in the output (it is already Failed).
#   - blocked_set is minimal: only tasks with a transitive dep on failed task.
#   - All "Depends On" edges are AND — no alternative paths exist.
#   - If failed_id has no dependents, output is empty (exit 0).

set -u

# ---------------------------------------------------------------------------
usage() {
    sed -n '2,58p' "$0" | sed 's/^# \{0,1\}//'
}

die() { echo "ERROR: compute-block-radius.sh: $*" >&2; exit "${2:-1}"; }
warn() { echo "WARN: compute-block-radius.sh: $*" >&2; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
FAILED_TASK=""
PLAN_FILE=""
GRAPH_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --failed-task)
            [[ $# -lt 2 ]] && die "--failed-task requires a value" 5
            FAILED_TASK="$2"; shift 2
            ;;
        --plan-file)
            [[ $# -lt 2 ]] && die "--plan-file requires a value" 5
            PLAN_FILE="$2"; shift 2
            ;;
        --graph-file)
            [[ $# -lt 2 ]] && die "--graph-file requires a value" 5
            GRAPH_FILE="$2"; shift 2
            ;;
        *)
            die "unknown argument: $1" 5
            ;;
    esac
done

[[ -z "$FAILED_TASK" ]] && die "--failed-task is required" 5
[[ -z "$PLAN_FILE" && -z "$GRAPH_FILE" ]] && die "one of --plan-file or --graph-file is required" 5
[[ -n "$PLAN_FILE" && -n "$GRAPH_FILE" ]] && die "specify only one of --plan-file or --graph-file" 4

# Normalize failed task: accept NNN (digits) or task-NNN form
# Defensive: strip surrounding whitespace and backticks (callers should pass clean form, but be safe)
FAILED_TASK=$(echo "$FAILED_TASK" | tr -d ' \t`\r\n')
if [[ "$FAILED_TASK" =~ ^task-([0-9]+)$ ]]; then
    FAILED_TASK_ID="${BASH_REMATCH[1]}"
elif [[ "$FAILED_TASK" =~ ^([0-9]+)$ ]]; then
    FAILED_TASK_ID="${BASH_REMATCH[1]}"
else
    die "invalid --failed-task '$FAILED_TASK': must be NNN or task-NNN" 4
fi
# Force base-10 arithmetic to prevent printf from interpreting leading-zero strings
# (e.g. "033") as octal. Using $((10#N)) strips leading zeros correctly.
FAILED_TASK_NORM="task-$(printf '%03d' "$((10#${FAILED_TASK_ID}))")"

# ---------------------------------------------------------------------------
# Parse Execution Graph from PLAN.md / SPEC.md
# Builds reverse_graph as a TSV file: "dependent TAB dependency"
# The "| Task | Depends On |" table is the source.
# ---------------------------------------------------------------------------
build_reverse_graph_from_plan() {
    local plan_file="$1"
    [[ -f "$plan_file" ]] || die "plan/spec file not found: $plan_file" 1

    # Parse the "| Task | Depends On |" table.
    # Lines look like:
    #   | task-001 | — |
    #   | task-002 | task-001 |
    #   | task-005 | task-003, task-004 |
    # Output TSV: dependent<TAB>dependency (one row per dependency edge).
    awk '
        BEGIN { in_table=0 }

        # Detect the Execution Graph header (#### Execution Graph)
        /^####[[:space:]]+Execution Graph/ { in_table=1; next }

        # Detect the Depends On table header row
        in_table && /^\|[[:space:]]*Task[[:space:]]*\|[[:space:]]*Depends[[:space:]]*On/ {
            in_depends=1; next
        }

        # Skip separator row (|---|---|)
        in_table && in_depends && /^\|[-|[:space:]]+$/ { next }

        # Parse data rows inside the Depends On table
        in_table && in_depends && /^\|/ {
            # Check if we hit the second table (Can Be Done In Parallel)
            if ($0 ~ /Can Be Done In Parallel/) { in_depends=0; in_table=0; next }
            # Also stop at blank line or non-table line
            if ($0 !~ /^\|/) { in_depends=0; next }

            # Extract columns: | task-NNN | dep1, dep2 |
            line = $0
            # Remove leading/trailing |
            gsub(/^\|/, "", line)
            gsub(/\|$/, "", line)
            # Split on |
            n = split(line, cols, "|")
            if (n < 2) next

            task = cols[1]; deps_str = cols[2]
            # Trim whitespace
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", task)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", deps_str)

            # Normalize task name (ensure task-NNN form)
            if (task ~ /^task-[0-9]+/) {
                # Acceptable — emit reverse edges
                if (deps_str == "—" || deps_str == "-" || deps_str == "") {
                    # No dependencies: no reverse edges to emit
                    next
                }
                # Split comma-separated dependencies
                nd = split(deps_str, dep_list, /,[[:space:]]*/);
                for (i = 1; i <= nd; i++) {
                    dep = dep_list[i]
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", dep)
                    if (dep != "" && dep != "—" && dep != "-") {
                        # Emit: dependency -> task (reverse edge: dep is depended-on by task)
                        print dep "\t" task
                    }
                }
            }
        }

        # Stop scanning after the second table in the Execution Graph block
        in_table && /^\|[[:space:]]*Can Be Done In Parallel/ { in_table=0; next }

        # A blank line after the table ends the table context
        in_table && in_depends && /^$/ { in_depends=0 }
    ' "$plan_file"
}

# ---------------------------------------------------------------------------
# BFS over reverse graph to compute transitive descendants
# reverse_graph_tsv: file with lines "dependency TAB dependent"
# ---------------------------------------------------------------------------
bfs_block_radius() {
    local failed_task="$1"    # task-NNN (may have surrounding whitespace; normalized below)
    local rg_file="$2"        # TSV file: dep TAB dependent

    # Defensive normalization: callers should already pass canonical task-NNN
    # form (see FAILED_TASK_NORM at top of script), but bfs_block_radius is
    # callable independently — strip whitespace + backticks to be safe.
    failed_task=$(echo "$failed_task" | tr -d ' \t`')

    # Use awk to run BFS entirely in memory.
    # rg_file format: "dependency<TAB>dependent" — meaning "dependent depends on dependency"
    # We want: given failed_task, find all tasks that directly or transitively depend on it.
    awk -v start="$failed_task" '
        BEGIN {
            # Load entire reverse graph into memory
        }

        # Each line: dependency TAB dependent
        {
            dep = $1; task = $2
            # Store: reverse_graph[dep] += task
            if (rg[dep] == "") {
                rg[dep] = task
            } else {
                rg[dep] = rg[dep] "," task
            }
        }

        END {
            # BFS from start
            queue[0] = start
            qhead = 0
            qtail = 1
            visited[start] = 1

            while (qhead < qtail) {
                current = queue[qhead++]

                # Get all direct dependents of current
                if (rg[current] != "") {
                    n = split(rg[current], deps, ",")
                    for (i = 1; i <= n; i++) {
                        d = deps[i]
                        if (d != "" && !(d in visited)) {
                            visited[d] = 1
                            # blocked_set = visited minus start
                            if (d != start) {
                                blocked[d] = 1
                            }
                            queue[qtail++] = d
                        }
                    }
                }
            }

            # Print blocked set sorted by task number
            for (t in blocked) {
                print t
            }
        }
    ' "$rg_file" | sort -t- -k2 -n
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [[ -n "$PLAN_FILE" ]]; then
    # Parse graph from plan/spec file
    [[ -f "$PLAN_FILE" ]] || die "plan file not found: $PLAN_FILE" 1

    TMPGRAPH=$(mktemp)
    trap 'rm -f "$TMPGRAPH"' EXIT

    build_reverse_graph_from_plan "$PLAN_FILE" > "$TMPGRAPH"

    # Verify the failed task exists in the graph (as a dependency or dependant)
    if ! grep -q "^${FAILED_TASK_NORM}" "$TMPGRAPH" && \
       ! grep -q "	${FAILED_TASK_NORM}$" "$TMPGRAPH" && \
       ! grep -qE "(^|\t)${FAILED_TASK_NORM}(\t|$)" "$TMPGRAPH"; then
        warn "task '${FAILED_TASK_NORM}' not found in Execution Graph of $PLAN_FILE — empty block-radius returned"
        exit 2
    fi

    bfs_block_radius "$FAILED_TASK_NORM" "$TMPGRAPH"

elif [[ -n "$GRAPH_FILE" ]]; then
    # Use pre-computed reverse-graph snapshot (TSV: dep TAB dependent)
    [[ -f "$GRAPH_FILE" ]] || die "graph file not found: $GRAPH_FILE" 1

    bfs_block_radius "$FAILED_TASK_NORM" "$GRAPH_FILE"
fi

exit 0
