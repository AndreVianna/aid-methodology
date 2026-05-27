#!/usr/bin/env bash
#
# parse-recipe.sh — feature-011 helper for canonical/recipes/ files.
# Portability: POSIX-portable; runs on Linux, macOS (Big Sur+), and Windows Git Bash.
# Avoids GNU-only grep flags. Uses `sleep 0.5` (fractional seconds — requires
# modern macOS [Big Sur+] or any Linux/Git Bash; not POSIX-strict but accepted
# by GNU coreutils sleep and macOS sleep ≥11).

# parse-recipe.sh — recipe parser for FR8 (feature-011) lite-path slot-fill
#
# Parses AID recipe files (YAML front-matter + ## spec / ## tasks body blocks).
# Consumed by /aid-interview triage's recipe-offer step.
#
# Usage:
#   parse-recipe.sh --list RECIPE_FILE
#       Emit one slot name per line (unique, order of first appearance) from the
#       recipe body. Slot names match [a-z][a-z0-9-]* (POSIX ERE). Does not
#       emit {{}} delimiters — just bare names.
#
#   parse-recipe.sh --validate RECIPE_FILE
#       Parse front-matter slot-count and task-count, compare to actual unique
#       slot-name count in body and actual ### task-NNN heading count in the
#       ## tasks block. Prints OK or WARN lines to stdout. Exits 0 even on
#       mismatch (mismatches are surfaced as warnings; instantiation continues).
#       Exits non-zero only on structural errors (missing file, malformed
#       front-matter, missing required blocks).
#
#   parse-recipe.sh --render --recipe RECIPE_FILE --slots-json SLOTS_JSON_FILE \
#                   --work-dir WORK_DIR
#       Substitute all {{slot-name}} tokens with user-supplied values from the
#       JSON file, apply the {!{ -> {{ escape rewrite, then emit:
#         WORK_DIR/SPEC.md          <- rendered ## spec block content
#         WORK_DIR/tasks/task-NNN.md <- one file per ### task-NNN heading
#       Uses a sentinel-file lock to coordinate concurrent writes if multiple
#       callers race on the same WORK_DIR.
#       SLOTS_JSON_FILE must be a flat JSON object: {"slot-name": "value", ...}
#       Only 'python3' or 'python' is required for JSON parsing (no jq dep).
#
#   parse-recipe.sh --spec RECIPE_FILE
#       Emit the raw (unrendered) ## spec block content to stdout.
#       Useful for preview; stops at ## tasks (or EOF).
#
#   parse-recipe.sh --tasks RECIPE_FILE
#       Emit the raw (unrendered) ## tasks block content to stdout.
#
#   parse-recipe.sh -h | --help
#       Print this usage text and exit 0.
#
# Exit codes:
#   0  success (or --validate with warnings — see stdout)
#   1  recipe file missing or unreadable
#   2  malformed front-matter (missing required field)
#   3  missing required body block (## spec or ## tasks absent)
#   4  invalid argument or argument value
#   5  missing required argument
#   6  work directory creation failed
#   7  render write error (SPEC.md or task file not written)
#   8  lock contention timeout

set -u

# ---------------------------------------------------------------------------
# Defaults — callers may override via environment for testing
# ---------------------------------------------------------------------------
LOCK_TIMEOUT="${AID_PARSE_RECIPE_LOCK_TIMEOUT:-10}"  # max retries (0.5s each)

# ---------------------------------------------------------------------------
usage() {
    sed -n '2,49p' "$0" | sed 's/^# \{0,1\}//'
}

die() { echo "ERROR: parse-recipe.sh: $*" >&2; exit "${2:-1}"; }
warn() { echo "WARN: parse-recipe.sh: $*" >&2; }

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
MODE=""
RECIPE_FILE=""
SLOTS_JSON_FILE=""
WORK_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --list)
            [[ $# -lt 2 ]] && die "--list requires RECIPE_FILE argument" 5
            MODE="list"
            RECIPE_FILE="$2"; shift 2
            ;;
        --validate)
            [[ $# -lt 2 ]] && die "--validate requires RECIPE_FILE argument" 5
            MODE="validate"
            RECIPE_FILE="$2"; shift 2
            ;;
        --spec)
            [[ $# -lt 2 ]] && die "--spec requires RECIPE_FILE argument" 5
            MODE="spec"
            RECIPE_FILE="$2"; shift 2
            ;;
        --tasks)
            [[ $# -lt 2 ]] && die "--tasks requires RECIPE_FILE argument" 5
            MODE="tasks"
            RECIPE_FILE="$2"; shift 2
            ;;
        --render)
            MODE="render"
            shift
            ;;
        --recipe)
            [[ $# -lt 2 ]] && die "--recipe requires a FILE argument" 5
            RECIPE_FILE="$2"; shift 2
            ;;
        --slots-json)
            [[ $# -lt 2 ]] && die "--slots-json requires a FILE argument" 5
            SLOTS_JSON_FILE="$2"; shift 2
            ;;
        --work-dir)
            [[ $# -lt 2 ]] && die "--work-dir requires a DIR argument" 5
            WORK_DIR="$2"; shift 2
            ;;
        *)
            die "unknown argument: '$1'" 4
            ;;
    esac
done

[[ -z "$MODE" ]] && die "no mode specified; use --list, --validate, --render, --spec, --tasks, or --help" 5

# Validate render mode has required arguments
if [[ "$MODE" == "render" ]]; then
    [[ -z "$RECIPE_FILE" ]] && die "--render requires --recipe FILE" 5
    [[ -z "$SLOTS_JSON_FILE" ]] && die "--render requires --slots-json FILE" 5
    [[ -z "$WORK_DIR" ]] && die "--render requires --work-dir DIR" 5
fi

# ---------------------------------------------------------------------------
# File existence check (all modes need RECIPE_FILE)
# ---------------------------------------------------------------------------
check_recipe_file() {
    [[ -f "$RECIPE_FILE" ]] || die "recipe file not found: $RECIPE_FILE" 1
    [[ -r "$RECIPE_FILE" ]] || die "recipe file not readable: $RECIPE_FILE" 1
}

# ---------------------------------------------------------------------------
# YAML front-matter parsing
# Extract lines between the first --- and second --- delimiters.
# Outputs: NAME, APPLIES_TO, SLOT_COUNT, TASK_COUNT (global vars)
# ---------------------------------------------------------------------------
NAME=""
APPLIES_TO=""
SLOT_COUNT=""
TASK_COUNT=""

parse_frontmatter() {
    local file="$1"
    local fm
    # Extract content between first and second --- delimiters
    fm=$(awk '/^---$/{c++; if(c==1){next} if(c==2){exit}} c==1{print}' "$file")

    NAME=$(echo "$fm" | grep -E '^name:' | head -1 | sed 's/^name:[[:space:]]*//' | tr -d '\r')
    APPLIES_TO=$(echo "$fm" | grep -E '^applies-to:' | head -1 | sed 's/^applies-to:[[:space:]]*//' | tr -d '\r')
    SLOT_COUNT=$(echo "$fm" | grep -E '^slot-count:' | head -1 | sed 's/^slot-count:[[:space:]]*//' | tr -d '\r')
    TASK_COUNT=$(echo "$fm" | grep -E '^task-count:' | head -1 | sed 's/^task-count:[[:space:]]*//' | tr -d '\r')

    [[ -z "$NAME" ]] && die "malformed front-matter: missing required field 'name' in $file" 2
    [[ -z "$APPLIES_TO" ]] && die "malformed front-matter: missing required field 'applies-to' in $file" 2
    [[ -z "$SLOT_COUNT" ]] && die "malformed front-matter: missing required field 'slot-count' in $file" 2
    [[ -z "$TASK_COUNT" ]] && die "malformed front-matter: missing required field 'task-count' in $file" 2

    # Validate numeric fields
    if ! echo "$SLOT_COUNT" | grep -qE '^[0-9]+$'; then
        die "malformed front-matter: 'slot-count' must be an integer, got: '$SLOT_COUNT'" 2
    fi
    if ! echo "$TASK_COUNT" | grep -qE '^[0-9]+$'; then
        die "malformed front-matter: 'task-count' must be an integer, got: '$TASK_COUNT'" 2
    fi
}

# ---------------------------------------------------------------------------
# Body extraction helpers
# Body = everything after the closing --- of the front-matter
# ---------------------------------------------------------------------------
get_body() {
    local file="$1"
    # Skip lines up to and including the second ---
    awk '/^---$/{c++; if(c==2){found=1; next}} found{print}' "$file"
}

# Extract the ## spec block (from ## spec to ## tasks or EOF)
get_spec_block() {
    local file="$1"
    get_body "$file" | awk '
        /^## spec$/{in_spec=1; next}
        in_spec && /^## tasks$/{exit}
        in_spec{print}
    '
}

# Extract the ## tasks block (from ## tasks to EOF)
get_tasks_block() {
    local file="$1"
    get_body "$file" | awk '
        /^## tasks$/{in_tasks=1; next}
        in_tasks{print}
    '
}

# ---------------------------------------------------------------------------
# Slot extraction
# Extract unique {{slot-name}} tokens from body text (order of first appearance)
# Slot name rule: [a-z][a-z0-9-]*
# ---------------------------------------------------------------------------
extract_slots_ordered() {
    local text="$1"
    # Extract all slot tokens, strip delimiters, preserve order, deduplicate
    echo "$text" | grep -oE '\{\{[a-z][a-z0-9-]*\}\}' | sed 's/[{}]//g' | awk '!seen[$0]++'
}

extract_slots_unique_count() {
    local text="$1"
    echo "$text" | grep -oE '\{\{[a-z][a-z0-9-]*\}\}' | sort -u | wc -l | tr -d ' '
}

# ---------------------------------------------------------------------------
# Count ### task-NNN headings in the ## tasks block
# ---------------------------------------------------------------------------
count_task_headings() {
    local tasks_block="$1"
    { echo "$tasks_block" | grep -cE '^### task-[0-9]'; true; }
}

# ---------------------------------------------------------------------------
# Lock helpers (sentinel-file pattern, matching writeback-task-status.sh)
# ---------------------------------------------------------------------------
LOCK_FILE=""
LOCK_ACQUIRED=0

acquire_lock() {
    local lock_parent
    lock_parent="$(dirname "$LOCK_FILE")"
    [[ -d "$lock_parent" ]] || die "lock directory does not exist: $lock_parent" 6

    local attempts=0
    while true; do
        if ( set -o noclobber; echo $$ > "$LOCK_FILE" ) 2>/dev/null; then
            LOCK_ACQUIRED=1
            return 0
        fi
        attempts=$((attempts + 1))
        if [[ "$attempts" -ge "$LOCK_TIMEOUT" ]]; then
            die "lock contention: $LOCK_FILE held after ${attempts} retries. Another process is writing." 8
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
# Python binary resolution
# Requires python3 or python. On Windows (pyenv-win), the shim may pass
# multi-line -c scripts through batch wrappers that mangle newlines;
# to avoid this, Python code is always written to a temp .py file and
# invoked as "python script.py arg1 arg2 ..." rather than "python -c '...'".
# ---------------------------------------------------------------------------
python_bin() {
    # Prefer the real binary over pyenv-win shims that break multiline -c
    if command -v python3 >/dev/null 2>&1; then
        echo "python3"
    elif command -v python >/dev/null 2>&1; then
        echo "python"
    else
        die "python3 or python is required for --render (JSON parsing); neither found in PATH" 4
    fi
}

# run_python SCRIPT_CONTENT ARG...
# Write SCRIPT_CONTENT to a temp .py file and execute it with remaining args.
# Cleans up the temp file regardless of exit status.
run_python() {
    local py
    py=$(python_bin)
    local script_content="$1"; shift
    local py_file
    py_file=$(mktemp --suffix=.py 2>/dev/null || mktemp)
    printf '%s\n' "$script_content" > "$py_file"
    local exit_code=0
    "$py" "$py_file" "$@" || exit_code=$?
    rm -f "$py_file"
    return $exit_code
}

# ---------------------------------------------------------------------------
# Slot substitution using python (handles multi-line values safely)
# Writes template_text to a temp file, passes file path to Python.
# Slot values come from the JSON file.
# After slot substitution, applies {!{ -> {{ escape rewrite.
# ---------------------------------------------------------------------------
render_template() {
    local json_file="$1"
    local template_text="$2"

    # Write template to a temp file to avoid shell arg quoting issues with
    # multi-line content containing special characters.
    local tmpl_file
    tmpl_file=$(mktemp)
    printf '%s' "$template_text" > "$tmpl_file"

    local render_exit=0
    run_python \
'import json, sys, re

with open(sys.argv[1]) as f:
    data = json.load(f)

with open(sys.argv[2]) as f:
    text = f.read()

slot_pattern = re.compile(r"\{\{([a-z][a-z0-9-]*)\}\}")

def replace_slot(m):
    name = m.group(1)
    if name in data:
        return str(data[name])
    return m.group(0)

text = slot_pattern.sub(replace_slot, text)
text = text.replace("{!{", "{{")
sys.stdout.write(text)
' "$json_file" "$tmpl_file" || render_exit=$?
    rm -f "$tmpl_file"
    return $render_exit
}

# ---------------------------------------------------------------------------
# Mode: --list RECIPE_FILE
# Emit unique slot names in order of first appearance, one per line.
# ---------------------------------------------------------------------------
mode_list() {
    check_recipe_file
    local body
    body=$(get_body "$RECIPE_FILE")
    extract_slots_ordered "$body"
}

# ---------------------------------------------------------------------------
# Mode: --validate RECIPE_FILE
# Check slot-count and task-count front-matter vs actual body counts.
# Exits 0 even on mismatch (warns); exits non-zero only on structural error.
# ---------------------------------------------------------------------------
mode_validate() {
    check_recipe_file
    parse_frontmatter "$RECIPE_FILE"

    local body tasks_block
    body=$(get_body "$RECIPE_FILE")
    tasks_block=$(get_tasks_block "$RECIPE_FILE")

    # Check ## spec block exists
    if ! get_body "$RECIPE_FILE" | grep -q '^## spec$'; then
        die "missing required block: '## spec' not found in body of $RECIPE_FILE" 3
    fi

    # Check ## tasks block exists
    if ! get_body "$RECIPE_FILE" | grep -q '^## tasks$'; then
        die "missing required block: '## tasks' not found in body of $RECIPE_FILE" 3
    fi

    # Count actual unique slots
    local actual_slots
    actual_slots=$(extract_slots_unique_count "$body")

    # Count actual task headings
    local actual_tasks
    actual_tasks=$(count_task_headings "$tasks_block")

    local ok=1

    if [[ "$actual_slots" -eq "$SLOT_COUNT" ]]; then
        echo "OK: slot-count matches — declared=$SLOT_COUNT actual=$actual_slots"
    else
        warn "slot-count mismatch — declared=$SLOT_COUNT actual=$actual_slots (instantiation continues)"
        ok=0
    fi

    if [[ "$actual_tasks" -eq "$TASK_COUNT" ]]; then
        echo "OK: task-count matches — declared=$TASK_COUNT actual=$actual_tasks"
    else
        warn "task-count mismatch — declared=$TASK_COUNT actual=$actual_tasks (instantiation continues)"
        ok=0
    fi

    # Also validate front-matter name matches filename (best-effort, non-fatal)
    local basename_noext
    basename_noext=$(basename "$RECIPE_FILE" .md)
    if [[ "$NAME" != "$basename_noext" ]]; then
        warn "name field '$NAME' does not match file basename '$basename_noext' (convention: they must match)"
    fi

    if [[ "$ok" -eq 1 ]]; then
        echo "OK: all checks passed for $RECIPE_FILE"
    fi
}

# ---------------------------------------------------------------------------
# Mode: --spec RECIPE_FILE
# Emit raw (unrendered) ## spec block to stdout.
# ---------------------------------------------------------------------------
mode_spec() {
    check_recipe_file
    # Validate blocks exist
    if ! get_body "$RECIPE_FILE" | grep -q '^## spec$'; then
        die "missing required block: '## spec' not found in body of $RECIPE_FILE" 3
    fi
    get_spec_block "$RECIPE_FILE"
}

# ---------------------------------------------------------------------------
# Mode: --tasks RECIPE_FILE
# Emit raw (unrendered) ## tasks block to stdout.
# ---------------------------------------------------------------------------
mode_tasks() {
    check_recipe_file
    if ! get_body "$RECIPE_FILE" | grep -q '^## tasks$'; then
        die "missing required block: '## tasks' not found in body of $RECIPE_FILE" 3
    fi
    get_tasks_block "$RECIPE_FILE"
}

# ---------------------------------------------------------------------------
# Mode: --render --recipe FILE --slots-json FILE --work-dir DIR
# Substitute slots + apply escape rewrite + emit SPEC.md + task files.
# ---------------------------------------------------------------------------
mode_render() {
    check_recipe_file
    [[ -f "$SLOTS_JSON_FILE" ]] || die "slots JSON file not found: $SLOTS_JSON_FILE" 1

    parse_frontmatter "$RECIPE_FILE"

    # Validate required body blocks
    if ! get_body "$RECIPE_FILE" | grep -q '^## spec$'; then
        die "missing required block: '## spec' not found in body of $RECIPE_FILE" 3
    fi
    if ! get_body "$RECIPE_FILE" | grep -q '^## tasks$'; then
        die "missing required block: '## tasks' not found in body of $RECIPE_FILE" 3
    fi

    # Create work-dir and tasks subdir if needed
    local tasks_dir="${WORK_DIR}/tasks"
    mkdir -p "$tasks_dir" || die "failed to create work directory: $tasks_dir" 6

    # Set up lock file in work-dir
    LOCK_FILE="${WORK_DIR}/.parse-recipe.lock"
    acquire_lock

    # Extract blocks
    local spec_block tasks_block
    spec_block=$(get_spec_block "$RECIPE_FILE")
    tasks_block=$(get_tasks_block "$RECIPE_FILE")

    # Validate slot count with warning (non-fatal per spec)
    local body
    body=$(get_body "$RECIPE_FILE")
    local actual_slots actual_tasks
    actual_slots=$(extract_slots_unique_count "$body")
    actual_tasks=$(count_task_headings "$tasks_block")

    if [[ "$actual_slots" -ne "$SLOT_COUNT" ]]; then
        warn "slot-count mismatch — declared=$SLOT_COUNT actual=$actual_slots (continuing render)"
    fi
    if [[ "$actual_tasks" -ne "$TASK_COUNT" ]]; then
        warn "task-count mismatch — declared=$TASK_COUNT actual=$actual_tasks (continuing render)"
    fi

    # Render SPEC.md
    local rendered_spec
    rendered_spec=$(render_template "$SLOTS_JSON_FILE" "$spec_block")
    local spec_file="${WORK_DIR}/SPEC.md"
    printf '%s\n' "$rendered_spec" > "$spec_file" || die "failed to write $spec_file" 7
    echo "OK: wrote $spec_file"

    # Parse and render each ### task-NNN heading block
    # Split tasks_block into per-task sections
    local task_num="" task_body="" in_task=0 rendered_task task_file
    local task_title=""

    while IFS= read -r line; do
        if echo "$line" | grep -qE '^### task-[0-9]'; then
            # If we were accumulating a previous task, render and write it
            if [[ -n "$task_num" ]]; then
                rendered_task=$(render_template "$SLOTS_JSON_FILE" "$task_body")
                task_file="${tasks_dir}/task-${task_num}.md"
                printf '%s\n' "$rendered_task" > "$task_file" || die "failed to write $task_file" 7
                echo "OK: wrote $task_file"
            fi
            # Start new task
            # Extract task number from heading: ### task-001 — Title or ### task-001 - Title
            task_num=$(echo "$line" | grep -oE 'task-[0-9]+' | head -1 | sed 's/task-//')
            task_title=$(echo "$line" | sed 's/^### task-[0-9]* *[-—]* *//')
            # Build header for the task file (rendered title comes from substitution below)
            task_body="### task-${task_num} — ${task_title}"$'\n'
            in_task=1
        elif [[ "$in_task" -eq 1 ]]; then
            task_body="${task_body}${line}"$'\n'
        fi
    done <<< "$tasks_block"

    # Write the last (or only) task
    if [[ -n "$task_num" ]]; then
        rendered_task=$(render_template "$SLOTS_JSON_FILE" "$task_body")
        task_file="${tasks_dir}/task-${task_num}.md"
        printf '%s\n' "$rendered_task" > "$task_file" || die "failed to write $task_file" 7
        echo "OK: wrote $task_file"
    fi

    echo "OK: render complete — recipe='${NAME}' work-dir='${WORK_DIR}'"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
case "$MODE" in
    list)     mode_list ;;
    validate) mode_validate ;;
    spec)     mode_spec ;;
    tasks)    mode_tasks ;;
    render)   mode_render ;;
    *) die "internal error: unknown mode '$MODE'" 4 ;;
esac
