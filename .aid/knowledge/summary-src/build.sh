#!/usr/bin/env bash
# build.sh — assemble knowledge-summary.html from per-section sources.
#
# Input layout (this dir):
#   00-head.html              — doctype + head + CSS + body open + header
#   01-at-a-glance.html       — §1
#   02-pipeline.html          — §2 (featured ★)
#   03-kb-center.html         — §3 (featured ★)
#   04-agent-model.html       — §4 (featured ★)
#   05-phase-deep-dive.html   — §5
#   06-artifact-dataflow.html — §6
#   07-cross-tool.html        — §7
#   08-tech-debt.html         — §8
#   09-adopting.html          — §9 (customized)
#   10-kb-index.html          — §10
#   11-mermaid-init.html      — small init script (Mermaid version comment)
#   99-tail.html              — lightbox script + closing body/html
#
# Plus external:
#   ../.cache/mermaid-block.html — full <script>...</script> with inlined Mermaid lib
#
# Output:
#   ../knowledge-summary.html — single self-contained HTML
set -eu

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
KB_DIR="$(cd "$SRC_DIR/.." && pwd)"
MERMAID_BLOCK="$KB_DIR/.cache/mermaid-block.html"
OUTPUT="$KB_DIR/knowledge-summary.html"

# Sanity
for f in "$SRC_DIR"/0[0-9]-*.html "$SRC_DIR"/10-*.html "$SRC_DIR"/11-*.html "$SRC_DIR"/99-*.html "$MERMAID_BLOCK"; do
    [ -f "$f" ] || { echo "❌ Missing: $f" >&2; exit 1; }
    [ -s "$f" ] || { echo "❌ Empty: $f" >&2; exit 1; }
done

# Concatenate in deterministic order: 00 → 01..10 (numeric) → 11 → mermaid-block → 99
{
    cat "$SRC_DIR/00-head.html"
    for n in 01 02 03 04 05 06 07 08 09 10; do
        cat "$SRC_DIR/$n-"*.html
    done
    cat "$SRC_DIR/11-mermaid-init.html"
    cat "$MERMAID_BLOCK"
    cat "$SRC_DIR/99-tail.html"
} > "$OUTPUT"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT" | tr -d ' ')
echo "✅ Built $OUTPUT ($SIZE bytes, $LINES lines)"
