#!/usr/bin/env bash
# render-table-view.sh -- the table-only page's own packaging contract
# (task-033, feature-007/feature-009). Sibling of render-graph-view.sh, not an
# edit to it -- that file's SRC_DIR/OUTPUT defaults and its vendor-copy step
# are graph.html's own, and this page vendors nothing (it draws nothing, so it
# needs none of the d3-force/PixiJS companions graph.html's canvas needs).
#
# Two steps, and NO fork of the reused assembler (AC-17, FR-12, C-4 -- the same
# rule render-graph-view.sh follows):
#   1. build-table-src.mjs fills every table-view-skeleton.html placeholder from
#      relationships.md (the one input, FR-3/AC-10) and writes the
#      .aid/.temp/graph/table-src/ layout the assembler already validates.
#   2. The REAL canonical/aid/scripts/summarize/assemble.sh is invoked,
#      unmodified, with its three real flags -- byte-identical invocation
#      shape to render-graph-view.sh's own step 2.
#
# EXIT CODES -- same contract as render-graph-view.sh, so a caller that already
# knows how to route THAT script's exit codes needs no new logic for this one:
#   0  the page was written; CHAIN to VALIDATE
#   1  the render failed; CHAIN to VALIDATE only if a page was written
#   2  an invocation error -- abort, not a defect to route into a ledger
#
# Usage:
#   bash render-table-view.sh [--relationships PATH] [--output PATH]
#                              [--src DIR] [--project-name NAME]
#                              [--generation-date DATE]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

SRC_DIR="${REPO_ROOT}/.aid/.temp/graph/table-src"
OUTPUT="${REPO_ROOT}/.aid/knowledge/table.html"
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
    echo "render-table-view.sh: node is required and is not on PATH" >&2
    exit 2
fi

BUILD_SRC="${SCRIPT_DIR}/build-table-src.mjs"
ASSEMBLER="${REPO_ROOT}/.claude/aid/scripts/summarize/assemble.sh"
MANIFEST="${SRC_DIR}/section-manifest.txt"

NODE_ARGS=(--repo-root "$REPO_ROOT" --relationships "$RELATIONSHIPS" --src "$SRC_DIR")
[[ -n "$PROJECT_NAME" ]] && NODE_ARGS+=(--project-name "$PROJECT_NAME")
[[ -n "$GENERATION_DATE" ]] && NODE_ARGS+=(--generation-date "$GENERATION_DATE")

# Step 1: fill placeholders, write the table-src layout. Exit codes (0/1/2)
# already match this script's own contract, so they are propagated verbatim.
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
