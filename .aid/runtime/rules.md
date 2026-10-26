## Summary

<!-- AID:SUMMARY:BEGIN -->
- Read the project card `.aid/knowledge/PROJECT.md` first; open `.aid/knowledge/INDEX.md` only to find a specific document.
- Consult the Knowledge Base (`.aid/knowledge/`) before changing anything; it is the source of truth.
- Record every state change (status, phase, grade, review outcome) in the work's STATE file immediately, `/aid-execute` included.
- Work folders (`.aid/works/`) are transient: nothing permanent may depend on them; `.aid/knowledge/**` never names a work id or path.
- Before writing a file, resolve and follow its review criteria (`.aid/knowledge/authoring-conventions.md`).
- Review output uses the 7-column ledger (`.aid/runtime/templates/reviewer-ledger-schema.md`).
- Write only inside the project directory.
<!-- AID:SUMMARY:END -->

## Tracking discipline (IMPERATIVE)

Every project, task and deliverable is tracked in a state file: the work's `.aid/works/work-NNN-*/STATE.yml`, plus
`.aid/knowledge/STATE.md` for knowledge-base and cross-phase state. Keeping it current is **not optional**:
- Write ANY change of status, phase, grade, review outcome or artifacts to that file **IMMEDIATELY**, in the same action. It binds
  **EVERY agent** (skill or direct prompt, FULL or LITE path). No file yet: create it first, from the work-state template.
- **Task execution is the sharpest case.** During `/aid-execute` write `State` the instant it changes: `In Progress` at the start of
  EXECUTE, `In Review` before the reviewer is dispatched, `Done` / `Failed` at the end. Its executor, orchestrator included, writes
  these itself. `Blocked` is the orchestrator's mark on a downstream task, never self-written (`task-state-template.yml`).
- **Work folders are transient**: pruned once the work ships. No permanent artifact (code, shared source or its render, tests,
  docs, the KB, context files) may depend on a specific work folder's contents; tests build their own fixtures. Pipeline
  skills and scripts that use work folders as live state are exempt.
- **Never name a work in the Knowledge Base.** `.aid/knowledge/**` holds no work id, no work-folder path and no
  `## Change Log` / `changelog:`: cite the durable artifact the work left on disk (why: `authoring-conventions.md`
  § No Work References). Skills, templates and scripts may name works.

## Knowledge Base

This project uses the [AID methodology](https://github.com/AndreVianna/aid-methodology).
- Read the project card `.aid/knowledge/PROJECT.md` first; open `.aid/knowledge/INDEX.md` only to find a specific document.
  Consult the relevant KB documents before making changes: the KB is the single source of truth for architecture, conventions and patterns.

## Connectors

Read `.aid/connectors/INDEX.md`.
- Connectors are catalogued via `aid-discover` (ELICIT); change them on demand, without re-running discovery, with `aid-set-connector` / `aid-unset-connector`.
- Consumption is MCP-first (`.aid/runtime/templates/connectors/consumption-protocol.md`): for a `connection_type: mcp`
  connector, request the connection from your host tool's own MCP/plugin. AID resolves nothing and stores no credential.
- aid-managed consumption (`api` / `ssh` / `url` / `cli`) is deferred: those descriptors serve discovery and audit only.

## Workflow

- Every change traces to a task or requirement; each phase produces verifiable artifacts; quality gates pass before proceeding.
- Follow the current numbered phase: Discover → Describe → Define → Specify → Plan → Detail → Execute; the sequence ends at
  Execute. `aid-config` bootstraps before it; Deploy and Monitor are optional, separately invoked Deliver paths.

## Review criteria (before you write)

Criteria are the writer's contract; the reviewer is the backstop, not the enforcer. **Before authoring or editing any file, resolve
its review criteria and comply**: the union of the global, document-type and file (`review-criteria:` frontmatter) criteria in
`.aid/knowledge/authoring-conventions.md`; the most specific wins; a `kind: exclude` entry binds like a `validate` one (it names what
not to add). Introducing or retiring a document type owes the KB a registry row; every in-scope file has exactly one type.
Review output (sub-agent, script validator or ad-hoc) is the single 7-column table of `.aid/runtime/templates/reviewer-ledger-schema.md`,
at `.aid/.temp/review-pending/<scope>.md`, with no narrative.

## Permissions

Read any file in the project; write only inside the project directory; run build and test commands (Python, Bash, PowerShell).
