#!/usr/bin/env bash
#
# ============================================================================
#  THIS FILE IS THE SOURCE. SEVEN RENDERS EXIST -- EDIT THIS ONE, NEVER A RENDER.
#
#  canonical/aid/scripts/execute/writeback-state.sh   <- you are here (edit this)
#  profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/.../writeback-state.sh
#  ...plus this repo's own per-tool dogfood trees, one render per installed tool
#     root, at that tool's own aid/scripts/execute/ path.
#
#  If you are reading this inside a tool's installed tree, you are in a RENDER.
#  Your edit will be erased by the next generator run and will reach no adopter.
#
#  ONE NINTH COPY IS NOT A RENDER: dashboard/scripts/writeback-state.sh is a
#  DELIBERATE FORK -- it additionally accepts `Deploy` as a Phase value. Do NOT
#  resync it from here; overwriting it silently removes that, and no test catches
#  it. Its own header says so.
#
#  After editing: run the profile generator, then resync the dogfood trees.
#  `tests/canonical/test-dogfood-byte-identity.sh` fails if you skip that.
#
#  This banner exists because the mistake was made: a fix landed in one dogfood
#  render only, which turned repo CI red and would have been erased by the next
#  render, reaching no adopter. The invariant was already documented
#  (architecture.md: "Editing a rendered or vendored copy is a defect") -- what was
#  missing was the file saying so at the moment someone opens it.
#
#  Deliberately names no tool root. An earlier version listed them literally, which
#  put another tool's root path into every render and tripped
#  `tests/canonical/test-multitool-isolation.sh` T21-T26 (no foreign-root reference
#  in an operational script). The guard was right: an adopter who installed one tool
#  should not find another tool's paths in their own scripts, in a comment or
#  anywhere else.
# ============================================================================
#
# writeback-state.sh -- row-level write coordination for FR6 parallel pool
# x per-unit STATE writes in AID aid-execute.
#
# Provides 7 safe write modes targeting PER-UNIT STATE.yml files (Pillar 2).
# Uses a sentinel-file lock (set -o noclobber + atomic create + sleep-poll retry)
# to prevent races when multiple parallel tasks dispatch reviewers concurrently.
#
# Single write path (work-009-refactor task-007): the target file is a single
# YAML document with no `---` fence (the whole file is the key space -- there
# is no separate frontmatter/body split any more). Every write mode resolves
# to ONE dotted key path of 1-3 segments (`wb_set_kv`, below):
#   1 segment  (S1) -- a flat top-level scalar, e.g. "lifecycle"
#   2 segments (S2) -- a one-level-nested child, e.g. "pipeline.path", or a
#                       one-level-nested SEQUENCE, e.g. "delivery_gate.issue_list"
#   3 segments (S3) -- a two-level-nested scalar, e.g.
#                       "tasks_lifecycle.task-004.state"
# `wb_set_kv` creates every missing ancestor mapping and inserts the missing
# child at the end of its parent's existing block -- the same
# create-parent-if-absent / insert-at-end-of-parent behavior the pre-refactor
# frontmatter writer already had one level up, now generalized to three.
# Every pre-existing line other than the written key's own line(s) is
# reproduced byte-for-byte: full-line comments, blank lines, key order and the
# presence/absence of a trailing newline (SP-4).
#
# Value quoting (SPEC.md SS D-5): bare iff the value matches
# ^[A-Za-z0-9_.+/-]+$ and is not on the implicit-type deny list (y/n/yes/no/
# true/false/on/off/null/~/empty/number-like/date-like -- NFR-2); else
# single-quoted (doubling an embedded '); else, only when the value carries a
# newline or control character, double-quoted with a 5-escape subset (\" \\
# \n \r \t). This is what lets a value containing `|`, a colon, a `#`, a
# quote or a newline round-trip intact -- there is no longer a `|`/newline
# reject guard anywhere in this script (FR-4b).
#
# Unit layout (work-004 hierarchy):
#   work-NNN-{name}/
#     STATE.yml                                 -- work-level (--pipeline target)
#     deliveries/
#       delivery-NNN/
#         STATE.yml                             -- delivery-level (--block / --lifecycle target)
#         tasks/
#           task-NNN/
#             STATE.yml                         -- task-level (--field / --findings target)
#
# Flattened single-delivery layout (feature-001, additive -- nested layout above
# is unchanged): declared by `pipeline.path: lite` in the work-root STATE.yml,
# or for an un-migrated work inferred from `tasks/task-NNN/DETAIL.md` present
# directly under the work root AND no `deliveries/` wrapper. The delivery
# lifecycle/gate AND the per-task mutable cells are all promoted into the SAME
# work-root STATE.yml:
#   work-NNN-{name}/
#     STATE.yml         -- work-level (--pipeline target) AND, for this layout,
#                           the --delivery-id 001 targets too:
#                             delivery_lifecycle  (--lifecycle target)
#                             delivery_gate        (--block target: issue_list)
#                             tasks_lifecycle       (--task-id/--field target;
#                                                     one task-NNN entry per task,
#                                                     replacing the per-task
#                                                     STATE.yml)
#                             tasks_lifecycle.task-NNN.quick_check
#                                                   (--task-id/--findings target
#                                                    on this layout only -- there
#                                                    is no per-task STATE.yml and
#                                                    no top-level quick_check key
#                                                    to nest a sequence under
#                                                    without exceeding the
#                                                    declared 3-level nesting cap
#                                                    (SPEC.md SS D-3), so the whole
#                                                    findings block is stored
#                                                    verbatim as ONE scalar child
#                                                    of the task's own
#                                                    tasks_lifecycle entry)
#     tasks/
#       task-NNN/
#         DETAIL.md      -- task definition (no per-task STATE.yml in this layout)
#
# Usage:
#   writeback-state.sh [--delivery-id NNN] --task-id NNN --field FIELD --value VALUE
#       Full-nested layout: single-key write of FIELD (state | review | elapsed |
#       notes | name) as a top-level scalar in
#       deliveries/delivery-NNN/tasks/task-NNN/STATE.yml (one-writer-per-branch file).
#       Fields: State | Review | Elapsed | Notes | Name
#       --delivery-id is optional; if omitted the delivery is resolved from the
#       task's Source line (e.g. "**Source:** work-NNN -> delivery-NNN").
#       Override env: AID_TASK_STATE_FILE (absolute path) skips all path resolution.
#       Flattened layout (feature-001, auto-detected): targets
#       tasks_lifecycle.task-NNN.<field> in the work-root STATE.yml instead
#       (creates the task-NNN entry on first write).
#
#   writeback-state.sh [--delivery-id NNN] --task-id NNN --findings BLOCK
#       Full-nested layout: writes quick_check.reviewer_tier (scalar) and
#       quick_check.findings (sequence of severity-tagged strings) in
#       deliveries/delivery-NNN/tasks/task-NNN/STATE.yml, parsed from BLOCK
#       (the same "- **Reviewer Tier:** ... / - **Findings:** ..." shape
#       aid-execute/references/state-review.md already documents). Creates the
#       quick_check key if absent.
#       Flattened layout (feature-001, auto-detected): there is no per-task
#       STATE.yml and no top-level quick_check key (see the layout note above),
#       so this targets tasks_lifecycle.task-NNN.quick_check -- BLOCK is stored
#       verbatim as one multi-line scalar (double-quoted per D-5 mode 3).
#
#   writeback-state.sh --delivery-id NNN --block MARKDOWN_BLOCK
#       Writes delivery_gate.issue_list (a sequence of severity-tagged strings)
#       in deliveries/delivery-NNN/STATE.yml (SD-5), parsed from BLOCK's
#       "- **Issue List:** ..." section (state-delivery-gate.md SS 6a's shape).
#       Override env: AID_DELIVERY_STATE_FILE (absolute path) skips path resolution.
#       Flattened layout (feature-001, auto-detected; --delivery-id 001): writes
#       delivery_gate.issue_list into the work-root STATE.yml instead.
#
#   writeback-state.sh --delivery-id NNN --lifecycle VALUE
#       Single-key write of the `delivery_state` top-level scalar (SD-8).
#       VALUE must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked
#       Override env: AID_DELIVERY_STATE_FILE (absolute path) skips path resolution.
#       Emits no user-facing output (C4 behavior-preserving).
#       Flattened layout (feature-001, auto-detected; --delivery-id 001): targets
#       the work-root STATE.yml's own `delivery_state` key instead.
#
#   writeback-state.sh --delivery-id NNN --gate-field FIELD --gate-value VALUE
#       Single-key write of one top-level Delivery Gate scalar.
#       FIELD must be one of: Tier | Grade | Timestamp -> gate_tier | gate_grade | gate_timestamp
#       Tier is closed-enum validated (Small | Medium | Large); Grade must match
#       ^[A-F][+-]?$ (grade.sh's own output alphabet). Timestamp is free ISO-8601 text.
#       Override env: AID_DELIVERY_STATE_FILE (absolute path) skips path resolution.
#       Emits no user-facing output (C4 behavior-preserving).
#       Flattened layout (feature-001, auto-detected; --delivery-id 001): targets
#       the work-root STATE.yml's own frontmatter instead (same 3 keys).
#
#   writeback-state.sh --delivery-id NNN --append-issue ROW
#       Append a single issue row to the delivery's delivery-NNN-issues.md.
#       ROW must be a valid markdown table row (pipe-delimited). Unaffected by
#       the YAML migration -- this targets a separate markdown log, not STATE.yml.
#
#   writeback-state.sh --pipeline --field FIELD --value VALUE
#       Single-key write of a top-level (or one-level-nested `pipeline.*`)
#       scalar in the work STATE.yml. FIELD must be one of: Lifecycle | Phase |
#         Active Skill | Updated | Pause Reason | Block Reason | Block Artifact |
#         Started | Minimum Grade | User Approved | Pipeline Path | Pipeline Initiator
#       Lifecycle, Phase, Active Skill, User Approved, and Pipeline Path are
#       closed-enum validated; Minimum Grade must match ^[A-F][+-]?$.
#       Conditional fields: Pause Reason written only when Lifecycle is
#         Paused-Awaiting-Input; Block Reason + Block Artifact written only when
#         Lifecycle is Blocked. On Lifecycle change, conditional fields that no
#         longer apply are cleared (reset to the "--" null sentinel).
#       Emits no user-facing output (C4 behavior-preserving).
#
#   writeback-state.sh -h | --help
#
# Flattened single-delivery layout (feature-001) detection: `pipeline.path: lite`
# in the work-root STATE.yml; for an un-migrated work declaring nothing, at least
# one `tasks/task-NNN/DETAIL.md` present directly under it AND no `deliveries/`
# wrapper under the work root. Auto-detected per-call; no new flag needed. The
# nested layout above is unchanged (additive only). See is_flat_layout.
#
# Exit codes:
#   0  success
#   1  STATE.yml or required artifact missing
#   2  lock contention (timeout)
#   3  writeback produced empty / unverifiable output
#   4  invalid argument value
#   5  missing required argument
#   6  malformed STATE.yml (the file does not parse as a YAML mapping)

set -u

# ---------------------------------------------------------------------------
# Defaults -- caller can override via environment for testing
# ---------------------------------------------------------------------------
# Work-level STATE.yml (--pipeline target)
STATE_FILE="${AID_STATE_FILE:-.aid/works/work/STATE.yml}"

# Work root (base for resolving delivery/task paths)
# Derived from STATE_FILE parent when not overridden.
WORK_DIR="${AID_WORK_DIR:-}"

# Delivery directory base: <work-root>/delivery-NNN
# Set AID_DELIVERY_DIR to override the per-delivery STATE path base.
DELIVERY_DIR_BASE="${AID_DELIVERY_DIR:-}"

# Task-level STATE.yml override (skips all path resolution for --field/--findings)
TASK_STATE_FILE="${AID_TASK_STATE_FILE:-}"

# Delivery-level STATE.yml override (skips path resolution for --block)
DELIVERY_STATE_FILE="${AID_DELIVERY_STATE_FILE:-}"

# Issues directory: directory containing delivery-NNN-issues.md files
# Defaults to the work directory (same dir as work STATE.yml). Unaffected by
# the YAML migration -- delivery-NNN-issues.md stays markdown.
DELIVERY_ISSUES_DIR="${AID_DELIVERY_ISSUES_DIR:-.aid/works/work}"

# Lock directory -- defaults to derived per-call below (see acquire_lock)
LOCK_DIR="${AID_LOCK_DIR:-}"

LOCK_TIMEOUT="${AID_LOCK_TIMEOUT:-10}"   # max retries (0.5s each -> 5s default)

# ---------------------------------------------------------------------------
usage() {
    # Upper bound tracks the end of the Exit codes stanza. Bump it whenever
    # lines are added to the header block above it, or --help silently
    # starts truncating (or over-printing) the usage text.
    sed -n '2,194p' "$0" | sed 's/^# \{0,1\}//'
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

# wb_get_pipeline_path: echo the work-root STATE.yml `pipeline.path` value,
# lowercased, or nothing when there is no `pipeline:` mapping, no `path:` under
# it, or no state file. Never throws.
#
# The key is NESTED (`pipeline:` then an indented `path:`), matching what the
# reader twins flatten to `pipeline.path` (state_schema.py documents the
# mapping: `pipeline:\n  path: lite` -> `{"pipeline.path": "lite"}`).
#
# STATE.yml only -- no STATE.md fallback, matching reader.py
# _declared_work_path and reader.mjs _declaredWorkPath exactly. SP-9 routes a
# work holding the retired markdown name to the legacy detector, which
# diagnoses rather than parses, so a fallback here would contradict that policy
# AND put this function out of step with its twins.
#
# The scalar handling below is not decoration. Those twins delegate to the
# shared D-3 subset engine; this one hand-rolls YAML in awk, so every scalar
# form the engine accepts has to be reproduced here by hand or the three
# disagree on the same file. Three forms were found diverging and are covered
# by cases WB-* in tests/canonical/test-writeback-state.sh: a CRLF file (awk's
# `$` anchors sat behind a stray \r, so `pipeline:` never matched and the value
# read empty), a single-quoted `'lite'` (only double quotes were stripped), and
# a trailing `# comment` (kept verbatim, so the value compared equal to
# nothing). Extending this parser means extending those cases too.
#
# Five MORE were then found by probing forms nobody had tried, rather than by
# waiting for the next reviewer -- the corpus was covering the failures already
# known, which is the one thing a corpus cannot get credit for. All five are in
# the three-way parity corpus now:
#
#   BOM            a UTF-8 byte-order mark sat in front of `pipeline:`, so the
#                  key never matched and the value read empty. Twins: `lite`.
#   deeper nest    `pipeline:` -> `opts:` -> `path:` matched here, because any
#                  indent was accepted; `pipeline.path` does not exist in that
#                  file and both twins correctly said so.
#   block/anchor   `|`, `>`, `&p lite` were returned VERBATIM. This is the worst
#                  failure of the five and the reason for the guard below: the
#                  harm is not the wrong value, it is that a non-empty answer
#                  tells is_flat_layout the layout WAS declared, suppressing the
#                  presence-rule fallback that would have classified correctly.
#   escaped quote  `"li\"te"` truncated at the backslash.
#   multi-document the first document won here and the last won in the twins.
#
# The indentation rule is EXACTLY two spaces, not "one or more". That is not a
# tightening for its own sake: the engine models nesting as `level = indent // 2`,
# so a four-space `path:` is level 2 -- a grandchild of `pipeline:`, not its
# child -- and both twins answer "not declared" for it. A parser that accepted
# any indent answered `lite` where they answered nothing. Note this makes all
# three agree while all three differ from a full YAML parser, which reads
# four-space nesting as an ordinary child: that is what being a documented
# SUBSET means, and consistency across the three is the invariant that matters,
# since a file all three misread the same way is classified consistently.
wb_get_pipeline_path() {
    resolve_work_dir
    local state="${WORK_DIR}/STATE.yml"
    [[ -f "$state" ]] || return 0
    awk '
        BEGIN { sq = sprintf("%c", 39); dq = "\"" }
        NR == 1 { sub(/^\xef\xbb\xbf/, "") }             # UTF-8 BOM, first line only
        { sub(/\r$/, "") }                               # CRLF -> LF, every line
        /^[ \t]*#/                     { next }          # whole-line YAML comment
        /^pipeline:[ \t]*$/            { inp = 1; next }
        # EXACTLY two spaces, matching the engine level model (see the header note).
        # SPACES only, not `[ \t]`: YAML forbids a tab as indentation and both twins
        # reject a tab-indented file outright.
        inp && /^  path:[ \t]*/ {
            sub(/^  path:[ \t]*/, "")
            v = $0
            c = substr(v, 1, 1)
            # Scalar forms outside the subset. Returning the marker verbatim is the
            # worst option available: `|`, `>` and `&p lite` are all NON-EMPTY, and a
            # non-empty answer tells is_flat_layout the layout was declared, which
            # suppresses the presence-rule fallback that would have got it right.
            # Declaring nothing is honest and lets the fallback run.
            if (c == "|" || c == ">" || c == "&" || c == "*") { exit }
            if (c == dq || c == sq) {
                # Quoted: the value is the quoted span. A # inside it is
                # literal, so comment-stripping must not run.
                v = substr(v, 2)
                out = ""
                while (length(v) > 0) {
                    ch = substr(v, 1, 1)
                    # Only the double-quoted form has escapes, per YAML.
                    if (c == dq && ch == "\\" && length(v) > 1) {
                        out = out substr(v, 2, 1)
                        v = substr(v, 3)
                        continue
                    }
                    if (ch == c) break
                    out = out ch
                    v = substr(v, 2)
                }
                v = out
            } else {
                # Plain: a # begins a comment only after whitespace.
                sub(/[ \t]+#.*$/, "", v)
            }
            gsub(/[ \t]+$/, "", v)
            # LAST occurrence wins, not the first. The engine skips a `---` document
            # marker with a warning and keeps parsing, so a multi-document file leaves
            # it holding the final document value; exiting here on the first match
            # would answer with the first instead.
            found = tolower(v)
            next
        }
        inp && /^[^ \t#]/              { inp = 0 }       # a dedented key ends the mapping
        END { if (found != "") print found }
    ' "$state"
}

# is_flat_layout: return 0 (true) when the work uses the FLATTENED
# single-delivery layout (feature-001).
#
# DECLARED FIRST, inferred only as a fallback. The layout is a property of the
# WHOLE WORK, so it is read from the work-root STATE.yml (`pipeline.path:
# lite | full`) -- one declared value, written once by the skill that started
# the work. A declared value cannot be ambiguous; an inferred one can, and
# inferring it from a FILE PRESENCE made an ordinary artifact load-bearing:
# `BLUEPRINT.md` could not be retired or relocated without silently changing how
# three separate implementations classified the work.
#
# The 3-part presence rule survives ONLY as the fallback for un-migrated works
# whose state file carries no `pipeline:` mapping -- a work-root BLUEPRINT.md AND
# at least one `tasks/task-NNN/DETAIL.md` AND no `deliveries/` wrapper. That
# fallback is filename-independent (SP-7) and so was unchanged by the
# STATE.md -> STATE.yml rename. The DECLARED read is filename-dependent and
# reads STATE.yml ONLY -- no STATE.md fallback, matching both reader twins;
# SP-9 sends a work still holding the retired name to the legacy detector,
# which diagnoses instead of parsing.
#
# This is the same declared-first-then-infer shape reader.mjs already documents
# for the `workPath` field ("stop inferring via _detectFlat/_detectHierarchy when
# present ... the fallback default for un-migrated works"); this extends it from
# the FIELD to the layout DISPATCH, which is what actually made the artifact
# load-bearing.
#
# Mirrors reader.py `_detect_flat` and reader.mjs `_detectFlat` exactly -- all
# three consumers must agree. Never throws. Auto-detected per-call.
is_flat_layout() {
    resolve_work_dir
    local declared
    declared="$(wb_get_pipeline_path)"
    if [[ -n "$declared" ]]; then
        [[ "$declared" == "lite" ]]
        return
    fi
    [[ -f "${WORK_DIR}/BLUEPRINT.md" ]] || return 1
    [[ -d "${WORK_DIR}/deliveries" ]] && return 1
    local f
    for f in "${WORK_DIR}"/tasks/task-*/DETAIL.md; do
        [[ -f "$f" ]] && return 0
    done
    return 1
}

# resolve_task_state_file DELIVERY_ID TASK_ID
# Sets TASK_STATE_FILE to deliveries/delivery-NNN/tasks/task-NNN/STATE.yml under the work root.
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
        TASK_STATE_FILE="${DELIVERY_DIR_BASE}/tasks/task-${padded_t}/STATE.yml"
    else
        TASK_STATE_FILE="${WORK_DIR}/deliveries/delivery-${padded_d}/tasks/task-${padded_t}/STATE.yml"
    fi
}

# resolve_delivery_state_file DELIVERY_ID
# Sets DELIVERY_STATE_FILE to deliveries/delivery-NNN/STATE.yml under the work root.
# If DELIVERY_STATE_FILE is already set (env override), this is a no-op.
# feature-001 flattened layout (auto-detected): with no `deliveries/` wrapper
# there is exactly one delivery and its lifecycle/gate blocks are promoted
# directly into the work-root STATE.yml (the SAME file as --pipeline), so this
# targets $STATE_FILE instead of a per-delivery STATE.yml.
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
        DELIVERY_STATE_FILE="${DELIVERY_DIR_BASE}/STATE.yml"
    else
        DELIVERY_STATE_FILE="${WORK_DIR}/deliveries/delivery-${padded_d}/STATE.yml"
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
# The lock serializes concurrent writes to the same per-unit STATE.yml.
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
# WB_SET_KV_AWK -- THE single write path (work-009-refactor task-007). Collapses
# the pre-refactor WB_SET_FRONTMATTER_AWK, write_task_field_flat and the two
# section-replace awk programs (findings / delivery gate) onto one algorithm:
# every write is a single dotted key path of 1-3 segments against a whole-file
# YAML key space (no `---` fence; D-1). Same create-parent-if-absent /
# insert-at-end-of-parent behavior the old 2-level `parent`/`child` code
# already had, generalized one level deeper for `tasks_lifecycle.task-NNN.*`.
#
# Reads the RAW value from ENVIRON (WB_KV_RAW_VALUE for a scalar write,
# WB_KV_RAW_ITEMS -- items joined by the ASCII Unit Separator 0x1F -- for a
# sequence write), never via an awk `-v` assignment, because awk's `-v
# var=value` re-processes C-style escape sequences in `value` and would
# corrupt a literal backslash or `\n` the caller wrote (the same fix
# WB_SET_FRONTMATTER_AWK and write_task_field_flat already carried; must not
# regress). `-v` remains fine for t1/t2/t3/n/kind/SEP -- those are
# program-controlled tokens this script itself constructs, never raw caller
# text.
#
# Quoting (SPEC.md SS D-5, `quote_value`): bare iff the value matches
# ^[A-Za-z0-9_.+/-]+$ and is not on the implicit-type deny list (y/n/yes/no/
# true/false/on/off/null/~/empty/number-like/date-like, NFR-2); else
# single-quoted (doubling an embedded '); else, only when the value carries a
# newline or a control character, double-quoted with the 5-escape subset (\"
# \\ \n \r \t) -- the one mode with no pre-refactor counterpart, and the
# reason the `|` guard and the two newline guards (FR-4b) are simply deleted
# rather than replaced: a `|`, colon, `#` or embedded quote is single-quoted
# and round-trips; a literal newline is double-quoted and round-trips.
#
# Sequence writes (kind=seq) are used only at the 2-segment depth in this
# script (delivery_gate.issue_list, quick_check.findings) -- a 3-segment
# sequence would nest a sequence two mapping levels deep, past the "sequence
# at the second level" cap SPEC.md SS D-3 declares, so this program does not
# implement one. A sequence write that replaces an existing populated
# sequence swallows the old `- ` continuation lines (the `swallowing` state)
# so a shorter or empty replacement does not leave stale items behind.
# ---------------------------------------------------------------------------
WB_SET_KV_AWK='
    function is_bare(v,    lv) {
        if (v !~ /^[A-Za-z0-9_.+\/-]+$/) return 0
        lv = tolower(v)
        if (lv=="y"||lv=="yes"||lv=="n"||lv=="no"||lv=="true"||lv=="false"||lv=="on"||lv=="off"||lv=="null") return 0
        if (v=="~") return 0
        if (v=="") return 0
        if (v ~ /^[-+]?[0-9]/) return 0
        if (v ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) return 0
        return 1
    }
    function has_ctrl(v) {
        if (v ~ /\n/) return 1
        if (v ~ /\r/) return 1
        if (v ~ /\t/) return 1
        return 0
    }
    function esc_dq(v,    out, i, n, c) {
        out = ""
        n = length(v)
        for (i = 1; i <= n; i++) {
            c = substr(v, i, 1)
            if (c == bs)        out = out bs bs
            else if (c == dq)   out = out bs dq
            else if (c == "\n") out = out bs "n"
            else if (c == "\r") out = out bs "r"
            else if (c == "\t") out = out bs "t"
            else out = out c
        }
        return out
    }
    function quote_value(v,    out) {
        if (is_bare(v)) return v
        if (!has_ctrl(v)) {
            out = v
            gsub(sq, sq sq, out)
            return sq out sq
        }
        return dq esc_dq(v) dq
    }
    function build_seq_lines(key, ind,    i) {
        gnl = 0
        if (nitems == 0) {
            gnl++; glines[gnl] = ind key ": []"
            return
        }
        gnl++; glines[gnl] = ind key ":"
        for (i = 1; i <= nitems; i++) {
            gnl++; glines[gnl] = ind "  - " quote_value(items[i])
        }
    }
    function build_scalar_line(key, ind) {
        gnl = 1
        glines[1] = ind key ": " quote_value(raw)
    }
    function print_glines(    gi) {
        for (gi = 1; gi <= gnl; gi++) print glines[gi]
    }
    function emit_leaf() {
        if (kind == "seq") build_seq_lines(leaf_key, indent)
        else build_scalar_line(leaf_key, indent)
        print_glines()
        done = 1
    }
    # buffer_pending() / flush_pending(): a run of blank/full-line-comment
    # lines seen while a nested scope is still searching for its target
    # child is held back instead of printed immediately, because SPEC.md SS
    # D-3/D-4 puts the documentation for a key on full-line comments directly
    # ABOVE it -- a blank/comment run immediately before the line that closes
    # the CURRENT scope typically documents the NEXT key, not this one.
    # Printing it early would leave an inserted field sitting between a
    # foreign comment and the key it explains. Only flushed once we know what
    # follows: before the missing field when the scope is ending (insert,
    # then flush, then print the boundary line), or simply before any other
    # line once we know it does not close the scope.
    function buffer_pending() { pending_n++; pending[pending_n] = $0 }
    function flush_pending(    pi) {
        for (pi = 1; pi <= pending_n; pi++) print pending[pi]
        pending_n = 0
    }
    function is_blank_or_comment() {
        return ($0 ~ /^[ \t]*$/) || ($0 ~ /^[ \t]*#/)
    }

    BEGIN {
        sq = sprintf("%c", 39); dq = sprintf("%c", 34); bs = sprintf("%c", 92)
        n = n + 0
        if (kind == "seq") {
            items_raw = ENVIRON["WB_KV_RAW_ITEMS"]
            nitems = 0
            if (items_raw != "") nitems = split(items_raw, items, SEP)
        } else {
            raw = ENVIRON["WB_KV_RAW_VALUE"]
        }
        leaf_key = (n==1) ? t1 : (n==2) ? t2 : t3
        indent = ""
        for (_i = 1; _i < n; _i++) indent = indent "  "

        done = 0
        l0_matched = 0
        l1_matched = 0
        t2_found = 0
        swallowing = 0
        swallow_block = 0
        swallow_min_indent = 0
        pending_n = 0
    }

    # Is the line we are about to replace the HEADER of a block scalar -- `key: >-`, `key: |`, and the
    # rest? If so its value is the indented lines beneath it, and replacing only this line orphans
    # them: the body stays behind under a key that no longer describes it, and the first orphaned line
    # containing a colon becomes a mapping key at the wrong indentation. That is unparseable YAML, and
    # it is what this guard exists to prevent.
    function is_block_header(line) {
        return (line ~ /:[ \t]*[|>][-+0-9]*[ \t]*$/)
    }

    # Swallow: consume old sequence-item continuation lines left over from the
    # value we just replaced. Checked before every other rule; when a line does
    # NOT continue the old sequence, swallowing is cleared and (no `next`
    # called) execution falls through to the normal rules below for this same
    # record -- that boundary line (blank, comment, or the next key) is still
    # handled normally.
    swallowing {
        line_indent = 0
        if (match($0, /^[ \t]*/)) line_indent = RLENGTH
        rest = substr($0, line_indent + 1)
        if (swallow_block) {
            # A block scalar body is every line indented deeper than its key, and a BLANK line inside
            # one belongs to it. So a blank is buffered rather than emitted or dropped: if the block
            # continues, the buffer is discarded with the rest of the body; if it has ended, the blank
            # is a real separator and the normal rules flush it.
            if (rest == "") { buffer_pending(); next }
            if (line_indent >= swallow_min_indent) { pending_n = 0; next }
            swallowing = 0
            swallow_block = 0
        } else {
            if (line_indent >= swallow_min_indent && rest ~ /^-( |$)/) next
            swallowing = 0
        }
    }

    # ---------------- n == 1 : flat top-level scalar ----------------
    n==1 && !done && $0 ~ ("^" t1 ":") {
        if (is_block_header($0)) { swallowing = 1; swallow_block = 1; swallow_min_indent = length(indent) + 2 }
        emit_leaf()
        next
    }

    # ---------------- n == 2 : parent.child (scalar or sequence leaf) ----------------
    n==2 && !l0_matched && $0 ~ ("^" t1 ":[ \t]*\\{\\}[ \t]*$") {
        print t1 ":"
        emit_leaf()
        next
    }
    n==2 && !l0_matched && $0 ~ ("^" t1 ":") {
        l0_matched = 1
        print
        next
    }
    n==2 && !l0_matched && $0 ~ /^[A-Za-z0-9_-]+:/ {
        print
        next
    }
    n==2 && l0_matched && !done && is_blank_or_comment() {
        buffer_pending()
        next
    }
    n==2 && l0_matched && !done && $0 ~ ("^  " t2 ":") {
        flush_pending()
        if (kind == "seq") { swallowing = 1; swallow_min_indent = length(indent) + 2 }
        else if (is_block_header($0)) { swallowing = 1; swallow_block = 1; swallow_min_indent = length(indent) + 2 }
        emit_leaf()
        next
    }
    n==2 && l0_matched && $0 ~ /^[A-Za-z0-9_-]+:/ {
        if (!done) emit_leaf()
        flush_pending()
        l0_matched = 0
        print
        next
    }
    n==2 && l0_matched {
        flush_pending()
        print
        next
    }

    # ---------------- n == 3 : parent.id.child (scalar leaf only) ----------------
    n==3 && !l0_matched && $0 ~ ("^" t1 ":[ \t]*\\{\\}[ \t]*$") {
        print t1 ":"
        print "  " t2 ":"
        build_scalar_line(t3, "    ")
        print_glines()
        done = 1
        next
    }
    n==3 && !l0_matched && $0 ~ ("^" t1 ":") {
        l0_matched = 1
        t2_found = 0
        print
        next
    }
    n==3 && !l0_matched && $0 ~ /^[A-Za-z0-9_-]+:/ {
        print
        next
    }
    n==3 && l0_matched && !l1_matched && !t2_found && is_blank_or_comment() {
        buffer_pending()
        next
    }
    n==3 && l0_matched && !l1_matched && $0 ~ ("^  " t2 ":[ \t]*\\{\\}[ \t]*$") {
        flush_pending()
        print "  " t2 ":"
        build_scalar_line(t3, "    ")
        print_glines()
        t2_found = 1
        done = 1
        next
    }
    n==3 && l0_matched && !l1_matched && $0 ~ ("^  " t2 ":[ \t]*$") {
        flush_pending()
        t2_found = 1
        l1_matched = 1
        print
        next
    }
    n==3 && l1_matched && !done && is_blank_or_comment() {
        buffer_pending()
        next
    }
    n==3 && l1_matched && !done && $0 ~ ("^    " t3 ":") {
        flush_pending()
        build_scalar_line(t3, "    ")
        print_glines()
        done = 1
        next
    }
    n==3 && l1_matched && $0 ~ /^    [A-Za-z0-9_-]+:/ {
        flush_pending()
        print
        next
    }
    n==3 && l1_matched && $0 ~ /^  [A-Za-z0-9_-]+:/ {
        if (!done) { build_scalar_line(t3, "    "); print_glines(); done = 1 }
        flush_pending()
        l1_matched = 0
        print
        next
    }
    n==3 && l0_matched && $0 ~ /^[A-Za-z0-9_-]+:/ {
        if (l1_matched && !done) { build_scalar_line(t3, "    "); print_glines(); done = 1 }
        else if (!l1_matched && !t2_found && !done) {
            print "  " t2 ":"
            build_scalar_line(t3, "    ")
            print_glines()
            t2_found = 1
            done = 1
        }
        flush_pending()
        l0_matched = 0
        l1_matched = 0
        print
        next
    }
    n==3 && (l0_matched || l1_matched) {
        flush_pending()
        print
        next
    }

    { print }

    END {
        if (!done) {
            if (n == 1) {
                build_scalar_line(t1, "")
                print_glines()
            } else if (n == 2) {
                if (l0_matched) {
                    emit_leaf()
                } else {
                    print t1 ":"
                    emit_leaf()
                }
            } else {
                if (l1_matched) {
                    build_scalar_line(t3, "    ")
                    print_glines()
                } else if (l0_matched) {
                    print "  " t2 ":"
                    build_scalar_line(t3, "    ")
                    print_glines()
                } else {
                    print t1 ":"
                    print "  " t2 ":"
                    build_scalar_line(t3, "    ")
                    print_glines()
                }
            }
        }
        # Flush any trailing blank/comment run that was held back while still
        # searching for the target -- the file ended before a boundary key
        # arrived to prove those lines belonged to something else, so they
        # belong to this scope after all and are printed after whatever was
        # just inserted above.
        flush_pending()
    }
'

# ---------------------------------------------------------------------------
# wb_set_kv SOURCE_FILE KEY_PATH KIND [VALUE | ITEM...]
# The single write path. KEY_PATH is a dotted key of 1-3 segments
# ("lifecycle", "pipeline.path", "tasks_lifecycle.task-004.state"). KIND is
# "scalar" (exactly one VALUE follows) or "seq" (zero or more ITEMs follow --
# zero means the sequence is written as `[]`). Prints the rewritten file
# content to stdout; caller redirects to a temp file and is responsible for
# the lock + sanity-check + atomic mv (same discipline as every other write
# in this script -- this helper only computes the bytes).
#
# Cross-platform byte-invariance guards (carried forward unchanged from the
# pre-refactor wb_set_frontmatter):
#   - CRLF: some awk builds (notably on Windows) silently strip a `\r` on
#     read/print; a strict LF-only awk (Linux) never matches a CRLF line at
#     all. A CRLF source is normalized to LF before the awk pass and every
#     line of the result has `\r` restored afterward, so WB_SET_KV_AWK only
#     ever sees plain LF content on every platform.
#   - Trailing newline: awk's `print` unconditionally appends ORS ("\n")
#     after every record including the last, so a source file with no final
#     newline would otherwise gain one. The pipeline's full output is
#     captured via an `X`-terminator (a character, not a newline, so `$(...)`
#     itself strips nothing) and the single spurious line terminator awk
#     added is stripped back off only when the source genuinely lacked one.
# ---------------------------------------------------------------------------
wb_set_kv() {
    local source_file="$1" key_path="$2" kind="$3"
    shift 3

    local t1="" t2="" t3=""
    IFS='.' read -r t1 t2 t3 <<< "$key_path"
    local depth
    depth=$(( $(grep -o '\.' <<< "$key_path" | wc -l) + 1 ))

    local sep
    sep=$(printf '\x1f')

    local has_crlf=0 had_trailing_nl=1
    if [[ -s "$source_file" ]]; then
        local first_line=""
        IFS= read -r first_line < "$source_file" 2>/dev/null || true
        [[ "$first_line" == *$'\r' ]] && has_crlf=1
        [[ "$(tail -c1 "$source_file" | wc -l)" -eq 0 ]] && had_trailing_nl=0
    fi

    local items_joined="" first=1 it
    if [[ "$kind" == "seq" ]]; then
        for it in "$@"; do
            if [[ $first -eq 1 ]]; then items_joined="$it"; first=0
            else items_joined="${items_joined}${sep}${it}"; fi
        done
    fi

    local raw_output
    if [[ "$has_crlf" -eq 1 ]]; then
        raw_output="$(
            if [[ "$kind" == "seq" ]]; then
                sed 's/\r$//' "$source_file" \
                    | WB_KV_RAW_ITEMS="$items_joined" awk -v t1="$t1" -v t2="$t2" -v t3="$t3" -v n="$depth" -v kind="$kind" -v SEP="$sep" "$WB_SET_KV_AWK" \
                    | sed 's/$/\r/'
            else
                sed 's/\r$//' "$source_file" \
                    | WB_KV_RAW_VALUE="$1" awk -v t1="$t1" -v t2="$t2" -v t3="$t3" -v n="$depth" -v kind="$kind" -v SEP="$sep" "$WB_SET_KV_AWK" \
                    | sed 's/$/\r/'
            fi
            printf 'X'
        )"
    else
        raw_output="$(
            if [[ "$kind" == "seq" ]]; then
                WB_KV_RAW_ITEMS="$items_joined" awk -v t1="$t1" -v t2="$t2" -v t3="$t3" -v n="$depth" -v kind="$kind" -v SEP="$sep" "$WB_SET_KV_AWK" "$source_file"
            else
                WB_KV_RAW_VALUE="$1" awk -v t1="$t1" -v t2="$t2" -v t3="$t3" -v n="$depth" -v kind="$kind" -v SEP="$sep" "$WB_SET_KV_AWK" "$source_file"
            fi
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

# ---------------------------------------------------------------------------
# WB_GET_KV_AWK / wb_get_kv -- the read-back half of `wb_state_verify` below.
# Deliberately NOT the dashboard reader twins (this is a sanity check inside
# writeback-state.sh, not the read path a dashboard consumes) -- a small,
# bounded, read-only walk of the SAME 1-3 segment key space WB_SET_KV_AWK
# writes, reporting what it finds so the caller can compare it to what it
# intended to write. Generalizes the pre-refactor `wb_frontmatter_verify`
# (which only ever grepped `^key:` / `^  child:`) to a real nested-key
# resolve-on-re-read, closing the blind spot noted in SPEC.md SS L-2: today's
# `^  child:` grep matches ANY parent, not specifically the one just written.
# ---------------------------------------------------------------------------
WB_GET_KV_AWK='
    function unesc_dq(v,    out, i, n, c, nx) {
        out = ""; n = length(v); i = 1
        while (i <= n) {
            c = substr(v, i, 1)
            if (c == bs && i < n) {
                nx = substr(v, i+1, 1)
                if (nx == "n") { out = out "\n"; i += 2; continue }
                if (nx == "r") { out = out "\r"; i += 2; continue }
                if (nx == "t") { out = out "\t"; i += 2; continue }
                if (nx == dq) { out = out dq; i += 2; continue }
                if (nx == bs) { out = out bs; i += 2; continue }
                out = out c; i += 1; continue
            }
            out = out c; i += 1
        }
        return out
    }
    function unquote_value(v,    inner) {
        if (length(v) >= 2 && substr(v,1,1) == sq && substr(v, length(v),1) == sq) {
            inner = substr(v, 2, length(v)-2)
            gsub(sq sq, sq, inner)
            return inner
        }
        if (length(v) >= 2 && substr(v,1,1) == dq && substr(v, length(v),1) == dq) {
            inner = substr(v, 2, length(v)-2)
            return unesc_dq(inner)
        }
        return v
    }
    BEGIN {
        sq = sprintf("%c", 39); dq = sprintf("%c", 34); bs = sprintf("%c", 92)
        n = n + 0
        l0 = 0; l1 = 0; status = "notfound"; collecting = 0; count = 0; firstitem = ""
    }
    # CRLF tolerance (read-back only): GNU awk keeps the trailing \r of a \r\n
    # line in $0, so a value read from a CRLF STATE.yml would carry a stray \r
    # and never equal the \r-free value wb_state_verify compares against (exit
    # 3). Strip it here, on the read side ONLY -- the write path preserves \r on
    # untouched lines byte-for-byte (test 22f asserts both).
    { sub(/\r$/, "") }
    n==1 && status=="notfound" && $0 ~ ("^" t1 ":") {
        val = $0; sub("^" t1 ":", "", val); sub(/^[ \t]*/, "", val)
        print "SCALAR|" unquote_value(val)
        status = "found"; exit
    }
    n>=2 && !l0 && $0 ~ ("^" t1 ":") { l0 = 1; next }
    n==2 && l0 && status=="notfound" && $0 ~ ("^  " t2 ":") {
        val = $0; sub("^  " t2 ":", "", val); sub(/^[ \t]*/, "", val)
        if (kind == "scalar") { print "SCALAR|" unquote_value(val); status = "found"; exit }
        if (val == "[]") { print "SEQ|0|"; status = "found"; exit }
        collecting = 1; next
    }
    # !collecting guards this rule (task-015 fix, wb_get_kv seq-verify bug):
    # once t2 has matched and a "seq" read is walking that sequences "- "
    # continuation lines (collecting=1), the FIRST following top-level (col-0)
    # key is that sequences own boundary line, not evidence the queried key is
    # absent -- the collecting rule below is what must see it and finalize
    # the count. Without this guard this rule fired first (program order),
    # printed a spurious "NOTFOUND" and exited before collecting ever got a
    # chance, and the subsequent END block then ALSO printed the correct
    # "SEQ|n|first" (status was never set to "found" by this rule) -- two
    # lines out of one wb_get_kv call, so wb_state_verify saw a value that can
    # never equal "SEQ|n|first" and every non-empty seq write (quick_check.
    # findings, delivery_gate.issue_list -- the ordinary case, since both are
    # followed by a real sibling key in the shipped templates) died at exit 3
    # with the correctly-written temp file discarded. The write path
    # (WB_SET_KV_AWK) was never wrong -- only this read-back sanity check was.
    n==2 && l0 && $0 ~ /^[A-Za-z0-9_-]+:/ && status=="notfound" && !collecting { print "NOTFOUND"; exit }
    n==3 && l0 && !l1 && $0 ~ ("^  " t2 ":") { l1 = 1; next }
    n==3 && l0 && l1 && status=="notfound" && $0 ~ ("^    " t3 ":") {
        val = $0; sub("^    " t3 ":", "", val); sub(/^[ \t]*/, "", val)
        print "SCALAR|" unquote_value(val); status = "found"; exit
    }
    n==3 && l0 && l1 && $0 ~ /^  [A-Za-z0-9_-]+:/ && status=="notfound" { print "NOTFOUND"; exit }
    n==3 && l0 && $0 ~ /^[A-Za-z0-9_-]+:/ && status=="notfound" { print "NOTFOUND"; exit }
    collecting {
        ind = 0; if (match($0, /^[ \t]*/)) ind = RLENGTH
        rest = substr($0, ind + 1)
        if (rest ~ /^-( |.+|$)/) {
            item = rest; sub(/^-[ \t]*/, "", item)
            count++
            if (count == 1) firstitem = unquote_value(item)
            next
        }
        print "SEQ|" count "|" firstitem
        status = "found"; exit
    }
    END {
        if (status == "notfound") {
            if (collecting) print "SEQ|" count "|" firstitem
            else print "NOTFOUND"
        }
    }
'

# wb_get_kv FILE KEY_PATH KIND
# Prints "SCALAR|value" (unquoted), "SEQ|count|firstitem" (unquoted first
# item, or empty when count is 0), or "NOTFOUND".
wb_get_kv() {
    local file="$1" key_path="$2" kind="$3"
    local t1="" t2="" t3=""
    IFS='.' read -r t1 t2 t3 <<< "$key_path"
    local depth
    depth=$(( $(grep -o '\.' <<< "$key_path" | wc -l) + 1 ))
    awk -v t1="$t1" -v t2="$t2" -v t3="$t3" -v n="$depth" -v kind="$kind" "$WB_GET_KV_AWK" "$file"
}

# wb_state_verify TMP_FILE KEY_PATH KIND [VALUE | ITEM...]
# Sanity check after a wb_set_kv write: re-reads TMP_FILE at KEY_PATH and
# confirms it resolves to the value (scalar) or item count + first item
# (seq) just written. Returns non-zero (caller must discard TMP_FILE and die)
# on any mismatch, including "not found".
wb_state_verify() {
    local tmp_file="$1" key_path="$2" kind="$3"
    shift 3
    [[ -s "$tmp_file" ]] || return 1
    local result
    result=$(wb_get_kv "$tmp_file" "$key_path" "$kind")
    if [[ "$kind" == "scalar" ]]; then
        [[ "$result" == "SCALAR|$1" ]] && return 0
        return 1
    fi
    local want_count=$#
    if [[ "$want_count" -eq 0 ]]; then
        [[ "$result" == "SEQ|0|" ]] && return 0
        return 1
    fi
    [[ "$result" == "SEQ|${want_count}|$1" ]] && return 0
    return 1
}

# wb_state_is_mapping FILE
# The malformed-file check (exit 6): "the file parses and is a mapping"
# (SPEC.md SS L-2), replacing the pre-refactor per-mode heading grep (e.g.
# `## Task State`). Bounded, mechanical, and consistent with the declared
# subset (SPEC.md SS D-3): the file is non-empty and its first non-blank,
# non-comment line is a column-0 `key:` line.
wb_state_is_mapping() {
    local file="$1"
    [[ -s "$file" ]] || return 1
    local line
    while IFS= read -r line; do
        line="${line%$'\r'}"
        [[ -z "${line//[[:space:]]/}" ]] && continue
        [[ "$line" == \#* ]] && continue
        [[ "$line" =~ ^[A-Za-z0-9_-]+: ]] && return 0
        return 1
    done < "$file"
    return 1
}

# ---------------------------------------------------------------------------
# ltrim STR -- print STR with leading whitespace stripped. Shared by the
# --findings and --block caller-format parsers below.
# ---------------------------------------------------------------------------
ltrim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    printf '%s' "$s"
}

# ---------------------------------------------------------------------------
# parse_findings_block BLOCK -> sets REVIEWER_TIER (scalar) and the
# FINDINGS_ITEMS array (one entry per finding bullet, "[SEVERITY] ..." text
# verbatim). Parses the fixed, declared shape
# aid-execute/references/state-review.md SS "Write Findings to STATE.md"
# documents:
#   - **Reviewer Tier:** Small
#   - **Findings:**
#     - [CRITICAL] {description} -- {source} -- Fixed-on-spot
#     - [HIGH] {description} -- {source} -- Deferred-to-gate
# or, with no findings: `- **Findings:** none`. This is a small, bounded
# parse of ONE caller's own declared mini-format -- not a general markdown
# parser (D-3's "hand-rolled, bounded" posture applies to the state file
# subset; this is the caller-contract analogue, kept equally small).
# ---------------------------------------------------------------------------
parse_findings_block() {
    local block="$1"
    REVIEWER_TIER="--"
    FINDINGS_ITEMS=()
    local line trimmed item
    while IFS= read -r line; do
        line="${line%$'\r'}"
        if [[ "$line" =~ ^-[[:space:]]*\*\*Reviewer[[:space:]]Tier:\*\*[[:space:]]*(.*)$ ]]; then
            REVIEWER_TIER="${BASH_REMATCH[1]}"
            continue
        fi
        if [[ "$line" =~ ^-[[:space:]]*\*\*Findings:\*\*[[:space:]]*(.*)$ ]]; then
            continue
        fi
        trimmed="$(ltrim "$line")"
        if [[ "$trimmed" == -\ * ]]; then
            item="${trimmed#- }"
            [[ -n "$item" && "$item" != "none" ]] && FINDINGS_ITEMS+=("$item")
        fi
    done <<< "$block"
}

# ---------------------------------------------------------------------------
# parse_issue_list_block BLOCK -> sets the ISSUE_ITEMS array (one entry per
# issue-list line, severity-tagged text verbatim). Parses the fixed shape
# aid-execute/references/state-delivery-gate.md SS "6a: Build the Delivery
# Gate Block" documents:
#   - **Complexity Score:** {N}
#   - **Cycles:** {N}
#   - **Issue List:**
#     {one line per issue, or "none"}
# Complexity Score / Cycles are deliberately not persisted: the STATE.yml
# `delivery_gate` key carries only `issue_list` (SPEC.md SS D-4) -- those two
# fields have no target in the migrated schema (see this task's own report
# for the scope note).
# ---------------------------------------------------------------------------
parse_issue_list_block() {
    local block="$1"
    ISSUE_ITEMS=()
    local in_list=0 line trimmed item rest
    while IFS= read -r line; do
        line="${line%$'\r'}"
        if [[ "$in_list" -eq 0 ]]; then
            if [[ "$line" =~ ^-[[:space:]]*\*\*Issue[[:space:]]List:\*\*[[:space:]]*(.*)$ ]]; then
                in_list=1
                rest="${BASH_REMATCH[1]}"
                if [[ -n "$rest" && "$rest" != "none" ]]; then
                    item="${rest#- }"
                    [[ -n "$item" ]] && ISSUE_ITEMS+=("$item")
                fi
            fi
            continue
        fi
        trimmed="$(ltrim "$line")"
        [[ -z "$trimmed" ]] && continue
        item="$trimmed"
        [[ "$item" == -\ * ]] && item="${item#- }"
        [[ "$item" == "none" ]] && continue
        ISSUE_ITEMS+=("$item")
    done <<< "$block"
}

# ---------------------------------------------------------------------------
# Mode: [--delivery-id NNN] --task-id NNN --field FIELD --value VALUE
# Single-key write of FIELD (state | review | elapsed | notes | name).
# State is enum-validated (closed enum).
# ---------------------------------------------------------------------------
mode_field() {
    # Validate field name (per-unit task STATE.yml fields)
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

    # `state`/`review`/`elapsed`/`notes` are top-level scalar keys verbatim in
    # task-state-template.yml; the ONE exception is `name` (feature-005),
    # whose reader key is `display_name` (models.py TaskModel.display_name).
    local fm_key="$field_lower"
    case "$field_lower" in
        name) fm_key="display_name" ;;
    esac

    local padded_t
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_t=$(printf '%03d' "$((10#$TASK_ID))")

    # feature-001 flattened layout (auto-detected): task cells live in
    # tasks_lifecycle.task-NNN.<field> in the work-root STATE.yml -- no
    # per-task STATE.yml. AID_TASK_STATE_FILE override (if set) bypasses ALL
    # path resolution, including this flat-layout check, per its documented
    # contract above.
    if [[ -z "$TASK_STATE_FILE" ]] && is_flat_layout; then
        if [[ ! -f "$STATE_FILE" ]]; then
            die "$STATE_FILE does not exist" 1
        fi
        wb_state_is_mapping "$STATE_FILE" || die "malformed STATE.yml: $STATE_FILE does not parse as a YAML mapping" 6

        init_lock_file "$STATE_FILE"
        acquire_lock

        local key_path="tasks_lifecycle.task-${padded_t}.${fm_key}"
        local tmp
        tmp=$(mktemp)
        wb_set_kv "$STATE_FILE" "$key_path" scalar "$FIELD_VALUE" > "$tmp"

        if ! wb_state_verify "$tmp" "$key_path" scalar "$FIELD_VALUE"; then
            rm -f "$tmp"
            die "writeback sanity check failed: '$key_path' does not resolve to '$FIELD_VALUE' in output; $STATE_FILE preserved" 3
        fi

        mv "$tmp" "$STATE_FILE"
        echo "OK: $STATE_FILE updated -- task $padded_t field '$FIELD' set to '$FIELD_VALUE' (tasks_lifecycle)"
        return 0
    fi

    resolve_delivery_for_task_mode
    resolve_task_state_file "$DELIVERY_ID" "$TASK_ID"

    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        die "$TASK_STATE_FILE does not exist" 1
    fi
    wb_state_is_mapping "$TASK_STATE_FILE" || die "malformed STATE.yml: $TASK_STATE_FILE does not parse as a YAML mapping" 6

    init_lock_file "$TASK_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)
    wb_set_kv "$TASK_STATE_FILE" "$fm_key" scalar "$FIELD_VALUE" > "$tmp"

    if ! wb_state_verify "$tmp" "$fm_key" scalar "$FIELD_VALUE"; then
        rm -f "$tmp"
        die "writeback sanity check failed: key '$fm_key' does not resolve to '$FIELD_VALUE' in output; $TASK_STATE_FILE preserved" 3
    fi

    mv "$tmp" "$TASK_STATE_FILE"
    echo "OK: $TASK_STATE_FILE updated -- task $padded_t field '$FIELD' set to '$FIELD_VALUE'"
}

# ---------------------------------------------------------------------------
# Mode: [--delivery-id NNN] --task-id NNN --findings BLOCK
# Full-nested layout: writes quick_check.reviewer_tier (scalar) and
# quick_check.findings (sequence) in deliveries/delivery-NNN/tasks/task-NNN/STATE.yml,
# parsed from BLOCK via parse_findings_block.
#
# Flattened layout (feature-001, auto-detected): there is no per-task
# STATE.yml and no top-level quick_check key to nest a sequence under without
# exceeding the declared 3-level nesting cap (a sequence one level under
# tasks_lifecycle.task-NNN would be a THIRD mapping level plus the sequence
# itself -- past "a sequence at the second level", SPEC.md SS D-3). This
# targets tasks_lifecycle.task-NNN.quick_check instead and stores BLOCK
# verbatim as one scalar (double-quoted per D-5 mode 3, since it carries
# newlines) -- the minimal model extension that keeps this write inside the
# declared subset instead of abandoning it (see this task's own report).
# ---------------------------------------------------------------------------
mode_findings() {
    local padded_id
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_id=$(printf '%03d' "$((10#$TASK_ID))")

    if [[ -z "$TASK_STATE_FILE" ]] && is_flat_layout; then
        if [[ ! -f "$STATE_FILE" ]]; then
            die "$STATE_FILE does not exist" 1
        fi

        init_lock_file "$STATE_FILE"
        acquire_lock

        local key_path="tasks_lifecycle.task-${padded_id}.quick_check"
        local tmp
        tmp=$(mktemp)
        wb_set_kv "$STATE_FILE" "$key_path" scalar "$FINDINGS_BLOCK" > "$tmp"

        if ! wb_state_verify "$tmp" "$key_path" scalar "$FINDINGS_BLOCK"; then
            rm -f "$tmp"
            die "writeback sanity check failed: '$key_path' does not resolve to the findings block in output; $STATE_FILE preserved" 3
        fi

        mv "$tmp" "$STATE_FILE"
        echo "OK: $STATE_FILE updated -- quick-check findings written for task-${padded_id} (tasks_lifecycle, flattened layout)"
        return 0
    fi

    resolve_delivery_for_task_mode
    resolve_task_state_file "$DELIVERY_ID" "$TASK_ID"

    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        die "$TASK_STATE_FILE does not exist" 1
    fi

    local REVIEWER_TIER FINDINGS_ITEMS
    parse_findings_block "$FINDINGS_BLOCK"

    init_lock_file "$TASK_STATE_FILE"
    acquire_lock

    local tmp tmp2
    tmp=$(mktemp)
    wb_set_kv "$TASK_STATE_FILE" "quick_check.reviewer_tier" scalar "$REVIEWER_TIER" > "$tmp"
    tmp2=$(mktemp)
    wb_set_kv "$tmp" "quick_check.findings" seq "${FINDINGS_ITEMS[@]}" > "$tmp2"
    mv "$tmp2" "$tmp"

    if ! wb_state_verify "$tmp" "quick_check.reviewer_tier" scalar "$REVIEWER_TIER"; then
        rm -f "$tmp"
        die "writeback sanity check failed: 'quick_check.reviewer_tier' not found in output; $TASK_STATE_FILE preserved" 3
    fi
    if ! wb_state_verify "$tmp" "quick_check.findings" seq "${FINDINGS_ITEMS[@]}"; then
        rm -f "$tmp"
        die "writeback sanity check failed: 'quick_check.findings' does not resolve in output; $TASK_STATE_FILE preserved" 3
    fi

    mv "$tmp" "$TASK_STATE_FILE"
    echo "OK: $TASK_STATE_FILE updated -- quick_check written for task-${padded_id}"
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --lifecycle VALUE
# Single-key write of the `delivery_state` top-level scalar (SD-8).
# VALUE must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked
# Emits no user-facing output.
# ---------------------------------------------------------------------------
mode_delivery_lifecycle() {
    # Enum validation (closed enum)
    case "$LIFECYCLE_VALUE" in
        Pending-Spec|Specified|Executing|Gated|Done|Blocked) ;;
        *) die "invalid --lifecycle value '$LIFECYCLE_VALUE'; must be one of: Pending-Spec | Specified | Executing | Gated | Done | Blocked" 4 ;;
    esac

    resolve_delivery_state_file "$DELIVERY_ID"

    if [[ ! -f "$DELIVERY_STATE_FILE" ]]; then
        die "$DELIVERY_STATE_FILE does not exist" 1
    fi
    wb_state_is_mapping "$DELIVERY_STATE_FILE" || die "malformed STATE.yml: $DELIVERY_STATE_FILE does not parse as a YAML mapping" 6

    init_lock_file "$DELIVERY_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)
    wb_set_kv "$DELIVERY_STATE_FILE" "delivery_state" scalar "$LIFECYCLE_VALUE" > "$tmp"

    if ! wb_state_verify "$tmp" "delivery_state" scalar "$LIFECYCLE_VALUE"; then
        rm -f "$tmp"
        die "writeback sanity check failed: key 'delivery_state' does not resolve to '$LIFECYCLE_VALUE' in output; $DELIVERY_STATE_FILE preserved" 3
    fi

    mv "$tmp" "$DELIVERY_STATE_FILE"
    # No user-facing output
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --gate-field FIELD --gate-value VALUE
# Single-key write of one top-level Delivery Gate scalar:
#   Tier      -> gate_tier       (Small | Medium | Large)
#   Grade     -> gate_grade      (matches ^[A-F][+-]?$)
#   Timestamp -> gate_timestamp  (free ISO-8601 text)
# Targets the same file --lifecycle/--block resolve to (delivery-NNN/STATE.yml,
# or the work-root STATE.yml for the flattened layout).
# Emits no user-facing output.
# ---------------------------------------------------------------------------
mode_gate_field() {
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
    wb_set_kv "$DELIVERY_STATE_FILE" "$fm_key" scalar "$GATE_VALUE" > "$tmp"

    if ! wb_state_verify "$tmp" "$fm_key" scalar "$GATE_VALUE"; then
        rm -f "$tmp"
        die "writeback sanity check failed: key '$fm_key' does not resolve to '$GATE_VALUE' in output; $DELIVERY_STATE_FILE preserved" 3
    fi

    mv "$tmp" "$DELIVERY_STATE_FILE"
    # No user-facing output
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --block MARKDOWN_BLOCK
# Writes delivery_gate.issue_list (a sequence of severity-tagged strings),
# parsed from BLOCK via parse_issue_list_block. Targets the per-delivery
# STATE.yml (one writer per delivery branch -- disjoint writes), or the
# work-root STATE.yml for the flattened layout.
# ---------------------------------------------------------------------------
mode_delivery_block() {
    local padded_id
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_id=$(printf '%03d' "$((10#$DELIVERY_ID))")

    resolve_delivery_state_file "$DELIVERY_ID"

    if [[ ! -f "$DELIVERY_STATE_FILE" ]]; then
        die "$DELIVERY_STATE_FILE does not exist" 1
    fi

    local ISSUE_ITEMS
    parse_issue_list_block "$DELIVERY_BLOCK"

    init_lock_file "$DELIVERY_STATE_FILE"
    acquire_lock

    local tmp
    tmp=$(mktemp)
    wb_set_kv "$DELIVERY_STATE_FILE" "delivery_gate.issue_list" seq "${ISSUE_ITEMS[@]}" > "$tmp"

    if ! wb_state_verify "$tmp" "delivery_gate.issue_list" seq "${ISSUE_ITEMS[@]}"; then
        rm -f "$tmp"
        die "writeback sanity check failed: 'delivery_gate.issue_list' does not resolve in output; $DELIVERY_STATE_FILE preserved" 3
    fi

    mv "$tmp" "$DELIVERY_STATE_FILE"
    echo "OK: $DELIVERY_STATE_FILE updated -- delivery_gate.issue_list written for delivery-${padded_id}"
}

# ---------------------------------------------------------------------------
# Mode: --delivery-id NNN --append-issue ROW
# Append a single issue row to delivery-NNN-issues.md.
# File is created with a header if it does not exist.
# Idempotent: if an identical row already exists, no duplicate is written.
# Unaffected by the YAML migration -- this is a separate markdown log file,
# not STATE.yml.
# ---------------------------------------------------------------------------
mode_append_issue() {
    local padded_id
    # Force base-10 arithmetic before padding (see resolve_task_state_file above).
    padded_id=$(printf '%03d' "$((10#$DELIVERY_ID))")
    local issues_file="${DELIVERY_ISSUES_DIR}/delivery-${padded_id}-issues.md"

    # Use the work-dir-based issues path whenever DELIVERY_ISSUES_DIR is still the default,
    # for consistency with every other path this script resolves.
    #
    # This condition used to be gated on `-n "$AID_STATE_FILE"`, which was wrong twice over.
    # Bare, it aborted under `set -u` -- this is the only place the variable is dereferenced
    # without a default (the STATE_FILE default line uses `${AID_STATE_FILE:-...}`). And
    # guarding on it at all was the wrong test: a caller that exports AID_WORK_DIR rather than
    # AID_STATE_FILE -- which is exactly what aid-execute's delivery gate does -- skipped the
    # branch and then failed on a `.aid/works/work` lock directory that does not exist.
    #
    # `resolve_work_dir` already honours AID_WORK_DIR first and otherwise derives the root
    # from STATE_FILE, so the no-env default (`.aid/works/work/delivery-NNN-issues.md`) is
    # unchanged and this is strictly more permissive than what it replaces.
    if [[ "$DELIVERY_ISSUES_DIR" == ".aid/works/work" ]]; then
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
# Single-key write of a top-level (or one-level-nested `pipeline.*`) scalar
# in the work STATE.yml.
#
# Fields (canonical casing) -> key:
#   Lifecycle -> lifecycle | Phase -> phase | Active Skill -> active_skill |
#   Updated -> updated | Pause Reason -> pause_reason |
#   Block Reason -> block_reason | Block Artifact -> block_artifact |
#   Started -> started | Minimum Grade -> minimum_grade |
#   User Approved -> user_approved | Pipeline Path -> pipeline.path |
#   Pipeline Initiator -> pipeline.initiator
#
# Enum-validated fields (closed enums from work-state-template.yml):
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
#   to the "--" null sentinel (never physically removed -- the key stays
#   present so the file's shape is stable across every write).
#
# Emits no user-facing output. Acquires the existing sentinel lock.
# ---------------------------------------------------------------------------
mode_pipeline() {
    if [[ ! -f "$STATE_FILE" ]]; then
        die "$STATE_FILE does not exist" 1
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
    wb_set_kv "$STATE_FILE" "$fm_key" scalar "$FIELD_VALUE" > "$tmp"

    # Lifecycle change: clear conditional fields that no longer apply (chained
    # writes over the same evolving temp file -- each wb_set_kv call only
    # ever touches its one target key, so chaining preserves every other
    # line across every step).
    if [[ "$canonical_field" == "Lifecycle" ]]; then
        local tmp2
        if [[ "$FIELD_VALUE" != "Paused-Awaiting-Input" ]]; then
            tmp2=$(mktemp)
            wb_set_kv "$tmp" "pause_reason" scalar "--" > "$tmp2"
            mv "$tmp2" "$tmp"
        fi
        if [[ "$FIELD_VALUE" != "Blocked" ]]; then
            tmp2=$(mktemp)
            wb_set_kv "$tmp" "block_reason" scalar "--" > "$tmp2"
            mv "$tmp2" "$tmp"
            tmp2=$(mktemp)
            wb_set_kv "$tmp" "block_artifact" scalar "--" > "$tmp2"
            mv "$tmp2" "$tmp"
        fi
    fi

    if ! wb_state_verify "$tmp" "$fm_key" scalar "$FIELD_VALUE"; then
        rm -f "$tmp"
        die "writeback sanity check failed: key '$fm_key' does not resolve to '$FIELD_VALUE' in output; $STATE_FILE preserved" 3
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
