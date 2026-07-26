#!/usr/bin/env bash
# writeback-state.sh -- append a new ## Summarization History entry to
# the consolidated Discovery area state file (.aid/knowledge/STATE.md, per FR2).
# Atomic via a sentinel lock file. Pre-FR2 this wrote to DISCOVERY-STATE.md.
#
# Usage:
#   writeback-state.sh GRADE DOMAIN DOCSET OUTPUT_FILENAME OUTPUT_SIZE NOTES
#       Appends a row to ## Summarization History (unchanged since FR2).
#
#   writeback-state.sh --set KEY VALUE [--set KEY VALUE ...]
#       Surgical frontmatter write (work-003-state-schema task-004): creates or
#       updates one or more of the 5 KB run-state scalars relocated by task-001
#       into the leading YAML block of .aid/knowledge/STATE.md, leaving the
#       markdown BODY byte-unchanged. Repeatable; all pairs are applied under a
#       single lock acquisition (one atomic write). Allowed keys:
#         kb_status        Initial | In Progress | Approved
#         kb_grade         matches ^[A-F][+-]?$ or "Pending"
#         last_kb_review   free date text (YYYY-MM-DD or --)
#         summary_approved yes | no
#         last_summary     free date text (YYYY-MM-DD or --)
#       Any other key is rejected (this script is narrowly scoped to these 5).
#       Emits no user-facing output.
#
#   writeback-state.sh -h | --help
#
#   GRADE   must match [A-F][+-]?  (e.g. A, A-, B+, C, F)
#   DOMAIN  domain value from .aid/knowledge/STATE.md ## Discovery Domain
#   DOCSET  resolved doc-set count, e.g. "12 of 15 docs"
#
# Exit codes:
#   0 success
#   1 STATE.md missing
#   2 lock contention
#   3 writeback produced empty / unverifiable output
#   4 invalid GRADE argument (or invalid --set KEY/VALUE)
#   5 missing required argument

set -u

usage() {
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    "")
        echo "ERROR: writeback-state.sh: GRADE argument required." >&2
        usage >&2
        exit 5
        ;;
esac

# ---------------------------------------------------------------------------
# Mode: --set KEY VALUE [--set KEY VALUE ...]  (task-004 frontmatter-writer path)
# ---------------------------------------------------------------------------
if [[ "$1" == "--set" ]]; then
    KB_DIR=".aid/knowledge"
    STATE="$KB_DIR/STATE.md"
    LOCK="$KB_DIR/.state.lock"

    if [ ! -f "$STATE" ]; then
        echo "ERROR: $STATE does not exist." >&2
        exit 1
    fi

    # wb_set_frontmatter SOURCE_FILE KEY VALUE
    # Identical surgical-rewrite algorithm to execute/writeback-state.sh's own
    # helper of the same name (duplicated, not sourced -- each canonical script
    # directory is self-contained; see that file's own doc comment for the
    # full behavior description). Only flat top-level keys are needed here (all
    # 5 discovery run-state scalars are flat), so the nested-key branch is
    # unreachable in practice but kept for algorithmic parity with the twin.
    wb_set_frontmatter() {
        local source_file="$1" key="$2" value="$3"
        local out_value="$value"
        if ! [[ "$value" =~ ^[A-Za-z0-9_./+-]+$ ]]; then
            out_value="\"${value//\"/\\\"}\""
        fi
        awk -v flat_key="$key" -v out_value="$out_value" '
            BEGIN { in_fm = 0; done = 0 }
            NR == 1 && $0 ~ /^---[ \t]*$/ { in_fm = 1; print; next }
            NR == 1 {
                print "---"
                print flat_key ": " out_value
                print "---"
                print ""
                print
                next
            }
            in_fm && /^---[ \t]*$/ {
                if (!done) { print flat_key ": " out_value; done = 1 }
                in_fm = 0
                print
                next
            }
            in_fm {
                if ($0 ~ ("^" flat_key ":")) {
                    print flat_key ": " out_value
                    done = 1
                    next
                }
                print
                next
            }
            { print }
        ' "$source_file"
    }

    # Acquire lock (5s timeout) -- same sentinel discipline as the GRADE path below.
    ATTEMPTS=0
    while [ -e "$LOCK" ]; do
        ATTEMPTS=$((ATTEMPTS + 1))
        if [ "$ATTEMPTS" -ge 10 ]; then
            echo "WARN: $STATE is locked by another AID process. Try again shortly." >&2
            exit 2
        fi
        sleep 0.5
    done
    if ! ( set -o noclobber; echo $$ > "$LOCK" ) 2>/dev/null; then
        echo "WARN: Failed to acquire lock on $STATE." >&2
        exit 2
    fi
    trap 'rm -f "$LOCK"' EXIT

    CURRENT="$STATE"
    shift   # drop the leading --set

    if [[ $# -eq 0 ]]; then
        echo "ERROR: writeback-state.sh: --set requires at least one KEY VALUE pair." >&2
        exit 5
    fi

    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "--set" ]]; then
            shift
            continue
        fi
        KEY="${1:-}"
        VALUE="${2:-}"
        if [[ -z "$KEY" || $# -lt 2 ]]; then
            echo "ERROR: writeback-state.sh: --set requires a KEY and a VALUE." >&2
            exit 5
        fi
        case "$KEY" in
            kb_status)
                case "$VALUE" in
                    Initial|"In Progress"|Approved) ;;
                    *) echo "ERROR: writeback-state.sh: invalid kb_status '$VALUE' -- must be one of: Initial | In Progress | Approved." >&2; exit 4 ;;
                esac
                ;;
            kb_grade)
                if ! [[ "$VALUE" =~ ^[A-F][+-]?$ ]] && [[ "$VALUE" != "Pending" ]]; then
                    echo "ERROR: writeback-state.sh: invalid kb_grade '$VALUE' -- must match ^[A-F][+-]?\$ or be 'Pending'." >&2
                    exit 4
                fi
                ;;
            summary_approved)
                case "$VALUE" in
                    yes|no) ;;
                    *) echo "ERROR: writeback-state.sh: invalid summary_approved '$VALUE' -- must be one of: yes | no." >&2; exit 4 ;;
                esac
                ;;
            last_kb_review|last_summary) ;;   # free date text (YYYY-MM-DD or --)
            *)
                echo "ERROR: writeback-state.sh: unknown --set key '$KEY' -- allowed: kb_status kb_grade last_kb_review summary_approved last_summary." >&2
                exit 4
                ;;
        esac
        if [[ "$VALUE" == *$'\n'* ]]; then
            echo "ERROR: writeback-state.sh: --set value cannot contain newline characters." >&2
            exit 4
        fi

        TMP=$(mktemp)
        wb_set_frontmatter "$CURRENT" "$KEY" "$VALUE" > "$TMP"
        if [ ! -s "$TMP" ] || ! grep -q "^${KEY}:" "$TMP"; then
            rm -f "$TMP"
            echo "ERROR: writeback-state.sh: frontmatter key '$KEY' not found in output; $STATE preserved." >&2
            exit 3
        fi
        if [[ "$CURRENT" != "$STATE" ]]; then
            rm -f "$CURRENT"
        fi
        CURRENT="$TMP"
        shift 2
    done

    mv "$CURRENT" "$STATE"
    exit 0
fi

GRADE="$1"
DOMAIN="${2:-?}"
DOCSET="${3:-?}"
OUTPUT="${4:-.aid/knowledge/kb.html}"
SIZE="${5:-?}"
NOTES="${6:-Initial generation}"

# Validate GRADE - letter A-F with optional + or - modifier.
# Rejects garbage like --help, JSON fragments, etc.
if ! [[ "$GRADE" =~ ^[A-F][+-]?$ ]]; then
    echo "ERROR: writeback-state.sh: invalid GRADE '$GRADE' - must match ^[A-F][+-]?\$ (e.g. A, A-, B+, F)." >&2
    exit 4
fi

KB_DIR=".aid/knowledge"
STATE="$KB_DIR/STATE.md"
LOCK="$KB_DIR/.state.lock"

if [ ! -f "$STATE" ]; then
    echo "ERROR: $STATE does not exist." >&2
    exit 1
fi

# Acquire lock (5s timeout)
ATTEMPTS=0
while [ -e "$LOCK" ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ "$ATTEMPTS" -ge 10 ]; then
        echo "WARN: $STATE is locked by another AID process. Try again shortly." >&2
        exit 2
    fi
    sleep 0.5
done
# Atomic create - fails if another process beat us
if ! ( set -o noclobber; echo $$ > "$LOCK" ) 2>/dev/null; then
    echo "WARN: Failed to acquire lock on $STATE." >&2
    exit 2
fi

# Always release lock on exit
trap 'rm -f "$LOCK"' EXIT

DATE=$(date +%Y-%m-%d)

# Determine next entry number from existing ## Summarization History
NEXT_NUM=1
if grep -q '^## Summarization History' "$STATE"; then
    LAST_NUM=$(awk '
        /^## Summarization History/ {in_section=1; next}
        in_section && /^## / {in_section=0}
        in_section && /^\| *[0-9]+ *\|/ {
            split($0, parts, "|")
            n=parts[2]; gsub(/^[ \t]+|[ \t]+$/, "", n)
            if (n ~ /^[0-9]+$/) last=n
        }
        END { print (last ? last : 0) }
    ' "$STATE")
    NEXT_NUM=$((LAST_NUM + 1))
fi

NEW_ROW="| $NEXT_NUM | $DATE | $GRADE | $DOMAIN | $DOCSET | $OUTPUT ($SIZE) | $NOTES |"

# Update file using a Python-free approach. Two cases:
# 1. ## Summarization History exists -> append row to its table
# 2. Doesn't exist -> insert new section after ## Review History

TMP=$(mktemp)
if grep -q '^## Summarization History' "$STATE"; then
    # Append new row at the end of the existing Summarization History table.
    # The table ends at the next blank line OR next ## section.
    awk -v new_row="$NEW_ROW" '
        BEGIN { in_section=0; printed=0 }
        /^## Summarization History/ { in_section=1; print; next }
        in_section && /^## / {
            # Reached next section - print new_row before it (if not printed).
            if (!printed) { print new_row; print ""; printed=1 }
            in_section=0
            print
            next
        }
        { print }
        END {
            if (in_section && !printed) { print new_row }
        }
    ' "$STATE" > "$TMP"
else
    # Insert new section after ## Review History
    awk -v new_row="$NEW_ROW" '
        BEGIN { in_review=0; inserted=0 }
        /^## Review History/ { in_review=1; print; next }
        in_review && /^## / && !inserted {
            # Print the new section before this next section
            print "## Summarization History"
            print ""
            print "| # | Date | Grade | Domain | Doc-set | Output | Notes |"
            print "|---|------|-------|--------|---------|--------|-------|"
            print new_row
            print ""
            inserted=1
            in_review=0
            print
            next
        }
        { print }
        END {
            # If Review History was the last section, append new section at EOF
            if (in_review && !inserted) {
                print ""
                print "## Summarization History"
                print ""
                print "| # | Date | Grade | Profile | Mermaid | Output | Notes |"
                print "|---|------|-------|---------|---------|--------|-------|"
                print new_row
                print ""
            }
        }
    ' "$STATE" > "$TMP"
fi

if [ ! -s "$TMP" ]; then
    echo "ERROR: Writeback produced empty output. Aborting (state preserved)." >&2
    rm -f "$TMP"
    exit 3
fi

# Sanity check: new row must appear in output
if ! grep -qF "$NEW_ROW" "$TMP"; then
    echo "ERROR: New row was not written to output. Aborting." >&2
    rm -f "$TMP"
    exit 3
fi

mv "$TMP" "$STATE"
echo "OK: $STATE updated:"
echo "    ## Summarization History -> entry #$NEXT_NUM added ($DATE, grade $GRADE)"
exit 0
