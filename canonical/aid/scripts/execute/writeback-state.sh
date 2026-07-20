#!/usr/bin/env bash
# writeback-state.sh -- row-level write coordination for FR6 parallel pool
# x per-unit STATE writes in AID aid-execute.
#
# Provides 8 safe write modes targeting PER-UNIT STATE.md files (Pillar 2).
# Uses a sentinel-file lock (set -o noclobber + atomic create + sleep-poll retry)
# to prevent races when multiple parallel tasks dispatch reviewers concurrently.
#
# Frontmatter-writer path (work-003-state-schema task-004): every machine-parsed
# field (pipeline/task-state/delivery-lifecycle/delivery-gate scalars) is written
# via a surgical YAML-frontmatter rewrite (`wb_set_frontmatter`, below) -- a single
# flat top-level key (e.g. `lifecycle`) or one-level-nested key (e.g.
# `pipeline.path`) is created-or-updated in the leading `---`...`---` block at the
# top of the target STATE.md, and the markdown BODY (everything from the first
# non-frontmatter line onward) is never touched -- byte-identical before/after.
# This replaces the OLDER convention (pre-task-004) of rewriting a
# `- **Field:** value` bullet inside a body section -- the 4 canonical templates
# (task-001) moved every one of these scalars into frontmatter, so the body
# sections they used to live in (`## Pipeline State`, `## Task State`,
# `## Delivery Lifecycle`'s `- **State:**` line, `## Delivery Gate`'s
# `- **Reviewer Tier:**`/`- **Grade:**`/`- **Timestamp:**` lines) are now static
# enum-reference/comment-only prose, never rewritten by this script. Values are
# single-quoted (`'...'`, doubling any embedded `'`) in the emitted YAML only
# when the raw text needs it (contains a `:`/`#`/`"`/`\`/leading special char);
# closed-enum/short tokens (`Running`, `yes`, `A+`, `aid-refactor`) are written
# bare, matching the 4 templates' own placeholder style. See
# WB_SET_FRONTMATTER_AWK's own doc comment for why single-quote style (not
# double-quote + backslash-escaping) is used. `wb_set_frontmatter` creates the
# frontmatter block from scratch (at the very top of the file) when the target
# file has none yet, so a not-yet-migrated (task-005) STATE.md degrades
# gracefully instead of failing.
#
# Unit layout (work-004 hierarchy):
#   work-NNN-{name}/
#     STATE.md                                  -- work-level (--pipeline target)
#     deliveries/
#       delivery-NNN/
#         STATE.md                              -- delivery-level (--block / --lifecycle target)
#         tasks/
#           task-NNN/
#             STATE.md                          -- task-level (--field / --findings target)
#
# Flattened single-delivery layout (feature-001, additive -- nested layout above
# is unchanged): detected by a work-root BLUEPRINT.md present AND
# `tasks/task-NNN/DETAIL.md` present directly under the work root AND no
# `deliveries/` wrapper. The delivery lifecycle/gate AND the per-task mutable
# cells are all promoted into the SAME work-root STATE.md:
#   work-NNN-{name}/
#     STATE.md          -- work-level (--pipeline target) AND, for this layout,
#                           the --delivery-id 001 targets too:
#                             ## Delivery Lifecycle  (--lifecycle target)
#                             ## Delivery Gate        (--block target)
#                             ### Tasks lifecycle     (--task-id/--field target;
#                                                       a table row per task-NNN,
#                                                       replacing the per-task
#                                                       STATE.md ## Task State)
#     tasks/
#       task-NNN/
#         DETAIL.md      -- task definition (no per-task STATE.md in this layout)
#
# Usage:
#   writeback-state.sh [--delivery-id NNN] --task-id NNN --field FIELD --value VALUE
#       Full-nested layout: surgical frontmatter write of a single scalar key
#       (state | review | elapsed | notes) in the leading YAML block of
#       deliveries/delivery-NNN/tasks/task-NNN/STATE.md (one-writer-per-branch file);
#       the ## Task State body section is static comment-only prose and is never
#       rewritten by this mode (task-004).
#       Fields: State | Review | Elapsed | Notes
#       --delivery-id is optional; if omitted the delivery is resolved from the
#       task's Source line (e.g. "**Source:** work-NNN -> delivery-NNN").
#       Override env: AID_TASK_STATE_FILE (absolute path) skips all path resolution.
#       Flattened layout (feature-001, auto-detected): targets the matching
#       task-NNN row of the work-root STATE.md's ### Tasks lifecycle table instead
#       (creates the row on first write; replaces the placeholder "_none yet_" row).
#       This table is NOT relocated to frontmatter (schema-note.md): it aggregates
#       many tasks in one file, so it stays a markdown table; this branch is
#       unchanged by task-004.
#
#   writeback-state.sh [--delivery-id NNN] --task-id NNN --findings BLOCK
#       Write/replace the ## Quick Check Findings block in
#       deliveries/delivery-NNN/tasks/task-NNN/STATE.md.
#       Same delivery resolution as --field mode.
#
#   writeback-state.sh --delivery-id NNN --block MARKDOWN_BLOCK
#       Write/replace the ## Delivery Gate block in deliveries/delivery-NNN/STATE.md (SD-5).
#       Override env: AID_DELIVERY_STATE_FILE (absolute path) skips path resolution.
#       Flattened layout (feature-001, auto-detected; --delivery-id 001): writes
#       the singular ## Delivery Gate block into the work-root STATE.md instead.
#
#   writeback-state.sh --delivery-id NNN --lifecycle VALUE
#       Surgical frontmatter write of the `delivery_state` key (SD-8 authored
#       delivery state) -- the ## Delivery Lifecycle body's `- **State:**` bullet
#       was relocated to frontmatter by task-001 and is never rewritten here
#       (task-004); the body's Updated/Block Reason/Block Artifact bullets are
#       untouched (not relocated -- see schema-note.md).
#       VALUE must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked
#       Override env: AID_DELIVERY_STATE_FILE (absolute path) skips path resolution.
#       Emits no user-facing output (C4 behavior-preserving).
#       Flattened layout (feature-001, auto-detected; --delivery-id 001): targets
#       the work-root STATE.md's own frontmatter instead (same `delivery_state` key;
#       see work-state-template.md's "Flattened single-delivery works only" group).
#
#   writeback-state.sh --delivery-id NNN --gate-field FIELD --gate-value VALUE
#       Surgical frontmatter write of one Delivery Gate scalar (relocated by
#       task-001; the ## Delivery Gate body block -- written via --block below --
#       now carries only Complexity Score / Cycles / Issue List, never these three).
#       FIELD must be one of: Tier | Grade | Timestamp -> gate_tier | gate_grade | gate_timestamp
#       Tier is closed-enum validated (Small | Medium | Large); Grade must match
#       ^[A-F][+-]?$ (grade.sh's own output alphabet). Timestamp is free ISO-8601 text.
#       Override env: AID_DELIVERY_STATE_FILE (absolute path) skips path resolution.
#       Emits no user-facing output (C4 behavior-preserving).
#       Flattened layout (feature-001, auto-detected; --delivery-id 001): targets
#       the work-root STATE.md's own frontmatter instead (same 3 keys).
#
#   writeback-state.sh --delivery-id NNN --append-issue ROW
#       Append a single issue row to the delivery's delivery-NNN-issues.md.
#       ROW must be a valid markdown table row (pipe-delimited).
#
#   writeback-state.sh --pipeline --field FIELD --value VALUE
#       Surgical frontmatter write of a single scalar key in the leading YAML
#       block of the work STATE.md (relocated by task-001; the ## Pipeline State
#       body section is now a static enum-reference blockquote and is never
#       rewritten by this mode). FIELD must be one of: Lifecycle | Phase |
#         Active Skill | Updated | Pause Reason | Block Reason | Block Artifact |
#         Started | Minimum Grade | User Approved | Pipeline Path | Pipeline Initiator
#       Lifecycle, Phase, Active Skill, User Approved, and Pipeline Path are
#       closed-enum validated; Minimum Grade must match ^[A-F][+-]?$.
#       Conditional fields: Pause Reason written only when Lifecycle is
#         Paused-Awaiting-Input; Block Reason + Block Artifact written only when
#         Lifecycle is Blocked. On Lifecycle change, conditional fields that no
#         longer apply are cleared (reset to the "--" null sentinel in frontmatter).
#       Emits no user-facing output (C4 behavior-preserving).
#
#   writeback-state.sh -h | --help
#
# Flattened single-delivery layout (feature-001) detection: a work-root
# BLUEPRINT.md present AND at least one `tasks/task-NNN/DETAIL.md` present
# directly under it AND no `deliveries/` wrapper under the work root.
# Auto-detected per-call; no new flag needed. The nested layout above is
# unchanged (additive only).
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
STATE_FILE="${AID_STATE_FILE:-.aid/works/work/STATE.md}"

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
DELIVERY_ISSUES_DIR="${AID_DELIVERY_ISSUES_DIR:-.aid/works/work}"

# Lock directory -- defaults to derived per-call below (see acquire_lock)
LOCK_DIR="${AID_LOCK_DIR:-}"

LOCK_TIMEOUT="${AID_LOCK_TIMEOUT:-10}"   # max retries (0.5s each -> 5s default)

# ---------------------------------------------------------------------------
usage() {
    sed -n '2,146p' "$0" | sed 's/^# \{0,1\}//'
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

# is_flat_layout: return 0 (true) when the work uses the FLATTENED
# single-delivery layout (feature-001) -- a work-root BLUEPRINT.md is present
# AND at least one `tasks/task-NNN/DETAIL.md` is present directly under the
# work root AND no `deliveries/` wrapper exists. Mirrors the SAME 3-part
# detection rule used by aid-execute's SKILL.md / state-execute.md /
# state-delivery-gate.md and the dashboard reader twins (reader.py
# `_detect_flat` / reader.mjs `_detectFlat`) -- all consumers assert all three
# parts identically (BLUEPRINT.md presence, DETAIL.md presence, deliveries/
# absence). Presence-based; never throws. Auto-detected per-call -- no new
# CLI flag needed.
is_flat_layout() {
    resolve_work_dir
    [[ -f "${WORK_DIR}/BLUEPRINT.md" ]] || return 1
    [[ -d "${WORK_DIR}/deliveries" ]] && return 1
    local f
    for f in "${WORK_DIR}"/tasks/task-*/DETAIL.md; do
        [[ -f "$f" ]] && return 0
    done
    return 1
}

# resolve_task_state_file DELIVERY_ID TASK_ID
# Sets TASK_STATE_FILE to deliveries/delivery-NNN/tasks/task-NNN/STATE.md under the work root.
# If TASK_STATE_FILE is already set (env override), this is a no-op.
resolve_task_state_file() {
    local delivery_id="$1" task_id="$2"
    if [[ -n "$TASK_STATE_FILE" ]]; then
        return 0
    fi
    resolve_work_dir
    local padded_d padded_t
    # Force base-10 arithmetic before padding: a zero-padded id containing 8/9
    # (e.g. "008", "090") would otherwise be parsed as an invalid octal literal.
    padded_d=$(printf '%03d' "$((10#$delivery_id))")
    padded_t=$(printf '%03d' "$((10#$task_id))")
    if [[ -n "$DELIVERY_DIR_BASE" ]]; then
        TASK_STATE_FILE="${DELIVERY_DIR_BASE}/tasks/task-${padded_t}/STATE.md"
    else
        TASK_STATE_FILE="${WORK_DIR}/deliveries/delivery-${padded_d}/tasks/task-${padded_t}/STATE.md"
    fi
}

# resolve_delivery_state_file DELIVERY_ID
# Sets DELIVERY_STATE_FILE to deliveries/delivery-NNN/STATE.md under the work root.
# If DELIVERY_STATE_FILE is already set (env override), this is a no-op.
# feature-001 flattened layout (auto-detected): with no `deliveries/` wrapper
# there is exactly one delivery and its lifecycle/gate blocks are promoted
# directly into the work-root STATE.md (the SAME file as --pipeline), so this
# targets $STATE_FILE instead of a per-delivery STATE.md.
resolve_delivery_state_file() {
    local delivery_id="$1"
    if [[ -n "$DELIVERY_STATE_FILE" ]]; then
        return 0
    fi
    resolve_work_dir
    if is_flat_layout; then
        DELIVERY_STATE_FILE="$STATE_FILE"
        return 0
    fi
    local padded_d
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_d=$(printf '%03d' "$((10#$delivery_id))")
    if [[ -n "$DELIVERY_DIR_BASE" ]]; then
        DELIVERY_STATE_FILE="${DELIVERY_DIR_BASE}/STATE.md"
    else
        DELIVERY_STATE_FILE="${WORK_DIR}/deliveries/delivery-${padded_d}/STATE.md"
    fi
}

# resolve_delivery_from_task_spec TASK_ID -> sets DELIVERY_ID_RESOLVED
# Reads the task DETAIL.md (deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md or legacy tasks/task-NNN.md)
# and extracts the delivery number from "**Source:** ... -> delivery-NNN" or
# "**Source:** ... delivery-NNN ...".
# Returns "" when resolution fails (caller must require --delivery-id).
DELIVERY_ID_RESOLVED=""
resolve_delivery_from_task_spec() {
    local task_id="$1"
    DELIVERY_ID_RESOLVED=""
    resolve_work_dir
    local padded_t
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_t=$(printf '%03d' "$((10#$task_id))")

    # Try legacy flat task spec first (tasks/task-NNN.md)
    local spec_file="${WORK_DIR}/tasks/task-${padded_t}.md"
    if [[ ! -f "$spec_file" ]]; then
        # Try hierarchical path: scan all deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md
        local found
        found=$(find "${WORK_DIR}" -path "*/tasks/task-${padded_t}/DETAIL.md" 2>/dev/null | head -1)
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
GATE_FIELD=""
GATE_VALUE=""

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
        --gate-field)
            [[ $# -lt 2 ]] && die "--gate-field requires a value" 5
            GATE_FIELD="$2"; shift 2
            ;;
        --gate-value)
            [[ $# -lt 2 ]] && die "--gate-value requires a value" 5
            GATE_VALUE="$2"; shift 2
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
elif [[ -n "$DELIVERY_ID" && -n "$GATE_FIELD" ]]; then
    MODE="gate-field"
    [[ -z "$GATE_VALUE" ]] && die "--gate-value is required with --gate-field" 5
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
# Otherwise attempt resolution from the task DETAIL.md Source line.
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
    # Distinguish missing lock directory (ENOENT) from lock contention (EEXIST).
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
# WB_SET_FRONTMATTER_AWK -- the awk program body used by wb_set_frontmatter,
# below. Kept as a single shared string (rather than duplicated inline across
# the CRLF and plain-LF invocation paths) so the two call sites can never drift.
#
# Reads the RAW value from ENVIRON (not an awk `-v` assignment) because awk's
# `-v var=value` re-processes C-style escape sequences in `value` -- a `\"`
# assigned this way silently becomes `"`, corrupting any caller-side
# backslash-escaping and producing invalid YAML for a value containing a
# literal `"` or `\` (task-004 FIX review, finding 1). ENVIRON values are NOT
# escape-reprocessed, so the value arrives byte-for-byte, and ALL YAML
# quoting/escaping happens here in awk, working from those exact bytes:
#   - a "bare-word-safe" value (letters/digits/`_.+/-` only) is emitted
#     unquoted, matching the 4 canonical templates' own placeholder style
#     (`lifecycle: Running`, not `lifecycle: "Running"`).
#   - anything else is emitted as a SINGLE-quoted YAML scalar (`'...'`),
#     doubling any embedded `'` -- the only escaping a single-quoted YAML
#     scalar ever needs, so this is valid for ANY byte sequence (colons,
#     hashes, double quotes, backslashes, a leading `-`/`{`) with no
#     backslash-escaping at all (unlike double-quoted style, which would
#     reintroduce the same backslash-escaping problem this fix exists to
#     avoid). A `sprintf("%c", 39)`-produced single-quote character stands in
#     for a literal `'` in this program's own source text, only to avoid the
#     bash single-quote-escaping gymnastics of embedding a literal `'` inside
#     the single-quoted string this whole program is written as.
# ---------------------------------------------------------------------------
WB_SET_FRONTMATTER_AWK='
    BEGIN {
        in_fm = 0; in_parent = 0; parent_seen = 0; done = 0
        sq = sprintf("%c", 39)
        raw = ENVIRON["WB_FM_RAW_VALUE"]
        if (raw ~ /^[A-Za-z0-9_.+\/-]+$/) {
            out_value = raw
        } else {
            gsub(sq, sq sq, raw)
            out_value = sq raw sq
        }
    }

    NR == 1 && $0 ~ /^---[ \t]*\r?$/ {
        in_fm = 1
        print
        next
    }
    NR == 1 {
        # No frontmatter block present -- synthesize one, then fall through
        # to print this same first line as the first BODY line, unmodified.
        print "---"
        if (parent == "") {
            print flat_key ": " out_value
        } else {
            print parent ":"
            print "  " child ": " out_value
        }
        print "---"
        print ""
        print
        next
    }

    in_fm && /^---[ \t]*\r?$/ {
        # Closing fence -- flush an unwritten key here (append at block end).
        # parent_seen distinguishes "parent mapping exists but child is
        # missing" (print only the child line, under the existing parent)
        # from "parent mapping never appeared at all in this frontmatter
        # block" (print BOTH a fresh parent header and the child line --
        # otherwise the child would be emitted with no parent, corrupting
        # the YAML and never satisfying the nested `key.child` lookup).
        if (parent == "" && !done) { print flat_key ": " out_value; done = 1 }
        if (parent != "" && !done) {
            if (!parent_seen) { print parent ":" }
            print "  " child ": " out_value
            done = 1
        }
        in_fm = 0
        in_parent = 0
        print
        next
    }

    in_fm && parent == "" {
        if ($0 ~ ("^" flat_key ":")) {
            print flat_key ": " out_value
            done = 1
            next
        }
        print
        next
    }

    in_fm && parent != "" {
        if (!in_parent) {
            if ($0 ~ ("^" parent ":")) {
                in_parent = 1
                parent_seen = 1
                print
                next
            }
            print
            next
        }
        # Inside the parent mapping -- another top-level key (col 0) ends it
        if ($0 ~ /^[A-Za-z0-9_-]+:/) {
            if (!done) { print "  " child ": " out_value; done = 1 }
            in_parent = 0
            print
            next
        }
        if ($0 ~ ("^[ \t]+" child ":")) {
            print "  " child ": " out_value
            done = 1
            next
        }
        print
        next
    }

    { print }
'

# ---------------------------------------------------------------------------
# wb_set_frontmatter SOURCE_FILE KEY VALUE
# Surgical YAML-frontmatter scalar writer (work-003-state-schema task-004).
# Prints the rewritten file content to stdout; caller redirects to a temp file
# (`wb_set_frontmatter "$STATE_FILE" lifecycle Running > "$tmp"`) and is
# responsible for the lock + sanity-check + atomic mv (same discipline as
# every other mode in this script -- this helper only computes the bytes).
#
# KEY is either a flat top-level scalar ("lifecycle") or a one-level-nested
# dotted key ("pipeline.path" -> the `path` child of the `pipeline:` mapping).
# Reads/updates ONLY the leading `---`...`---` frontmatter block; every line
# from the closing fence onward (the markdown BODY) is reproduced byte-for-byte
# unchanged -- this is what makes the write "surgical" (AC: body byte-invariance).
#
# Behavior:
#   - Key already present (even holding the template's own un-instantiated
#     placeholder text, e.g. "lifecycle: Running | Paused-Awaiting-Input | ...")
#     -> its line is replaced with the real single value.
#   - Key absent but its frontmatter block exists -> the key is appended at the
#     end of the block (flat) or at the end of its parent mapping (nested).
#   - No frontmatter block at all (a not-yet-migrated STATE.md, task-005) -> one
#     is synthesized at the very top of the file holding just this one key; the
#     entire original file becomes the BODY, unchanged.
#
# Value quoting: see WB_SET_FRONTMATTER_AWK's own doc comment above.
#
# Cross-platform byte-invariance guards (task-004 FIX review findings 2/4):
#   - CRLF: some awk builds (notably on Windows) silently strip a `\r` that is
#     part of $0 on read/print; a strict LF-only awk (Linux) never matches a
#     `---\r` fence line at all (the fence regex above tolerates a trailing
#     `\r` as defense-in-depth, but the real fix is architectural: a CRLF
#     source file is normalized to LF before the awk pass and every line of
#     the result has `\r` restored afterward, so the awk logic above only
#     ever sees plain LF content on every platform).
#   - Trailing newline: awk's `print` unconditionally appends ORS ("\n")
#     after every record including the last, so a source file with no final
#     newline would otherwise gain one. The pipeline's FULL output is
#     captured via an `X`-terminator (a character, not a newline, so `$(...)`
#     itself strips nothing) and the single spurious line terminator awk
#     added (`\n`, or `\r\n` for a CRLF source) is stripped back off only
#     when the source genuinely lacked a final one.
# ---------------------------------------------------------------------------
wb_set_frontmatter() {
    local source_file="$1" key="$2" value="$3"
    local parent="" child="$key"
    if [[ "$key" == *.* ]]; then
        parent="${key%%.*}"
        child="${key#*.}"
    fi

    local has_crlf=0 had_trailing_nl=1
    if [[ -s "$source_file" ]]; then
        local first_line=""
        IFS= read -r first_line < "$source_file" 2>/dev/null || true
        [[ "$first_line" == *$'\r' ]] && has_crlf=1
        [[ "$(tail -c1 "$source_file" | wc -l)" -eq 0 ]] && had_trailing_nl=0
    fi

    local raw_output
    if [[ "$has_crlf" -eq 1 ]]; then
        raw_output="$(
            sed 's/\r$//' "$source_file" \
                | WB_FM_RAW_VALUE="$value" awk -v parent="$parent" -v child="$child" -v flat_key="$key" "$WB_SET_FRONTMATTER_AWK" \
                | sed 's/$/\r/'
            printf 'X'
        )"
    else
        raw_output="$(
            WB_FM_RAW_VALUE="$value" awk -v parent="$parent" -v child="$child" -v flat_key="$key" "$WB_SET_FRONTMATTER_AWK" "$source_file"
            printf 'X'
        )"
    fi
    raw_output="${raw_output%X}"

    if [[ "$had_trailing_nl" -eq 0 ]]; then
        if [[ "$has_crlf" -eq 1 ]]; then
            raw_output="${raw_output%$'\r\n'}"
        else
            raw_output="${raw_output%$'\n'}"
        fi
    fi

    printf '%s' "$raw_output"
}

# wb_frontmatter_verify TMP_FILE KEY
# Sanity check after a wb_set_frontmatter write: the file is non-empty and the
# target key (flat or the dotted-nested child) is present in the output.
# Returns non-zero (caller must discard TMP_FILE and die) on failure.
wb_frontmatter_verify() {
    local tmp_file="$1" key="$2" child="$2"
    [[ -s "$tmp_file" ]] || return 1
    if [[ "$key" == *.* ]]; then
        child="${key#*.}"
        grep -q "^  ${child}:" "$tmp_file" || return 1
    else
        grep -q "^${key}:" "$tmp_file" || return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Mode: [--delivery-id NNN] --task-id NNN --field FIELD --value VALUE
# Update a single named field in the task's ## Task State section of
# delivery-NNN/tasks/task-NNN/STATE.md.
# Fields: State | Review | Elapsed | Notes
# State is enum-validated (closed enum).
# ---------------------------------------------------------------------------
mode_field() {
    # Reject --value containing literal '|' to prevent row corruption.
    if [[ "$FIELD_VALUE" == *"|"* ]]; then
        die "--value cannot contain '|' (pipe is the column separator); escape with HTML entity or rephrase" 4
    fi

    # Also reject newline characters (same row-corruption class as the pipe check).
    if [[ "$FIELD_VALUE" == *$'\n'* ]]; then
        die "--value cannot contain newline characters (row separator); rephrase to single line" 4
    fi

    # Validate field name (per-unit task STATE.md fields)
    local field_lower
    field_lower="${FIELD,,}"   # bash 4+ lowercase
    case "$field_lower" in
        state|review|elapsed|notes|name) ;;
        *) die "unknown field '$FIELD'; allowed: State Review Elapsed Notes Name" 4 ;;
    esac

    # Enum validation for the State field (closed enum).
    if [[ "$field_lower" == "state" ]]; then
        case "$FIELD_VALUE" in
            Pending|"In Progress"|"In Review"|Blocked|Done|Failed|Canceled|"_none yet_") ;;
            *) die "invalid State value '$FIELD_VALUE'; must be one of: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled (or the _none yet_ placeholder)" 4 ;;
        esac
    fi

    # feature-001 flattened layout (auto-detected): task cells live in the
    # work-root STATE.md ### Tasks lifecycle table -- no per-task STATE.md.
    # AID_TASK_STATE_FILE override (if set) bypasses ALL path resolution,
    # including this flat-layout check, per its documented contract above.
    if [[ -z "$TASK_STATE_FILE" ]] && is_flat_layout; then
        write_task_field_flat "$FIELD" "$field_lower" "$FIELD_VALUE" "$TASK_ID"
        return 0
    fi

    resolve_delivery_for_task_mode
    resolve_task_state_file "$DELIVERY_ID" "$TASK_ID"

    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        die "$TASK_STATE_FILE does not exist" 1
    fi

    # Verify ## Task State section exists (the body header itself is still
    # present -- only the "- **Field:** value" bullets under it were relocated
    # to frontmatter by task-001; this presence check still guards against a
    # malformed/foreign file).
    if ! grep -q '^## Task State' "$TASK_STATE_FILE"; then
        die "malformed task STATE.md: ## Task State section not found in $TASK_STATE_FILE" 6
    fi

    init_lock_file "$TASK_STATE_FILE"
    acquire_lock

    # Surgical frontmatter write (task-004): `state`/`review`/`elapsed`/`notes`
    # are flat top-level keys in task-state-template.md's frontmatter block --
    # field_lower IS the frontmatter key verbatim for those four, no mapping
    # needed. The ONE exception is `name` (feature-005): its reader key is
    # `display_name` (models.py TaskModel.display_name), so it is routed
    # through the same fm_key indirection mode_gate_field already uses for
    # Tier/Grade/Timestamp -> gate_* -- writing a literal `name:` key would be
    # silently unread by both dashboard reader twins.
    local fm_key="$field_lower"
    case "$field_lower" in
        name) fm_key="display_name" ;;
    esac

    local tmp
    tmp=$(mktemp)
    wb_set_frontmatter "$TASK_STATE_FILE" "$fm_key" "$FIELD_VALUE" > "$tmp"

    if ! wb_frontmatter_verify "$tmp" "$fm_key"; then
        rm -f "$tmp"
        die "writeback sanity check failed: frontmatter key '$fm_key' not found in output; $TASK_STATE_FILE preserved" 3
    fi

    # Sanity: ## Task State section must still be present in output (body untouched)
    if ! grep -q '^## Task State' "$tmp"; then
        rm -f "$tmp"
        die "writeback sanity check failed: ## Task State disappeared from output" 3
    fi

    mv "$tmp" "$TASK_STATE_FILE"
    local padded_t
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_t=$(printf '%03d' "$((10#$TASK_ID))")
    echo "OK: $TASK_STATE_FILE updated -- task $padded_t field '$FIELD' set to '$FIELD_VALUE' (frontmatter)"
}

# ---------------------------------------------------------------------------
# write_task_field_flat FIELD_RAW FIELD_LOWER NEW_VAL TASK_ID
# feature-001 flattened layout: rewrite (or create) the task's row in the
# work-root STATE.md's ### Tasks lifecycle table -- the single-writer home
# that REPLACES the now-absent per-task STATE.md ## Task State section.
# Table shape (byte-identical closed State enum -- validated by the caller):
#   | Task | State | Review | Elapsed | Notes | Name |
# Name (feature-005) is a trailing 6th DATA column (col_idx=7 -- column 2 is
# the task-id cell) holding the same mutable display-name override the nested
# layout stores under `display_name`. This function touches DATA rows only:
# the header and separator rows are printed byte-verbatim elsewhere in this
# awk program, with NO column-count reconciliation -- a legacy 5-column
# header/separator (pre-feature-005 work) is left exactly as-is; only
# work-state-template.md's SEEDED header/separator gain the Name column for
# newly-created works. A legacy DATA row missing column 7 reads as an empty
# trailing cell (awk's split() naturally yields "" for an absent field), so
# rewriting any field on such a row is backward-compatible by construction.
# The placeholder "_none yet_" row is replaced by the first task row ever
# written; subsequent tasks are appended just before the section ends.
# Rewriting an existing row's field preserves its other columns unchanged.
# Uses the SAME sentinel lock as --pipeline / --lifecycle / --block (all
# target $STATE_FILE for this layout), so concurrent writers serialize.
# ---------------------------------------------------------------------------
write_task_field_flat() {
    local field_raw="$1" field_lower="$2" new_val="$3" task_id="$4"
    local padded_t task_row_id col_idx
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_t=$(printf '%03d' "$((10#$task_id))")
    task_row_id="task-${padded_t}"

    case "$field_lower" in
        state)   col_idx=3 ;;
        review)  col_idx=4 ;;
        elapsed) col_idx=5 ;;
        notes)   col_idx=6 ;;
        name)    col_idx=7 ;;
        *) die "internal error: unknown field_lower '$field_lower' in write_task_field_flat" 1 ;;
    esac

    if [[ ! -f "$STATE_FILE" ]]; then
        die "$STATE_FILE does not exist" 1
    fi

    # Verify ### Tasks lifecycle section exists
    if ! grep -q '^### Tasks lifecycle' "$STATE_FILE"; then
        die "malformed work STATE.md: ### Tasks lifecycle section not found in $STATE_FILE (flat layout)" 6
    fi

    init_lock_file "$STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)

    # new_val is read from ENVIRON (not an awk `-v` assignment) because awk's
    # `-v var=value` re-processes C-style escape sequences in `value` -- a
    # `foo\tbar` assigned this way silently becomes "foo<TAB>bar", corrupting
    # the row with a literal control character the caller never wrote
    # (delivery-001 gate finding; same bug class wb_set_frontmatter above
    # already fixed via WB_FM_RAW_VALUE). ENVIRON values are NOT
    # escape-reprocessed, so the value arrives byte-for-byte.
    AID_WB_RAW_VALUE="$new_val" awk -v task_row_id="$task_row_id" -v col_idx="$col_idx" '
        function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
        function new_row(    line, c, v) {
            line = "| " task_row_id " |"
            for (c = 3; c <= 7; c++) {
                v = (c == col_idx) ? new_val : "--"
                line = line " " v " |"
            }
            return line
        }
        # maybe_insert: append the new/updated row immediately after the LAST
        # table row seen so far (tracked via last_was_row), instead of at the
        # section boundary -- keeps the appended row contiguous with the
        # existing table (no blank line splitting it into two tables).
        function maybe_insert() {
            if (!found && last_was_row) { print new_row(); found=1 }
        }

        BEGIN { in_tl=0; header_seen=0; found=0; last_was_row=0; new_val = ENVIRON["AID_WB_RAW_VALUE"] }

        /^### Tasks lifecycle/ { in_tl=1; header_seen=0; last_was_row=0; print; next }

        in_tl && (/^## / || /^### /) {
            maybe_insert()
            if (!found) { print new_row(); found=1 }   # table had no rows at all
            in_tl=0
            print
            next
        }

        in_tl {
            stripped = trim($0)

            if (stripped !~ /^\|/) {
                maybe_insert()
                last_was_row=0
                print
                next
            }

            # separator row: only |, -, :, spaces
            if (stripped ~ /^[-|: ]+$/) { print; last_was_row=1; next }

            n = split(stripped, cols, "|")
            for (i = 1; i <= n; i++) cols[i] = trim(cols[i])

            if (!header_seen) { header_seen=1; print; next }   # header row (not a data row)

            first_cell = cols[2]

            if (index(first_cell, "_none yet_") > 0) {
                if (!found) { print new_row(); found=1 }
                last_was_row=1
                next
            }

            if (tolower(first_cell) == tolower(task_row_id)) {
                line = "| " first_cell " |"
                for (c = 3; c <= 7; c++) {
                    v = (c == col_idx) ? new_val : cols[c]
                    line = line " " v " |"
                }
                print line
                found=1
                last_was_row=1
                next
            }

            print
            last_was_row=1
            next
        }

        { print }

        END {
            # Defensive: Tasks lifecycle was the last section in the file (no
            # trailing heading closed it above) -- append here instead.
            if (in_tl) {
                maybe_insert()
                if (!found) print new_row()
            }
        }
    ' "$STATE_FILE" > "$tmp"
    local awk_exit=$?
    if [[ "$awk_exit" -ne 0 ]]; then
        rm -f "$tmp"
        die "writeback awk failed (exit $awk_exit); $STATE_FILE preserved" "$awk_exit"
    fi

    if [[ ! -s "$tmp" ]]; then
        rm -f "$tmp"
        die "writeback produced empty output; $STATE_FILE preserved" 3
    fi

    # Sanity: ### Tasks lifecycle section and the task's row must both survive
    if ! grep -q '^### Tasks lifecycle' "$tmp"; then
        rm -f "$tmp"
        die "writeback sanity check failed: ### Tasks lifecycle disappeared from output" 3
    fi
    if ! grep -qi "| ${task_row_id} |" "$tmp"; then
        rm -f "$tmp"
        die "writeback sanity check failed: row for ${task_row_id} not found in output" 3
    fi

    mv "$tmp" "$STATE_FILE"
    echo "OK: $STATE_FILE updated -- task $padded_t field '$field_raw' set to '$new_val' (### Tasks lifecycle)"
}

# ---------------------------------------------------------------------------
# Mode: [--delivery-id NNN] --task-id NNN --findings BLOCK
# Write/replace the ## Quick Check Findings block in
# delivery-NNN/tasks/task-NNN/STATE.md.
# Creates the ## Quick Check Findings section if absent.
# ---------------------------------------------------------------------------
mode_findings() {
    local padded_id
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_id=$(printf '%03d' "$((10#$TASK_ID))")

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
        # Stop the replacement at the first bare `---` separator OR the next `## `
        # heading, whichever comes first -- task-state-template.md places a `---`
        # immediately after this section's field lines (before `## Dispatch Log`),
        # and that separator (plus any inter-section content after it) must survive
        # the rewrite untouched, not be swallowed as if it were old field content.
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
            in_qcf && (/^## / || /^---[ \t]*$/) {
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
# Surgical frontmatter write of the `delivery_state` key (SD-8) in the leading
# YAML block of delivery-NNN/STATE.md (or the work-root STATE.md for the
# flattened layout -- resolve_delivery_state_file already targets the right
# file either way). The ## Delivery Lifecycle body's `- **State:**` bullet was
# relocated to frontmatter by task-001 and is never rewritten here; the body's
# Updated/Block Reason/Block Artifact bullets are untouched (not relocated).
# VALUE must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked
# Emits no user-facing output.
# ---------------------------------------------------------------------------
mode_delivery_lifecycle() {
    local padded_id
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_id=$(printf '%03d' "$((10#$DELIVERY_ID))")

    # Enum validation (closed enum)
    case "$LIFECYCLE_VALUE" in
        Pending-Spec|Specified|Executing|Gated|Done|Blocked) ;;
        *) die "invalid --lifecycle value '$LIFECYCLE_VALUE'; must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked" 4 ;;
    esac

    resolve_delivery_state_file "$DELIVERY_ID"

    if [[ ! -f "$DELIVERY_STATE_FILE" ]]; then
        die "$DELIVERY_STATE_FILE does not exist" 1
    fi

    # Verify ## Delivery Lifecycle section exists (the body header itself is
    # still present -- only its `- **State:**` bullet was relocated).
    if ! grep -q '^## Delivery Lifecycle' "$DELIVERY_STATE_FILE"; then
        die "malformed delivery STATE.md: ## Delivery Lifecycle section not found in $DELIVERY_STATE_FILE" 6
    fi

    init_lock_file "$DELIVERY_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)
    wb_set_frontmatter "$DELIVERY_STATE_FILE" "delivery_state" "$LIFECYCLE_VALUE" > "$tmp"

    if ! wb_frontmatter_verify "$tmp" "delivery_state"; then
        rm -f "$tmp"
        die "writeback sanity check failed: frontmatter key 'delivery_state' not found in output; $DELIVERY_STATE_FILE preserved" 3
    fi

    # Sanity: ## Delivery Lifecycle section must still be present (body untouched)
    if ! grep -q '^## Delivery Lifecycle' "$tmp"; then
        rm -f "$tmp"
        die "writeback sanity check failed: ## Delivery Lifecycle disappeared from output" 3
    fi

    mv "$tmp" "$DELIVERY_STATE_FILE"
    # No user-facing output
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --gate-field FIELD --gate-value VALUE
# Surgical frontmatter write of one Delivery Gate scalar (relocated by task-001):
#   Tier      -> gate_tier       (Small | Medium | Large)
#   Grade     -> gate_grade      (matches ^[A-F][+-]?$)
#   Timestamp -> gate_timestamp  (free ISO-8601 text)
# Targets the same file --lifecycle/--block resolve to (delivery-NNN/STATE.md,
# or the work-root STATE.md for the flattened layout).
# Emits no user-facing output.
# ---------------------------------------------------------------------------
mode_gate_field() {
    local padded_id
    padded_id=$(printf '%03d' "$((10#$DELIVERY_ID))")

    local field_lower fm_key
    field_lower="${GATE_FIELD,,}"
    case "$field_lower" in
        tier)      fm_key="gate_tier" ;;
        grade)     fm_key="gate_grade" ;;
        timestamp) fm_key="gate_timestamp" ;;
        *) die "unknown --gate-field '$GATE_FIELD'; allowed: Tier Grade Timestamp" 4 ;;
    esac

    case "$field_lower" in
        tier)
            case "$GATE_VALUE" in
                Small|Medium|Large) ;;
                *) die "invalid --gate-field Tier value '$GATE_VALUE'; must be one of: Small | Medium | Large" 4 ;;
            esac
            ;;
        grade)
            [[ "$GATE_VALUE" =~ ^[A-F][+-]?$ ]] || die "invalid --gate-field Grade value '$GATE_VALUE'; must match ^[A-F][+-]?\$ (e.g. A, A-, B+, F)" 4
            ;;
    esac

    if [[ "$GATE_VALUE" == *$'\n'* ]]; then
        die "--gate-value cannot contain newline characters" 4
    fi

    resolve_delivery_state_file "$DELIVERY_ID"

    if [[ ! -f "$DELIVERY_STATE_FILE" ]]; then
        die "$DELIVERY_STATE_FILE does not exist" 1
    fi

    init_lock_file "$DELIVERY_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)
    wb_set_frontmatter "$DELIVERY_STATE_FILE" "$fm_key" "$GATE_VALUE" > "$tmp"

    if ! wb_frontmatter_verify "$tmp" "$fm_key"; then
        rm -f "$tmp"
        die "writeback sanity check failed: frontmatter key '$fm_key' not found in output; $DELIVERY_STATE_FILE preserved" 3
    fi

    mv "$tmp" "$DELIVERY_STATE_FILE"
    # No user-facing output
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --block MARKDOWN_BLOCK
# Write/replace the ## Delivery Gate block in delivery-NNN/STATE.md.
# This is the per-delivery delivery gate block, targeting the delivery-level
# STATE.md (one writer per delivery branch -- disjoint writes).
# Creates the ## Delivery Gate section if absent.
# ---------------------------------------------------------------------------
mode_delivery_block() {
    local padded_id
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_id=$(printf '%03d' "$((10#$DELIVERY_ID))")

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
        # Stop the replacement at the first bare `---` separator OR the next `## `
        # heading, whichever comes first. Both delivery-state-template.md (full
        # path -- `---` before `## Cross-phase Q&A`) and work-state-template.md
        # (flat path -- `---` + the `DERIVED / READ-ONLY VIEWS` comment banner
        # before `## Features State`) place a `---` immediately after this
        # section's field lines; that separator and everything after it must
        # survive the rewrite untouched, not be swallowed as if it were old
        # field content.
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
            in_dg && (/^## / || /^---[ \t]*$/) {
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
# ---------------------------------------------------------------------------
mode_append_issue() {
    local padded_id
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_id=$(printf '%03d' "$((10#$DELIVERY_ID))")
    local issues_file="${DELIVERY_ISSUES_DIR}/delivery-${padded_id}-issues.md"

    # Use work-dir-based issues path when DELIVERY_ISSUES_DIR is default
    # and WORK_DIR is resolvable, for consistency with path resolution.
    if [[ "$DELIVERY_ISSUES_DIR" == ".aid/works/work" && -n "$AID_STATE_FILE" ]]; then
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
# Surgical frontmatter write of a single scalar key in the leading YAML block
# of the work STATE.md (task-004; relocated by task-001). The ## Pipeline State
# body section is now a static enum-reference blockquote and is never
# rewritten by this mode -- the body is byte-unchanged by every call here.
#
# Fields (canonical casing) -> frontmatter key:
#   Lifecycle -> lifecycle | Phase -> phase | Active Skill -> active_skill |
#   Updated -> updated | Pause Reason -> pause_reason |
#   Block Reason -> block_reason | Block Artifact -> block_artifact |
#   Started -> started | Minimum Grade -> minimum_grade |
#   User Approved -> user_approved | Pipeline Path -> pipeline.path |
#   Pipeline Initiator -> pipeline.initiator
#
# Enum-validated fields (closed enums from work-state-template.md):
#   Lifecycle:      Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
#   Phase:          Describe | Define | Specify | Plan | Detail | Execute
#   Active Skill:   any string matching "aid-{skill}" pattern, or "none"
#   Minimum Grade:  matches ^[A-F][+-]?$
#   User Approved:  yes | no
#   Pipeline Path:  lite | full
#   Pipeline Initiator: any string matching "aid-{skill}" pattern
#
# Conditional fields (written only when Lifecycle matches; cleared otherwise):
#   Pause Reason   -> present only when Lifecycle = Paused-Awaiting-Input
#   Block Reason   -> present only when Lifecycle = Blocked
#   Block Artifact -> present only when Lifecycle = Blocked
#   On a Lifecycle change, a conditional field that no longer applies is reset
#   to the "--" null sentinel in frontmatter (never physically removed -- the
#   key stays present so the block's shape is stable across every write).
#
# Creates the frontmatter block from scratch if the target file has none yet
# (wb_set_frontmatter). Emits no user-facing output. Acquires the existing
# sentinel lock.
# ---------------------------------------------------------------------------
mode_pipeline() {
    if [[ ! -f "$STATE_FILE" ]]; then
        die "$STATE_FILE does not exist" 1
    fi

    # Reject newline characters -- a raw newline in a YAML flow scalar would
    # corrupt the frontmatter block (same defensive class as mode_field's
    # pipe/newline checks).
    if [[ "$FIELD_VALUE" == *$'\n'* ]]; then
        die "--value cannot contain newline characters; rephrase to single line" 4
    fi

    # Validate field name (canonical casing stored; comparison is case-insensitive)
    local field_lower
    field_lower="${FIELD,,}"
    local canonical_field fm_key
    case "$field_lower" in
        lifecycle)          canonical_field="Lifecycle";          fm_key="lifecycle" ;;
        phase)              canonical_field="Phase";              fm_key="phase" ;;
        "active skill")     canonical_field="Active Skill";       fm_key="active_skill" ;;
        updated)            canonical_field="Updated";            fm_key="updated" ;;
        "pause reason")     canonical_field="Pause Reason";       fm_key="pause_reason" ;;
        "block reason")     canonical_field="Block Reason";       fm_key="block_reason" ;;
        "block artifact")   canonical_field="Block Artifact";     fm_key="block_artifact" ;;
        started)            canonical_field="Started";            fm_key="started" ;;
        "minimum grade")    canonical_field="Minimum Grade";      fm_key="minimum_grade" ;;
        "user approved")    canonical_field="User Approved";      fm_key="user_approved" ;;
        "pipeline path")    canonical_field="Pipeline Path";      fm_key="pipeline.path" ;;
        "pipeline initiator") canonical_field="Pipeline Initiator"; fm_key="pipeline.initiator" ;;
        *) die "unknown --pipeline field '$FIELD'; allowed: Lifecycle Phase \"Active Skill\" Updated \"Pause Reason\" \"Block Reason\" \"Block Artifact\" Started \"Minimum Grade\" \"User Approved\" \"Pipeline Path\" \"Pipeline Initiator\"" 4 ;;
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
                Describe|Define|Specify|Plan|Detail|Execute) ;;
                *) die "invalid Phase value '$FIELD_VALUE'; must be one of: Describe | Define | Specify | Plan | Detail | Execute" 4 ;;
            esac
            ;;
        "Active Skill")
            # Accepts aid-{skill} (aid- prefix followed by at least one char) or "none"
            if [[ "$FIELD_VALUE" != "none" ]] && ! [[ "$FIELD_VALUE" =~ ^aid-[a-zA-Z0-9_-]+$ ]]; then
                die "invalid Active Skill value '$FIELD_VALUE'; must match aid-{skill} or be \"none\"" 4
            fi
            ;;
        "Minimum Grade")
            [[ "$FIELD_VALUE" =~ ^[A-F][+-]?$ ]] || die "invalid Minimum Grade value '$FIELD_VALUE'; must match ^[A-F][+-]?\$ (e.g. A, A-, B+, F)" 4
            ;;
        "User Approved")
            case "$FIELD_VALUE" in
                yes|no) ;;
                *) die "invalid User Approved value '$FIELD_VALUE'; must be one of: yes | no" 4 ;;
            esac
            ;;
        "Pipeline Path")
            case "$FIELD_VALUE" in
                lite|full) ;;
                *) die "invalid Pipeline Path value '$FIELD_VALUE'; must be one of: lite | full" 4 ;;
            esac
            ;;
        "Pipeline Initiator")
            [[ "$FIELD_VALUE" =~ ^aid-[a-zA-Z0-9_-]+$ ]] || die "invalid Pipeline Initiator value '$FIELD_VALUE'; must match aid-{skill}" 4
            ;;
    esac

    init_lock_file "$STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)
    wb_set_frontmatter "$STATE_FILE" "$fm_key" "$FIELD_VALUE" > "$tmp"

    # Lifecycle change: clear conditional fields that no longer apply (chained
    # writes over the same evolving temp file -- each wb_set_frontmatter call
    # only ever touches the frontmatter block, so chaining preserves the
    # untouched body across every step).
    if [[ "$canonical_field" == "Lifecycle" ]]; then
        local tmp2
        if [[ "$FIELD_VALUE" != "Paused-Awaiting-Input" ]]; then
            tmp2=$(mktemp)
            wb_set_frontmatter "$tmp" "pause_reason" "--" > "$tmp2"
            mv "$tmp2" "$tmp"
        fi
        if [[ "$FIELD_VALUE" != "Blocked" ]]; then
            tmp2=$(mktemp)
            wb_set_frontmatter "$tmp" "block_reason" "--" > "$tmp2"
            mv "$tmp2" "$tmp"
            tmp2=$(mktemp)
            wb_set_frontmatter "$tmp" "block_artifact" "--" > "$tmp2"
            mv "$tmp2" "$tmp"
        fi
    fi

    if ! wb_frontmatter_verify "$tmp" "$fm_key"; then
        rm -f "$tmp"
        die "writeback sanity check failed: frontmatter key '$fm_key' not found in output; $STATE_FILE preserved" 3
    fi

    mv "$tmp" "$STATE_FILE"
    # No user-facing output
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
    gate-field)          mode_gate_field ;;
    append-issue)        mode_append_issue ;;
    *) die "internal error: unknown mode '$MODE'" 1 ;;
esac
