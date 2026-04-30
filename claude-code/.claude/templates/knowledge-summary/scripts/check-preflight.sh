#!/usr/bin/env bash
# check-preflight.sh — verifies /aid-summarize prerequisites.
# Usage: check-preflight.sh [--cdn-mermaid]
# Exits 0 on success, non-zero on any failure with a clear message.

set -u

KB_DIR=".aid/knowledge"
CDN_MODE=0

for arg in "$@"; do
    case "$arg" in
        --cdn-mermaid) CDN_MODE=1 ;;
    esac
done

err() {
    echo "❌ Cannot run /aid-summarize." >&2
    echo "   $1" >&2
    if [ -n "${2:-}" ]; then
        echo "" >&2
        echo "   → $2" >&2
    fi
    exit 1
}

# Check 1: DISCOVERY-STATE.md exists
if [ ! -f "$KB_DIR/DISCOVERY-STATE.md" ]; then
    err "$KB_DIR/DISCOVERY-STATE.md does not exist." \
        "Run /aid-init then /aid-discover to set up the Knowledge Base."
fi

# Check 2: User Approved: yes
if ! grep -q '^\*\*User Approved:\*\* yes' "$KB_DIR/DISCOVERY-STATE.md"; then
    APPROVAL_VALUE=$(grep -m1 '^\*\*User Approved:\*\*' "$KB_DIR/DISCOVERY-STATE.md" 2>/dev/null | sed 's/^\*\*User Approved:\*\* *//')
    APPROVAL_VALUE="${APPROVAL_VALUE:-not set}"
    err "Knowledge Base discovery is not yet approved. Current status: **User Approved:** $APPROVAL_VALUE" \
        "Run /aid-discover until it reaches APPROVAL state and approve the KB. Then re-run /aid-summarize."
fi

# Check 3: at least one populated KB document
POPULATED=0
if [ -d "$KB_DIR" ]; then
    for f in "$KB_DIR"/*.md; do
        [ -f "$f" ] || continue
        # Skip state files; look at content docs
        case "$(basename "$f")" in
            DISCOVERY-STATE.md|SUMMARY-STATE.md|README.md) continue ;;
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

# Check 4: Plan Mode (best-effort — env-var convention)
if [ "${CLAUDE_PLAN_MODE:-}" = "1" ]; then
    err "Plan Mode is active. /aid-summarize needs write access to generate the HTML." \
        "Press Shift+Tab to exit Plan Mode, then re-run."
fi

# Check 5: Network reachable to npm registry (skipped if --cdn-mermaid)
if [ "$CDN_MODE" -eq 0 ]; then
    if command -v curl >/dev/null 2>&1; then
        if ! curl -sSf --max-time 10 -o /dev/null "https://registry.npmjs.org/mermaid/latest" 2>/dev/null; then
            err "Cannot fetch latest Mermaid version (registry.npmjs.org unreachable)." \
                "Either ensure network connectivity, or pass --cdn-mermaid to use the CDN at runtime."
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q --timeout=10 --tries=1 -O /dev/null "https://registry.npmjs.org/mermaid/latest" 2>/dev/null; then
            err "Cannot fetch latest Mermaid version (registry.npmjs.org unreachable)." \
                "Either ensure network connectivity, or pass --cdn-mermaid."
        fi
    else
        err "Neither curl nor wget is available." \
            "Install one to allow Mermaid library fetching."
    fi
fi

# Check 6: Node.js available (required for Mermaid validation)
if ! command -v node >/dev/null 2>&1; then
    err "Node.js is required for Mermaid diagram validation." \
        "Install Node.js (>= 18) and re-run."
fi

NODE_VERSION_MAJOR=$(node -e 'console.log(process.versions.node.split(".")[0])' 2>/dev/null)
if [ -n "$NODE_VERSION_MAJOR" ] && [ "$NODE_VERSION_MAJOR" -lt 18 ] 2>/dev/null; then
    err "Node.js >= 18 is required (you have $(node -v))." \
        "Upgrade Node.js and re-run."
fi

echo "✅ Preflight checks passed."
exit 0
