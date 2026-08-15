#!/usr/bin/env bash
# discover-preflight.sh -- pre-flight checks for /aid-discover.
#
# Usage: discover-preflight.sh [knowledge-dir]
# Example: discover-preflight.sh .aid/knowledge/
#
# Checks:
#   1. STATE.md exists; if absent it is self-created from the template.
#   2. Not in Plan Mode (checks CLAUDE_MODE env var if available)
#
# Exit codes:
#   0 = all checks pass (STATE.md present or just self-created)
#   1 = STATE.md cannot be created or is empty after self-create
#   2 = Plan Mode detected

set -euo pipefail

KB_DIR="${1:-.aid/knowledge}"

# ---------------------------------------------------------------------------
# Resolve the template path relative to this script's own location so the
# script works correctly regardless of the install tree layout.
# The script lives at <tree>/aid/scripts/kb/discover-preflight.sh and the
# template lives at <tree>/aid/templates/discovery-state-template.md, which
# is two levels up from the script directory.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="${SCRIPT_DIR}/../../templates/discovery-state-template.md"

# Check 1: STATE.md must exist and be non-empty.
# If it is absent, self-create it from the template so /aid-discover can
# proceed without requiring /aid-config to have run first.
if [ ! -f "$KB_DIR/STATE.md" ]; then
  echo "STATE.md not found -- self-creating from template."
  mkdir -p "$KB_DIR"
  if [ -f "$TEMPLATE_PATH" ]; then
    cp "$TEMPLATE_PATH" "$KB_DIR/STATE.md"
    echo "STATE.md seeded from discovery-state-template.md."
  else
    # Fallback: template not found; write a minimal valid scaffold so the
    # skill can still proceed (the orchestrator will fill it in). Frontmatter
    # (not body prose) is the schema for kb_status since work-003-state-schema
    # task-001/004 -- match that shape even in this degraded fallback path.
    printf -- '---\nkb_status: Initial\n---\n\n# Discovery State\n' > "$KB_DIR/STATE.md"
    echo "Template not found at ${TEMPLATE_PATH}; wrote minimal STATE.md scaffold."
  fi
fi

# Verify the file is non-empty (guards against a zero-byte STATE.md left by
# a prior interrupted run; the self-create above will always produce content).
if [ ! -s "$KB_DIR/STATE.md" ]; then
  echo "ERROR: STATE.md is empty and could not be repaired. Remove it and re-run."
  exit 1
fi

echo "STATE.md present."

# Check 2: Verify Not in Plan Mode
# Note: Plan Mode is a Claude Code UI state. This script checks for the
# CLAUDE_MODE environment variable as a hint, but the orchestrator should
# also verify visually via the Claude Code interface.
if [ "${CLAUDE_MODE:-}" = "plan" ]; then
  echo "ERROR: Plan Mode detected. Discovery needs to write files."
  echo "       Press Shift+Tab to switch out of Plan Mode, then re-run /aid-discover."
  exit 2
fi

echo "Pre-flight checks passed."
exit 0
