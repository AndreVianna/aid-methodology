#!/usr/bin/env bash
# render-graph-view.sh -- the graph view's own packaging contract (task-013,
# feature-007-graph-view-shell); this is what state-render.md's routing table
# means by "invoke the view's assembly per the view's own packaging contract".
#
# Three steps, and NO fork of the reused assembler (AC-17, FR-12, C-4):
#   0. If canonical/aid/templates/knowledge-graph/vendor/ exists (feature-012 D6,
#      task-023's own vendoring), its companion bundles are copied beside the
#      output as graph-assets/vendor/ -- FR-9/A-4's "companions travel beside
#      graph.html", and exactly the path kb-write-fence.sh's allowlist already
#      names. Absent (a tree that has not vendored anything yet), this step is a
#      silent no-op and the page renders in its existing degraded
#      (mode: 'unavailable') form -- no dead reference is ever written.
#   1. build-graph-src.mjs fills every skeleton placeholder from relationships.md
#      (the one input, FR-3/AC-10), auto-detects step 0's companions and injects
#      their <script src> tags, and writes the .aid/.temp/graph/graph-src/
#      layout the assembler already validates.
#   2. The REAL canonical/aid/scripts/summarize/assemble.sh is invoked, unmodified,
#      with its three real flags (feature-007 SPEC :1565).
#
# EXIT CODES -- read verbatim by state-render.md's routing table:
#   0  the page was written; CHAIN to VALIDATE
#   1  the render failed; CHAIN to VALIDATE only if a page was written (an
#      assemble.sh failure never writes one -- it validates its required parts
#      before opening the output -- so exit 1 here always means "abort, no page")
#   2  an invocation error (bad flags, or a shipped input this script depends on
#      is missing) -- abort, not a defect to route into a ledger
#
# Usage:
#   bash render-graph-view.sh [--relationships PATH] [--output PATH]
#                              [--src DIR] [--project-name NAME]
#                              [--generation-date DATE]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

SRC_DIR="${REPO_ROOT}/.aid/.temp/graph/graph-src"
OUTPUT="${REPO_ROOT}/.aid/knowledge/graph.html"
RELATIONSHIPS="${REPO_ROOT}/.aid/knowledge/relationships.md"
PROJECT_NAME=""
GENERATION_DATE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --relationships)    RELATIONSHIPS="$2";    shift 2 ;;
        --output)           OUTPUT="$2";           shift 2 ;;
        --src)              SRC_DIR="$2";          shift 2 ;;
        --project-name)     PROJECT_NAME="$2";     shift 2 ;;
        --generation-date)  GENERATION_DATE="$2";  shift 2 ;;
        -h|--help)
            sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Run with --help for usage." >&2
            exit 2
            ;;
    esac
done

if ! command -v node >/dev/null 2>&1; then
    echo "render-graph-view.sh: node is required and is not on PATH" >&2
    exit 2
fi

BUILD_SRC="${SCRIPT_DIR}/build-graph-src.mjs"
ASSEMBLER="${REPO_ROOT}/.cursor/aid/scripts/summarize/assemble.sh"
MANIFEST="${SRC_DIR}/section-manifest.txt"

NODE_ARGS=(--repo-root "$REPO_ROOT" --relationships "$RELATIONSHIPS" --src "$SRC_DIR")
[[ -n "$PROJECT_NAME" ]] && NODE_ARGS+=(--project-name "$PROJECT_NAME")
[[ -n "$GENERATION_DATE" ]] && NODE_ARGS+=(--generation-date "$GENERATION_DATE")

# Step 0: copy the vendored companion bundles, if any exist, beside the output.
# Deliberately BEFORE step 1: build-graph-src.mjs's own graphAssetsPresent check
# and its <script src> auto-detection both read the destination this copies
# into, so the copy has to land first for either to see it.
VENDOR_SRC="${REPO_ROOT}/.cursor/aid/templates/knowledge-graph/vendor"
GRAPH_ASSETS_DIR="$(dirname -- "$OUTPUT")/graph-assets"
if [[ -d "$VENDOR_SRC" ]]; then
    mkdir -p -- "$GRAPH_ASSETS_DIR/vendor"
    cp -R "$VENDOR_SRC/." "$GRAPH_ASSETS_DIR/vendor/"
fi

# Step 1: fill placeholders, write the graph-src layout. Its own exit codes
# (0/1/2) already match this script's contract, so they are propagated verbatim
# rather than re-mapped -- a step that failed wrote no page, which is exactly
# what exit 1 and exit 2 both mean here.
set +e
node "$BUILD_SRC" "${NODE_ARGS[@]}"
build_rc=$?
set -e
if [[ "$build_rc" -ne 0 ]]; then
    exit "$build_rc"
fi

# Step 2: the reused assembler, unmodified, with its three real flags.
mkdir -p -- "$(dirname -- "$OUTPUT")"
exec bash "$ASSEMBLER" --src "$SRC_DIR" --manifest "$MANIFEST" --output "$OUTPUT"
