#!/usr/bin/env bash
# graph-preflight.sh - verify /aid-graph's prerequisites before any state runs.
#
# Purpose:
#   The synchronous gate of the /aid-graph state machine. It answers one question --
#   may this run start at all -- and it writes nothing whatever the answer, so a
#   refusal leaves the project byte-identical to how it was found.
#
#   Seven checks, P1-P7. Each failure names the action that clears it, because a
#   refusal that does not say what to do leaves the user guessing why nothing
#   happened.
#
# Usage:
#   graph-preflight.sh [--install-root PATH]
#   graph-preflight.sh -h | --help
#
# Flags:
#   --install-root PATH  The installed AID tree that carries aid/scripts/graph/ and
#                        aid/templates/graph/ (P6). Default: resolved from this
#                        script's own location, which holds for the canonical tree
#                        and for every rendered profile alike.
#
# Checks:
#   P1  .aid/knowledge/STATE.md exists.
#   P2  The Knowledge Base is approved. The frontmatter scalar `kb_status` is read
#       first and `Approved` passes; only when that key is absent does a legacy
#       `> **User Approved:** yes` line count, and then only above the first `##`
#       heading -- the region that carries the Knowledge Base's own approval. An
#       unscoped match would also see the summary skill's approval line further
#       down the same file and pass an unapproved Knowledge Base.
#   P3  At least one populated Knowledge Base document.
#   P4  Not in Plan Mode -- the run writes files.
#   P5  Node.js >= 20.
#   P6  The installed graph area is present.
#   P7  Inside a git working tree -- the enumeration's exclusion classes need
#       `git check-ignore` and `git check-attr`, so a non-git checkout cannot
#       produce a reproducible node set.
#
#   A missing .aid/knowledge/external-sources.md is NOT a refusal: it is a notice
#   on stderr and the run continues with zero nodes of the affected kinds.
#
# Output:
#   stdout: the pass line. stderr: the refusal, or the external-sources notice.
#
# Exit codes:
#   0 - every check passed
#   1 - a prerequisite failed (the message names the action)
#   2 - a usage error

# A read-only analyser, so `-e` is dropped on this project's stated convention for
# that class: every check below is an explicit `if` that ends in err() or falls
# through, and the two greps that legitimately return non-zero are handled where
# they are called.
set -uo pipefail
export LC_ALL=C

SELF="graph-preflight.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# <install-root>/aid/scripts/graph -> <install-root>.
INSTALL_ROOT=$(cd -- "${SCRIPT_DIR}/../../.." && pwd)

KB_DIR=".aid/knowledge"
STATE="${KB_DIR}/STATE.md"
EXTERNAL_SOURCES="${KB_DIR}/external-sources.md"

while [ $# -gt 0 ]; do
    case "$1" in
        --install-root) INSTALL_ROOT="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0"
            exit 0
            ;;
        *)
            echo "${SELF}: unknown flag: $1" >&2
            exit 2
            ;;
    esac
done

# The refusal shape: a cause line, then an actionable line. Nothing is written.
err() {
    echo "❌ Cannot run /aid-graph." >&2
    echo "   $1" >&2
    if [ -n "${2:-}" ]; then
        echo "" >&2
        echo "   → $2" >&2
    fi
    exit 1
}

# --- P1 -------------------------------------------------------------------
if [ ! -f "$STATE" ]; then
    err "${STATE} does not exist." \
        "Run /aid-config, then /aid-discover, to set up the Knowledge Base."
fi

# --- P2 -------------------------------------------------------------------
# Frontmatter first. One awk pass over the leading YAML block; no fork per field.
KB_STATUS=$(awk '
    NR==1 && $0 !~ /^---[ \t]*$/ { exit }
    NR==1 { in_fm=1; next }
    in_fm && /^---[ \t]*$/ { exit }
    in_fm && /^kb_status:/ {
        sub(/^kb_status:[ \t]*/, "")
        sub(/[ \t]+#.*$/, "")
        gsub(/^["\047]|["\047]$/, "")
        sub(/[ \t]+$/, "")
        print
        exit
    }
' "$STATE")

if [ -n "$KB_STATUS" ]; then
    if [ "$KB_STATUS" != "Approved" ]; then
        err "The Knowledge Base is not approved. Current kb_status: ${KB_STATUS}" \
            "Run /aid-discover through to APPROVAL and approve the Knowledge Base, then re-run /aid-graph."
    fi
else
    # Legacy fallback, scoped to the region above the first `##` heading.
    LEGACY=$(awk '
        /^##/ { exit }
        /^(> *)?\*\*User Approved:\*\*/ { print; exit }
    ' "$STATE")
    if ! printf '%s\n' "$LEGACY" | grep -qE '^(> *)?\*\*User Approved:\*\* yes'; then
        LEGACY_VALUE=$(printf '%s\n' "$LEGACY" | sed -E 's/^(> *)?\*\*User Approved:\*\* *//')
        err "The Knowledge Base is not approved. Current **User Approved:** ${LEGACY_VALUE:-not set}" \
            "Run /aid-discover through to APPROVAL and approve the Knowledge Base, then re-run /aid-graph."
    fi
fi

# --- P3 -------------------------------------------------------------------
POPULATED=0
for f in "$KB_DIR"/*.md; do
    [ -f "$f" ] || continue
    case "${f##*/}" in
        STATE.md|README.md|INDEX.md) continue ;;
    esac
    LINES=$(grep -cve '^[[:space:]]*$' "$f" 2>/dev/null || echo 0)
    if [ "$LINES" -gt 30 ] && ! grep -q '^❌ Pending' "$f" 2>/dev/null; then
        POPULATED=1
        break
    fi
done
if [ "$POPULATED" -eq 0 ]; then
    err "The Knowledge Base is empty, or every document is still pending." \
        "Run /aid-discover to populate the Knowledge Base first."
fi

# --- P4 -------------------------------------------------------------------
if [ "${CLAUDE_PLAN_MODE:-}" = "1" ]; then
    err "Plan Mode is active, and /aid-graph writes files." \
        "Exit Plan Mode and re-run."
fi

# --- P5 -------------------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
    err "Node.js is required by the graph's own detector and by the reused validators." \
        "Install Node.js (>= 20) and re-run."
fi
NODE_MAJOR=$(node -e 'console.log(process.versions.node.split(".")[0])' 2>/dev/null || true)
if [ -n "$NODE_MAJOR" ] && [ "$NODE_MAJOR" -lt 20 ] 2>/dev/null; then
    err "Node.js >= 20 is required (found $(node -v))." \
        "Upgrade Node.js and re-run."
fi

# --- P6 -------------------------------------------------------------------
for area in "aid/scripts/graph" "aid/templates/graph"; do
    if [ ! -d "${INSTALL_ROOT}/${area}" ]; then
        err "The installed graph area is incomplete: ${INSTALL_ROOT}/${area} is missing." \
            "Reinstall or upgrade AID, then re-run."
    fi
done

# --- P7 -------------------------------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    err "Not inside a git working tree." \
        "Run /aid-graph from a git checkout: the enumeration's exclusion classes need git check-ignore and git check-attr."
fi

# --- The one non-refusal ---------------------------------------------------
if [ ! -f "$EXTERNAL_SOURCES" ]; then
    echo "${SELF}: notice: ${EXTERNAL_SOURCES} is absent; the run continues and the coverage notes report the absence." >&2
fi

echo "✅ Preflight checks passed (P1-P7)."
exit 0
