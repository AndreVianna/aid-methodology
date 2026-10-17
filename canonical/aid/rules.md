## Summary

<!-- AID:SUMMARY:BEGIN -->
- Read every request by its meaning and match it to the skill guide in `.aid/runtime/rules.md`;
  answer project questions from the Knowledge Base.
- Record every state change (status, phase, grade, review outcome) in the work's STATE file immediately;
  during /aid-execute write In Progress, In Review and Done/Failed as they happen.
- Work folders (`.aid/works/`) are transient: nothing permanent may depend on them.
- Never name a work id or work-folder path in `.aid/knowledge/**`.
- Consult the Knowledge Base (`.aid/knowledge/`) before changing anything; it is the source of truth.
- Before writing a file, resolve and follow its review criteria (`.aid/knowledge/authoring-conventions.md`).
- Review output uses the 7-column ledger (`.aid/runtime/templates/reviewer-ledger-schema.md`).
- Write only inside the project directory.
<!-- AID:SUMMARY:END -->

## Tracking discipline (IMPERATIVE)

Every project, task, and deliverable is tracked in a state file — the work's
`.aid/works/work-NNN-*/STATE.yml` (plus `.aid/knowledge/STATE.md` for knowledge-base and
cross-phase process state). Keeping it current is **not optional**:

- **ANY and ALL** changes to the state of a project, task, or deliverable —
  status, phase, grade, review outcome, or artifacts produced — MUST be written
  to the proper tracking file **IMMEDIATELY**, as part of the same action that
  made the change. Untracked work is incomplete work.
- This binds **EVERY agent, without exception** — whether invoked by a SKILL or
  by a DIRECT PROMPT.
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
- **Work folders are transient.** `.aid/works/work-NNN-*/` holds disposable
  per-work pipeline state and may be pruned once the work ships. No permanent
  artifact — product code, shared source content (or its host render),
  tests, docs, the Knowledge Base, or these context files — may depend on the
  contents of a specific work folder: tests build their own fixtures, and the
  KB never cites a work folder as a source. Pipeline skills/scripts that
  create, read, or update work folders as live runtime state are exempt.
- **Never name a work in the Knowledge Base.** `.aid/knowledge/**` must contain no
  work id and no work-folder path — not `work-042`, not `.aid/works/work-042-*/`, not
  "specified by work-042" or "added in work-042" — in prose, tables, headings, or
  frontmatter. Two reasons, each sufficient: a work folder is pruned when its work
  ships, so the cite is a dangling pointer by design; and the KB states only the
  **current state of the project's sources**, whereas which work produced a change is
  history. Cite the durable artifact the work left on disk instead. It follows that a
  KB doc carries no `## Change Log` / `## Revision History` section and no `changelog:`
  frontmatter field — git records per-doc history with author, date, and diff, at higher
  fidelity and without drift. This binds `.aid/knowledge/` alone: skills, templates, and
  pipeline scripts name works legitimately, because they operate on them.

## Knowledge Base

This project uses the [AID methodology](https://github.com/AndreVianna/aid-methodology).
- Read `.aid/knowledge/INDEX.md`.
- Always consult relevant KB documents before making changes.
- The KB is the single source of truth for architecture, conventions, and patterns.

## Connectors

Read `.aid/connectors/INDEX.md`.

- Connectors are catalogued via `aid-discover` (ELICIT) and can be added, updated, or removed on
  demand — without re-running discovery — with `aid-set-connector` / `aid-unset-connector`.
- Consumption is MCP-first (`.aid/runtime/templates/connectors/consumption-protocol.md`, shared by
  all tools): scan the index, and for a `connection_type: mcp` connector, request the connection
  from your host tool's own MCP/plugin — AID resolves nothing and stores no credential for it.
- aid-managed consumption (`api` / `ssh` / `url` / `cli`) remains deferred; those descriptors exist
  for discovery and audit only, not for live use.

## Handling a request

- Read what the user wants by its meaning, not its wording, and match it to the skill guide below.
- A question about this project starts no work: answer it from the Knowledge Base, citing sources.
- One skill fits: propose its workflow. Several fit: choose yourself; ask one question, with your
  recommendation, only if you cannot choose. None fits: carry on with no AID workflow.
- A typed `/aid-<skill>` always wins.
- The user's words are a hint: check your reading against the Knowledge Base and the code (a
  "refactor" that adds an endpoint changes behaviour, so it is new work).
- To start, resume or cancel a work, run `/aid-orchestrate`: it finds where the work stands, sizes it and
  picks the phases it needs.
- Show your reading and its reason in one line, inside your first question or approval; then wait.
- Specification, Planning and Building (with tests) almost always run; Definition only when the problem
  must first be shaped; Preparation builds the Knowledge Base once, then updates it on demand; CI always
  closes the work. Release, deploy and monitoring are works of their own.
- If the work turns out bigger or different, re-route and say so in one line.
- Check every decision against the Knowledge Base; raise a conflict, never settle it alone.
- Ask one topic at a time, with a recommendation; the user approves before building and the result.

## Skill guide

One line per skill: what it is for; when to use it. `<kind>` stands for each kind that
`.aid/runtime/templates/shortcut-catalog.yml` lists for that action.

### Phase skills

- `/aid-orchestrate` -- start, resume or cancel a work; when a plain request starts or continues one
- `/aid-discover` -- build the Knowledge Base from existing code; when a project has none yet
- `/aid-describe` -- gather the requirements by interview; when a new work needs them written
- `/aid-define` -- split approved requirements into features; after the requirements are approved
- `/aid-specify` -- write a feature's technical specification; after the features are defined
- `/aid-plan` -- group the specified features into deliveries; after the specifications are approved
- `/aid-detail` -- break a delivery into small typed tasks; after the plan is approved
- `/aid-execute` -- carry out and review each planned task; when a delivery's tasks are ready
- `/aid-deploy` -- package completed deliveries into a release; when they are ready to ship
- `/aid-monitor` -- watch production and route what it finds; after a release, or when it misbehaves

### Knowledge Base skills

- `/aid-ask` -- answer a question about the project, with sources; when the user asks one
- `/aid-update-kb` -- apply one confirmed change to the Knowledge Base; when a fact changes
- `/aid-summarize` -- build `kb.html`, the Knowledge Base web view; when someone wants to read it
- `/aid-housekeep` -- re-sync drifted docs and sweep stale works; when the project has drifted

### Supporting skills

- `/aid-brainstorm` -- shape an unformed idea into a design seed; when the problem is still unclear
- `/aid-research` -- investigate an open technical question; when options must be weighed first
- `/aid-design` -- design a subject no kind below covers; when its shape is still open
- `/aid-design-<kind>` -- design one kind of thing as a seed; when its shape is still open
- `/aid-prototype` -- build a low-fidelity model of a direction; before committing to a full build
- `/aid-prototype-<kind>` -- prototype one kind of thing, such as a UI; before building it for real
- `/aid-create` -- create a new code artifact (module, interface, type); when it does not exist yet
- `/aid-create-<kind>` -- create one kind of thing (an API, a UI, a job, ...); when it is new
- `/aid-update` -- change an existing code artifact's behaviour; when its criteria change
- `/aid-update-<kind>` -- change one kind of thing that exists; when it must behave differently
- `/aid-fix` -- diagnose and correct a defect; when something is broken
- `/aid-refactor` -- restructure code without changing behaviour; when code needs reshaping
- `/aid-remove` -- remove code, a feature or a dependency and its uses; when something must go
- `/aid-deprecate` -- mark something deprecated, with a migration path; before removing it
- `/aid-migrate` -- move data, a dependency or a platform, with rollback; when switching over
- `/aid-test` -- run tests or checks and report the findings; when something must be verified
- `/aid-test-<kind>` -- run one kind of check (security, performance, ...); when only it is due
- `/aid-experiment` -- design, run and analyse a controlled experiment; when a choice needs evidence
- `/aid-review` -- review code, a change or a design against criteria; when a review is asked for
- `/aid-report` -- analyse data or usage into an insight report; when the user needs it explained
- `/aid-document` -- write a how-to, reference or explanation; when a general document is needed
- `/aid-document-<kind>` -- write one kind of document (decision, runbook, ...); when that is needed
- `/aid-read-ticket` -- read one tracker ticket and show its fields; when a ticket is named
- `/aid-create-ticket` -- file one new tracker ticket; when work must be recorded in the tracker
- `/aid-update-ticket` -- change one part of a tracker ticket; when the user wants it updated
- `/aid-chat` -- talk with another AI coding session; when sessions must coordinate

### Setup skills

- `/aid-config` -- view or change the project's AID settings; when setting up or tuning AID
- `/aid-set-connector` -- add or change a connector to a tracker or tool; when connecting one
- `/aid-unset-connector` -- remove a connector; when a connection is no longer wanted

## Review criteria (before you write)

Criteria are the writer's contract, not the reviewer's checklist. **Before authoring or
editing any file, resolve its review criteria and comply** -- the reviewer is the backstop,
not the enforcer:

- Resolve three levels and satisfy the union: the **global** criteria and the criteria for
  the file's **document type**, both in the type registry and criteria tables of
  `.aid/knowledge/authoring-conventions.md`, plus anything the **file itself** declares in
  its `review-criteria:` frontmatter. On a collision the most specific wins -- file over
  type over global. A `kind: exclude` entry is as binding as a `validate` one: it names
  what you must NOT add.
- **Introducing or retiring a document type owes the KB a registry row.** Adding the first
  file of a new type adds its row and its criteria in the same change; removing the last
  file of a type removes the row. Every in-scope file must resolve to exactly one type.

## Review output format (global)

Any review output you produce — dispatched sub-agent, script validator, or
ad-hoc user-prompted — uses the schema at
`.aid/runtime/templates/reviewer-ledger-schema.md`. Write the ledger as a single
markdown table at `.aid/.temp/review-pending/<scope>.md`. Use the 7-column
shape: `# | Severity | Status | Doc | Line | Description | Evidence`.
Severity tags bracketed; Status enum: Pending/Fixed/Recurred/Accepted/OOS/Invalid.
No narrative or summary sections in the ledger.

## Permissions

- Read any file in the project
- Write only within the project directory
- Run build and test commands (Python, Bash, PowerShell)
- Do NOT modify files outside the project root
