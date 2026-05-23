#!/usr/bin/env bash
# stale-check.sh — determine if knowledge-summary.html is stale relative to KB.
# Usage: stale-check.sh
# Output (stdout, last line):
#   STALE                    — needs regeneration
#   CURRENT_APPROVED         — up-to-date and approved (skip to DONE)
#   CURRENT_UNAPPROVED       — up-to-date but pending approval
#   FIRST_RUN                — never been run
# Exit 0 always (the "decision" is informational, not a failure).

set -u

KB_DIR=".aid/knowledge"
DISCOVERY_STATE="$KB_DIR/DISCOVERY-STATE.md"
SUMMARY_STATE="$KB_DIR/SUMMARY-STATE.md"
HTML_FILE="$KB_DIR/knowledge-summary.html"

if [ ! -f "$HTML_FILE" ]; then
    echo "ℹ️  knowledge-summary.html does not exist."
    echo "FIRST_RUN"
    exit 0
fi

if [ ! -f "$DISCOVERY_STATE" ]; then
    echo "❌ DISCOVERY-STATE.md missing — cannot determine staleness." >&2
    exit 1
fi

# Last review date: latest entry in ## Review History
# Table format: | # | Date | Grade | Source | Notes |
LAST_KB_DATE=$(awk '
    /^## Review History/ {in_section=1; next}
    in_section && /^## / {in_section=0}
    in_section && /^\| *[0-9]+ *\|/ {
        # Extract second column = Date
        split($0, parts, "|")
        date=parts[3]; gsub(/^[ \t]+|[ \t]+$/, "", date)
        if (date != "" && date != "Date") last=date
    }
    END { print last }
' "$DISCOVERY_STATE")

# Last summary date: latest entry in ## Summarization History (may not exist)
LAST_SUMMARY_DATE=""
if grep -q '^## Summarization History' "$DISCOVERY_STATE"; then
    LAST_SUMMARY_DATE=$(awk '
        /^## Summarization History/ {in_section=1; next}
        in_section && /^## / {in_section=0}
        in_section && /^\| *[0-9]+ *\|/ {
            split($0, parts, "|")
            date=parts[3]; gsub(/^[ \t]+|[ \t]+$/, "", date)
            if (date != "" && date != "Date") last=date
        }
        END { print last }
    ' "$DISCOVERY_STATE")
fi

if [ -z "$LAST_KB_DATE" ]; then
    echo "⚠️  No Review History entries found in DISCOVERY-STATE.md." >&2
    echo "STALE"
    exit 0
fi

if [ -z "$LAST_SUMMARY_DATE" ]; then
    echo "ℹ️  No Summarization History yet — first run for this skill."
    echo "FIRST_RUN"
    exit 0
fi

echo "ℹ️  Last KB review:    $LAST_KB_DATE"
echo "ℹ️  Last summary run:  $LAST_SUMMARY_DATE"

# Date comparison: lex compare works for YYYY-MM-DD
if [[ "$LAST_KB_DATE" > "$LAST_SUMMARY_DATE" ]]; then
    echo "ℹ️  KB has changed since last summary."
    echo "STALE"
    exit 0
fi

# HTML up-to-date. Now check approval.
APPROVED=no
if [ -f "$SUMMARY_STATE" ] && grep -q '^\*\*User Approved:\*\* yes' "$SUMMARY_STATE"; then
    APPROVED=yes
fi

if [ "$APPROVED" = "yes" ]; then
    echo "✅ HTML is up-to-date and approved. Nothing to do."
    echo "CURRENT_APPROVED"
else
    echo "ℹ️  HTML is up-to-date but pending your approval."
    echo "CURRENT_UNAPPROVED"
fi
exit 0
