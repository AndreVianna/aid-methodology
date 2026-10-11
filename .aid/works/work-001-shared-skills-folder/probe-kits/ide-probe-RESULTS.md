# AID IDE probe — results

Fill one cell per test and tool. Paste the exact reply, or write what you saw.

| # | Test | Claude Code | Cursor | Antigravity |
|---|------|-------------|--------|-------------|
| 1 | `probe-agents` (in .agents/skills) | not recognized | PROBE-AGENTS-OK | PROBE-AGENTS-OK |
| 2 | `probe-claude` (in .claude/skills) | PROBE-CLAUDE-OK | (implied yes: dup reply came from .claude) |  |
| 3a | `probe-dup` shows how many times in the `/` menu? | 1 (Copy B) | 1 (Copy A) | 1 (Copy A) |
| 3b | `probe-dup` reply (which copy won?) | DUP-FROM-CLAUDE | DUP-FROM-CLAUDE | DUP-FROM-AGENTS |
| 4 | `probe-path` reply | RUNTIME-PATH-OK | RUNTIME-PATH-OK | RUNTIME-PATH-OK |
| 5a | `probe-shell-bash`: permission prompt? (yes/no) | no (git init, default mode) | no (prior grants existed — inconclusive) | yes, until global grant |
| 5b | `probe-shell-shell`: permission prompt? (yes/no) | YES (git init, default mode) | no (prior grants existed — inconclusive) | yes, until global grant |
| 6 | Dispatch-tool parameters (reply to prompt P6) |  |  |  |
| 7 | Dispatch `probe-agent` with a chosen model (reply to P7) |  |  |  |
| 8 | Dispatch with fake model ID (reply to P8) |  |  |  |
| 9 | Dispatch `probe-badmodel` (reply to P9) |  |  |  |
| 10 | Sub-agents listed (which of: probe-agent-claude / -cursor / -shared / -antigravity) |  |  |  |


Antigravity v2.22.0, Windows: 5a reply SHELL-Bash-DONE (git 2.53.0.windows.2); 5b reply SHELL-Shell-DONE (same). Prompts not reported yet.
Cursor, Windows: 5b reply SHELL-Shell-DONE (git 2.53.0.windows.2). 5a not run yet. Prompts not reported.
Cursor 5a reply: SHELL-Bash-DONE.
NOTE Cursor: menu showed Copy A (.agents) description but reply was DUP-FROM-CLAUDE (.claude body) - listing and execution used different copies.
Claude Code: 5a SHELL-Bash-DONE, 5b SHELL-Shell-DONE (git --version). Prompt status not reported.

Codex (Windows, 2026-10-10): maintainer reports behaviour identical to Cursor and Antigravity (reads .agents/skills; dup listed once; .aid/runtime path OK; shell skills run).
Copilot CLI (Windows, 2026-10-10): /probe-dup menu shows Copy A (.agents) -> discovers .agents/skills. Execution blocked: 403 "unauthorized: not authorized to use this Copilot feature" (account access).
