#!/usr/bin/env bash
# complexity-score.sh — compute delivery-complexity score for aid-execute DELIVERY-GATE.
#
# Extracted from canonical/skills/aid-execute/references/state-delivery-gate.md
# (Step 1: SCORE) per feature-002 SPEC §Layers principle: "complexity scoring
# is pure arithmetic over task files — belongs in scripts/, not in the skill
# body".
#
# Usage:
#   complexity-score.sh --plan-file PATH --delivery-id NNN [--tasks-dir PATH]
#   complexity-score.sh --graph-file PATH --tasks-dir PATH
#
# --delivery-id is REQUIRED for a multi-delivery PLAN.md (### delivery-NNN
# sections) and scopes extraction to that delivery. For a lite/recipe SPEC with a
# top-level "## Execution Graph" (no delivery sections), --delivery-id is optional.
#
# Outputs (stdout, one per line):
#   tasks=N
#   depth=N
#   risk=N
#   consults=N    (always 0 — quick-check consults computed externally; see note)
#   score=N
#   tier=Small|Medium|Large
#
# Tier thresholds:
#   - Reads .aid/knowledge/STATE.md if AID_KB_STATE is set.
#   - Default Low Threshold = 6; High Threshold = 14 (when STATE.md absent).
#
# Note on `consults`: quick-check [CRITICAL] events live in the work STATE.md
# `## Quick Check Findings` section; this script does NOT scan that file by
# default (caller can pass --quick-check-state PATH to include). The
# Agent-Selection consult count is also caller-provided via --consults N.
#
# Exit codes:
#   0  success
#   1  input file not found
#   2  malformed graph (no Task | Depends On table)
#   4  invalid argument

set -u

PLAN_FILE=""
GRAPH_FILE=""
DELIVERY_ID=""
TASKS_DIR=""
QUICK_CHECK_STATE=""
EXTRA_CONSULTS=0

usage() {
    cat <<USAGE
Usage:
  $(basename "$0") --plan-file PATH --delivery-id NNN [--tasks-dir PATH] [--quick-check-state PATH] [--consults N]
  $(basename "$0") --graph-file PATH [--tasks-dir PATH] [--quick-check-state PATH] [--consults N]
USAGE
    exit 4
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --plan-file)         PLAN_FILE="$2"; shift 2 ;;
        --graph-file)        GRAPH_FILE="$2"; shift 2 ;;
        --delivery-id)       DELIVERY_ID="$2"; shift 2 ;;
        --tasks-dir)         TASKS_DIR="$2"; shift 2 ;;
        --quick-check-state) QUICK_CHECK_STATE="$2"; shift 2 ;;
        --consults)          EXTRA_CONSULTS="$2"; shift 2 ;;
        -h|--help)           usage ;;
        *) echo "ERROR: unknown arg: $1" >&2; usage ;;
    esac
done

# Resolve input file
if [[ -n "$PLAN_FILE" && -n "$GRAPH_FILE" ]]; then
    echo "ERROR: --plan-file and --graph-file are mutually exclusive" >&2
    exit 4
fi
if [[ -n "$PLAN_FILE" ]]; then
    [[ -f "$PLAN_FILE" ]] || { echo "ERROR: PLAN file not found: $PLAN_FILE" >&2; exit 1; }
    GRAPH_TMP=$(mktemp)
    trap 'rm -f "$GRAPH_TMP"' EXIT
    if grep -qE '^### delivery-' "$PLAN_FILE"; then
        # Full multi-delivery PLAN.md — extract only the requested delivery's graph.
        [[ -z "$DELIVERY_ID" ]] && { echo "ERROR: --plan-file with delivery sections requires --delivery-id NNN" >&2; exit 4; }
        # Portable awk only: 2-arg match() + substr() (no gawk 3-arg capture array),
        # numeric delivery-id comparison (robust to leading zeros: 003 == 3).
        awk -v did="$DELIVERY_ID" '
            BEGIN { in_section=0; in_graph=0 }
            /^### delivery-/ {
                in_section = 0
                if (match($0, /delivery-[0-9]+/)) {
                    num = substr($0, RSTART, RLENGTH); sub(/delivery-/, "", num)
                    if (num + 0 == did + 0) in_section = 1
                }
            }
            in_section && /^#### Execution Graph/ { in_graph = 1; next }
            in_section && in_graph && /^####|^###/ { in_graph = 0; in_section = 0 }
            in_section && in_graph { print }
        ' "$PLAN_FILE" > "$GRAPH_TMP"
    else
        # Lite/recipe SPEC — top-level "## Execution Graph", no delivery wrapper.
        # --delivery-id is not required for this shape. Capture the Execution Graph
        # block at ANY heading level, stopping at the next level-1/2 heading so a
        # preceding/following "## Tasks" table is never swallowed (the level-3
        # "### Task Dependencies" / "### Can Be Done In Parallel" subheadings stay in).
        awk '
            BEGIN { in_graph=0 }
            /^#+[[:space:]]+Execution Graph[[:space:]]*$/ { in_graph = 1; next }
            in_graph && /^##?[[:space:]]/ { in_graph = 0 }
            in_graph { print }
        ' "$PLAN_FILE" > "$GRAPH_TMP"
    fi
    GRAPH_FILE="$GRAPH_TMP"
elif [[ -n "$GRAPH_FILE" ]]; then
    [[ -f "$GRAPH_FILE" ]] || { echo "ERROR: graph file not found: $GRAPH_FILE" >&2; exit 1; }
else
    usage
fi

# Parse `| Task | Depends On |` table into edges (task_to_deps map)
# Output: task list + deps map (associative arrays via temp files)
declare -A DEPS
declare -a TASKS
parsed_rows=0
while IFS= read -r line; do
    # Match: | task-NNN | task-NNN[, task-NNN]... | OR | task-NNN | — |
    if [[ "$line" =~ ^\|[[:space:]]*([a-z]+-[0-9]+)[[:space:]]*\|[[:space:]]*(.+)[[:space:]]*\|[[:space:]]*$ ]]; then
        task="${BASH_REMATCH[1]}"
        deps="${BASH_REMATCH[2]}"
        # Skip header rows
        [[ "$task" == "Task" ]] && continue
        [[ "$deps" == "Depends On" ]] && continue
        TASKS+=("$task")
        # Normalize deps — treat em-dash / hyphen / "none" / "(none)" / "— (none)"
        # as "no dependencies". (The lite-spec template uses the "— (none)" form;
        # full PLAN.md tables use a bare "—".)
        dtrim="${deps#"${deps%%[![:space:]]*}"}"; dtrim="${dtrim%"${dtrim##*[![:space:]]}"}"
        case "${dtrim,,}" in
            ""|"—"|"-"|"none"|"(none)"|"—(none)"|"— (none)") DEPS["$task"]="" ;;
            *) DEPS["$task"]="$deps" ;;
        esac
        parsed_rows=$((parsed_rows + 1))
    fi
done < "$GRAPH_FILE"

if [[ $parsed_rows -eq 0 ]]; then
    echo "ERROR: no Task|Depends On rows found in graph" >&2
    exit 2
fi

TASK_COUNT=${#TASKS[@]}

# Compute graph depth — longest path in the DAG (memoized DFS)
declare -A DEPTH_CACHE
declare -A DEPTH_VISITING   # cycle guard: tasks currently on the recursion stack
compute_depth() {
    local t="$1"
    if [[ -n "${DEPTH_CACHE[$t]:-}" ]]; then echo "${DEPTH_CACHE[$t]}"; return; fi
    # Cycle guard: a task already on the current recursion stack means the
    # Depends On table has a back-edge. Break it (contribute 0) and warn rather
    # than recursing until bash aborts. (Each recursive call is a command-
    # substitution subshell that inherits DEPTH_VISITING, so ancestors on the
    # current path are visible here.)
    if [[ -n "${DEPTH_VISITING[$t]:-}" ]]; then
        echo "WARN: complexity-score.sh: dependency cycle detected at '$t' — breaking cycle" >&2
        echo 0
        return
    fi
    DEPTH_VISITING["$t"]=1
    local deps_str="${DEPS[$t]:-}"
    if [[ -z "$deps_str" ]]; then
        DEPTH_CACHE["$t"]=0
        echo 0
        return
    fi
    local max=0
    IFS=',' read -ra deps_arr <<< "$deps_str"
    for d in "${deps_arr[@]}"; do
        # Trim + strip backticks
        d=$(echo "$d" | tr -d ' `')
        [[ -z "$d" ]] && continue
        local d_depth
        d_depth=$(compute_depth "$d")
        local candidate=$((d_depth + 1))
        if [[ "$candidate" -gt "$max" ]]; then max=$candidate; fi
    done
    DEPTH_CACHE["$t"]=$max
    echo $max
}

MAX_DEPTH=0
for t in "${TASKS[@]}"; do
    d=$(compute_depth "$t")
    if [[ "$d" -gt "$MAX_DEPTH" ]]; then MAX_DEPTH=$d; fi
done

# Risk-weighted types (read task-NNN.md if --tasks-dir provided)
RISK=0
if [[ -n "$TASKS_DIR" && -d "$TASKS_DIR" ]]; then
    for t in "${TASKS[@]}"; do
        # Find task file (allow task-NNN.md or task-NNN-*.md)
        f=$(find "$TASKS_DIR" -maxdepth 1 -name "${t}.md" -o -name "${t}-*.md" 2>/dev/null | head -1)
        [[ -z "$f" || ! -f "$f" ]] && continue
        # Match both the bold task-template form (**Type:**) and the flat recipe
        # form (- Type:); recipe-generated tasks use the latter (see recipes/*.md).
        type_line=$(grep -m1 -iE '^[[:space:]]*(- )?\*{0,2}Type:' "$f" 2>/dev/null || true)
        case "$type_line" in
            *MIGRATE*|*REFACTOR*) RISK=$((RISK + 2));;
            *IMPLEMENT*|*TEST*)   RISK=$((RISK + 1));;
            *) ;;  # RESEARCH/DESIGN/DOCUMENT/CONFIGURE +0
        esac
    done
fi

# Quick-check consults from STATE.md if provided
CONSULTS=$EXTRA_CONSULTS
if [[ -n "$QUICK_CHECK_STATE" && -f "$QUICK_CHECK_STATE" ]]; then
    qc_critical=$(awk '/## Quick Check Findings/{flag=1; next} /^## /{flag=0} flag && /\[CRITICAL\].*Fixed-on-spot/' "$QUICK_CHECK_STATE" | wc -l)
    CONSULTS=$((CONSULTS + qc_critical))
fi

SCORE=$((TASK_COUNT + MAX_DEPTH + RISK + CONSULTS))

# Tier selection
LOW_THRESHOLD=6
HIGH_THRESHOLD=14
KB_STATE="${AID_KB_STATE:-.aid/knowledge/STATE.md}"
if [[ -f "$KB_STATE" ]]; then
    low=$(grep -m1 "^\*\*Gate Tier Low Threshold:\*\*" "$KB_STATE" 2>/dev/null | awk -F'\\*\\*Gate Tier Low Threshold:\\*\\*' '{print $2}' | tr -dc '0-9' || true)
    high=$(grep -m1 "^\*\*Gate Tier High Threshold:\*\*" "$KB_STATE" 2>/dev/null | awk -F'\\*\\*Gate Tier High Threshold:\\*\\*' '{print $2}' | tr -dc '0-9' || true)
    [[ -n "$low" ]] && LOW_THRESHOLD=$low
    [[ -n "$high" ]] && HIGH_THRESHOLD=$high
fi

TIER="Small"
if [[ "$SCORE" -ge "$HIGH_THRESHOLD" ]]; then
    TIER="Large"
elif [[ "$SCORE" -gt "$LOW_THRESHOLD" ]]; then
    TIER="Medium"
fi

echo "tasks=$TASK_COUNT"
echo "depth=$MAX_DEPTH"
echo "risk=$RISK"
echo "consults=$CONSULTS"
echo "score=$SCORE"
echo "tier=$TIER"
