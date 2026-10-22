#!/usr/bin/env bash
# aid-question-form.sh -- Claude Code Stop-hook launcher for the AID question-form check.
#
# Purpose:
#   Claude Code runs this when the main agent finishes a response (the Stop event). It finds
#   a Python 3.8+ interpreter and runs aid-question-form.py, which checks that a message that
#   waits on the user is in the form of .aid/runtime/templates/question-protocol.md and that
#   the question was recorded first. A failing message is sent back once, with the reason.
#
# Usage:
#   bash "${CLAUDE_PROJECT_DIR}/.aid/runtime/scripts/hooks/aid-question-form.sh" < stop-event.json
#     stdin   the Stop-event JSON Claude Code supplies
#     env     AID_QUESTION_HOOK=off          turn the check off for this session
#             AID_QUESTION_HOOK_LOG=<file>   append one JSON line per blocked message
#
# Output:
#   stdout: exactly one JSON object -- `{}` (let the turn end) or
#           {"decision": "block", "reason": "..."} (Claude continues with the reason).
#
# Exit codes:
#   0 -- always. A broken hook must never hold a session, so every failure (no Python, a crash,
#        output that is not a JSON object) prints `{}` and exits 0.

set -u

# Locate this script with shell built-ins only (no dirname), so a PATH without tools still fails open.
SRC="${BASH_SOURCE[0]}"
case "$SRC" in
    */*) SRC_DIR="${SRC%/*}" ;;
    *) SRC_DIR="." ;;
esac
HERE="$(cd "$SRC_DIR" 2>/dev/null && pwd)" || { echo '{}'; exit 0; }
CHECKER="${HERE}/aid-question-form.py"
[ -f "$CHECKER" ] || { echo '{}'; exit 0; }

PY=""
for cand in python3 python; do
    command -v "$cand" >/dev/null 2>&1 || continue
    if "$cand" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' >/dev/null 2>&1; then
        PY="$cand"
        break
    fi
done
[ -n "$PY" ] || { echo '{}'; exit 0; }

out="$("$PY" "$CHECKER" 2>/dev/null)" || { echo '{}'; exit 0; }
case "$out" in
    '{'*'}') printf '%s\n' "$out" ;;
    *) echo '{}' ;;
esac
exit 0
