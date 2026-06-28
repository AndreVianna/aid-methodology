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

## Knowledge Base

@.aid/knowledge.

- Always consult relevant KB documents before making changes.
- The KB is the single source of truth for architecture, conventions, and patterns.

## Workflow

- Every change should be traceable to a task or requirement.
- Follow the current numbered phase: Discover → Describe/Define (2a/2b) → Specify → Plan → Detail → Execute (the six numbered pipeline phases; phase 2 = Describe (2a) + Define (2b)). `aid-config` bootstraps before the pipeline; Deploy and Monitor are optional Deliver skills after it. Init/Implement/Review/Test/Track/Triage are NOT numbered phases — they are the bootstrap, Execute task-types/states, or the optional Deliver skills.
- Produce verifiable artifacts at each phase.
- Quality gates must pass before proceeding.

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
