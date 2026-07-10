#!/usr/bin/env bash
# writeback-state.sh -- append a new ## Summarization History entry to
# the consolidated Discovery area state file (.aid/knowledge/STATE.md, per FR2).
# Atomic via a sentinel lock file. Pre-FR2 this wrote to DISCOVERY-STATE.md.
#
# Usage:
#   writeback-state.sh GRADE DOMAIN DOCSET OUTPUT_FILENAME OUTPUT_SIZE NOTES
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
#   4 invalid GRADE argument
#   5 missing required argument

set -u

usage() {
    sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
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

GRADE="$1"
DOMAIN="${2:-?}"
DOCSET="${3:-?}"
OUTPUT="${4:-.aid/dashboard/kb.html}"
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
