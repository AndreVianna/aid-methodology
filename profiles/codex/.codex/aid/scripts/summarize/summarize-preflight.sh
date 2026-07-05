#!/usr/bin/env bash
# summarize-preflight.sh -- verifies /aid-summarize prerequisites.
# Usage: summarize-preflight.sh
# Exits 0 on success, non-zero on any failure with a clear message.
#
# CHANGE 7 (FR-51 / D-012): The Mermaid engine is fully removed. The network
# reachability check (check 5) and Mermaid-block detection are no longer needed;
# visuals are authored as inline SVG / HTML+CSS at build time.

set -u

KB_DIR=".aid/knowledge"

err() {
    echo "❌ Cannot run /aid-summarize." >&2
    echo "   $1" >&2
    if [ -n "${2:-}" ]; then
        echo "" >&2
        echo "   → $2" >&2
    fi
    exit 1
}

# Check 1: STATE.md exists (consolidated Discovery area state -- FR2)
if [ ! -f "$KB_DIR/STATE.md" ]; then
    err "$KB_DIR/STATE.md does not exist." \
        "Run /aid-config then /aid-discover to set up the Knowledge Base."
fi

# Check 2: User Approved: yes (in top-of-file metadata block)
# Match with OR without a leading `> ` blockquote prefix -- the canonical
# discovery-state-template.md uses `> **User Approved:** ...` in the
# blockquoted metadata block at the top of the file.
if ! grep -qE '^(> *)?\*\*User Approved:\*\* yes' "$KB_DIR/STATE.md"; then
    APPROVAL_VALUE=$(grep -mE '^(> *)?\*\*User Approved:\*\*' "$KB_DIR/STATE.md" 2>/dev/null | head -1 | sed -E 's/^(> *)?\*\*User Approved:\*\* *//')
    APPROVAL_VALUE="${APPROVAL_VALUE:-not set}"
    err "Knowledge Base discovery is not yet approved. Current status: **User Approved:** $APPROVAL_VALUE" \
        "Run /aid-discover until it reaches APPROVAL state and approve the KB. Then re-run /aid-summarize."
fi

# Check 3: at least one populated KB document
POPULATED=0
if [ -d "$KB_DIR" ]; then
    for f in "$KB_DIR"/*.md; do
        [ -f "$f" ] || continue
        # Skip state files; look at content docs (${f##*/} = basename, no fork)
        case "${f##*/}" in
            STATE.md|README.md|INDEX.md) continue ;;
        esac
        # A doc is "populated" if it has more than 30 non-blank lines and doesn't only say "Pending"
        LINES=$(grep -cve '^[[:space:]]*$' "$f" 2>/dev/null || echo 0)
        if [ "$LINES" -gt 30 ] && ! grep -q '^❌ Pending' "$f" 2>/dev/null; then
            POPULATED=1
            break
        fi
    done
fi
if [ "$POPULATED" -eq 0 ]; then
    err "Knowledge Base is empty or all documents are still in 'Pending' state." \
        "Run /aid-discover to populate the Knowledge Base first."
fi

# Check 4: Plan Mode (best-effort -- env-var convention)
if [ "${CLAUDE_PLAN_MODE:-}" = "1" ]; then
    err "Plan Mode is active. /aid-summarize needs write access to generate the HTML." \
        "Press Shift+Tab to exit Plan Mode, then re-run."
fi

# Check 5: Node.js available (required for visual-fidelity validation)
if ! command -v node >/dev/null 2>&1; then
    err "Node.js is required for visual-fidelity validation." \
        "Install Node.js (>= 18) and re-run."
fi

NODE_VERSION_MAJOR=$(node -e 'console.log(process.versions.node.split(".")[0])' 2>/dev/null)
if [ -n "$NODE_VERSION_MAJOR" ] && [ "$NODE_VERSION_MAJOR" -lt 18 ] 2>/dev/null; then
    err "Node.js >= 18 is required (you have $(node -v))." \
        "Upgrade Node.js and re-run."
fi

# --- FR31 legacy-summary migration (best-effort, idempotent) ---
# Relocate a pre-d009 summary so the dashboard's summary_present flips true and
# STALE-CHECK sees the existing approved summary (skips regeneration).
OLD_SUMMARY=".aid/knowledge/knowledge-summary.html"
NEW_SUMMARY=".aid/dashboard/kb.html"
if [ -f "$OLD_SUMMARY" ] && [ ! -f "$NEW_SUMMARY" ]; then
    if mkdir -p .aid/dashboard 2>/dev/null && mv -n "$OLD_SUMMARY" "$NEW_SUMMARY" 2>/dev/null; then
        echo "i  Migrated legacy summary -> $NEW_SUMMARY (FR31 relocation)."
    else
        echo "i  Could not migrate legacy summary (continuing; summary will regenerate)." >&2
    fi
fi

echo "✅ Preflight checks passed."
exit 0
