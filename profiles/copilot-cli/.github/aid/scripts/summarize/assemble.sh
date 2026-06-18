#!/usr/bin/env bash
# assemble.sh — assemble kb.html (the KB summary) from multi-source authoring layout
#
# Reads `.aid/knowledge/summary-src/` and concatenates:
#   skeleton-head.html
#   sections/01-*.html ... 12-*.html  (lexical order ensures stable section order)
#   skeleton-foot.html
#   <Mermaid library>                 (default: cached at .aid/knowledge/.cache/mermaid.min.js)
#   post-mermaid.html
#
# Output: .aid/dashboard/kb.html (or as specified by --output)
#
# Usage:
#   bash assemble.sh                                                     # default paths
#   bash assemble.sh --src .aid/knowledge/summary-src --output OUT.html  # custom paths
#   bash assemble.sh --no-mermaid                                        # skip Mermaid library (CDN-mode output)

set -euo pipefail

SRC_DIR=".aid/knowledge/summary-src"
OUTPUT=".aid/dashboard/kb.html"
MERMAID_LIB=".aid/knowledge/.cache/mermaid.min.js"
NO_MERMAID=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --src)         SRC_DIR="$2";     shift 2 ;;
        --output)      OUTPUT="$2";      shift 2 ;;
        --mermaid)     MERMAID_LIB="$2"; shift 2 ;;
        --no-mermaid)  NO_MERMAID=1;     shift ;;
        -h|--help)
            sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
    esac
done

for f in \
    "$SRC_DIR/skeleton-head.html" \
    "$SRC_DIR/skeleton-foot.html" \
    "$SRC_DIR/post-mermaid.html"; do
    [[ -f "$f" ]] || { echo "Missing source: $f" >&2; exit 1; }
    [[ -s "$f" ]] || { echo "Empty source: $f" >&2; exit 1; }
done

SECTIONS=( "$SRC_DIR"/sections/*.html )
if [[ ${#SECTIONS[@]} -eq 0 ]] || [[ ! -f "${SECTIONS[0]}" ]]; then
    echo "No section files found in $SRC_DIR/sections/" >&2
    exit 1
fi

if [[ "$NO_MERMAID" -eq 0 ]]; then
    [[ -f "$MERMAID_LIB" ]] || { echo "Mermaid library not found: $MERMAID_LIB" >&2; echo "   Run: bash .github/aid/scripts/summarize/fetch-mermaid.sh" >&2; exit 1; }
    [[ -s "$MERMAID_LIB" ]] || { echo "Empty Mermaid library: $MERMAID_LIB" >&2; exit 1; }
fi

OUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUT_DIR"

{
    cat "$SRC_DIR/skeleton-head.html"
    for s in "${SECTIONS[@]}"; do
        cat "$s"
    done
    cat "$SRC_DIR/skeleton-foot.html"
    if [[ "$NO_MERMAID" -eq 0 ]]; then
        cat "$MERMAID_LIB"
    fi
    cat "$SRC_DIR/post-mermaid.html"
} > "$OUTPUT"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT" | tr -d ' ')
SECTION_COUNT=${#SECTIONS[@]}

if [[ "$NO_MERMAID" -eq 1 ]]; then
    MODE="--no-mermaid (CDN-mode output; needs <script src=...> tag for the library)"
else
    MODE="inline Mermaid from $MERMAID_LIB"
fi

echo "Assembled $OUTPUT"
echo "  Sections: $SECTION_COUNT"
echo "  Mode: $MODE"
echo "  Size: $SIZE bytes, $LINES lines"
