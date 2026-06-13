#!/usr/bin/env bash
# stale-check.sh — determine if the KB summary (.aid/dashboard/kb.html) is stale relative to KB.
# Usage: stale-check.sh
# Output (stdout, last line):
#   STALE                    — needs regeneration
#   CURRENT_APPROVED         — up-to-date and approved (skip to DONE)
#   CURRENT_UNAPPROVED       — up-to-date but pending approval
#   FIRST_RUN                — never been run
# Exit 0 always (the "decision" is informational, not a failure).
#
# FR2: reads from the consolidated .aid/knowledge/STATE.md.
#   - KB review date  → `## Review History` (Discovery area history)
#   - Summary date    → `## Summarization History`
#   - Approval flag   → `## Knowledge Summary Status` block, **User Approved:** line
# Both old separate files (DISCOVERY-STATE.md, SUMMARY-STATE.md) are retired.

set -u

KB_DIR=".aid/knowledge"
STATE="$KB_DIR/STATE.md"
# The summary now lives at .aid/dashboard/kb.html (feature-007 relocation; served by
# the multi-repo dashboard at /r/<id>/kb.html). KB_DIR still anchors the STATE.md read.
HTML_FILE=".aid/dashboard/kb.html"

if [ ! -f "$HTML_FILE" ]; then
    echo "ℹ️  kb.html does not exist."
    echo "FIRST_RUN"
    exit 0
fi

if [ ! -f "$STATE" ]; then
    echo "❌ $STATE missing — cannot determine staleness." >&2
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
' "$STATE")

# Last summary date: latest entry in ## Summarization History (may not exist)
LAST_SUMMARY_DATE=""
if grep -q '^## Summarization History' "$STATE"; then
    LAST_SUMMARY_DATE=$(awk '
        /^## Summarization History/ {in_section=1; next}
        in_section && /^## / {in_section=0}
        in_section && /^\| *[0-9]+ *\|/ {
            split($0, parts, "|")
            date=parts[3]; gsub(/^[ \t]+|[ \t]+$/, "", date)
            if (date != "" && date != "Date") last=date
        }
        END { print last }
    ' "$STATE")
fi

if [ -z "$LAST_KB_DATE" ]; then
    echo "⚠️  No Review History entries found in $STATE." >&2
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
# Knowledge Summary Status block lives at the top of STATE.md (section heading
# "## Knowledge Summary Status"). It has its own **User Approved:** line.
# We scope the grep to that section so we don't get false positives from the
# KB Documents Status block's **User Approved:** line.
APPROVED=no
SUMMARY_APPROVAL=$(awk '
    /^## Knowledge Summary Status/ {in_section=1; next}
    in_section && /^## / {in_section=0}
    in_section && /^\*\*User Approved:\*\*/ {print; exit}
' "$STATE")
if echo "$SUMMARY_APPROVAL" | grep -q '^\*\*User Approved:\*\* yes'; then
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
