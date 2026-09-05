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
  - https://nodejs.org/api/sqlite.html
tags: [meta, external-docs, vendor-specs, references]
see_also: [integration-map.md]
owner: architect
audience: [developer, architect]
review-criteria: []
---

# External Sources

> **Source:** aid-discover (Phase 1 -- Pre-scan); host agent-tool docs added during requirements work
> **Status:** Populated -- host agent-tool vendor documentation
> **Last Updated:** 2026-08-09

## Contents

- [Sources](#sources)

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

### Node's built-in SQLite module

`node:sqlite` is the runtime's own SQLite binding — no third-party dependency, no native
build step. Its **availability is version-gated in a way the module's own presence does not
reveal**, which is the reason this entry exists: a declared floor of `>=22` admits releases on
which `require('node:sqlite')` throws, and the failure reads as a missing module rather than
as an unmet version requirement.

| Source | URL | What it answers | Accessed |
|---|---|---|---|
| Node.js SQLite API | https://nodejs.org/api/sqlite.html | Version history: **added in v22.5.0** behind `--experimental-sqlite`; the flag requirement was **removed in v22.13.0** (and v23.4.0); **release-candidate status in v24.15.0** (and v25.7.0). Below 24.15.0 the module emits an `ExperimentalWarning` on stderr at every open | 2026-09-01 |

**So the usable floor is 22.13.0, not 22.** On 22.0–22.4 the module does not exist at all; on
22.5–22.12 it exists only behind a flag. Anything declaring a Node floor for a component that
opens `node:sqlite` needs 22.13.0 or later, and a floor of `>=22` is not one.

#### First-hand measurements

Run against the module directly rather than read from documentation, and recorded here as
first-hand — the same distinction this document draws for the Claude Code harness above.
**Method:** each clause executed against a real database file on each runtime; **runtimes:**
Node v22.14.0, v24.19.0 and v26.7.0; **date:** 2026-09-01 (v22.14.0) and 2026-08-10 (the
other two).

| Property | Result |
|---|---|
| Write-ahead logging | Engages and persists across reopen |
| `synchronous=FULL` | Sticks |
| Partial unique index | Rejects a duplicate key while permitting many nulls |
| `ON DELETE CASCADE` | Fires |
| Concurrent reader/writer | A reader held a transaction open 3 s while a writer committed 49 rows; slowest commit 3 ms |
| Crash durability | `SIGKILL` mid-transaction left the committed rows, discarded the uncommitted one, and passed `integrity_check` |

**Two findings that surprise people, and are worth knowing before designing against this
module:** the default `busy_timeout` is **0**, so a second writer fails instantly rather than
waiting unless a non-zero value is set explicitly; and there is **no `db.transaction()`
helper**, so a transaction wrapper is hand-written.

If further external documentation becomes available, re-run discovery or add it here.
