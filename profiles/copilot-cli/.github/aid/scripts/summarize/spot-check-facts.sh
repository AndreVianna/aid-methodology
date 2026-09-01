#!/usr/bin/env bash
# spot-check-facts.sh — extract numeric/named claims from the HTML and cross-check
# them against source Knowledge Base documents.
#
# Usage:
#   spot-check-facts.sh <html-file> [--kb-dir DIR] [--out FILE] [--limit N]
#
# Flags:
#   --kb-dir DIR   Directory containing KB .md files (default: .aid/knowledge).
#   --out FILE     Output report path (default: .aid/.temp/summarize/spot-check-facts.txt).
#   --limit N      Max number of claims to extract (default: 10).
#   -h, --help     Print this header and exit.
#
# Exit codes:
#   0  Report written (even if some claims are MISS).
#   1  Could not read HTML or KB dir.
#   2  Invocation error.
#
# Output format (written to --out and printed to stdout):
#   [OK]   HTML-claim | KB-evidence (file:line)
#   [MISS] HTML-claim | not found in KB
#
# This script does NOT affect grading. It is intended to help the user answer
# K2 (fact accuracy) in manual-checklist.sh.

set -euo pipefail

# --- Argument parsing ---
HTML=""
KB_DIR=".aid/knowledge"
OUT_FILE=".aid/.temp/summarize/spot-check-facts.txt"
LIMIT=10

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0" | head -30
            exit 0
            ;;
        --kb-dir)
            KB_DIR="${2:-}"
            shift 2
            ;;
        --out)
            OUT_FILE="${2:-}"
            shift 2
            ;;
        --limit)
            LIMIT="${2:-10}"
            shift 2
            ;;
        -*)
            echo "❌ Unknown flag: $1" >&2
            exit 2
            ;;
        *)
            HTML="$1"
            shift
            ;;
    esac
done

if [ -z "$HTML" ] || [ ! -f "$HTML" ]; then
    echo "❌ Usage: spot-check-facts.sh <html-file> [--kb-dir DIR] [--out FILE]" >&2
    exit 2
fi

if [ ! -d "$KB_DIR" ]; then
    echo "❌ KB directory not found: $KB_DIR" >&2
    exit 1
fi

echo "Extracting numeric/named claims from: $HTML"
echo "Cross-checking against KB at: $KB_DIR"
echo ""

# --- Extract claims from HTML ---
# Patterns:
#  1. "<N> terms|skills|agents|items|files|lines|phases|docs|sections|diagrams|commands|checks|points|checks"
#  2. Named version pins: "v<N>.<N>" or "<Name> <N>.<N>"
#  3. Named entity counts: "<N>-<word>" compound nouns in headings

CLAIMS_TMP=$(mktemp)
trap 'rm -f "$CLAIMS_TMP"' EXIT

# Strip HTML tags from the file first using sed for a text version
HTML_TEXT=$(sed 's/<[^>]*>//g' "$HTML" 2>/dev/null | sed '/^[[:space:]]*$/d')

# Pattern 1: number + unit noun (case-insensitive)
UNIT_NOUNS="terms|skills|agents|items|files|lines|phases|docs|sections|diagrams|commands|checks|points|tests|modules|packages|endpoints|entities|services|scripts|jobs|features|layers|tiers"
echo "$HTML_TEXT" \
    | grep -oiE "[0-9]+ ($UNIT_NOUNS)" 2>/dev/null \
    | sort -t' ' -k1 -rn \
    | awk '!seen[$0]++' \
    >> "$CLAIMS_TMP" || true

# Pattern 2: version strings  v<N>.<N> or v<N>.<N>.<N>
echo "$HTML_TEXT" \
    | grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' 2>/dev/null \
    | sort -u \
    >> "$CLAIMS_TMP" || true

# Pattern 3: named counts in compact form like "22 agents" already captured above
# Extra: "N/N" fraction-style counts (e.g. "8/8 diagrams")
echo "$HTML_TEXT" \
    | grep -oE '[0-9]+/[0-9]+ [a-z]+' 2>/dev/null \
    | sort -u \
    >> "$CLAIMS_TMP" || true

# Deduplicate and limit
CLAIMS=$(sort -u "$CLAIMS_TMP" | head -"$LIMIT")

if [ -z "$CLAIMS" ]; then
    echo "No numeric/named claims found in the HTML."
    echo "Nothing to check — verify manually."
    exit 0
fi

CLAIM_COUNT=$(echo "$CLAIMS" | wc -l | tr -d ' ')
echo "Found $CLAIM_COUNT claim(s) to check (limit $LIMIT)."
echo ""

# --- Cross-check each claim against KB ---
OUT_DIR=$(dirname "$OUT_FILE")
mkdir -p "$OUT_DIR"

{
    echo "# Fact Spot-Check Report"
    echo "# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)"
    echo "# HTML: $HTML"
    echo "# KB:   $KB_DIR"
    echo "#"
    echo "# Format: [OK|MISS] HTML-claim | KB-evidence"
    echo ""
} > "$OUT_FILE"

OK_COUNT=0
MISS_COUNT=0

while IFS= read -r claim; do
    [ -z "$claim" ] && continue

    # Build a grep-friendly pattern from the claim
    # Escape regex metacharacters
    PATTERN=$(printf '%s' "$claim" | sed 's/[.+*?^${}()|[\]\\]/\\&/g')

    # Search across all KB .md files, excluding state/meta files
    MATCH=""
    MATCH=$(grep -rniE "$PATTERN" "$KB_DIR"/*.md \
        --include="*.md" \
        --exclude="STATE.md" \
        --exclude="README.md" \
        --exclude="INDEX.md" \
        2>/dev/null | head -1 || true)

    if [ -n "$MATCH" ]; then
        # Shorten the match line to fit in report
        EVIDENCE=$(echo "$MATCH" | cut -c1-120)
        printf '[OK]   %-35s | %s\n' "$claim" "$EVIDENCE" | tee -a "$OUT_FILE"
        OK_COUNT=$((OK_COUNT + 1))
    else
        printf '[MISS] %-35s | not found in KB\n' "$claim" | tee -a "$OUT_FILE"
        MISS_COUNT=$((MISS_COUNT + 1))
    fi
done <<< "$CLAIMS"

echo "" | tee -a "$OUT_FILE"
{
    echo "# Summary: $OK_COUNT OK, $MISS_COUNT MISS (of $CLAIM_COUNT claims checked)"
    echo "# MISS claims may indicate invented numbers — verify manually before scoring K2."
} | tee -a "$OUT_FILE"

echo ""
echo "Report written to: $OUT_FILE"
echo "Use this output to answer Q3 (K2) in manual-checklist.sh."
exit 0
