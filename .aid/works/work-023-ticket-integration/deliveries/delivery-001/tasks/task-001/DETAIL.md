# task-001: Shared ticket-resolution connector reference

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-023-ticket-integration -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Author the DRY shared reference `canonical/aid/templates/connectors/ticket-resolution.md` that the three ticket skills point to (feature-001 §Layers "Shared reference (DRY, decision 1)"; the pattern skills already use for `shortcut-engine.md` / `consumption-protocol.md`).
- Describe, ONCE, the FR-4 connector-resolution ladder (first match wins): explicit `<connector>` (read/update `<stem>:` prefix; create `--connector` flag) validated as a catalogued `issue-tracker` connector -> scan `.aid/connectors/INDEX.md` for `Type = mcp` AND tag `issue-tracker` (exactly one -> use silently; two or more -> `AskUserQuestion`) -> host tool's own issue-tracker MCP -> notify `"no issue-tracker connector found."` and exit.
- Describe the deterministic grammar-parse conventions shared by the skills: read/update `[<connector>:]<ticket-id>` colon-split; update closed `part` enum `{description, comment, status}`; create `--connector`/`--level`/`--parent` flags in any order with the whole non-flag remainder taken verbatim as `<description>` and NO bare-leading-token connector heuristic (feature-001 §API Contracts).
- Describe the write preview/confirm-gate convention: an in-invocation `AskUserQuestion` confirm before any MCP write, a CHAIN advance (not `PAUSE-FOR-USER-DECISION`) per `state-machine-chaining.md`; reads are non-destructive and never prompt.
- Describe MCP-first consumption (pointer to `consumption-protocol.md`), the `api`/`ssh`/`cli` fall-through, and the catalog-reality note (no `mcp` `issue-tracker` preset ships today -> the silent-single-match path activates once a user registers a custom `mcp` tracker).
- Authored under `canonical/` only; the render to the five `profiles/*` + dogfood `.claude/` is delivery-003 (feature-005), NOT this task.

**Acceptance Criteria:**
- [ ] `canonical/aid/templates/connectors/ticket-resolution.md` exists and describes the FR-4 ladder once (explicit override -> single silent -> 2+ ask -> host-MCP -> the notify string), the deterministic grammar-parse rules for all three skills, and the write preview/confirm-gate CHAIN convention (feature-001 §External Integrations, §API Contracts, §Security Specs).
- [ ] The reference states MCP-first consumption (pointer to `consumption-protocol.md`), the `api`/`ssh`/`cli` fall-through, and the catalog-reality note (feature-001 §External Integrations).
- [ ] The ladder/grammar/confirm are described only here (the single home) -- the three skills point to it and never re-describe it inline (feature-001 decision 1).
- [ ] Edit is authored under `canonical/` only; no `.claude/` or `profiles/` hand-edit (byte/path-parity is delivery-003's gate -- PLAN.md R3).
- [ ] Structural coverage of this reference is exercised by the delivery-001 TEST suite (task-005); there is no compiled build for this prose contract, so the code-specific IMPLEMENT defaults (unit tests / build passes) are superseded by that structural coverage and by delivery-003's render gate.
- [ ] All section-6 quality gates pass.
