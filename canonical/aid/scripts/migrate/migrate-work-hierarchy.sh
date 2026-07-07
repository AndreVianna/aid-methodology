#!/usr/bin/env bash
# migrate-work-hierarchy.sh -- idempotent monolithic -> hierarchy migration helper.
#
# Converts a monolithic work-NNN-{name}/ layout (single STATE.md + tasks/*.md)
# into the uniform unit hierarchy:
#
#   work-NNN-{name}/
#     STATE.md                          (rewritten: AUTHORED header + DERIVED placeholders)
#     tasks/                            (legacy flat files retained as-is for reference)
#     delivery-NNN/
#       SPEC.md                         (delivery definition)
#       STATE.md                        (delivery authored lifecycle + gate + Q&A + derived tasks view)
#       tasks/
#         task-NNN/
#           SPEC.md                     (task definition -- from legacy tasks/task-NNN.md)
#           STATE.md                    (task mutable cells + findings + dispatch log)
#
# IDEMPOTENT: if any per-task STATE.md already exists, the entire work is skipped (no-op).
#
# Delivery resolution:
#   Each task is placed under the delivery parsed from the task's **Source:** line:
#     **Source:** work-NNN-{name} -> delivery-NNN
#   The pattern delivery-[0-9]+ is matched (same parse as writeback-state.sh).
#   Tasks with no parseable token default to delivery-001 with a WARNING row emitted.
#
# Scope discipline: runs ONLY on the path passed as $1.
# Does NOT scan $HOME or any real works automatically.
#
# Usage:
#   migrate-work-hierarchy.sh <work-dir> [--dry-run]
#
#   <work-dir>   Absolute or relative path to the monolithic work folder.
#   --dry-run    Print what would be done without writing files.
#
# Exit codes:
#   0  success (migrated or already-migrated no-op)
#   1  <work-dir> missing or not a directory
#   2  STATE.md not found in <work-dir>
#   3  No task files found in <work-dir>/tasks/
#   4  Verification failure (a per-unit file expected to be non-empty is empty)

set -euo pipefail

# ---------------------------------------------------------------------------
# Globals
# ---------------------------------------------------------------------------
SCRIPT_NAME="migrate-work-hierarchy.sh"
DRY_RUN=0
WARNINGS=()
WORK_DIR=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

log()  { echo "${SCRIPT_NAME}: $*"; }
warn() { echo "${SCRIPT_NAME}: WARNING: $*" >&2; WARNINGS+=("$*"); }
die()  { echo "${SCRIPT_NAME}: ERROR: $*" >&2; exit "${2:-1}"; }

p() { printf '%s\n' "$*"; }

# pad3 N -- zero-pad integer to 3 digits.
pad3() { printf '%03d' "$1"; }

# ---------------------------------------------------------------------------
# Delivery token resolution (same parse as writeback-state.sh)
# ---------------------------------------------------------------------------

# resolve_delivery_token TASK_FILE
# Prints the delivery number (integer) or "" on failure.
resolve_delivery_token() {
    local task_file="$1"
    local source_line delivery_raw raw_num resolved

    source_line=$(grep -m1 '^\*\*Source:\*\*' "$task_file" 2>/dev/null || true)
    if [[ -z "$source_line" ]]; then
        echo ""; return 0
    fi

    # Match delivery-NNN (1+ digits) -- same regex as writeback-state.sh.
    delivery_raw=$(echo "$source_line" | grep -oE 'delivery-[0-9]+' | head -1)
    if [[ -z "$delivery_raw" ]]; then
        echo ""; return 0
    fi

    raw_num="${delivery_raw#delivery-}"
    # Strip leading zeros via base-10 arithmetic (handles delivery-001, delivery-01, delivery-1).
    resolved=$(( 10#$raw_num ))
    if [[ "$resolved" -eq 0 ]]; then
        echo ""; return 0
    fi
    echo "$resolved"
}

# ---------------------------------------------------------------------------
# Section extractors for the monolithic STATE.md
# ---------------------------------------------------------------------------

# extract_between_h2 FILE SECTION_HEADER
# Prints lines between one ## heading and the next.
extract_between_h2() {
    local file="$1" heading="$2"
    awk -v h="## ${heading}" '
        $0 == h { inside=1; next }
        inside && /^## / { exit }
        inside { print }
    ' "$file"
}

# extract_task_findings FILE TASK_ID
# Extracts the ### task-NNN block under ## Quick Check Findings.
extract_task_findings() {
    local file="$1" task_id="$2"
    local heading="### ${task_id}"
    extract_between_h2 "$file" "Quick Check Findings" | awk -v h="$heading" '
        found && /^###/ { exit }
        found { print }
        $0 == h { found=1 }
    '
}

# extract_task_dispatches FILE TASK_ID
# Extracts the ### task-NNN block under ## Dispatches.
extract_task_dispatches() {
    local file="$1" task_id="$2"
    local heading="### ${task_id}"
    extract_between_h2 "$file" "Dispatches" | awk -v h="$heading" '
        found && /^###/ { exit }
        found { print }
        $0 == h { found=1 }
    '
}

# extract_delivery_gate FILE DELIVERY_NUM
# Extracts the ### delivery-NNN block under ## Delivery Gates.
extract_delivery_gate() {
    local file="$1" delivery_num="$2"
    local padded heading
    padded=$(pad3 "$delivery_num")
    heading="### delivery-${padded}"
    extract_between_h2 "$file" "Delivery Gates" | awk -v h="$heading" '
        found && /^###/ { exit }
        found { print }
        $0 == h { found=1 }
    '
}

# extract_delivery_qa FILE DELIVERY_NUM
# Extracts Q&A blocks (### Q lines + content) that mention delivery-NNN in any line.
# Skips non-### Q preamble text (intro quotes/notes before the first Q block).
extract_delivery_qa() {
    local file="$1" delivery_num="$2"
    local padded="delivery-$(pad3 "$delivery_num")"
    extract_between_h2 "$file" "Cross-phase Q&A" | awk -v d="$padded" '
        /^### Q[0-9]/ {
            # Flush previous block if it matched.
            if (match_d && block != "") {
                printf "%s", block
            }
            block = $0 "\n"
            match_d = 0
            in_block = 1
            next
        }
        in_block {
            block = block $0 "\n"
            if (index($0, d) > 0) { match_d = 1 }
        }
        # Lines before the first ### Q block are preamble -- skip them.
        END {
            if (match_d && block != "") {
                printf "%s", block
            }
        }
    '
}

# extract_work_qa FILE
# Extracts Q&A blocks (### Q + content) that do NOT mention any delivery-NNN.
# Skips preamble text before the first ### Q block.
extract_work_qa() {
    local file="$1"
    extract_between_h2 "$file" "Cross-phase Q&A" | awk '
        /^### Q[0-9]/ {
            if (!has_delivery && in_block && block != "") {
                printf "%s", block
            }
            block = $0 "\n"
            has_delivery = 0
            in_block = 1
            next
        }
        in_block {
            block = block $0 "\n"
            if ($0 ~ /delivery-[0-9]/) { has_delivery = 1 }
        }
        # Preamble (before first ### Q) is skipped.
        END {
            if (!has_delivery && in_block && block != "") {
                printf "%s", block
            }
        }
    '
}

# extract_task_row_fields FILE TASK_ID
# Prints pipe-separated State|Review|Elapsed|Notes from ## Tasks Status (or ## Tasks State) table.
# Tolerates both "Status" and "State" heading names, and both task-NNN and integer # column.
extract_task_row_fields() {
    local file="$1" task_id="$2"
    local table_lines=""

    table_lines=$(extract_between_h2 "$file" "Tasks Status")
    if [[ -z "$table_lines" ]]; then
        table_lines=$(extract_between_h2 "$file" "Tasks State")
    fi

    echo "$table_lines" | awk -v tid="$task_id" '
        /^\|/ {
            n = split($0, cells, "|")
            for (i = 1; i <= n; i++) {
                v = cells[i]
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
                if (v == tid) {
                    # Found. The table has columns:
                    # | # | Task | Type | Wave | Status/State | Review | Elapsed | Notes |
                    # split by "|" gives: [0]="" [1]="" [2]=# [3]=Task [4]=Type [5]=Wave [6]=Status [7]=Review [8]=Elapsed [9]=Notes [10]=""
                    st = cells[6]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", st)
                    rv = cells[7]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", rv)
                    el = cells[8]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", el)
                    nt = cells[9]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", nt)
                    print st "|" rv "|" el "|" nt
                    found = 1
                    exit
                }
            }
        }
        END { if (!found) print "Pending|--|--|--" }
    '
}

# ---------------------------------------------------------------------------
# Output writers (use p() to avoid printf flag issues with leading dashes)
# ---------------------------------------------------------------------------

write_task_state() {
    local out_file="$1" task_id="$2" delivery_num="$3" work_name="$4"
    local state="$5" review="$6" elapsed="$7" notes="$8"
    local findings="$9" dispatches="${10}"
    local padded_d
    padded_d=$(pad3 "$delivery_num")

    {
        p "# Task State -- ${task_id}"
        p ""
        p "> **Task:** ${task_id}"
        p "> **Delivery:** delivery-${padded_d}"
        p "> **Work:** ${work_name}"
        p ""
        p "---"
        p ""
        p "## Task State"
        p ""
        p "<!-- AUTHORED -- written ONLY by \`writeback-state.sh --task-id NNN --field State --value VALUE\`."
        p "     State enum (closed; single source of truth):"
        p "       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled"
        p "     SD-2 ordering (most-advanced wins on reconcile):"
        p "       Done > Canceled > In Review > In Progress > Blocked > Failed > Pending -->"
        p ""
        p "- **State:** ${state}"
        p "- **Review:** ${review}"
        p "- **Elapsed:** ${elapsed}"
        p "- **Notes:** ${notes}"
        p ""
        p "---"
        p ""
        p "## Quick Check Findings"
        p ""
        p "<!-- AUTHORED -- written by \`writeback-state.sh --task-id NNN --findings ...\` -->"
        p ""
        if [[ -n "$findings" ]]; then
            # Trim leading blank lines from extracted findings block.
            printf '%s\n' "$findings" | awk 'NF || found { found=1; print }'
        else
            p "_none_"
        fi
        p ""
        p "---"
        p ""
        p "## Dispatch Log"
        p ""
        p "<!-- AUTHORED -- appended by the dispatcher on subagent completion. -->"
        p ""
        p "| Date | Agent | ETA Band | Actual | Outcome |"
        p "|------|-------|----------|--------|---------|"
        if [[ -n "$dispatches" ]]; then
            # Print only data rows (skip header row "| Date |..." and separator "|----|..." and blank lines).
            printf '%s\n' "$dispatches" | awk '
                /^\|[[:space:]]*Date[[:space:]]*\|/ { next }   # header row
                /^\|[-| ]+\|/ { next }                          # separator row
                /^[[:space:]]*$/ { next }                       # blank lines
                { print }
            '
        fi
    } > "$out_file"
}

write_delivery_spec() {
    local out_file="$1" delivery_num="$2" work_name="$3" task_rows="$4"
    local padded_d
    padded_d=$(pad3 "$delivery_num")

    {
        p "# Delivery SPEC -- delivery-${padded_d}"
        p ""
        p "> **Delivery:** delivery-${padded_d}"
        p "> **Work:** ${work_name}"
        p "> **Created:** $(date -u +%Y-%m-%d)"
        p ""
        p "---"
        p ""
        p "## Objective"
        p ""
        p "(Migrated from monolithic work STATE.md -- populate from PLAN.md or work SPEC.md.)"
        p ""
        p "## Scope"
        p ""
        p "(Migrated -- see work PLAN.md or REQUIREMENTS.md for full scope.)"
        p ""
        p "**Out of scope:** --"
        p ""
        p "## Gate Criteria"
        p ""
        p "(Migrated -- see original delivery gate block below for the gate outcome.)"
        p ""
        p "- [ ] All tasks in this delivery complete."
        p "- [ ] All section-6 quality gates pass."
        p ""
        p "## Tasks"
        p ""
        p "| Task | Type | Title |"
        p "|------|------|-------|"
        if [[ -n "$task_rows" ]]; then
            printf '%s\n' "$task_rows"
        else
            p "| _none_ | | |"
        fi
        p ""
        p "## Dependencies"
        p ""
        p "- **Depends on:** -- (none)"
        p "- **Blocks:** -- (none)"
        p ""
        p "## Notes"
        p ""
        p "Migrated by migrate-work-hierarchy.sh from monolithic layout."
    } > "$out_file"
}

write_delivery_state() {
    local out_file="$1" delivery_num="$2" work_name="$3"
    local gate_block="$4" qa_block="$5" lifecycle="$6"
    local padded_d
    padded_d=$(pad3 "$delivery_num")

    {
        p "# Delivery State -- delivery-${padded_d}"
        p ""
        p "> **Delivery:** delivery-${padded_d}"
        p "> **Work:** ${work_name}"
        p "> **Branch:** aid/work-NNN-delivery-${padded_d}  (fill in work number)"
        p ""
        p "---"
        p ""
        p "## Delivery Lifecycle"
        p ""
        p "<!-- AUTHORED -- SD-8 enum; independently authored (SD-9). -->"
        p ""
        p "- **State:** ${lifecycle}"
        p "- **Updated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        p "- **Block Reason:** --"
        p "- **Block Artifact:** --"
        p ""
        p "---"
        p ""
        p "## Delivery Gate"
        p ""
        p "<!-- AUTHORED -- written via \`writeback-state.sh --delivery-id NNN --block ...\`. -->"
        p ""
        if [[ -n "$gate_block" ]]; then
            # Trim leading blank lines from extracted gate block.
            printf '%s\n' "$gate_block" | awk 'NF || found { found=1; print }'
        else
            p "- **Reviewer Tier:** --"
            p "- **Grade:** Pending"
            p "- **Issue List:** --"
            p "- **Timestamp:** --"
        fi
        p ""
        p "---"
        p ""
        p "## Cross-phase Q&A"
        p ""
        p "<!-- AUTHORED -- delivery-scoped Q&A (SD-5); single writer: this delivery branch. -->"
        p ""
        if [[ -n "$qa_block" ]]; then
            # Ensure trailing newline so the separator lands on its own line.
            printf '%s\n' "$qa_block"
        else
            p "_none_"
        fi
        p ""
        p "---"
        p ""
        p "<!-- DERIVED / READ-ONLY VIEWS"
        p "     The Tasks State section below is assembled at READ TIME from per-task STATE.md files."
        p "     It is NEVER written directly into this file. -->"
        p ""
        p "## Tasks State"
        p ""
        p "<!-- DERIVED -- read-only rollup from tasks/task-NNN/STATE.md at read time. Never written here. -->"
        p ""
        p "| # | Task | Type | Wave | State | Review | Elapsed | Notes |"
        p "|---|------|------|------|-------|--------|---------|-------|"
        p "| _derived_ | | | | | | | |"
    } > "$out_file"
}

# rewrite_work_state SRC_FILE DST_FILE WORK_QA
# Rewrites the work STATE.md: preserves the header sections (Pipeline Status, Triage, etc.)
# and Lifecycle History; replaces Tasks Status/State, Delivery Gates, Cross-phase Q&A,
# Quick Check Findings, Dispatches, and Calibration Log with derived-view placeholders.
# WORK_QA (work-owner Q&A not scoped to any delivery) is inserted INTO the Cross-phase Q&A
# section placeholder, before Lifecycle History, so it appears in the correct section.
rewrite_work_state() {
    local src="$1" dst="$2" work_qa="$3"

    # Pass work_qa into awk via a temp file to avoid quoting complexity.
    local qa_tmp
    qa_tmp="$(mktemp)"
    if [[ -n "$work_qa" ]]; then
        printf '%s\n' "$work_qa" > "$qa_tmp"
    fi

    # Sections to DROP (replace with derived-view placeholders):
    #   ## Tasks Status / ## Tasks State
    #   ## Delivery Gates
    #   ## Cross-phase Q&A
    #   ## Quick Check Findings
    #   ## Dispatches
    #   ## Calibration Log
    # Sections to KEEP verbatim:
    #   Everything before the first dropped section (header, Pipeline Status, Triage, etc.)
    #   ## Lifecycle History (keep -- single writer, append-only)

    awk -v qa_file="$qa_tmp" '
        function emit_derived_block(   f, line) {
            print "## Tasks State"
            print ""
            print "<!-- DERIVED -- read-only; assembled from delivery-NNN/tasks/task-NNN/STATE.md at read time. Never written here. -->"
            print ""
            print "| # | Task | Type | Wave | State | Review | Elapsed | Notes |"
            print "|---|------|------|------|-------|--------|---------|-------|"
            print "| _derived_ | | | | | | | |"
            print ""
            print "## Plan / Deliveries"
            print ""
            print "<!-- DERIVED -- read-only rollup from delivery-NNN/STATE.md at read time. Never written here. -->"
            print ""
            print "| Delivery | State | Tasks | Notes |"
            print "|----------|-------|-------|-------|"
            print "| _derived_ | | | |"
            print ""
            print "## Delivery Gates"
            print ""
            print "<!-- DERIVED -- union of delivery-NNN/STATE.md ## Delivery Gate blocks at read time. Never written here. -->"
            print ""
            print "_See delivery-NNN/STATE.md for each delivery gate block._"
            print ""
            print "## Cross-phase Q&A"
            print ""
            print "<!-- DERIVED (delivery-scoped entries) + AUTHORED (work-owner entries only)."
            print "     Delivery-scoped Q&A lives in delivery-NNN/STATE.md (SD-5)."
            print "     Work-owner Q&A below was not delivery-scoped in the legacy file. -->"
            print ""
            # Emit work-owner Q&A inline if present.
            if (qa_file != "" && (getline line < qa_file) > 0) {
                print line
                while ((getline line < qa_file) > 0) { print line }
                close(qa_file)
                print ""
            }
        }
        /^## Tasks Status/ || /^## Tasks State/ ||
        /^## Delivery Gates/ ||
        /^## Cross-phase Q&A/ ||
        /^## Quick Check Findings/ ||
        /^## Dispatches/ ||
        /^## Calibration Log/ {
            skip = 1
            next
        }
        /^## Lifecycle History/ {
            if (skip && !derived_emitted) {
                skip = 0
                derived_emitted = 1
                emit_derived_block()
            }
            print
            next
        }
        !skip { print }
        END {
            # If Lifecycle History was never encountered, emit the derived block at end.
            if (!derived_emitted) {
                print ""
                emit_derived_block()
            }
        }
    ' "$src" > "$dst"

    rm -f "$qa_tmp"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=1; shift ;;
            -h|--help)
                echo "Usage: ${SCRIPT_NAME} <work-dir> [--dry-run]"
                exit 0
                ;;
            *)
                if [[ -z "$WORK_DIR" ]]; then
                    WORK_DIR="$1"; shift
                else
                    die "Unexpected argument: $1" 1
                fi
                ;;
        esac
    done
    if [[ -z "$WORK_DIR" ]]; then
        echo "Usage: ${SCRIPT_NAME} <work-dir> [--dry-run]" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Main migration logic
# ---------------------------------------------------------------------------

main() {
    parse_args "$@"

    WORK_DIR="$(cd "$WORK_DIR" && pwd)"
    local WORK_NAME
    WORK_NAME="$(basename "$WORK_DIR")"

    log "Migrating: $WORK_DIR"

    # Input validation.
    [[ -d "$WORK_DIR" ]] || die "'$WORK_DIR' is not a directory." 1
    [[ -f "$WORK_DIR/STATE.md" ]] || die "'$WORK_DIR/STATE.md' not found." 2
    [[ -d "$WORK_DIR/tasks" ]] || die "'$WORK_DIR/tasks/' not found." 3

    # Gather task files (sorted).
    local -a TASK_FILES
    mapfile -t TASK_FILES < <(find "$WORK_DIR/tasks" -maxdepth 1 -name 'task-*.md' | sort)
    if [[ "${#TASK_FILES[@]}" -eq 0 ]]; then
        die "No task files found in '$WORK_DIR/tasks/'." 3
    fi

    # IDEMPOTENCY CHECK: skip if any hierarchy file already exists.
    if find "$WORK_DIR" -path "*/delivery-*/tasks/task-*/STATE.md" -maxdepth 5 2>/dev/null | grep -q .; then
        log "IDEMPOTENT: hierarchy already present in '${WORK_NAME}'. No-op."
        exit 0
    fi

    log "Tasks found: ${#TASK_FILES[@]}"

    # -----------------------------------------------------------------------
    # Pass 1: resolve delivery placement for each task.
    # -----------------------------------------------------------------------
    declare -A TASK_DELIVERY   # task_id -> delivery_number (integer)
    declare -A TASK_TITLE      # task_id -> title string
    declare -A TASK_TYPE       # task_id -> type string
    local -a ALL_DELIVERIES=() # unique delivery numbers (in order first seen)

    local task_file task_id delivery_num type_line title_line already d
    for task_file in "${TASK_FILES[@]}"; do
        task_id="$(basename "$task_file" .md)"

        delivery_num="$(resolve_delivery_token "$task_file")"

        if [[ -z "$delivery_num" ]]; then
            warn "Task '${task_id}': no parseable delivery token in Source line -- defaulting to delivery-001"
            log "  [WARNING] Task ${task_id}: no parseable delivery token; defaulted to delivery-001"
            delivery_num=1
        fi

        TASK_DELIVERY["$task_id"]="$delivery_num"

        type_line=$(grep -m1 '^\*\*Type:\*\*' "$task_file" 2>/dev/null || true)
        TASK_TYPE["$task_id"]="${type_line#\*\*Type:\*\* }"
        [[ -z "${TASK_TYPE[$task_id]}" ]] && TASK_TYPE["$task_id"]="--"

        title_line=$(grep -m1 '^# task-' "$task_file" 2>/dev/null || true)
        # Strip "# task-NNN: " prefix.
        TASK_TITLE["$task_id"]="${title_line#\# ${task_id}: }"
        [[ -z "${TASK_TITLE[$task_id]}" ]] && TASK_TITLE["$task_id"]="(no title)"

        already=0
        for d in "${ALL_DELIVERIES[@]:-}"; do
            if [[ "$d" -eq "$delivery_num" ]]; then already=1; break; fi
        done
        if [[ "$already" -eq 0 ]]; then
            ALL_DELIVERIES+=("$delivery_num")
        fi
    done

    log "Deliveries detected: ${ALL_DELIVERIES[*]}"

    # -----------------------------------------------------------------------
    # Pass 2: create per-task directories with SPEC.md + STATE.md.
    # -----------------------------------------------------------------------
    local padded_d padded_t task_dest_dir
    local row_fields state review elapsed notes findings dispatches

    for task_file in "${TASK_FILES[@]}"; do
        task_id="$(basename "$task_file" .md)"
        delivery_num="${TASK_DELIVERY[$task_id]}"
        padded_d="$(pad3 "$delivery_num")"
        task_dest_dir="${WORK_DIR}/delivery-${padded_d}/tasks/${task_id}"

        log "Creating ${task_dest_dir}/"

        if [[ "$DRY_RUN" -eq 0 ]]; then
            mkdir -p "$task_dest_dir"
        fi

        # task SPEC.md -- verbatim copy of the legacy task file.
        if [[ "$DRY_RUN" -eq 0 ]]; then
            cp "$task_file" "${task_dest_dir}/SPEC.md"
        else
            log "DRY-RUN: would copy ${task_file} -> ${task_dest_dir}/SPEC.md"
        fi

        # Extract mutable cells from the Tasks Status/State table.
        row_fields="$(extract_task_row_fields "$WORK_DIR/STATE.md" "$task_id")"
        IFS='|' read -r state review elapsed notes <<< "$row_fields"

        # Extract findings + dispatch rows for this task.
        findings="$(extract_task_findings "$WORK_DIR/STATE.md" "$task_id")"
        dispatches="$(extract_task_dispatches "$WORK_DIR/STATE.md" "$task_id")"

        if [[ "$DRY_RUN" -eq 0 ]]; then
            write_task_state "${task_dest_dir}/STATE.md" \
                "$task_id" "$delivery_num" "$WORK_NAME" \
                "$state" "$review" "$elapsed" "$notes" \
                "$findings" "$dispatches"
        else
            log "DRY-RUN: would write ${task_dest_dir}/STATE.md"
        fi
    done

    # -----------------------------------------------------------------------
    # Pass 3: create per-delivery directories with SPEC.md + STATE.md.
    # -----------------------------------------------------------------------
    local delivery_dir task_rows tid tdelivery ttype ttitle gate_block qa_block lifecycle has_tasks grade_line grade_val

    for delivery_num in "${ALL_DELIVERIES[@]}"; do
        padded_d="$(pad3 "$delivery_num")"
        delivery_dir="${WORK_DIR}/delivery-${padded_d}"
        log "Creating ${delivery_dir}/"

        if [[ "$DRY_RUN" -eq 0 ]]; then
            mkdir -p "$delivery_dir"
        fi

        # Build task-rows table for this delivery.
        task_rows=""
        for task_file in "${TASK_FILES[@]}"; do
            tid="$(basename "$task_file" .md)"
            tdelivery="${TASK_DELIVERY[$tid]}"
            if [[ "$tdelivery" -eq "$delivery_num" ]]; then
                ttype="${TASK_TYPE[$tid]}"
                ttitle="${TASK_TITLE[$tid]}"
                task_rows+="| ${tid} | ${ttype} | ${ttitle} |"$'\n'
            fi
        done
        task_rows="${task_rows%$'\n'}"

        if [[ "$DRY_RUN" -eq 0 ]]; then
            write_delivery_spec "${delivery_dir}/SPEC.md" "$delivery_num" "$WORK_NAME" "$task_rows"
        else
            log "DRY-RUN: would write ${delivery_dir}/SPEC.md"
        fi

        # Extract gate block + delivery-scoped Q&A.
        gate_block="$(extract_delivery_gate "$WORK_DIR/STATE.md" "$delivery_num")"
        qa_block="$(extract_delivery_qa "$WORK_DIR/STATE.md" "$delivery_num")"

        # Derive initial lifecycle from gate outcome.
        # No tasks at all -> Pending-Spec.
        # Gate Pending or absent -> Executing (tasks present, execution started/underway).
        # Gate grade != Pending and non-empty -> Done.
        has_tasks=0
        for task_file in "${TASK_FILES[@]}"; do
            tid="$(basename "$task_file" .md)"
            tdelivery="${TASK_DELIVERY[$tid]}"
            if [[ "$tdelivery" -eq "$delivery_num" ]]; then has_tasks=1; break; fi
        done

        if [[ "$has_tasks" -eq 0 ]]; then
            lifecycle="Pending-Spec"
        elif [[ -z "$gate_block" ]]; then
            lifecycle="Executing"
        else
            grade_line=$(echo "$gate_block" | grep -m1 '^\- \*\*Grade:\*\*' || true)
            grade_val="${grade_line#- \*\*Grade:\*\* }"
            grade_val="$(echo "$grade_val" | tr -d '[:space:]')"
            if [[ "$grade_val" == "Pending" || -z "$grade_val" ]]; then
                lifecycle="Executing"
            else
                lifecycle="Done"
            fi
        fi

        if [[ "$DRY_RUN" -eq 0 ]]; then
            write_delivery_state "${delivery_dir}/STATE.md" \
                "$delivery_num" "$WORK_NAME" \
                "$gate_block" "$qa_block" "$lifecycle"
        else
            log "DRY-RUN: would write ${delivery_dir}/STATE.md"
        fi
    done

    # -----------------------------------------------------------------------
    # Pass 4: verify per-unit files are non-empty, then rewrite work STATE.md.
    # -----------------------------------------------------------------------
    log "Verifying per-unit files..."

    if [[ "$DRY_RUN" -eq 0 ]]; then
        for task_file in "${TASK_FILES[@]}"; do
            task_id="$(basename "$task_file" .md)"
            delivery_num="${TASK_DELIVERY[$task_id]}"
            padded_d="$(pad3 "$delivery_num")"
            task_dest_dir="${WORK_DIR}/delivery-${padded_d}/tasks/${task_id}"

            [[ -s "${task_dest_dir}/SPEC.md" ]] || die "Verification: '${task_dest_dir}/SPEC.md' is empty." 4
            [[ -s "${task_dest_dir}/STATE.md" ]] || die "Verification: '${task_dest_dir}/STATE.md' is empty." 4
        done

        for delivery_num in "${ALL_DELIVERIES[@]}"; do
            padded_d="$(pad3 "$delivery_num")"
            delivery_dir="${WORK_DIR}/delivery-${padded_d}"
            [[ -s "${delivery_dir}/SPEC.md" ]] || die "Verification: '${delivery_dir}/SPEC.md' is empty." 4
            [[ -s "${delivery_dir}/STATE.md" ]] || die "Verification: '${delivery_dir}/STATE.md' is empty." 4
        done
    fi

    log "Verification passed. Rewriting work STATE.md..."

    # Extract work-level Q&A (no delivery mention) to preserve in work STATE.md.
    local work_qa
    work_qa="$(extract_work_qa "$WORK_DIR/STATE.md")"

    if [[ "$DRY_RUN" -eq 0 ]]; then
        local tmp_file="${WORK_DIR}/STATE.md.migrate-tmp"
        rewrite_work_state "$WORK_DIR/STATE.md" "$tmp_file" "$work_qa"
        mv "$tmp_file" "$WORK_DIR/STATE.md"
    else
        log "DRY-RUN: would rewrite $WORK_DIR/STATE.md with derived-view placeholders"
    fi

    # -----------------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------------
    log "Migration complete: ${WORK_NAME}"
    log "  Deliveries created: ${#ALL_DELIVERIES[@]} (${ALL_DELIVERIES[*]})"
    log "  Tasks migrated: ${#TASK_FILES[@]}"

    if [[ "${#WARNINGS[@]}" -gt 0 ]]; then
        log "  Warnings (${#WARNINGS[@]}):"
        local w
        for w in "${WARNINGS[@]}"; do
            log "    [WARNING] ${w}"
        done
    else
        log "  Warnings: none"
    fi
}

main "$@"
