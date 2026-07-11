# CLAUDE.md

## Project
AID — AI Integrated Development
A full-lifecycle methodology for building software with AI agents

<!-- AID:BEGIN -->
## Tracking discipline (IMPERATIVE)

Every project, task, and deliverable is tracked in a state file — the work's
`.aid/work-NNN-*/STATE.md` (plus `.aid/knowledge/STATE.md` for knowledge-base and
cross-phase process state). Keeping it current is **not optional**:

- **ANY and ALL** changes to the state of a project, task, or deliverable —
  status, phase, grade, review outcome, or artifacts produced — MUST be written
  to the proper tracking file **IMMEDIATELY**, as part of the same action that
  made the change. Untracked work is incomplete work.
- This binds **EVERY agent, without exception** — whether invoked by a SKILL or
  by a DIRECT PROMPT, and whether on the FULL or the LITE path.
- If no tracking file exists for the work yet, **create it first** (from the
  work-state template) before doing anything else.
- **Task execution is the sharpest case of this rule.** During `/aid-execute`,
  a task's `State` MUST be written the instant it changes — `In Progress` at
  the start of EXECUTE, `In Review` before the reviewer is dispatched, and a
  terminal value (`Done` / `Failed` / `Blocked`) at the end. This binds
  **whoever executes the task** — the main/orchestrator agent executing it
  DIRECTLY (not only a dispatched sub-agent) MUST perform these writes itself,
  at the same points, with **no exception and no bypass**. A task that sits
  at `Pending` in the dashboard for its entire execution and then jumps
  straight to `Done` is exactly the failure mode this rule exists to prevent.

## Knowledge Base

@.aid/knowledge.

- Always consult relevant KB documents before making changes.
- The KB is the single source of truth for architecture, conventions, and patterns.

## Connectors

@.aid/connectors/INDEX.md.

- Before connecting to an external tool, scan the connectors index to find
  its descriptor, then open the descriptor for full fields and auth details.
- For an `mcp` connector (tool-managed), request the connection from your
  host tool's own MCP/plugin — the tool provides it and handles auth; AID
  stores no credential for it. The descriptor exists for discovery and
  audit, not connect-time consumption.
- For `api` / `ssh` / `url` / `cli`, resolve the descriptor's
  `secret_reference` at use-time: `env:` reads an environment variable,
  `file:` reads `.aid/connectors/.secrets/<connector>`, `keychain:` reads the
  OS keychain.
- Out of scope: no agent-side code that actively consumes non-MCP
  descriptors is built here — this section documents the contract only.

## Workflow

- Every change should be traceable to a task or requirement.
- Follow the current numbered phase: Discover → Describe → Define → Specify → Plan → Detail → Execute. `aid-config` bootstraps before the pipeline; Deploy and Monitor are optional Deliver skills after it.
- Produce verifiable artifacts at each phase.
- Quality gates must pass before proceeding.
- Pipeline settings (installed tools, quality-gate thresholds) live in `.aid/settings.yml`; consult it before assuming a default.

## Review output format (global)

Any review output you produce — dispatched sub-agent, script validator, or
ad-hoc user-prompted — uses the schema at
`.claude/aid/templates/reviewer-ledger-schema.md`. Write the ledger as a single
markdown table at `.aid/.temp/review-pending/<scope>.md`. Use the 7-column
shape: `# | Severity | Status | Doc | Line | Description | Evidence`.
Severity tags bracketed; Status enum: Pending/Fixed/Recurred/Accepted/OOS/Invalid.
No narrative or summary sections in the ledger.

## Permissions

- Read any file in the project
- Write only within the project directory
- Run build and test commands
- Do NOT modify files outside the project root
<!-- AID:END -->
