# AGENTS.md

## Project Overview
<!-- AID-DISCOVER — Replace with project name, purpose, tech stack, and target platform -->
(pending discovery)

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
  terminal value (`Done` / `Failed`) at the end (`Blocked` is a distinct,
  orchestrator-assigned value for a DIFFERENT, downstream task that depends on
  a failed one — never self-written by the task being executed). This binds
  **whoever executes the task** — the main/orchestrator agent executing it
  DIRECTLY (not only a dispatched sub-agent) MUST perform these writes itself,
  at the same points, with **no exception and no bypass**. A task that sits
  at `Pending` in the dashboard for its entire execution and then jumps
  straight to `Done` is exactly the failure mode this rule exists to prevent.

## Knowledge Base

This project uses the [AID methodology](https://github.com/AndreVianna/aid-methodology).
- Read `.aid/knowledge/INDEX.md`.
- Always consult relevant KB documents before making changes.
- The KB is the single source of truth for architecture, conventions, and patterns.

## Workflow

- Every change should be traceable to a task or requirement.
- Follow the current numbered phase: Discover → Describe → Define → Specify → Plan → Detail → Execute. `aid-config` bootstraps before the pipeline; Deploy and Monitor are optional Deliver skills after it.
- Produce verifiable artifacts at each phase.
- Quality gates must pass before proceeding.

## Review output format (global)

Any review output you produce — dispatched sub-agent, script validator, or
ad-hoc user-prompted — uses the schema at
`aid/templates/reviewer-ledger-schema.md` (under this tool's install root). Write the ledger as a single
markdown table at `.aid/.temp/review-pending/<scope>.md`. Use the 7-column
shape: `# | Severity | Status | Doc | Line | Description | Evidence`.
Severity tags bracketed; Status enum: Pending/Fixed/Recurred/Accepted/OOS/Invalid.
No narrative or summary sections in the ledger.

## Permissions

- Read any file in the project
- Write only within the project directory
- Run build and test commands (Python, Bash, PowerShell)
- Do NOT modify files outside the project root
<!-- AID:END -->
