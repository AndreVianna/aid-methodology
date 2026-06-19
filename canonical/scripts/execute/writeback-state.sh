#!/usr/bin/env bash
# writeback-state.sh -- row-level write coordination for FR6 parallel pool
# x per-unit STATE writes in AID aid-execute.
#
# Provides 6 safe write modes targeting PER-UNIT STATE.md files (Pillar 2).
# Uses a sentinel-file lock (set -o noclobber + atomic create + sleep-poll retry)
# to prevent races when multiple parallel tasks dispatch reviewers concurrently.
#
# Unit layout (work-004 hierarchy):
#   work-NNN-{name}/
#     STATE.md                                  -- work-level (--pipeline target)
#     delivery-NNN/
#       STATE.md                                -- delivery-level (--block / --lifecycle target)
#       tasks/
#         task-NNN/
#           STATE.md                            -- task-level (--field / --findings target)
#
# Usage:
#   writeback-state.sh [--delivery-id NNN] --task-id NNN --field FIELD --value VALUE
#       Update a single named field in the task's ## Task State section of
#       delivery-NNN/tasks/task-NNN/STATE.md (one-writer-per-branch file).
#       Fields: State | Review | Elapsed | Notes
#       --delivery-id is optional; if omitted the delivery is resolved from the
#       task's Source line (e.g. "**Source:** work-NNN -> delivery-NNN").
#       Override env: AID_TASK_STATE_FILE (absolute path) skips all path resolution.
#
#   writeback-state.sh [--delivery-id NNN] --task-id NNN --findings BLOCK
#       Write/replace the ## Quick Check Findings block in
#       delivery-NNN/tasks/task-NNN/STATE.md.
#       Same delivery resolution as --field mode.
#
#   writeback-state.sh --delivery-id NNN --block MARKDOWN_BLOCK
#       Write/replace the ## Delivery Gate block in delivery-NNN/STATE.md (SD-5).
#       Override env: AID_DELIVERY_STATE_FILE (absolute path) skips path resolution.
#
#   writeback-state.sh --delivery-id NNN --lifecycle VALUE
#       Update the State: line in the ## Delivery Lifecycle section of
#       delivery-NNN/STATE.md (SD-8 authored delivery state).
#       VALUE must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked
#       Override env: AID_DELIVERY_STATE_FILE (absolute path) skips path resolution.
#       Emits no user-facing output (C4 behavior-preserving).
#
#   writeback-state.sh --delivery-id NNN --append-issue ROW
#       Append a single issue row to the delivery's delivery-NNN-issues.md.
#       ROW must be a valid markdown table row (pipe-delimited).
#
#   writeback-state.sh --pipeline --field FIELD --value VALUE
#       Write/update a single field in the ## Pipeline State block of the work
#       STATE.md. FIELD must be one of: Lifecycle | Phase | Active Skill | Updated |
#         Pause Reason | Block Reason | Block Artifact
#       Lifecycle, Phase, and Active Skill are closed-enum validated.
#       Conditional fields: Pause Reason written only when Lifecycle is
#         Paused-Awaiting-Input; Block Reason + Block Artifact written only when
#         Lifecycle is Blocked. On Lifecycle change, conditional fields that no
#         longer apply are cleared (removed from the block).
#       Emits no user-facing output (C4 behavior-preserving).
#
#   writeback-state.sh -h | --help
#
# Exit codes:
#   0  success
#   1  STATE.md or required artifact missing
#   2  lock contention (timeout)
#   3  writeback produced empty / unverifiable output
#   4  invalid argument value
#   5  missing required argument
#   6  malformed STATE.md (## Task State section absent in task file)

set -u

# ---------------------------------------------------------------------------
# Defaults -- caller can override via environment for testing
# ---------------------------------------------------------------------------
# Work-level STATE.md (--pipeline target)
STATE_FILE="${AID_STATE_FILE:-.aid/work/STATE.md}"

# Work root (base for resolving delivery/task paths)
# Derived from STATE_FILE parent when not overridden.
WORK_DIR="${AID_WORK_DIR:-}"

# Delivery directory base: <work-root>/delivery-NNN
# Set AID_DELIVERY_DIR to override the per-delivery STATE path base.
DELIVERY_DIR_BASE="${AID_DELIVERY_DIR:-}"

# Task-level STATE.md override (skips all path resolution for --field/--findings)
TASK_STATE_FILE="${AID_TASK_STATE_FILE:-}"

# Delivery-level STATE.md override (skips path resolution for --block)
DELIVERY_STATE_FILE="${AID_DELIVERY_STATE_FILE:-}"

# Issues directory: directory containing delivery-NNN-issues.md files
# Defaults to the work directory (same dir as work STATE.md).
DELIVERY_ISSUES_DIR="${AID_DELIVERY_ISSUES_DIR:-.aid/work}"

# Lock directory -- defaults to derived per-call below (see acquire_lock)
LOCK_DIR="${AID_LOCK_DIR:-}"

LOCK_TIMEOUT="${AID_LOCK_TIMEOUT:-10}"   # max retries (0.5s each -> 5s default)

# ---------------------------------------------------------------------------
usage() {
    sed -n '2,55p' "$0" | sed 's/^# \{0,1\}//'
}

die() { echo "ERROR: writeback-state.sh: $*" >&2; exit "${2:-1}"; }

# ---------------------------------------------------------------------------
# Path resolution helpers
# ---------------------------------------------------------------------------

# resolve_work_dir: derive the work root from STATE_FILE when WORK_DIR unset.
resolve_work_dir() {
    if [[ -z "$WORK_DIR" ]]; then
        WORK_DIR="$(dirname "$STATE_FILE")"
    fi
}

# resolve_task_state_file DELIVERY_ID TASK_ID
# Sets TASK_STATE_FILE to delivery-NNN/tasks/task-NNN/STATE.md under the work root.
# If TASK_STATE_FILE is already set (env override), this is a no-op.
resolve_task_state_file() {
    local delivery_id="$1" task_id="$2"
    if [[ -n "$TASK_STATE_FILE" ]]; then
        return 0
    fi
    resolve_work_dir
    local padded_d padded_t
    padded_d=$(printf '%03d' "$delivery_id")
    padded_t=$(printf '%03d' "$task_id")
    if [[ -n "$DELIVERY_DIR_BASE" ]]; then
        TASK_STATE_FILE="${DELIVERY_DIR_BASE}/tasks/task-${padded_t}/STATE.md"
    else
        TASK_STATE_FILE="${WORK_DIR}/delivery-${padded_d}/tasks/task-${padded_t}/STATE.md"
    fi
}

# resolve_delivery_state_file DELIVERY_ID
# Sets DELIVERY_STATE_FILE to delivery-NNN/STATE.md under the work root.
# If DELIVERY_STATE_FILE is already set (env override), this is a no-op.
resolve_delivery_state_file() {
    local delivery_id="$1"
    if [[ -n "$DELIVERY_STATE_FILE" ]]; then
        return 0
    fi
    resolve_work_dir
    local padded_d
    padded_d=$(printf '%03d' "$delivery_id")
    if [[ -n "$DELIVERY_DIR_BASE" ]]; then
        DELIVERY_STATE_FILE="${DELIVERY_DIR_BASE}/STATE.md"
    else
        DELIVERY_STATE_FILE="${WORK_DIR}/delivery-${padded_d}/STATE.md"
    fi
}

# resolve_delivery_from_task_spec TASK_ID -> sets DELIVERY_ID_RESOLVED
# Reads the task SPEC.md (delivery-NNN/tasks/task-NNN/SPEC.md or legacy tasks/task-NNN.md)
# and extracts the delivery number from "**Source:** ... -> delivery-NNN" or
# "**Source:** ... delivery-NNN ...".
# Returns "" when resolution fails (caller must require --delivery-id).
DELIVERY_ID_RESOLVED=""
resolve_delivery_from_task_spec() {
    local task_id="$1"
    DELIVERY_ID_RESOLVED=""
    resolve_work_dir
    local padded_t
    padded_t=$(printf '%03d' "$task_id")

    # Try legacy flat task spec first (tasks/task-NNN.md)
    local spec_file="${WORK_DIR}/tasks/task-${padded_t}.md"
    if [[ ! -f "$spec_file" ]]; then
        # Try hierarchical path: scan all delivery-NNN/tasks/task-NNN/SPEC.md
        local found
        found=$(find "${WORK_DIR}" -path "*/tasks/task-${padded_t}/SPEC.md" 2>/dev/null | head -1)
        if [[ -n "$found" ]]; then
            spec_file="$found"
        fi
    fi

    if [[ ! -f "$spec_file" ]]; then
        return 0   # unresolvable; caller must supply --delivery-id
    fi

    # Extract delivery number from Source line:
    # **Source:** work-NNN-{name} -> delivery-NNN
    # **Source:** work-NNN-{name} delivery-NNN
    local source_line
    source_line=$(grep -m1 '^\*\*Source:\*\*' "$spec_file" 2>/dev/null || true)
    if [[ -z "$source_line" ]]; then
        return 0
    fi

    # Match delivery-NNN pattern (N=1-3 digits)
    local delivery_raw
    delivery_raw=$(echo "$source_line" | grep -oE 'delivery-[0-9]+' | head -1)
    if [[ -z "$delivery_raw" ]]; then
        return 0
    fi

    # Strip leading zeros via base-10 arithmetic (handles delivery-001, delivery-01, delivery-1)
    local raw_num
    raw_num="${delivery_raw#delivery-}"
    DELIVERY_ID_RESOLVED=$(( 10#$raw_num ))
    if [[ "$DELIVERY_ID_RESOLVED" -eq 0 ]]; then
        # delivery-000 or parse failure
        DELIVERY_ID_RESOLVED=""
    fi
}

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
LIFECYCLE_VALUE=""
ISSUE_ROW=""
PIPELINE_FLAG=0

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
        --pipeline)
            PIPELINE_FLAG=1; shift
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
        --lifecycle)
            [[ $# -lt 2 ]] && die "--lifecycle requires a value" 5
            LIFECYCLE_VALUE="$2"; shift 2
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
if [[ "$PIPELINE_FLAG" -eq 1 && -n "$FIELD" ]]; then
    MODE="pipeline"
    [[ -z "$FIELD_VALUE" ]] && die "--value is required with --pipeline --field" 5
elif [[ -n "$TASK_ID" && -n "$FIELD" ]]; then
    MODE="field"
    [[ -z "$FIELD_VALUE" ]] && die "--value is required with --task-id --field" 5
elif [[ -n "$TASK_ID" && -n "$FINDINGS_BLOCK" ]]; then
    MODE="findings"
elif [[ -n "$DELIVERY_ID" && -n "$DELIVERY_BLOCK" ]]; then
    MODE="delivery-block"
elif [[ -n "$DELIVERY_ID" && -n "$LIFECYCLE_VALUE" ]]; then
    MODE="delivery-lifecycle"
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
# Delivery resolution for task modes (--field / --findings)
# If --delivery-id was supplied, use it directly.
# Otherwise attempt resolution from the task SPEC.md Source line.
# ---------------------------------------------------------------------------
resolve_delivery_for_task_mode() {
    if [[ -n "$DELIVERY_ID" ]]; then
        return 0   # explicit override
    fi
    resolve_delivery_from_task_spec "$TASK_ID"
    if [[ -z "$DELIVERY_ID_RESOLVED" ]]; then
        die "cannot resolve delivery for task $TASK_ID: --delivery-id not supplied and Source line not found in task spec. Supply --delivery-id NNN." 5
    fi
    DELIVERY_ID="$DELIVERY_ID_RESOLVED"
}

# ---------------------------------------------------------------------------
# Lock helpers
# The lock serializes concurrent writes to the same per-unit STATE.md.
# LOCK_FILE is derived from the write-target directory for clarity
# (scoped to the per-unit file's parent directory when possible).
# ---------------------------------------------------------------------------
LOCK_FILE=""
LOCK_ACQUIRED=0

# init_lock_file TARGET_FILE
# Sets LOCK_FILE to a .writeback-state.lock sentinel in the same directory as
# TARGET_FILE, falling back to LOCK_DIR when set, then to the work dir.
init_lock_file() {
    local target_file="$1"
    local lock_parent

    if [[ -n "$LOCK_DIR" ]]; then
        lock_parent="$LOCK_DIR"
    elif [[ -n "$target_file" && -f "$target_file" ]]; then
        lock_parent="$(dirname "$target_file")"
    elif [[ -n "$target_file" ]]; then
        lock_parent="$(dirname "$target_file")"
    else
        resolve_work_dir
        lock_parent="$WORK_DIR"
    fi
    LOCK_FILE="${lock_parent}/.writeback-state.lock"
}

acquire_lock() {
    # M2: Distinguish missing lock directory (ENOENT) from lock contention (EEXIST).
    local lock_parent
    lock_parent="$(dirname "$LOCK_FILE")"
    [[ -d "$lock_parent" ]] || die "lock directory does not exist: $lock_parent" 1

    local attempts=0
    while true; do
        # Atomic create -- succeeds only if file does not exist
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
# Mode: [--delivery-id NNN] --task-id NNN --field FIELD --value VALUE
# Update a single named field in the task's ## Task State section of
# delivery-NNN/tasks/task-NNN/STATE.md.
# Fields: State | Review | Elapsed | Notes
# State is enum-validated (closed enum).
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

    # Validate field name (per-unit task STATE.md fields)
    local field_lower
    field_lower="${FIELD,,}"   # bash 4+ lowercase
    case "$field_lower" in
        state|review|elapsed|notes) ;;
        *) die "unknown field '$FIELD'; allowed: State Review Elapsed Notes" 4 ;;
    esac

    # Enum validation for the State field (closed enum; SD-2).
    if [[ "$field_lower" == "state" ]]; then
        case "$FIELD_VALUE" in
            Pending|"In Progress"|"In Review"|Blocked|Done|Failed|Canceled|"_none yet_") ;;
            *) die "invalid State value '$FIELD_VALUE'; must be one of: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled (or the _none yet_ placeholder)" 4 ;;
        esac
    fi

    resolve_delivery_for_task_mode
    resolve_task_state_file "$DELIVERY_ID" "$TASK_ID"

    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        die "$TASK_STATE_FILE does not exist" 1
    fi

    # Verify ## Task State section exists
    if ! grep -q '^## Task State' "$TASK_STATE_FILE"; then
        die "malformed task STATE.md: ## Task State section not found in $TASK_STATE_FILE" 6
    fi

    init_lock_file "$TASK_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)

    # Field lines in ## Task State section have the form:
    # - **Field:** value
    # We use awk to find the ## Task State section and rewrite the matching field line.
    awk -v field_lower="$field_lower" -v new_val="$FIELD_VALUE" '
        BEGIN { in_ts=0; updated=0 }

        /^## Task State/ { in_ts=1; print; next }

        in_ts && /^## / { in_ts=0 }

        in_ts {
            # Match lines like: - **Field:** value
            if ($0 ~ /^- \*\*[^*]+:\*\*/) {
                line = $0
                sub(/^- \*\*/, "", line)
                sub(/:\*\*.*$/, "", line)
                cur_field = line
                cur_lower = tolower(cur_field)

                if (cur_lower == field_lower) {
                    print "- **" cur_field ":** " new_val
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
                print "ERROR: field '" field_lower "' not updated in ## Task State" > "/dev/stderr"
                exit 3
            }
        }
    ' "$TASK_STATE_FILE" > "$tmp"
    local awk_exit=$?
    if [[ "$awk_exit" -ne 0 ]]; then
        rm -f "$tmp"
        die "writeback awk failed (exit $awk_exit); $TASK_STATE_FILE preserved" "$awk_exit"
    fi

    # Verify output is non-empty
    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $TASK_STATE_FILE preserved" 3
    fi

    # Sanity: ## Task State section must still be present in output
    if ! grep -q '^## Task State' "$tmp"; then
        rm -f "$tmp"
        die "writeback sanity check failed: ## Task State disappeared from output" 3
    fi

    mv "$tmp" "$TASK_STATE_FILE"
    local padded_t
    padded_t=$(printf '%03d' "$TASK_ID")
    echo "OK: $TASK_STATE_FILE updated -- task $padded_t field '$FIELD' set to '$FIELD_VALUE'"
}

# ---------------------------------------------------------------------------
# Mode: [--delivery-id NNN] --task-id NNN --findings BLOCK
# Write/replace the ## Quick Check Findings block in
# delivery-NNN/tasks/task-NNN/STATE.md (per SD-5 / Pillar 2).
# Creates the ## Quick Check Findings section if absent.
# ---------------------------------------------------------------------------
mode_findings() {
    local padded_id
    padded_id=$(printf '%03d' "$TASK_ID")

    resolve_delivery_for_task_mode
    resolve_task_state_file "$DELIVERY_ID" "$TASK_ID"

    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        die "$TASK_STATE_FILE does not exist" 1
    fi

    init_lock_file "$TASK_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)

    if grep -q '^## Quick Check Findings' "$TASK_STATE_FILE"; then
        # Section exists -- replace entire block content (the task owns this file
        # exclusively, so there is no per-task sub-heading needed; replace the whole section).
        awk -v new_block="$FINDINGS_BLOCK" '
            BEGIN { in_qcf=0; inserted=0 }
            /^## Quick Check Findings/ {
                in_qcf=1
                print
                print ""
                print new_block
                inserted=1
                next
            }
            in_qcf && /^## / {
                in_qcf=0
                print
                next
            }
            in_qcf { next }
            { print }
            END {
                if (!inserted) {
                    print ""
                    print "## Quick Check Findings"
                    print ""
                    print new_block
                }
            }
        ' "$TASK_STATE_FILE" > "$tmp"
    else
        # ## Quick Check Findings section absent -- append it at EOF.
        {
            cat "$TASK_STATE_FILE"
            echo ""
            echo "## Quick Check Findings"
            echo ""
            printf '%s\n' "$FINDINGS_BLOCK"
        } > "$tmp"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $TASK_STATE_FILE preserved" 3
    fi

    # Sanity: ## Quick Check Findings section must be present in output
    if ! grep -q '^## Quick Check Findings' "$tmp"; then
        rm -f "$tmp"
        die "## Quick Check Findings section was not written to output" 3
    fi

    mv "$tmp" "$TASK_STATE_FILE"
    echo "OK: $TASK_STATE_FILE updated -- ## Quick Check Findings block written for task-${padded_id}"
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --lifecycle VALUE
# Update the State: line in the ## Delivery Lifecycle section of
# delivery-NNN/STATE.md (SD-8 authored delivery state).
# VALUE must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked
# Emits no user-facing output (C4 behavior-preserving).
# ---------------------------------------------------------------------------
mode_delivery_lifecycle() {
    local padded_id
    padded_id=$(printf '%03d' "$DELIVERY_ID")

    # SD-8 enum validation (closed enum)
    case "$LIFECYCLE_VALUE" in
        Pending-Spec|Specified|Executing|Gated|Done|Blocked) ;;
        *) die "invalid --lifecycle value '$LIFECYCLE_VALUE'; must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked" 4 ;;
    esac

    resolve_delivery_state_file "$DELIVERY_ID"

    if [[ ! -f "$DELIVERY_STATE_FILE" ]]; then
        die "$DELIVERY_STATE_FILE does not exist" 1
    fi

    # Verify ## Delivery Lifecycle section exists
    if ! grep -q '^## Delivery Lifecycle' "$DELIVERY_STATE_FILE"; then
        die "malformed delivery STATE.md: ## Delivery Lifecycle section not found in $DELIVERY_STATE_FILE" 6
    fi

    init_lock_file "$DELIVERY_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)

    # Rewrite only the FIRST - **State:** line within ## Delivery Lifecycle.
    # The done flag prevents degenerate multi-line input from corrupting subsequent
    # State lines (e.g. nested sub-sections that may carry their own State fields).
    # The section uses "- **State:** VALUE" format (same as ## Task State).
    awk -v new_val="$LIFECYCLE_VALUE" '
        BEGIN { in_dl=0; updated=0; done=0 }

        /^## Delivery Lifecycle/ { in_dl=1; print; next }

        in_dl && /^## / { in_dl=0 }

        in_dl {
            if (!done && $0 ~ /^- \*\*State:\*\*/) {
                print "- **State:** " new_val
                updated=1
                done=1
                next
            }
            print
            next
        }

        { print }

        END {
            if (!updated) {
                print "ERROR: State field not found in ## Delivery Lifecycle" > "/dev/stderr"
                exit 3
            }
        }
    ' "$DELIVERY_STATE_FILE" > "$tmp"
    local awk_exit=$?
    if [[ "$awk_exit" -ne 0 ]]; then
        rm -f "$tmp"
        die "writeback awk failed (exit $awk_exit); $DELIVERY_STATE_FILE preserved" "$awk_exit"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $DELIVERY_STATE_FILE preserved" 3
    fi

    # Sanity: ## Delivery Lifecycle section must still be present
    if ! grep -q '^## Delivery Lifecycle' "$tmp"; then
        rm -f "$tmp"
        die "writeback sanity check failed: ## Delivery Lifecycle disappeared from output" 3
    fi

    mv "$tmp" "$DELIVERY_STATE_FILE"
    # No user-facing output (C4)
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --block MARKDOWN_BLOCK
# Write/replace the ## Delivery Gate block in delivery-NNN/STATE.md (SD-5).
# This is the per-delivery delivery gate block, targeting the delivery-level
# STATE.md (one writer per delivery branch -- Pillar 2 disjoint writes).
# Creates the ## Delivery Gate section if absent.
# ---------------------------------------------------------------------------
mode_delivery_block() {
    local padded_id
    padded_id=$(printf '%03d' "$DELIVERY_ID")

    resolve_delivery_state_file "$DELIVERY_ID"

    if [[ ! -f "$DELIVERY_STATE_FILE" ]]; then
        die "$DELIVERY_STATE_FILE does not exist" 1
    fi

    init_lock_file "$DELIVERY_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)

    if grep -q '^## Delivery Gate$' "$DELIVERY_STATE_FILE"; then
        # Section exists -- replace entire block content.
        awk -v new_block="$DELIVERY_BLOCK" '
            BEGIN { in_dg=0; inserted=0 }
            /^## Delivery Gate$/ {
                in_dg=1
                print
                print ""
                print new_block
                inserted=1
                next
            }
            in_dg && /^## / {
                in_dg=0
                print
                next
            }
            in_dg { next }
            { print }
            END {
                if (!inserted) {
                    print ""
                    print "## Delivery Gate"
                    print ""
                    print new_block
                }
            }
        ' "$DELIVERY_STATE_FILE" > "$tmp"
    else
        # ## Delivery Gate section absent -- append it at EOF.
        {
            cat "$DELIVERY_STATE_FILE"
            echo ""
            echo "## Delivery Gate"
            echo ""
            printf '%s\n' "$DELIVERY_BLOCK"
        } > "$tmp"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $DELIVERY_STATE_FILE preserved" 3
    fi

    # Sanity: ## Delivery Gate section must be present in output
    if ! grep -q '^## Delivery Gate$' "$tmp"; then
        rm -f "$tmp"
        die "## Delivery Gate section was not written to output" 3
    fi

    mv "$tmp" "$DELIVERY_STATE_FILE"
    echo "OK: $DELIVERY_STATE_FILE updated -- ## Delivery Gate block written for delivery-${padded_id}"
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --append-issue ROW
# Append a single issue row to delivery-NNN-issues.md.
# File is created with a header if it does not exist.
# Idempotent: if an identical row already exists, no duplicate is written.
# Unchanged from pre-retarget (already disjoint per Pillar 2).
# ---------------------------------------------------------------------------
mode_append_issue() {
    local padded_id
    padded_id=$(printf '%03d' "$DELIVERY_ID")
    local issues_file="${DELIVERY_ISSUES_DIR}/delivery-${padded_id}-issues.md"

    # Use work-dir-based issues path when DELIVERY_ISSUES_DIR is default
    # and WORK_DIR is resolvable, for consistency with path resolution.
    if [[ "$DELIVERY_ISSUES_DIR" == ".aid/work" && -n "$AID_STATE_FILE" ]]; then
        resolve_work_dir
        issues_file="${WORK_DIR}/delivery-${padded_id}-issues.md"
    fi

    # Lock is scoped to the issues file's directory
    init_lock_file "$issues_file"
    acquire_lock

    # Create file with header if it does not exist
    if [[ ! -f "$issues_file" ]]; then
        cat > "$issues_file" <<EOF
# Delivery Issue Log -- delivery-${padded_id}

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
EOF
        echo "OK: created $issues_file"
    fi

    # Idempotency: skip if identical row already present
    if grep -qF "$ISSUE_ROW" "$issues_file" 2>/dev/null; then
        echo "OK: $issues_file -- row already present, no-op (idempotent)"
        return 0
    fi

    # Validate row is pipe-delimited markdown table syntax
    if ! echo "$ISSUE_ROW" | grep -qE '^\|.*\|'; then
        die "invalid --append-issue row: must be a pipe-delimited markdown table row starting and ending with '|'" 4
    fi

    # Append the row
    printf '%s\n' "$ISSUE_ROW" >> "$issues_file"
    echo "OK: $issues_file -- issue row appended"
}

# ---------------------------------------------------------------------------
# Mode: --pipeline --field FIELD --value VALUE
# Write/update a single field in the ## Pipeline State block of the work STATE.md.
# The block shape (grep-recoverable **Field:** value lines) matches the
# work-state-template.md ## Pipeline State section.
#
# Fields (canonical casing): Lifecycle | Phase | Active Skill | Updated |
#   Pause Reason | Block Reason | Block Artifact
#
# Enum-validated fields (closed enums from work-state-template.md):
#   Lifecycle:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
#   Phase:        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
#   Active Skill: any string matching "aid-{skill}" pattern, or "none"
#
# Conditional fields (written only when Lifecycle matches; cleared otherwise):
#   Pause Reason   -> present only when Lifecycle = Paused-Awaiting-Input
#   Block Reason   -> present only when Lifecycle = Blocked
#   Block Artifact -> present only when Lifecycle = Blocked
#
# Creates the ## Pipeline State section if absent. Emits no user-facing
# output (C4 behavior-preserving). Acquires the existing sentinel lock.
# ---------------------------------------------------------------------------
mode_pipeline() {
    if [[ ! -f "$STATE_FILE" ]]; then
        die "$STATE_FILE does not exist" 1
    fi

    # Validate field name (canonical casing stored; comparison is case-insensitive)
    local field_lower
    field_lower="${FIELD,,}"
    local canonical_field
    case "$field_lower" in
        lifecycle)       canonical_field="Lifecycle" ;;
        phase)           canonical_field="Phase" ;;
        "active skill")  canonical_field="Active Skill" ;;
        updated)         canonical_field="Updated" ;;
        "pause reason")  canonical_field="Pause Reason" ;;
        "block reason")  canonical_field="Block Reason" ;;
        "block artifact") canonical_field="Block Artifact" ;;
        *) die "unknown --pipeline field '$FIELD'; allowed: Lifecycle Phase \"Active Skill\" Updated \"Pause Reason\" \"Block Reason\" \"Block Artifact\"" 4 ;;
    esac

    # Enum validation for closed-enum fields
    case "$canonical_field" in
        Lifecycle)
            case "$FIELD_VALUE" in
                Running|Paused-Awaiting-Input|Blocked|Completed|Canceled) ;;
                *) die "invalid Lifecycle value '$FIELD_VALUE'; must be one of: Running | Paused-Awaiting-Input | Blocked | Completed | Canceled" 4 ;;
            esac
            ;;
        Phase)
            case "$FIELD_VALUE" in
                Interview|Specify|Plan|Detail|Execute|Deploy|Monitor) ;;
                *) die "invalid Phase value '$FIELD_VALUE'; must be one of: Interview | Specify | Plan | Detail | Execute | Deploy | Monitor" 4 ;;
            esac
            ;;
        "Active Skill")
            # Accepts aid-{skill} (aid- prefix followed by at least one char) or "none"
            if [[ "$FIELD_VALUE" != "none" ]] && ! [[ "$FIELD_VALUE" =~ ^aid-[a-zA-Z0-9_-]+$ ]]; then
                die "invalid Active Skill value '$FIELD_VALUE'; must match aid-{skill} or be \"none\"" 4
            fi
            ;;
    esac

    init_lock_file "$STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)

    # Accept both old "## Pipeline Status" and new "## Pipeline State" section headers.
    # On create/update, always write "## Pipeline State" (the renamed header from task-001).
    if grep -qE '^## Pipeline Stat(us|e)' "$STATE_FILE"; then
        # Section exists (either name) -- update/add the target field within it, and manage
        # conditional fields when Lifecycle changes.
        awk \
            -v field="$canonical_field" \
            -v value="$FIELD_VALUE" \
            '
            BEGIN {
                in_ps = 0
                field_written = 0
            }

            /^## Pipeline Stat(us|e)/ {
                in_ps = 1
                # Normalize header to "## Pipeline State" on every rewrite
                print "## Pipeline State"
                next
            }

            in_ps && /^## / {
                # Leaving the section -- flush any field not yet written
                if (!field_written) {
                    print "- **" field ":** " value
                    field_written = 1
                }
                in_ps = 0
                print
                next
            }

            in_ps {
                # Check if this line is a **Field:** line in the block.
                # Format: - **Field:** value  (colon is inside the bold markers)
                if ($0 ~ /^- \*\*[^*]+:\*\*/) {
                    # Extract field name between ** markers (strip colon too)
                    line = $0
                    sub(/^- \*\*/, "", line)
                    sub(/:\*\*.*$/, "", line)
                    cur_field = line

                    if (cur_field == field) {
                        # Replace with the new value
                        print "- **" field ":** " value
                        field_written = 1
                        next
                    }

                    # For conditional Pause/Block fields: suppress them when
                    # we are writing Lifecycle and the new Lifecycle does not
                    # match the condition.
                    if (field == "Lifecycle") {
                        if (cur_field == "Pause Reason" && value != "Paused-Awaiting-Input") {
                            # Clear -- omit this line
                            next
                        }
                        if ((cur_field == "Block Reason" || cur_field == "Block Artifact") && value != "Blocked") {
                            # Clear -- omit this line
                            next
                        }
                    }
                }
                print
                next
            }

            { print }

            END {
                if (!field_written) {
                    print "- **" field ":** " value
                }
            }
            ' "$STATE_FILE" > "$tmp"
    else
        # ## Pipeline State section absent -- build a minimal block and append.
        {
            cat "$STATE_FILE"
            printf '\n'
            printf '## Pipeline State\n'
            printf '\n'
            printf '> Single-source derivation summary for read-only consumers (the dashboard reader).\n'
            printf '> Written ONLY by the helper `writeback-state.sh --pipeline ...` at every existing\n'
            printf '> phase/state transition the pipeline already performs. Never hand-edited. All values are\n'
            printf '> closed enums so a deterministic reader needs no inference.\n'
            printf '>\n'
            printf '> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled\n'
            printf '> Phase enum:        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor\n'
            printf '> Active Skill enum: aid-{skill} | none\n'
            printf '\n'
            # Write all 7 field lines; for the target field use the provided value;
            # for others use a dash placeholder (will be updated by later calls).
            local lc ph as up pr br ba
            lc="-"; ph="-"; as="-"; up="-"; pr=""; br=""; ba=""
            case "$canonical_field" in
                Lifecycle)       lc="$FIELD_VALUE" ;;
                Phase)           ph="$FIELD_VALUE" ;;
                "Active Skill")  as="$FIELD_VALUE" ;;
                Updated)         up="$FIELD_VALUE" ;;
                "Pause Reason")  pr="$FIELD_VALUE" ;;
                "Block Reason")  br="$FIELD_VALUE" ;;
                "Block Artifact") ba="$FIELD_VALUE" ;;
            esac
            echo "- **Lifecycle:** $lc"
            echo "- **Phase:** $ph"
            echo "- **Active Skill:** $as"
            echo "- **Updated:** $up"
            # Conditional fields: only emit if relevant
            [[ -n "$pr" ]] && echo "- **Pause Reason:** $pr"
            [[ -n "$br" ]] && echo "- **Block Reason:** $br"
            [[ -n "$ba" ]] && echo "- **Block Artifact:** $ba"
        } > "$tmp"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $STATE_FILE preserved" 3
    fi

    # Sanity: ## Pipeline State section must be present in output (either name accepted)
    if ! grep -qE '^## Pipeline Stat(us|e)' "$tmp"; then
        rm -f "$tmp"
        die "## Pipeline State section was not written to output" 3
    fi

    mv "$tmp" "$STATE_FILE"
    # No user-facing output (C4)
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$MODE" in
    pipeline)            mode_pipeline ;;
    field)               mode_field ;;
    findings)            mode_findings ;;
    delivery-block)      mode_delivery_block ;;
    delivery-lifecycle)  mode_delivery_lifecycle ;;
    append-issue)        mode_append_issue ;;
    *) die "internal error: unknown mode '$MODE'" 1 ;;
esac
