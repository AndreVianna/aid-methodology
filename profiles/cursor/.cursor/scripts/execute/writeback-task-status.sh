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
#       Write/replace the ### task-NNN block under ## Quick Check Findings
#       in the work STATE.md (per work-003 FR2 per-area STATE rule). BLOCK is
#       the multi-line findings text. task-NNN.md is NOT modified.
#
#   writeback-task-status.sh --delivery-id NNN --block MARKDOWN_BLOCK
#       Write/replace the ### delivery-NNN block under ## Delivery Gates in the
#       work STATE.md (per feature-004 Alignment Update — see SPEC §Alignment Update; line cites in body are known-stale).
#       MARKDOWN_BLOCK is the full block text. STATE.md is the canonical target;
#       task files are NOT modified by this mode.
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
    sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'
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
    # M2: Distinguish missing lock directory (ENOENT) from lock contention (EEXIST).
    local lock_parent
    lock_parent="$(dirname "$LOCK_FILE")"
    [[ -d "$lock_parent" ]] || die "lock directory does not exist: $lock_parent" 1

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
    # H2: Reject --value containing literal '|' to prevent row corruption.
    if [[ "$FIELD_VALUE" == *"|"* ]]; then
        die "--value cannot contain '|' (pipe is the column separator); escape with HTML entity or rephrase" 4
    fi

    # Cycle-3 fix: also reject newline characters (same row-corruption class as H2).
    if [[ "$FIELD_VALUE" == *$'\n'* ]]; then
        die "--value cannot contain newline characters (row separator); rephrase to single line" 4
    fi

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
        BEGIN { in_tasks=0; updated=0; schema_error=0 }

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
                    # H1: Verify the row has the expected 8 columns (n == 10: 8 cols + 2 boundary empties)
                    if (n != 10) {
                        printf "ERROR: Tasks Status table row '\''%s'\'' has wrong column count (expected 8, got %d); refusing to update\n", task_id, n - 2 > "/dev/stderr"
                        schema_error = 1
                        exit 4
                    }
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
            if (schema_error) { exit 4 }
            if (!updated) {
                print "ERROR: task row not updated" > "/dev/stderr"
                exit 3
            }
        }
        ' "$STATE_FILE" > "$tmp"
    local awk_exit=$?
    if [[ "$awk_exit" -eq 4 ]]; then
        rm -f "$tmp"
        # Re-read the actual column count from the file for the die message
        local bad_row actual_cols
        bad_row=$(awk "/^## Tasks Status/{s=1} s && /^## / && !/^## Tasks Status/{s=0} s && /^\|/{n=split(\$0,f,\"|\"); cell=f[2]; gsub(/^[[:space:]]+|[[:space:]]+\$/,\"\",cell); if(cell==\"$padded_id\" || cell+0==$TASK_ID+0) print \$0}" "$STATE_FILE" | head -1)
        actual_cols=$(echo "$bad_row" | awk '{n=split($0,f,"|"); print n-2}')
        die "Tasks Status table row '${padded_id}' has wrong column count (expected 8, got ${actual_cols}); refusing to update" 4
    fi
    if [[ "$awk_exit" -ne 0 ]]; then
        rm -f "$tmp"
        die "writeback awk failed (exit $awk_exit); STATE.md preserved" 3
    fi

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
# Write/replace the ### task-NNN block under ## Quick Check Findings in
# STATE.md (per work-003 FR2 per-area STATE rule). task-NNN.md is NOT modified.
# Creates the ## Quick Check Findings section if absent (appends to STATE.md).
# Creates/replaces the ### task-NNN sub-block within that section.
# ---------------------------------------------------------------------------
mode_findings() {
    local padded_id
    padded_id=$(printf '%03d' "$TASK_ID")
    local task_heading="### task-${padded_id}"

    if [[ ! -f "$STATE_FILE" ]]; then
        die "$STATE_FILE does not exist" 1
    fi

    acquire_lock

    local tmp
    tmp=$(mktemp)

    if grep -q '^## Quick Check Findings' "$STATE_FILE"; then
        # Section exists. Replace ### task-NNN block if present; otherwise insert
        # before the next ## section (or at EOF of the Quick Check Findings section).
        if grep -q "^${task_heading}$" "$STATE_FILE"; then
            # Replace existing ### task-NNN block: skip old content from ### task-NNN
            # up to (but not including) the next ## section OR the next peer ### task-
            # heading. Sub-headings within the findings block (e.g. ### Findings) are
            # NOT peer blocks — only ### task-NNN lines from the file are peers.
            awk -v heading="$task_heading" -v new_block="$FINDINGS_BLOCK" '
                BEGIN { in_task=0; inserted=0 }
                $0 == heading {
                    in_task=1
                    print heading
                    print ""
                    print new_block
                    inserted=1
                    next
                }
                in_task && /^## / {
                    in_task=0
                    print ""
                    print
                    next
                }
                in_task && /^### task-/ && $0 != heading {
                    in_task=0
                    print ""
                    print
                    next
                }
                in_task { next }
                { print }
                END {
                    if (!inserted) {
                        print ""
                        print heading
                        print ""
                        print new_block
                    }
                }
            ' "$STATE_FILE" > "$tmp"
        else
            # Append ### task-NNN block within the ## Quick Check Findings section.
            # Strategy: insert before the NEXT ## section after Quick Check Findings,
            # or at EOF if no such section follows.
            awk -v heading="$task_heading" -v new_block="$FINDINGS_BLOCK" '
                BEGIN { in_qcf=0; inserted=0 }
                /^## Quick Check Findings/ { in_qcf=1; print; next }
                in_qcf && /^## / && !/^## Quick Check Findings/ {
                    if (!inserted) {
                        print ""
                        print heading
                        print ""
                        print new_block
                        inserted=1
                    }
                    in_qcf=0
                    print
                    next
                }
                { print }
                END {
                    if (!inserted) {
                        print ""
                        print heading
                        print ""
                        print new_block
                    }
                }
            ' "$STATE_FILE" > "$tmp"
        fi
    else
        # ## Quick Check Findings section absent — append it (with the task block) at EOF.
        {
            cat "$STATE_FILE"
            echo ""
            echo "## Quick Check Findings"
            echo ""
            echo "$task_heading"
            echo ""
            printf '%s\n' "$FINDINGS_BLOCK"
        } > "$tmp"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $STATE_FILE preserved" 3
    fi

    # Sanity: ## Quick Check Findings section must be present in output
    if ! grep -q '^## Quick Check Findings' "$tmp"; then
        rm -f "$tmp"
        die "## Quick Check Findings section was not written to output" 3
    fi

    # Sanity: ### task-NNN heading must be present in output
    if ! grep -q "^${task_heading}$" "$tmp"; then
        rm -f "$tmp"
        die "${task_heading} was not written to output" 3
    fi

    mv "$tmp" "$STATE_FILE"
    echo "OK: $STATE_FILE updated — ## Quick Check Findings ### task-${padded_id} block written"
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --block MARKDOWN_BLOCK
# Write/replace the ### delivery-NNN block under ## Delivery Gates in
# STATE.md (per feature-004 Alignment Update — see SPEC §Alignment Update; line cites in body are known-stale). STATE.md is
# the canonical write target. task files are NOT modified by this mode.
# Creates the ## Delivery Gates section if absent (appends to STATE.md).
# Creates/replaces the ### delivery-NNN sub-block within that section.
# Mirrors the pattern of mode_findings (which writes ## Quick Check Findings).
# ---------------------------------------------------------------------------
mode_delivery_block() {
    local padded_id
    padded_id=$(printf '%03d' "$DELIVERY_ID")
    local delivery_heading="### delivery-${padded_id}"

    if [[ ! -f "$STATE_FILE" ]]; then
        die "$STATE_FILE does not exist" 1
    fi

    acquire_lock

    local tmp
    tmp=$(mktemp)

    if grep -q '^## Delivery Gates' "$STATE_FILE"; then
        # Section exists. Replace ### delivery-NNN block if present; otherwise insert
        # before the next ## section (or at EOF of the Delivery Gates section).
        if grep -q "^${delivery_heading}$" "$STATE_FILE"; then
            # Replace existing ### delivery-NNN block.
            awk -v heading="$delivery_heading" -v new_block="$DELIVERY_BLOCK" '
                BEGIN { in_delivery=0; inserted=0 }
                $0 == heading {
                    in_delivery=1
                    print heading
                    print ""
                    print new_block
                    inserted=1
                    next
                }
                in_delivery && /^## / {
                    in_delivery=0
                    print ""
                    print
                    next
                }
                in_delivery && /^### delivery-/ && $0 != heading {
                    in_delivery=0
                    print ""
                    print
                    next
                }
                in_delivery { next }
                { print }
                END {
                    if (!inserted) {
                        print ""
                        print heading
                        print ""
                        print new_block
                    }
                }
            ' "$STATE_FILE" > "$tmp"
        else
            # Append ### delivery-NNN block within ## Delivery Gates section.
            awk -v heading="$delivery_heading" -v new_block="$DELIVERY_BLOCK" '
                BEGIN { in_dg=0; inserted=0 }
                /^## Delivery Gates/ { in_dg=1; print; next }
                in_dg && /^## / && !/^## Delivery Gates/ {
                    if (!inserted) {
                        print ""
                        print heading
                        print ""
                        print new_block
                        inserted=1
                    }
                    in_dg=0
                    print
                    next
                }
                { print }
                END {
                    if (!inserted) {
                        print ""
                        print heading
                        print ""
                        print new_block
                    }
                }
            ' "$STATE_FILE" > "$tmp"
        fi
    else
        # ## Delivery Gates section absent — append it (with the delivery block) at EOF.
        {
            cat "$STATE_FILE"
            echo ""
            echo "## Delivery Gates"
            echo ""
            echo "$delivery_heading"
            echo ""
            printf '%s\n' "$DELIVERY_BLOCK"
        } > "$tmp"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $STATE_FILE preserved" 3
    fi

    # Sanity: ## Delivery Gates section must be present in output
    if ! grep -q '^## Delivery Gates' "$tmp"; then
        rm -f "$tmp"
        die "## Delivery Gates section was not written to output" 3
    fi

    # Sanity: ### delivery-NNN heading must be present in output
    if ! grep -q "^${delivery_heading}$" "$tmp"; then
        rm -f "$tmp"
        die "${delivery_heading} was not written to output" 3
    fi

    mv "$tmp" "$STATE_FILE"
    echo "OK: $STATE_FILE updated — ## Delivery Gates ### delivery-${padded_id} block written"
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
