#!/usr/bin/env bash
# build-md-export.sh -- build the Markdown export payload from .aid/knowledge/*.md
#
# Purpose:
#   Reads KB source documents from --kb-dir in manifest-driven order, strips YAML
#   frontmatter, converts any relative SVG image references to inline data: URIs,
#   and produces a single portable Markdown document wrapped in a
#   <script type="text/markdown" id="kb-md-export"> block. The output is written to
#   --output (default: .aid/knowledge/summary-src/md-export-payload.html) for
#   embedding in kb.html by assemble.sh.
#
# Usage:
#   build-md-export.sh [options]
#
# Options:
#   --kb-dir DIR        KB source directory  (default: .aid/knowledge)
#   --manifest FILE     Section manifest     (default: .aid/knowledge/summary-src/section-manifest.txt)
#   --output PATH       Output HTML snippet  (default: .aid/knowledge/summary-src/md-export-payload.html)
#   -h / --help         Print this help
#
# Exit codes:
#   0  Success
#   1  Runtime error (missing KB dir, no docs found, missing python3)
#   2  Usage error (unknown flag)
#
# Payload element contract (consumed by task-002 / client-side export buttons):
#   Element:       <script type="text/markdown" id="kb-md-export">
#   Content:       Combined KB source docs, frontmatter stripped, SVG images embedded
#                  as data:image/svg+xml;base64,... URIs; </script> inside content
#                  escaped as <\/script> to prevent premature tag close.
#   Access:        document.getElementById('kb-md-export').textContent
#   Filename hint: 'knowledge-base-export.md'
#   Location:      Injected between skeleton-foot.html and post-script.html by assemble.sh.

set -euo pipefail

KB_DIR=".aid/knowledge"
MANIFEST_FILE=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --kb-dir)    KB_DIR="$2";        shift 2 ;;
        --manifest)  MANIFEST_FILE="$2"; shift 2 ;;
        --output)    OUTPUT="$2";        shift 2 ;;
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0" | head -30
            exit 0
            ;;
        *)
            echo "build-md-export.sh: unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

# Apply defaults
if [[ -z "$MANIFEST_FILE" ]]; then
    MANIFEST_FILE=".aid/knowledge/summary-src/section-manifest.txt"
fi
if [[ -z "$OUTPUT" ]]; then
    OUTPUT=".aid/knowledge/summary-src/md-export-payload.html"
fi

[[ -d "$KB_DIR" ]] || {
    echo "build-md-export.sh: KB dir not found: $KB_DIR" >&2
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "build-md-export.sh: python3 not found (required for SVG image conversion)" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Resolve ordered list of KB docs from the section manifest.
#
# Mapping rule: strip leading NN- prefix and .html extension to get the base
# name, then look for {base}.md in KB_DIR. Special cases:
#   at-a-glance -> skip (synthesized section; no KB source doc)
#   kb-index    -> INDEX.md
#   readme      -> README.md
# ---------------------------------------------------------------------------
DOCS=()

if [[ -f "$MANIFEST_FILE" ]]; then
    while IFS= read -r line; do
        # skip blank lines and # comments
        [[ -z "$line" || "$line" == \#* ]] && continue

        # strip leading NN- prefix (one or more digits + hyphen at start)
        base="${line#[0-9]*-}"
        # strip .html extension
        base="${base%.html}"

        # skip synthesized sections that have no source MD
        [[ "$base" == "at-a-glance" ]] && continue

        # resolve special-case filenames
        case "$base" in
            kb-index) candidate="$KB_DIR/INDEX.md" ;;
            readme)   candidate="$KB_DIR/README.md" ;;
            *)        candidate="$KB_DIR/${base}.md" ;;
        esac

        if [[ -f "$candidate" ]]; then
            DOCS+=("$candidate")
        else
            echo "build-md-export.sh: warning: KB doc not found for section '${line}' (tried: ${candidate})" >&2
        fi
    done < "$MANIFEST_FILE"
else
    echo "build-md-export.sh: manifest not found at ${MANIFEST_FILE}; falling back to glob" >&2
    for f in "$KB_DIR"/*.md; do
        [[ -f "$f" ]] && DOCS+=("$f")
    done
fi

[[ ${#DOCS[@]} -gt 0 ]] || {
    echo "build-md-export.sh: no KB docs found in ${KB_DIR}" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# strip_frontmatter: remove YAML frontmatter (--- delimited block at the
# start of the file) from stdin and print the remaining content.
# ---------------------------------------------------------------------------
strip_frontmatter() {
    awk '
        NR==1 && /^---[[:space:]]*$/ { in_fm=1; next }
        in_fm && /^---[[:space:]]*$/  { in_fm=0; next }
        !in_fm                        { print }
    '
}

# ---------------------------------------------------------------------------
# Write the SVG image converter to a temp file so Python reads KB docs from
# stdin (not from a heredoc which would conflict with the pipe).
#
# Converts Markdown image links pointing to .svg files:
#   ![alt](path.svg) -> ![alt](data:image/svg+xml;base64,...)
# Only relative paths are converted; absolute URLs and existing data: URIs
# are left unchanged. Each converted image carries its alt text so viewers
# that ignore data URIs degrade to the alt text.
# ---------------------------------------------------------------------------
SVG_PY=$(mktemp)
TMPFILE=$(mktemp)
trap 'rm -f "$SVG_PY" "$TMPFILE"' EXIT

cat > "$SVG_PY" <<'PYEOF'
import sys
import re
import base64
import os

kb_dir = sys.argv[1]

def replace_svg(m):
    alt  = m.group(1)
    path = m.group(2)
    # Leave absolute URLs and existing data: URIs unchanged
    if path.startswith(('http://', 'https://', 'data:', '/')):
        return m.group(0)
    full = os.path.join(kb_dir, path)
    try:
        with open(full, 'rb') as fh:
            b64 = base64.b64encode(fh.read()).decode('ascii')
        return '![' + alt + '](data:image/svg+xml;base64,' + b64 + ')'
    except OSError:
        return m.group(0)  # file not found; keep original reference

_SVG_IMG = re.compile(r'!\[([^\]]*)\]\(([^)]+\.svg)\)')

for line in sys.stdin:
    sys.stdout.write(_SVG_IMG.sub(replace_svg, line))
PYEOF

# ---------------------------------------------------------------------------
# Build the combined Markdown document:
#   1. Title header and preamble
#   2. One section per KB doc (frontmatter stripped)
#   3. Pipe through SVG converter (data: URI inline images)
#   4. Escape </script> sequences to prevent premature HTML tag close
#      (<\/script> is safe: the HTML parser sees <\ as literal < not a tag open)
# ---------------------------------------------------------------------------
{
    printf '# AID Knowledge Base -- Export\n\n'
    printf '> Generated from `.aid/knowledge/` source documents.\n'
    printf '> Single portable Markdown file -- images embedded as data: URIs.\n\n'

    for doc in "${DOCS[@]}"; do
        printf '\n---\n\n'
        strip_frontmatter < "$doc"
        printf '\n'
    done
} | python3 "$SVG_PY" "$KB_DIR" \
  | sed 's|</script>|<\\/script>|g' \
  > "$TMPFILE"

# ---------------------------------------------------------------------------
# Wrap in the hidden payload element and write output
# ---------------------------------------------------------------------------
OUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUT_DIR"

{
    printf '<script type="text/markdown" id="kb-md-export">\n'
    cat "$TMPFILE"
    printf '</script>\n'
} > "$OUTPUT"

PAYLOAD_BYTES=$(wc -c < "$OUTPUT" | tr -d ' ')
echo "Built MD export payload: ${OUTPUT} (${PAYLOAD_BYTES} bytes, ${#DOCS[@]} docs)"
