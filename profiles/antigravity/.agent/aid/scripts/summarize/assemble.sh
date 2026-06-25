#!/usr/bin/env bash
# assemble.sh -- assemble kb.html (the KB summary) from multi-source authoring layout.
#
# CHANGE 7 (FR-51): The Mermaid engine embed was REMOVED in D-012. Visuals are
#   pre-rendered as inline SVG / HTML+CSS at build time. The assembled kb.html is
#   single-file self-contained with NO runtime diagram engine and NO external fetch.
#
# Reads .aid/knowledge/summary-src/ and concatenates:
#   skeleton-head.html
#   sections/ files in MANIFEST ORDER (deterministic, same input -> same output)
#   skeleton-foot.html
#   post-script.html
#
# DETERMINISM (Change 6 / FR-50):
#   Section ordering is driven by --manifest FILE, NOT a lexical glob.
#   The manifest is a plain-text file (one section filename per line, relative to
#   sections/, blank lines and # comments ignored) produced by the GENERATE state
#   after applying the section ordering rule:
#     1. At a Glance (always first, synthesized)
#     2. Concept-first trio (glossary, decisions, capabilities)
#     3. Remaining primary-tier docs (discovery.doc_set order)
#     4. Extension-tier docs (discovery.doc_set order)
#     5. Meta-tier docs (last before KB Index)
#     6. KB Index (always last)
#   Same manifest -> same structural output (reproducible + auditable, FR-50).
#
#   Without --manifest the script falls back to lexical glob order (backward-
#   compatible, but NOT deterministic from the doc-set; use --manifest for all
#   new runs).
#
# Usage:
#   bash assemble.sh [options]
#
# Options:
#   --src DIR         Source layout dir    (default: .aid/knowledge/summary-src)
#   --output PATH     Output path          (default: .aid/dashboard/kb.html)
#   --manifest FILE   Section manifest     (one filename per line, relative to
#                                           sections/; blank + # lines ignored)
#   -h / --help       Print this help

set -euo pipefail

SRC_DIR=".aid/knowledge/summary-src"
OUTPUT=".aid/dashboard/kb.html"
MANIFEST_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --src)         SRC_DIR="$2";        shift 2 ;;
        --output)      OUTPUT="$2";         shift 2 ;;
        --manifest)    MANIFEST_FILE="$2";  shift 2 ;;
        -h|--help)
            sed -n '2,38p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
    esac
done

# Validate required shell parts
for f in \
    "$SRC_DIR/skeleton-head.html" \
    "$SRC_DIR/skeleton-foot.html" \
    "$SRC_DIR/post-script.html"; do
    [[ -f "$f" ]] || { echo "Missing source: $f" >&2; exit 1; }
    [[ -s "$f" ]] || { echo "Empty source: $f" >&2; exit 1; }
done

# Resolve section order
# With --manifest: read ordered filenames from manifest (deterministic from doc-set).
# Without --manifest: fall back to lexical glob (backward-compat, not doc-set-driven).
if [[ -n "$MANIFEST_FILE" ]]; then
    [[ -f "$MANIFEST_FILE" ]] || { echo "Manifest file not found: $MANIFEST_FILE" >&2; exit 1; }
    SECTIONS=()
    while IFS= read -r line; do
        # skip blank lines and # comments
        [[ -z "$line" || "$line" == \#* ]] && continue
        sec="$SRC_DIR/sections/$line"
        [[ -f "$sec" ]] || { echo "Section listed in manifest not found: $sec" >&2; exit 1; }
        [[ -s "$sec" ]] || { echo "Section listed in manifest is empty: $sec" >&2; exit 1; }
        SECTIONS+=("$sec")
    done < "$MANIFEST_FILE"
    [[ ${#SECTIONS[@]} -gt 0 ]] || { echo "Manifest is empty (no section files): $MANIFEST_FILE" >&2; exit 1; }
    ORDER_MODE="manifest ($MANIFEST_FILE, ${#SECTIONS[@]} sections)"
else
    SECTIONS=( "$SRC_DIR"/sections/*.html )
    if [[ ${#SECTIONS[@]} -eq 0 ]] || [[ ! -f "${SECTIONS[0]}" ]]; then
        echo "No section files found in $SRC_DIR/sections/" >&2
        exit 1
    fi
    ORDER_MODE="lexical glob (use --manifest for doc-set-deterministic order)"
fi

OUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUT_DIR"

{
    cat "$SRC_DIR/skeleton-head.html"
    for s in "${SECTIONS[@]}"; do
        cat "$s"
    done
    cat "$SRC_DIR/skeleton-foot.html"
    cat "$SRC_DIR/post-script.html"
} > "$OUTPUT"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT" | tr -d ' ')
SECTION_COUNT=${#SECTIONS[@]}

echo "Assembled $OUTPUT"
echo "  Sections:  $SECTION_COUNT (order: $ORDER_MODE)"
echo "  Engine:    none (inline SVG pre-rendered at build time; no Mermaid engine)"
echo "  Size:      $SIZE bytes, $LINES lines"
