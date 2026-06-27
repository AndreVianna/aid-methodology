#!/usr/bin/env bash
# assemble-3part.sh -- assemble final kb.html from PART1 + PART2 (no Mermaid engine).
#
# CHANGE 7 (FR-51): The Mermaid engine embed was REMOVED in D-012. This script
#   previously concatenated PART1 + MERMAID + PART2. The Mermaid argument is now
#   retired; the script concatenates PART1 + PART2 only. Inline SVG visuals are
#   pre-rendered at build time -- no runtime diagram engine needed.
#
# DETERMINISM (Change 6 / FR-50):
#   When --manifest FILE is supplied the script records the manifest path in its
#   output so callers can verify PART1 was assembled with the same manifest.
#   PART1 itself must be built with assemble.sh --manifest for full determinism;
#   this script performs the final byte-level concatenation regardless.
#   Same PART1 + PART2 -> same output (reproducible + auditable, FR-50).
#
# Usage (positional):
#   assemble-3part.sh PART1 PART2 OUTPUT
#
# Usage (named flags -- preferred for new runs):
#   assemble-3part.sh --part1 X --part2 Z --output W [--manifest FILE]
#
# Options:
#   --part1 FILE      Pre-assembled head+sections+foot HTML (PART1)
#   --part2 FILE      Post-script HTML (PART2)
#   --output FILE     Output path for the assembled kb.html
#   --manifest FILE   Section manifest used when building PART1 (informational;
#                     recorded in output line for auditability)

set -eu

PART1=""
PART2=""
OUTPUT=""
MANIFEST_FILE=""

# Support both positional (3-arg: PART1 PART2 OUTPUT) and named-flag interfaces
if [[ $# -ge 3 && "${1:0:2}" != "--" ]]; then
    # Positional interface: PART1 PART2 OUTPUT
    PART1="$1"
    PART2="$2"
    OUTPUT="$3"
    shift 3
    # consume any trailing flags (e.g. --manifest)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --manifest) MANIFEST_FILE="$2"; shift 2 ;;
            *) echo "Unknown argument: $1" >&2; exit 2 ;;
        esac
    done
else
    # Named-flag interface
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --part1)    PART1="$2";          shift 2 ;;
            --part2)    PART2="$2";          shift 2 ;;
            --output)   OUTPUT="$2";         shift 2 ;;
            --manifest) MANIFEST_FILE="$2";  shift 2 ;;
            *) echo "Unknown argument: $1" >&2; exit 2 ;;
        esac
    done
fi

if [[ -z "$PART1" || -z "$PART2" || -z "$OUTPUT" ]]; then
    echo "Usage: assemble-3part.sh PART1 PART2 OUTPUT" >&2
    echo "   or: assemble-3part.sh --part1 X --part2 Z --output W [--manifest FILE]" >&2
    exit 1
fi

for f in "$PART1" "$PART2"; do
    [ -f "$f" ] || { echo "Missing input: $f" >&2; exit 1; }
    [ -s "$f" ] || { echo "Empty input: $f" >&2; exit 1; }
done

OUT_DIR=$(dirname "$OUTPUT")
if [ -n "$OUT_DIR" ] && [ "$OUT_DIR" != "." ]; then
    mkdir -p "$OUT_DIR"
fi

cat "$PART1" "$PART2" > "$OUTPUT"

SIZE=$(wc -c < "$OUTPUT" | tr -d ' ')
LINES=$(wc -l < "$OUTPUT" | tr -d ' ')

if [ -n "$MANIFEST_FILE" ]; then
    echo "Wrote $OUTPUT ($SIZE bytes, $LINES lines; manifest: $MANIFEST_FILE)"
else
    echo "Wrote $OUTPUT ($SIZE bytes, $LINES lines)"
fi
