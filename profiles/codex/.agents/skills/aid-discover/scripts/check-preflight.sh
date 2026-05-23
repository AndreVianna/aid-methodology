#!/usr/bin/env bash
# Pre-flight checks for aid-discover.
#
# Usage: check-preflight.sh [knowledge-dir]
# Example: check-preflight.sh .aid/knowledge/
#
# Checks:
#   1. DISCOVERY-STATE.md exists (init has run)
#   2. Not in Plan Mode (checks CLAUDE_MODE env var if available)
#
# Exit codes:
#   0 = all checks pass
#   1 = init has not run (DISCOVERY-STATE.md missing)
#   2 = Plan Mode detected

set -euo pipefail

KB_DIR="${1:-.aid/knowledge}"

# Check 1: Verify Init Has Run
if [ ! -f "$KB_DIR/DISCOVERY-STATE.md" ]; then
  echo "⚠️ Knowledge Base not initialized. Run /aid-init first to set up the project."
  exit 1
fi

# Check that DISCOVERY-STATE.md is not empty
if [ ! -s "$KB_DIR/DISCOVERY-STATE.md" ]; then
  echo "⚠️ DISCOVERY-STATE.md is empty. Run /aid-init first to set up the project."
  exit 1
fi

echo "✅ DISCOVERY-STATE.md exists."

# Check 2: Verify Not in Plan Mode
# Note: Plan Mode is a Claude Code UI state. This script checks for the
# CLAUDE_MODE environment variable as a hint, but the orchestrator should
# also verify visually via the Claude Code interface.
if [ "${CLAUDE_MODE:-}" = "plan" ]; then
  echo "❌ Plan Mode detected. Discovery needs to write files."
  echo "   Press Shift+Tab to switch out of Plan Mode, then re-run /aid-discover."
  exit 2
fi

echo "✅ Pre-flight checks passed."
exit 0
