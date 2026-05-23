#!/usr/bin/env bash
# validate-links.sh — verify anchor and relative-md links in the generated HTML.
# Usage: validate-links.sh <html-file> [--kb-dir DIR]
# Exit 0 if all links resolve; 1 otherwise.

set -u

HTML_FILE="${1:-}"
KB_DIR=".aid/knowledge"

shift || true
while [ $# -gt 0 ]; do
    case "$1" in
        --kb-dir) KB_DIR="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [ -z "$HTML_FILE" ] || [ ! -f "$HTML_FILE" ]; then
    echo "❌ Usage: validate-links.sh <html-file> [--kb-dir DIR]" >&2
    exit 2
fi

FAIL=0
HTML_DIR=$(dirname "$HTML_FILE")

# --- L1: anchor links resolve to in-page IDs ---
echo "Validating in-page anchor links..."
ANCHOR_HREFS=$(grep -oE 'href="#[^"]+"' "$HTML_FILE" | sed 's/href="#//;s/"$//' | sort -u)
ANCHOR_FAIL=0
ANCHOR_TOTAL=0
for anchor in $ANCHOR_HREFS; do
    ANCHOR_TOTAL=$((ANCHOR_TOTAL + 1))
    # Skip empty anchor
    [ -z "$anchor" ] && continue
    if ! grep -qE "id=\"$anchor\"" "$HTML_FILE"; then
        echo "  ❌ #$anchor — no matching id=\"$anchor\"" >&2
        ANCHOR_FAIL=$((ANCHOR_FAIL + 1))
        FAIL=1
    fi
done

if [ "$ANCHOR_FAIL" -eq 0 ]; then
    echo "  ✅ $ANCHOR_TOTAL/$ANCHOR_TOTAL anchor links resolve"
else
    echo "  ❌ $ANCHOR_FAIL anchor link(s) broken (of $ANCHOR_TOTAL)"
fi

# --- L2: relative .md links resolve to existing files ---
echo "Validating relative markdown links..."
MD_HREFS=$(grep -oE 'href="\./[^"]+\.md"' "$HTML_FILE" | sed 's/href="\.\///;s/"$//' | sort -u)
MD_FAIL=0
MD_TOTAL=0
for mdlink in $MD_HREFS; do
    MD_TOTAL=$((MD_TOTAL + 1))
    # Resolve the path relative to the HTML file's directory
    target="$HTML_DIR/$mdlink"
    if [ ! -f "$target" ]; then
        echo "  ❌ ./$mdlink — file does not exist at $target" >&2
        MD_FAIL=$((MD_FAIL + 1))
        FAIL=1
    fi
done

if [ "$MD_FAIL" -eq 0 ]; then
    echo "  ✅ $MD_TOTAL/$MD_TOTAL relative md links resolve"
else
    echo "  ❌ $MD_FAIL md link(s) broken (of $MD_TOTAL)"
fi

if [ "$FAIL" -ne 0 ]; then
    echo "" >&2
    echo "❌ Link validation failed" >&2
    exit 1
fi

echo "✅ All links resolve"
exit 0
