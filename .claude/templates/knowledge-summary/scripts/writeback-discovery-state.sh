#!/usr/bin/env bash
# writeback-discovery-state.sh — append a new ## Summarization History entry to
# DISCOVERY-STATE.md. Atomic via a sentinel lock file.
#
# Usage: writeback-discovery-state.sh GRADE PROFILE MERMAID_VERSION OUTPUT_FILENAME OUTPUT_SIZE NOTES
# Exit 0 on success, non-zero on failure.

set -u

GRADE="${1:-?}"
PROFILE="${2:-?}"
MERMAID="${3:-?}"
OUTPUT="${4:-knowledge-summary.html}"
SIZE="${5:-?}"
NOTES="${6:-Initial generation}"

KB_DIR=".aid/knowledge"
STATE="$KB_DIR/DISCOVERY-STATE.md"
LOCK="$KB_DIR/.discovery-state.lock"

if [ ! -f "$STATE" ]; then
    echo "❌ $STATE does not exist." >&2
    exit 1
fi

# Acquire lock (5s timeout)
ATTEMPTS=0
while [ -e "$LOCK" ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    if [ "$ATTEMPTS" -ge 10 ]; then
        echo "⚠️  $STATE is locked by another AID process. Try again shortly." >&2
        exit 2
    fi
    sleep 0.5
done
# Atomic create — fails if another process beat us
if ! ( set -o noclobber; echo $$ > "$LOCK" ) 2>/dev/null; then
    echo "⚠️  Failed to acquire lock on $STATE." >&2
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

NEW_ROW="| $NEXT_NUM | $DATE | $GRADE | $PROFILE | $MERMAID | $OUTPUT ($SIZE) | $NOTES |"

# Update file using a Python-free approach. Two cases:
# 1. ## Summarization History exists → append row to its table
# 2. Doesn't exist → insert new section after ## Review History

TMP=$(mktemp)
if grep -q '^## Summarization History' "$STATE"; then
    # Append new row at the end of the existing Summarization History table.
    # The table ends at the next blank line OR next ## section.
    awk -v new_row="$NEW_ROW" '
        BEGIN { in_section=0; printed=0 }
        /^## Summarization History/ { in_section=1; print; next }
        in_section && /^## / {
            # Reached next section — print new_row before it (if not printed).
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
            print "| # | Date | Grade | Profile | Mermaid | Output | Notes |"
            print "|---|------|-------|---------|---------|--------|-------|"
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
    echo "❌ Writeback produced empty output. Aborting (state preserved)." >&2
    rm -f "$TMP"
    exit 3
fi

# Sanity check: new row must appear in output
if ! grep -qF "$NEW_ROW" "$TMP"; then
    echo "❌ New row was not written to output. Aborting." >&2
    rm -f "$TMP"
    exit 3
fi

mv "$TMP" "$STATE"
echo "✓ DISCOVERY-STATE.md updated:"
echo "    ## Summarization History → entry #$NEXT_NUM added ($DATE, grade $GRADE)"
exit 0
