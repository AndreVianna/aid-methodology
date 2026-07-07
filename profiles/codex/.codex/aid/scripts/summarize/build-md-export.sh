#!/usr/bin/env bash
# build-md-export.sh -- build the Markdown export payload from .aid/knowledge/*.md
#
# Purpose:
#   Reads KB source documents from --kb-dir in manifest-driven order, strips YAML
#   frontmatter, converts any relative SVG image references to inline data: URIs,
#   and produces a single portable Markdown document wrapped in a
#   <script type="text/markdown" id="kb-md-export"> block. The output is written to
#   --output (default: .aid/.temp/summarize/summary-src/md-export-payload.html) for
#   embedding in kb.html by assemble.sh.
#
# Usage:
#   build-md-export.sh [options]
#
# Options:
#   --kb-dir DIR        KB source directory  (default: .aid/knowledge)
#   --manifest FILE     Section manifest     (default: .aid/.temp/summarize/summary-src/section-manifest.txt)
#   --output PATH       Output HTML snippet  (default: .aid/.temp/summarize/summary-src/md-export-payload.html)
#   -h / --help         Print this help
#
# Exit codes:
#   0  Success
#   1  Runtime error (missing KB dir, no docs found, missing python3)
#   2  Usage error (unknown flag)
#
# Payload element contract (consumed by client-side export buttons):
#   Element:       <script type="text/markdown" id="kb-md-export" data-encoding="base64">
#   Content:       Combined KB source docs, frontmatter stripped, local images embedded as
#                  data: URIs (SVG -> data:image/svg+xml;base64,...;
#                  PNG/JPG/GIF/WEBP -> data:image/<type>;base64,...).
#                  The entire payload is base64-encoded (UTF-8 bytes -> base64 ASCII).
#                  No escaping is needed; the base64 alphabet ([A-Za-z0-9+/=]) contains
#                  no HTML-significant characters, so the round-trip is lossless.
#   Access:        const b64 = document.getElementById('kb-md-export').textContent;
#   Decode:        new TextDecoder().decode(Uint8Array.from(atob(b64), c => c.charCodeAt(0)))
#                  -- or equivalently: decodeURIComponent(escape(atob(b64)))
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
    MANIFEST_FILE=".aid/.temp/summarize/summary-src/section-manifest.txt"
fi
if [[ -z "$OUTPUT" ]]; then
    OUTPUT=".aid/.temp/summarize/summary-src/md-export-payload.html"
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
# emit_stripped_docs: for each KB doc passed as an argument, emit a section
# separator ('\n---\n\n'), the doc's content with YAML frontmatter removed
# (the leading '---'-delimited block), and a trailing newline. Frontmatter is
# stripped only when '---' is the doc's first line.
#
# All docs are processed in a SINGLE awk pass (getline per file inside a BEGIN
# block) rather than spawning one awk per doc. Emitting the separators from awk
# keeps empty docs (which yield no records) behaving exactly like non-empty
# ones -- separator before, trailing newline after -- so the byte stream is
# identical to a per-doc printf + awk loop.
# ---------------------------------------------------------------------------
emit_stripped_docs() {
    awk '
        BEGIN {
            for (i = 1; i < ARGC; i++) {
                f = ARGV[i]
                printf "\n---\n\n"
                in_fm = 0
                first = 1
                while ((getline line < f) > 0) {
                    if (first && line ~ /^---[[:space:]]*$/) { in_fm = 1; first = 0; continue }
                    first = 0
                    if (in_fm && line ~ /^---[[:space:]]*$/) { in_fm = 0; continue }
                    if (!in_fm) print line
                }
                close(f)
                printf "\n"
            }
        }
    ' "$@"
}

# ---------------------------------------------------------------------------
# Write the image converter and base64 encoder to a temp Python file.
#
# Converts Markdown image links pointing to local image files:
#   ![alt](path.svg)  -> ![alt](data:image/svg+xml;base64,...)
#   ![alt](path.png)  -> ![alt](data:image/png;base64,...)
#   ![alt](path.jpg)  -> ![alt](data:image/jpeg;base64,...)
#   ![alt](path.gif)  -> ![alt](data:image/gif;base64,...)
#   ![alt](path.webp) -> ![alt](data:image/webp;base64,...)
# Only relative paths are converted; absolute URLs (http/https) and existing
# data: URIs are left unchanged. Each converted image carries its alt text so
# viewers that ignore data URIs degrade gracefully to the alt text.
#
# After image conversion the entire Markdown text is base64-encoded (UTF-8
# bytes -> base64 ASCII) and written to stdout. The base64 alphabet
# ([A-Za-z0-9+/=]) has no HTML-significant characters, eliminating the need
# for </script> escaping and making the payload round-trip losslessly.
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

MIME_MAP = {
    '.svg':  'image/svg+xml',
    '.png':  'image/png',
    '.jpg':  'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif':  'image/gif',
    '.webp': 'image/webp',
}

def replace_img(m):
    alt  = m.group(1)
    path = m.group(2)
    # Leave absolute URLs and existing data: URIs unchanged
    if path.startswith(('http://', 'https://', 'data:', '/')):
        return m.group(0)
    full = os.path.join(kb_dir, path)
    ext = os.path.splitext(path)[1].lower()
    mime = MIME_MAP.get(ext, 'application/octet-stream')
    try:
        with open(full, 'rb') as fh:
            b64 = base64.b64encode(fh.read()).decode('ascii')
        return '![' + alt + '](data:' + mime + ';base64,' + b64 + ')'
    except OSError:
        return m.group(0)  # file not found; keep original reference

_IMG_RE = re.compile(
    r'!\[([^\]]*)\]\(([^)]+\.(?:svg|png|jpe?g|gif|webp))\)',
    re.IGNORECASE
)

# Read all stdin at once, convert image refs, then base64-encode the UTF-8 result.
# Reading all at once (rather than line-by-line) is required so the base64 output
# is one contiguous string with no mid-content newlines that atob() would reject.
text = sys.stdin.buffer.read().decode('utf-8')
converted = _IMG_RE.sub(replace_img, text)
payload = base64.b64encode(converted.encode('utf-8')).decode('ascii')
sys.stdout.write(payload)
PYEOF

# ---------------------------------------------------------------------------
# Build the combined Markdown document:
#   1. Title header and preamble
#   2. One section per KB doc (frontmatter stripped)
#   3. Pipe through image converter (inline SVG + raster) and base64 encoder.
#      TMPFILE receives the base64-encoded payload (pure ASCII, no HTML escaping
#      needed -- base64 alphabet has no <, >, or " characters).
# ---------------------------------------------------------------------------
{
    printf '# AID Knowledge Base -- Export\n\n'
    printf '> Generated from `.aid/knowledge/` source documents.\n'
    printf '> Single portable Markdown file -- images embedded as data: URIs.\n\n'

    emit_stripped_docs "${DOCS[@]}"
} | python3 "$SVG_PY" "$KB_DIR" \
  > "$TMPFILE"

# ---------------------------------------------------------------------------
# Wrap in the hidden payload element and write output.
# The base64 content is placed immediately after the opening tag (no leading
# whitespace or newline inside the element body) so textContent returns the
# base64 string exactly -- no stray newline for atob() to reject.
# ---------------------------------------------------------------------------
OUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUT_DIR"

{
    printf '<script type="text/markdown" id="kb-md-export" data-encoding="base64">'
    cat "$TMPFILE"
    printf '</script>\n'
} > "$OUTPUT"

PAYLOAD_BYTES=$(wc -c < "$OUTPUT" | tr -d ' ')
echo "Built MD export payload: ${OUTPUT} (${PAYLOAD_BYTES} bytes, ${#DOCS[@]} docs)"
