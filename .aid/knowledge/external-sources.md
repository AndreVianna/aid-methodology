---
kb-category: meta
source: hand-authored
objective: Registry of external documentation, vendor specs, and reference URLs the AID project depends on.
summary: Read this before fetching documentation that may already be cataloged here. Discovery provided none; the host agent-tool vendor docs catalogued since answer how each harness behaves — which hook events fire, and whether anything outside a session can start a turn in it.
sources:
  # EXTERNAL URLs/docs cataloged in this registry.
  - https://docs.github.com/en/copilot/reference/hooks-reference
  - https://docs.github.com/en/copilot/concepts/agents/hooks
  - https://cursor.com/docs/hooks
  - https://cursor.com/docs/cli/headless
  - https://docs.cursor.com/en/background-agent/api/add-followup
  - https://cursor.com/docs/cloud-agent/api/webhooks
  - https://antigravity.google/docs/cli/subagents
  - https://github.com/orgs/community/discussions/160291
  - https://forum.cursor.com/t/mcp-elicitation-support-immediate-need/116516
tags: [meta, external-docs, vendor-specs, references]
see_also: [integration-map.md]
owner: architect
audience: [developer, architect]
intent: |
  Registry of external documentation, vendor specs, and reference URLs the project depends on. Read this before fetching documentation that may already be cataloged.
contracts: []
---

# External Sources

> **Source:** aid-discover (Phase 1 -- Pre-scan); host agent-tool docs added during requirements work
> **Status:** Populated -- host agent-tool vendor documentation
> **Last Updated:** 2026-08-09

## Contents

- [Sources](#sources)
- [Change Log](#change-log)

---

## Sources

Discovery itself provided no external documentation — all knowledge was derived from
repository content. The entries below were catalogued afterwards, during requirements work
that needed vendor answers the repository could not supply.

### Host agent-tool documentation

AID installs into five host agent tools, and their harness behaviour — the hook events each
one fires, and whether anything outside a session can start a turn in it — is vendor
knowledge with no representation in this repository. Consult these before designing or
reviewing anything that depends on host lifecycle behaviour.

**Coverage is partial, and the gaps are load-bearing.** Three of the five hosts are
catalogued below: Cursor, GitHub Copilot CLI, and Antigravity. **Claude Code and Codex are
not.** For Claude Code this is not an oversight to be filled from a search: its harness
capabilities are exposed to an agent at runtime rather than published as a document, so a
claim about them is first-hand rather than citable. Treat any Claude Code harness claim as
unsourced until a published reference exists. Codex has simply not been researched.

| Source | URL | What it answers | Accessed |
|---|---|---|---|
| GitHub Copilot hooks reference | https://docs.github.com/en/copilot/reference/hooks-reference | The 14 hook events and when each fires; `agentStop` can force a further turn; **no idle hook exists and no external process can inject into a session** | 2026-08-09 |
| GitHub Copilot hooks concept | https://docs.github.com/en/copilot/concepts/agents/hooks | Hook configuration locations (`.github/hooks/*.json`, `~/.copilot/hooks/*.json`) | 2026-08-09 |
| Cursor hooks | https://cursor.com/docs/hooks | The full hook event list; the `stop` hook fires when the agent loop ends and **can submit the next user message**; **no mechanism exists for a background process to initiate a turn** | 2026-08-09 |
| Cursor CLI headless mode | https://cursor.com/docs/cli/headless | Print and resume are script paths, not live sessions; ACP exposes the agent as a JSON-RPC server over stdio | 2026-08-09 |
| Cursor cloud-agent follow-up API | https://docs.cursor.com/en/background-agent/api/add-followup | An already-running **cloud** agent can be sent a further instruction — does not apply to a local editor session | 2026-08-09 |
| Cursor cloud-agent webhooks | https://cursor.com/docs/cloud-agent/api/webhooks | Webhook events are limited to `statusChange` (ERROR, FINISHED) | 2026-08-09 |
| Antigravity subagents and background tasks | https://antigravity.google/docs/cli/subagents | Background task and subagent model; **silent on external wake mechanisms** | 2026-08-09 |
| Copilot MCP sampling support | https://github.com/orgs/community/discussions/160291 | Copilot implements only the MCP `tools` primitive — no server-initiated sampling | 2026-08-09 |
| Cursor MCP elicitation request | https://forum.cursor.com/t/mcp-elicitation-support-immediate-need/116516 | MCP elicitation is requested but not implemented in Cursor | 2026-08-09 |

**The load-bearing conclusion**, because it is easy to reach the opposite one from vendor
marketing: MCP is a **pull** surface on these hosts. Server-initiated MCP messages are
unsupported in Copilot and unimplemented in Cursor, so no MCP server can start a turn in an
idle session. Most vendor "notification" features notify the **human**, not the agent — a
distinction worth checking before relying on any of them.

If further external documentation becomes available, re-run discovery or add it here.

---

