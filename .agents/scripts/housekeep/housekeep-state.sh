#!/usr/bin/env bash
# housekeep-state.sh — read/write individual fields in the ## Housekeep Status
# block of the /aid-housekeep run-state file and resolve the resume target.
#
# The run-state file is project-level and transient:
# `.aid/.temp/HOUSEKEEP_STATE_<YYYYMMDDHHMM>.md` (gitignored; created on a fresh
# run, removed by the skill's DONE state). It is NOT a work-area STATE.md — the
# script is location-agnostic and operates on whatever path --state names.
#
# Purpose:
#   Provides deterministic read/write access to the nine `**Field:** value` lines
#   inside `## Housekeep Status` in the run-state file (created on first --write).
#   Also resolves the re-entry target for a resumed /aid-housekeep run by
#   implementing the six-row resume-detection table (feature-001 SPEC § "Resume detection").
#
#   No yq/python dependency — uses bash + grep/sed/awk only.
#
# Usage:
#   housekeep-state.sh --state FILE --write --field FIELD --value VALUE
#       Write (or replace) a **FIELD:** line in ## Housekeep Status.
#       Creates the section if absent. Idempotent: replaces existing line.
#
#   housekeep-state.sh --state FILE --read --field FIELD
#       Print the current value of **FIELD:** to stdout (empty string if absent).
#       Exit 0 even when the field or section is absent (prints empty line).
#
#   housekeep-state.sh --state FILE --resume [--cleanup-only]
#       Resolve the resume target based on the ## Housekeep Status block contents.
#       Prints one of: KB-DELTA  SUMMARY-DELTA  CLEANUP  DONE  PREFLIGHT
#       --cleanup-only is only consulted when no ## Housekeep Status section exists.
#
#   housekeep-state.sh -h | --help
#       Print this help.
#
# Exit codes:
#   0  success (read, write, or resume resolution completed)
#   1  STATE.md file not found / unreadable
#   2  argument error (unknown flag, missing required value, incompatible flags)
#   3  write verification failed (output sanity check)
#
# Output:
#   stdout: resolved value (--read), resume target (--resume), or "OK: ..." (--write)
#   stderr: error messages on failure

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
    sed -n '2,43p' "$0" | sed 's/^# \{0,1\}//'
}

die() { echo "ERROR: housekeep-state.sh: $*" >&2; exit "${2:-1}"; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
STATE_FILE=""
MODE=""
FIELD=""
FIELD_VALUE=""
CLEANUP_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --state)
            [[ $# -lt 2 ]] && die "--state requires a value" 2
            STATE_FILE="$2"; shift 2
            ;;
        --write)
            [[ -n "$MODE" ]] && die "--write, --read, and --resume are mutually exclusive" 2
            MODE="write"; shift
            ;;
        --read)
            [[ -n "$MODE" ]] && die "--write, --read, and --resume are mutually exclusive" 2
            MODE="read"; shift
            ;;
        --resume)
            [[ -n "$MODE" ]] && die "--write, --read, and --resume are mutually exclusive" 2
            MODE="resume"; shift
            ;;
        --field)
            [[ $# -lt 2 ]] && die "--field requires a value" 2
            FIELD="$2"; shift 2
            ;;
        --value)
            [[ $# -lt 2 ]] && die "--value requires a value" 2
            FIELD_VALUE="$2"; shift 2
            ;;
        --cleanup-only)
            CLEANUP_ONLY=1; shift
            ;;
        *)
            die "unknown argument: $1" 2
            ;;
    esac
done

# Validate required args
[[ -z "$STATE_FILE" ]] && die "--state FILE is required" 2
[[ -z "$MODE" ]]       && die "one of --write, --read, or --resume is required" 2

if [[ "$MODE" == "write" ]]; then
    [[ -z "$FIELD" ]]       && die "--field is required with --write" 2
    [[ -z "$FIELD_VALUE" ]] && die "--value is required with --write" 2
fi

if [[ "$MODE" == "read" ]]; then
    [[ -z "$FIELD" ]] && die "--field is required with --read" 2
fi

# File-existence handling. The state file is the project-level housekeep run-state
# (.aid/.temp/HOUSEKEEP_STATE_<ts>.md), which does NOT exist on a fresh run:
#   - write : create the file (+ parent dir) if absent — fresh-run init.
#   - read  : absent file → print empty value, exit 0.
#   - resume: absent file → resolve as if no ## Housekeep Status section (row 1/2).
if [[ ! -f "$STATE_FILE" ]]; then
    case "$MODE" in
        write)
            mkdir -p "$(dirname "$STATE_FILE")" 2>/dev/null || true
            : > "$STATE_FILE" || die "cannot create STATE file: $STATE_FILE" 1
            ;;
        read)
            echo ""
            exit 0
            ;;
        resume)
            if [[ "$CLEANUP_ONLY" -eq 1 ]]; then echo "CLEANUP"; else echo "PREFLIGHT"; fi
            exit 0
            ;;
    esac
fi

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
SECTION_HEADING="## Housekeep Status"

# Valid field names for the ## Housekeep Status block (C-2 table)
VALID_FIELDS=(
    "State"
    "Stage Status"
    "Branch"
    "Mode"
    "Stall Reason"
    "Last Run"
    "KB Stage"
    "Summary Stage"
    "Cleanup Stage"
)

# ---------------------------------------------------------------------------
# Helper: check whether the ## Housekeep Status section exists in FILE
# ---------------------------------------------------------------------------
section_exists() {
    grep -q "^${SECTION_HEADING}" "$STATE_FILE"
}

# ---------------------------------------------------------------------------
# Helper: read the raw value for a given field from the section.
# Prints the value (may be empty). Exits 0 whether or not the field exists.
# Scans only lines inside ## Housekeep Status (up to the next ## heading or EOF).
# ---------------------------------------------------------------------------
read_field() {
    local field="$1"
    # Escape field name for use in awk pattern (handle spaces in field names)
    awk -v section="$SECTION_HEADING" -v field="$field" '
        $0 == section           { in_section=1; next }
        in_section && /^## /    { in_section=0; next }
        in_section {
            # Match: **Field:** value  (leading ** and trailing **)
            pat = "^\\*\\*" field ":\\*\\* "
            if (match($0, pat)) {
                val = substr($0, RLENGTH + 1)
                # strip trailing whitespace
                gsub(/[[:space:]]+$/, "", val)
                print val
                exit
            }
            # Also handle case where value is empty: "**Field:**" (no trailing space+value)
            pat2 = "^\\*\\*" field ":\\*\\*$"
            if (match($0, pat2)) {
                print ""
                exit
            }
        }
    ' "$STATE_FILE"
}

# ---------------------------------------------------------------------------
# Helper: write (create or replace) a **Field:** line in the section.
# If the section does not exist, appends it to the file.
# If the field line already exists, replaces it (idempotent).
# If the section exists but lacks the field, appends the field before the
# next ## heading (or at EOF of the section).
# ---------------------------------------------------------------------------
write_field() {
    local field="$1"
    local value="$2"
    local new_line="**${field}:** ${value}"
    local tmp
    tmp=$(mktemp)

    if ! section_exists; then
        # Section absent — append the section + the field line at EOF
        {
            cat "$STATE_FILE"
            echo ""
            echo "$SECTION_HEADING"
            echo ""
            echo "$new_line"
        } > "$tmp"
    else
        # Section present — check if field line already exists
        local field_pattern="^\\*\\*${field}:\\*\\* "
        local field_pattern2="^\\*\\*${field}:\\*\\*$"
        if grep -qE "(${field_pattern}|${field_pattern2})" "$STATE_FILE"; then
            # Field exists — replace the line within the section
            awk -v section="$SECTION_HEADING" \
                -v field="$field" \
                -v new_line="$new_line" '
                $0 == section        { in_section=1; print; next }
                in_section && /^## / { in_section=0 }
                in_section {
                    # Check if this line matches the field pattern
                    pat  = "^\\*\\*" field ":\\*\\* "
                    pat2 = "^\\*\\*" field ":\\*\\*$"
                    if (match($0, pat) || match($0, pat2)) {
                        print new_line
                        next
                    }
                }
                { print }
            ' "$STATE_FILE" > "$tmp"
        else
            # Section exists but field absent — insert the field at the end
            # of the section (before the next ## heading, or at EOF)
            awk -v section="$SECTION_HEADING" \
                -v new_line="$new_line" '
                BEGIN { in_section=0; inserted=0 }
                $0 == section        { in_section=1; print; next }
                in_section && /^## / {
                    if (!inserted) {
                        print new_line
                        inserted=1
                    }
                    in_section=0
                    print
                    next
                }
                { print }
                END {
                    if (in_section && !inserted) {
                        print new_line
                    }
                }
            ' "$STATE_FILE" > "$tmp"
        fi
    fi

    # Sanity checks
    [[ ! -s "$tmp" ]] && { rm -f "$tmp"; die "write produced empty output; $STATE_FILE preserved" 3; }
    if ! grep -qF "$new_line" "$tmp"; then
        rm -f "$tmp"
        die "field line not found in output after write; $STATE_FILE preserved" 3
    fi

    mv "$tmp" "$STATE_FILE"
    echo "OK: $STATE_FILE updated — **${field}:** set to '${value}'"
}

# ---------------------------------------------------------------------------
# Mode: --read
# ---------------------------------------------------------------------------
mode_read() {
    if ! section_exists; then
        echo ""
        exit 0
    fi
    read_field "$FIELD"
}

# ---------------------------------------------------------------------------
# Mode: --write
# ---------------------------------------------------------------------------
mode_write() {
    write_field "$FIELD" "$FIELD_VALUE"
}

# ---------------------------------------------------------------------------
# Mode: --resume
# Implements the six-row re-entry table from SPEC § "Resume detection":
#
# Row 1: No section, no --cleanup-only         -> PREFLIGHT (-> KB-DELTA)
# Row 2: No section, --cleanup-only            -> CLEANUP   (Mode=cleanup-only)
# Row 3: **KB Stage:** stalled/running/—       -> KB-DELTA
# Row 4: KB passed/skipped AND Summary stalled/running/— -> SUMMARY-DELTA
# Row 5: KB+Summary passed/skipped AND Cleanup not passed -> CLEANUP
# Row 6: All three passed/skipped AND State=DONE -> DONE (nothing to resume)
# ---------------------------------------------------------------------------
mode_resume() {
    # Row 1 & 2: No section present
    if ! section_exists; then
        if [[ "$CLEANUP_ONLY" -eq 1 ]]; then
            echo "CLEANUP"
        else
            echo "PREFLIGHT"
        fi
        exit 0
    fi

    # Section present — read the three gate-ledger fields
    local kb_stage summary_stage cleanup_stage state_val
    kb_stage=$(read_field "KB Stage")
    summary_stage=$(read_field "Summary Stage")
    cleanup_stage=$(read_field "Cleanup Stage")
    state_val=$(read_field "State")

    # Helper: returns true (0) if a stage value counts as "passed or skipped"
    is_complete() {
        local v="$1"
        [[ "$v" == "passed" || "$v" == "skipped" ]]
    }

    # Row 3: KB Stage is NOT passed/skipped
    if ! is_complete "$kb_stage"; then
        echo "KB-DELTA"
        exit 0
    fi

    # Row 4: KB is complete but Summary is NOT complete
    if ! is_complete "$summary_stage"; then
        echo "SUMMARY-DELTA"
        exit 0
    fi

    # Row 5: KB + Summary complete but Cleanup is NOT passed
    if [[ "$cleanup_stage" != "passed" ]]; then
        echo "CLEANUP"
        exit 0
    fi

    # Row 6: All three complete AND State is DONE
    if [[ "$state_val" == "DONE" ]]; then
        echo "DONE"
        exit 0
    fi

    # Fallback: all stage fields indicate completion but State is not DONE yet
    # (e.g. run was interrupted after all stages passed but before DONE was written).
    # Route to CLEANUP as the last stage to let it finalize and chain to DONE.
    echo "CLEANUP"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$MODE" in
    read)   mode_read ;;
    write)  mode_write ;;
    resume) mode_resume ;;
    *)      die "internal error: unknown mode '$MODE'" 2 ;;
esac
