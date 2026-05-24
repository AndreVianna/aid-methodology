#!/usr/bin/env bash
# writeback-task-status.sh — row-level write coordination for FR6 parallel pool
# × per-area STATE writes in AID aid-execute.
#
# Provides 4 safe write modes for the work STATE.md Tasks Status section and
# per-task/per-delivery artifact files. Uses a sentinel-file lock (set -o
# noclobber + atomic create + sleep-poll retry) to prevent races when multiple
# parallel tasks dispatch reviewers concurrently.
#
# Usage:
#   writeback-task-status.sh --task-id NNN --field FIELD --value VALUE
#       Update a single named field in the task row inside ## Tasks Status.
#       Fields: Status | Review | Elapsed | Notes | Wave | Type
#
#   writeback-task-status.sh --task-id NNN --findings BLOCK
#       Write/replace the ## Quick Check block in the task's Execution Record
#       (task-NNN.md). BLOCK is the multi-line findings text.
#
#   writeback-task-status.sh --delivery-id NNN --block MARKDOWN_BLOCK
#       Write/replace the ## Delivery Gate block in the delivery's gate-record
#       task Execution Record. MARKDOWN_BLOCK is the full block text.
#
#   writeback-task-status.sh --delivery-id NNN --append-issue ROW
#       Append a single issue row to the delivery's delivery-NNN-issues.md.
#       ROW must be a valid markdown table row (pipe-delimited).
#
#   writeback-task-status.sh -h | --help
#
# Exit codes:
#   0  success
#   1  STATE.md or required artifact missing
#   2  lock contention (timeout)
#   3  writeback produced empty / unverifiable output
#   4  invalid argument value
#   5  missing required argument
#   6  malformed STATE.md (## Tasks Status section absent)

set -u

# ---------------------------------------------------------------------------
# Defaults — caller can override via environment for testing
# ---------------------------------------------------------------------------
STATE_FILE="${AID_STATE_FILE:-.aid/work/STATE.md}"
TASKS_DIR="${AID_TASKS_DIR:-.aid/work/tasks}"
DELIVERY_ISSUES_DIR="${AID_DELIVERY_ISSUES_DIR:-.aid/work}"
LOCK_DIR="${AID_LOCK_DIR:-.aid/work}"
LOCK_TIMEOUT="${AID_LOCK_TIMEOUT:-10}"   # max retries (0.5s each → 5s default)

# ---------------------------------------------------------------------------
usage() {
    sed -n '3,29p' "$0" | sed 's/^# \{0,1\}//'
}

die() { echo "ERROR: writeback-task-status.sh: $*" >&2; exit "${2:-1}"; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
MODE=""
TASK_ID=""
DELIVERY_ID=""
FIELD=""
FIELD_VALUE=""
FINDINGS_BLOCK=""
DELIVERY_BLOCK=""
ISSUE_ROW=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --task-id)
            [[ $# -lt 2 ]] && die "--task-id requires a value" 5
            TASK_ID="$2"; shift 2
            ;;
        --delivery-id)
            [[ $# -lt 2 ]] && die "--delivery-id requires a value" 5
            DELIVERY_ID="$2"; shift 2
            ;;
        --field)
            [[ $# -lt 2 ]] && die "--field requires a value" 5
            FIELD="$2"; shift 2
            ;;
        --value)
            [[ $# -lt 2 ]] && die "--value requires a value" 5
            FIELD_VALUE="$2"; shift 2
            ;;
        --findings)
            [[ $# -lt 2 ]] && die "--findings requires a value" 5
            FINDINGS_BLOCK="$2"; shift 2
            ;;
        --block)
            [[ $# -lt 2 ]] && die "--block requires a value" 5
            DELIVERY_BLOCK="$2"; shift 2
            ;;
        --append-issue)
            [[ $# -lt 2 ]] && die "--append-issue requires a value" 5
            ISSUE_ROW="$2"; shift 2
            ;;
        *)
            die "unknown argument: $1" 5
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Determine mode from parsed arguments
# ---------------------------------------------------------------------------
if [[ -n "$TASK_ID" && -n "$FIELD" ]]; then
    MODE="field"
    [[ -z "$FIELD_VALUE" ]] && die "--value is required with --task-id --field" 5
elif [[ -n "$TASK_ID" && -n "$FINDINGS_BLOCK" ]]; then
    MODE="findings"
elif [[ -n "$DELIVERY_ID" && -n "$DELIVERY_BLOCK" ]]; then
    MODE="delivery-block"
elif [[ -n "$DELIVERY_ID" && -n "$ISSUE_ROW" ]]; then
    MODE="append-issue"
else
    die "no valid mode detected; use --help for usage" 5
fi

# Validate NNN pattern (1-3 digits; allow zero-padded like 019)
if [[ -n "$TASK_ID" ]] && ! [[ "$TASK_ID" =~ ^[0-9]+$ ]]; then
    die "invalid --task-id '$TASK_ID': must be a numeric task number" 4
fi
if [[ -n "$DELIVERY_ID" ]] && ! [[ "$DELIVERY_ID" =~ ^[0-9]+$ ]]; then
    die "invalid --delivery-id '$DELIVERY_ID': must be a numeric delivery number" 4
fi

# ---------------------------------------------------------------------------
# Lock helpers
# ---------------------------------------------------------------------------
LOCK_FILE="${LOCK_DIR}/.writeback-task-status.lock"
LOCK_ACQUIRED=0

acquire_lock() {
    local attempts=0
    while true; do
        # Atomic create — succeeds only if file does not exist
        if ( set -o noclobber; echo $$ > "$LOCK_FILE" ) 2>/dev/null; then
            LOCK_ACQUIRED=1
            return 0
        fi
        # Another process holds the lock (or we lost the race). Sleep and retry.
        attempts=$((attempts + 1))
        if [[ "$attempts" -ge "$LOCK_TIMEOUT" ]]; then
            die "lock contention: $LOCK_FILE is held after ${attempts} retries (~$((attempts / 2))s). Another process is writing. Try again." 2
        fi
        sleep 0.5
    done
}

release_lock() {
    if [[ "$LOCK_ACQUIRED" -eq 1 ]]; then
        rm -f "$LOCK_FILE"
        LOCK_ACQUIRED=0
    fi
}

trap 'release_lock' EXIT

# ---------------------------------------------------------------------------
# Mode: --task-id NNN --field FIELD --value VALUE
# Update a single field in the task's ## Tasks Status row.
# The Tasks Status table columns are:
#   | # | Task | Type | Wave | Status | Review | Elapsed | Notes |
# Field names (case-insensitive): Status, Review, Elapsed, Notes, Wave, Type, Task
# ---------------------------------------------------------------------------
mode_field() {
    if [[ ! -f "$STATE_FILE" ]]; then
        die "$STATE_FILE does not exist" 1
    fi

    # Validate field name
    local field_lower
    field_lower="${FIELD,,}"   # bash 4+ lowercase
    case "$field_lower" in
        status|review|elapsed|notes|wave|type|task) ;;
        *) die "unknown field '$FIELD'; allowed: Status Review Elapsed Notes Wave Type Task" 4 ;;
    esac

    # Verify ## Tasks Status section exists
    if ! grep -q '^## Tasks Status' "$STATE_FILE"; then
        die "malformed STATE.md: ## Tasks Status section not found in $STATE_FILE" 6
    fi

    # Pad TASK_ID to 3 digits for pattern matching (task-019 style)
    local padded_id
    padded_id=$(printf '%03d' "$TASK_ID")

    # Verify the task row exists
    # Rows look like: | 019 | task-019-... | ... |  OR  | 19 | task-019-... | ... |
    if ! awk '/^## Tasks Status/{s=1} s && /^## / && !/^## Tasks Status/{s=0} s' "$STATE_FILE" \
            | grep -qE "^\| *0*${TASK_ID} *\|"; then
        die "task row for task-id $TASK_ID not found in ## Tasks Status of $STATE_FILE" 1
    fi

    acquire_lock

    local tmp
    tmp=$(mktemp)

    # Column index mapping (1-based pipe-delimited, field 1 = empty before first |)
    # | # | Task | Type | Wave | Status | Review | Elapsed | Notes |
    #   1    2      3      4      5        6        7         8
    local col_idx
    case "$field_lower" in
        "#")      col_idx=1 ;;
        task)     col_idx=2 ;;
        type)     col_idx=3 ;;
        wave)     col_idx=4 ;;
        status)   col_idx=5 ;;
        review)   col_idx=6 ;;
        elapsed)  col_idx=7 ;;
        notes)    col_idx=8 ;;
    esac

    # Use awk to rewrite only the matching task row, within ## Tasks Status section
    awk -v task_id="$padded_id" \
        -v task_id_num="$TASK_ID" \
        -v col="$col_idx" \
        -v new_val=" $FIELD_VALUE " \
        '
        BEGIN { in_tasks=0; updated=0 }

        /^## Tasks Status/ { in_tasks=1; print; next }

        in_tasks && /^## / { in_tasks=0 }

        in_tasks {
            # Check if this is the task row for our task
            # Match: | NNN | or | 0NNN | where number equals task_id_num
            if ($0 ~ /^\|/) {
                # Split by pipe
                n = split($0, fields, "|")
                # fields[1] is empty (before first |), fields[2] is #, etc.
                cell = fields[2]
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell)
                # Match numeric value (strips leading zeros for comparison)
                cell_num = cell + 0
                # Also check padded form
                if (cell == task_id || cell_num == task_id_num + 0) {
                    # Replace the target column
                    fields[col + 1] = new_val
                    # Reconstruct the row
                    row = "|"
                    for (i = 2; i <= n; i++) {
                        row = row fields[i] (i < n ? "|" : "")
                    }
                    print row
                    updated = 1
                    next
                }
            }
            print
            next
        }

        { print }

        END {
            if (!updated) {
                print "ERROR: task row not updated" > "/dev/stderr"
                exit 3
            }
        }
        ' "$STATE_FILE" > "$tmp"

    # Verify output is non-empty
    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; STATE.md preserved" 3
    fi

    # Verify the state file still has the Tasks Status section
    if ! grep -q '^## Tasks Status' "$tmp"; then
        rm -f "$tmp"
        die "writeback sanity check failed: ## Tasks Status disappeared from output" 3
    fi

    mv "$tmp" "$STATE_FILE"
    echo "OK: $STATE_FILE updated — task $TASK_ID field '$FIELD' set to '$FIELD_VALUE'"
}

# ---------------------------------------------------------------------------
# Mode: --task-id NNN --findings BLOCK
# Write/replace the ## Quick Check block in task-NNN.md Execution Record.
# Creates the block if absent, replaces it if it already exists.
# ---------------------------------------------------------------------------
mode_findings() {
    # Locate task file
    local padded_id
    padded_id=$(printf '%03d' "$TASK_ID")
    local task_file=""
    # Search for task-NNN.md (may be named task-019-... or simply task-019.md)
    if [[ -f "${TASKS_DIR}/task-${padded_id}.md" ]]; then
        task_file="${TASKS_DIR}/task-${padded_id}.md"
    else
        # Glob for task-NNN-*.md
        for f in "${TASKS_DIR}/task-${padded_id}-"*.md "${TASKS_DIR}/task-${padded_id}.md"; do
            if [[ -f "$f" ]]; then
                task_file="$f"
                break
            fi
        done
    fi

    if [[ -z "$task_file" ]]; then
        die "task file for task-id $TASK_ID not found in $TASKS_DIR" 1
    fi

    acquire_lock

    local tmp
    tmp=$(mktemp)

    # If ## Quick Check block exists, replace it.
    # Otherwise, append it before the next ## section or at EOF.
    if grep -q '^## Quick Check' "$task_file"; then
        # Replace existing block: delete from ## Quick Check up to (but not
        # including) the next ## section, then insert new block.
        awk -v new_block="$FINDINGS_BLOCK" '
            BEGIN { in_qc=0; inserted=0 }
            /^## Quick Check/ {
                in_qc=1
                print "## Quick Check"
                print ""
                print new_block
                inserted=1
                next
            }
            in_qc && /^## / {
                in_qc=0
                print
                next
            }
            in_qc { next }
            { print }
            END {
                if (!inserted) {
                    print ""
                    print "## Quick Check"
                    print ""
                    print new_block
                }
            }
        ' "$task_file" > "$tmp"
    else
        # Append new block at end of file
        {
            cat "$task_file"
            echo ""
            echo "## Quick Check"
            echo ""
            printf '%s\n' "$FINDINGS_BLOCK"
        } > "$tmp"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $task_file preserved" 3
    fi

    # Verify the findings block appears in output (idempotency check)
    # Use a short prefix to verify (first 40 chars of block)
    local block_prefix
    block_prefix="${FINDINGS_BLOCK:0:40}"
    if [[ -n "$block_prefix" ]] && ! grep -qF "$block_prefix" "$tmp" 2>/dev/null; then
        # Block might contain newlines — just verify ## Quick Check header
        if ! grep -q '^## Quick Check' "$tmp"; then
            rm -f "$tmp"
            die "## Quick Check block was not written to output" 3
        fi
    fi

    mv "$tmp" "$task_file"
    echo "OK: $task_file updated — ## Quick Check block written for task $TASK_ID"
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --block MARKDOWN_BLOCK
# Write/replace the ## Delivery Gate block in the gate-record task's
# Execution Record. The gate-record task is the highest-numbered task file
# found in TASKS_DIR (the Execution-Graph terminal node rule from FR6).
# ---------------------------------------------------------------------------
mode_delivery_block() {
    local padded_id
    padded_id=$(printf '%03d' "$DELIVERY_ID")

    # Find the gate-record task: highest-numbered task-NNN*.md in TASKS_DIR
    local gate_task=""
    # Sort all task files, pick the last one (highest number)
    for f in "${TASKS_DIR}/task-"*.md; do
        [[ -f "$f" ]] && gate_task="$f"
    done
    # Explicit sort to ensure we get the highest
    if compgen -G "${TASKS_DIR}/task-*.md" > /dev/null 2>&1; then
        gate_task=$(ls -1 "${TASKS_DIR}/task-"*.md 2>/dev/null | sort | tail -n 1)
    fi

    if [[ -z "$gate_task" || ! -f "$gate_task" ]]; then
        die "no task files found in $TASKS_DIR" 1
    fi

    acquire_lock

    local tmp
    tmp=$(mktemp)

    # Delivery gate block header uses delivery-NNN
    local gate_header="## Delivery Gate — delivery-${padded_id}"

    if grep -q "^## Delivery Gate" "$gate_task"; then
        # Replace existing block
        awk -v header="$gate_header" -v new_block="$DELIVERY_BLOCK" '
            BEGIN { in_gate=0; inserted=0 }
            /^## Delivery Gate/ {
                in_gate=1
                print header
                print ""
                print new_block
                inserted=1
                next
            }
            in_gate && /^## / {
                in_gate=0
                print
                next
            }
            in_gate { next }
            { print }
            END {
                if (!inserted) {
                    print ""
                    print header
                    print ""
                    print new_block
                }
            }
        ' "$gate_task" > "$tmp"
    else
        {
            cat "$gate_task"
            echo ""
            printf '%s\n' "$gate_header"
            echo ""
            printf '%s\n' "$DELIVERY_BLOCK"
        } > "$tmp"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $gate_task preserved" 3
    fi

    if ! grep -q "^## Delivery Gate" "$tmp"; then
        rm -f "$tmp"
        die "## Delivery Gate block was not written to output" 3
    fi

    mv "$tmp" "$gate_task"
    echo "OK: $gate_task updated — ## Delivery Gate block written for delivery $DELIVERY_ID"
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --append-issue ROW
# Append a single issue row to delivery-NNN-issues.md.
# File is created with a header if it does not exist.
# Idempotent: if an identical row already exists, no duplicate is written.
# ---------------------------------------------------------------------------
mode_append_issue() {
    local padded_id
    padded_id=$(printf '%03d' "$DELIVERY_ID")
    local issues_file="${DELIVERY_ISSUES_DIR}/delivery-${padded_id}-issues.md"

    acquire_lock

    # Create file with header if it does not exist
    if [[ ! -f "$issues_file" ]]; then
        cat > "$issues_file" <<EOF
# Delivery Issue Log — delivery-${padded_id}

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded — grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
EOF
        echo "OK: created $issues_file"
    fi

    # Idempotency: skip if identical row already present
    if grep -qF "$ISSUE_ROW" "$issues_file" 2>/dev/null; then
        echo "OK: $issues_file — row already present, no-op (idempotent)"
        return 0
    fi

    # Validate row is pipe-delimited markdown table syntax
    if ! echo "$ISSUE_ROW" | grep -qE '^\|.*\|'; then
        die "invalid --append-issue row: must be a pipe-delimited markdown table row starting and ending with '|'" 4
    fi

    # Append the row
    printf '%s\n' "$ISSUE_ROW" >> "$issues_file"
    echo "OK: $issues_file — issue row appended"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$MODE" in
    field)            mode_field ;;
    findings)         mode_findings ;;
    delivery-block)   mode_delivery_block ;;
    append-issue)     mode_append_issue ;;
    *) die "internal error: unknown mode '$MODE'" 1 ;;
esac
