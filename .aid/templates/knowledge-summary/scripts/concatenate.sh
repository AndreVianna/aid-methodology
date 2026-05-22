#!/usr/bin/env bash
# concatenate.sh — assemble final knowledge-summary.html from parts.
# Usage: concatenate.sh PART1 MERMAID_LIB PART2 OUTPUT
set -eu

PART1="$1"
MERMAID="$2"
PART2="$3"
OUTPUT="$4"

for f in "$PART1" "$MERMAID" "$PART2"; do
    [ -f "$f" ] || { echo "❌ Missing input: $f" >&2; exit 1; }
    [ -s "$f" ] || { echo "❌ Empty input: $f" >&2; exit 1; }
done

OUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUT_DIR"

cat "$PART1" "$MERMAID" "$PART2" > "$OUTPUT"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "✅ Wrote $OUTPUT ($SIZE bytes, $LINES lines)"
