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

- Match a request by its meaning to the skill guide below. A question about this project starts no work: answer it from the Knowledge Base, citing sources.
- One skill fits. Only `/aid-ask`, `/aid-research`, `/aid-review`, `/aid-report`, `/aid-monitor` and `/aid-read-ticket` start at once, and only when
  the user's words ask for exactly that action: say so in one line, run it before investigating or asking. That skips only the go-ahead: its own
  intake questions and approvals still come, in the form and recorded. Every other skill: run `/aid-orchestrate` first, before any question; it
  asks the one confirmation question; no project file changes until the user agrees. Several fit: choose, asking once if you can't. None: carry on.
- The richness check sets the depth: any of its five elements missing means `full`. No step of the chosen workflow is skipped; the reading picks its
  phases, and nothing runs by hand outside it. After the yes or the one-line start, run the skill by its slash command or the Skill tool.
- A typed `/aid-<skill>` always wins. Every other request that changes the project, or starts, resumes ("carry on" too), closes or cancels a work,
  goes through `/aid-orchestrate` first, before you read the work's files. A finished work is only reported: no reopen, no old questions.
- Your reading takes the user's words as a hint only: check it against the Knowledge Base and the code, then show it and its reason in one line,
  inside the first question or approval and wait, or in the one-line start and go on.
- CI closes each work: `/aid-orchestrate` marks it `Completed` once all its tasks are `Done`, or when nothing was to land. Definition runs only when
  the problem must be shaped; release, deploy, monitoring are works of their own.
- A Knowledge Base conflict (a request that would make a KB statement false): quote it, raise it, plan nothing on it until answered. A ticket, file or
  link brought into a work is added to its `sources:` before it is applied. If the work grows or changes, re-route it and say so in one line.
- A review never turns into a fix: after `/aid-review` or a review the user asks for, offer none; a fix needs their own new request and confirmation.
- Ask only as `.aid/runtime/templates/question-protocol.md` says; the user approves before building and the result. AID never merges, even when the
  user asks: the merge is the user's own step, and no merge is offered for later.

## Asking the user

Every question to the user follows `.aid/runtime/templates/question-protocol.md`. In short:

- A question is any message that waits on the user's reply, a go-ahead, a clarification and "what next" included.
- One question per message, on one topic. Never put two questions in one message.
- Write for the lower technical level: when the user writes in plain words, keep file paths, code names and technical
  walkthroughs out of every message; say what happens and what it means for them, unless they ask for more.
- Record it before you show it, `Pending`, where the protocol's "Where each record lives" says (for a
  work, `writeback-state.sh --ask`), and record the reply with `--answer`. Before a work exists we are in
  the design stage: every question asked then, with its answer, is recorded in a design document under
  `.aid/design/` (`--ask --design`), and a build skill takes that document into the work it opens.
- Show it in this form, in plain text, never through the host tool's question picker:

```text
{subject} -- question {n} of {m} -- importance: {high|medium|low}
{the question, short and plain}
Why I ask: {one short reason}
My recommendation: {the answer you propose, and why}
  1. {option} (recommended)
  2. {option}
Or answer in your own words, ask me to explain, or skip this question.
```

- An approval ends with the other closing line, `Or answer in your own words, or ask me to explain.`, with no skip. An approval is a yes
  that lets the agent change, build, delete, publish or push something, or that approves a document or design. A question that changes
  nothing when skipped, such as a reopen or close menu, is a plain question and ends with the skip line.
- List options only when two or more are valid, the recommended one first; with one valid option, ask
  for a confirmation instead. An approval cannot be skipped.
- Before you end a turn that waits on the user, check the message: the first line with its importance, `Why I ask`,
  `My recommendation`, the right closing line, and the `--ask` record already written. A closing or follow-up question ("Your call",
  "which would you like?", "shall I go on?") is a question like any other: the second and the last as much as the first. The exceptions are
  the break offer and the confirmations the protocol leaves unrecorded (recovery, cancel); a skill with no writer for its place records
  where the protocol says, or says it cannot.
- Group questions by subject, most important first, and offer a break when the subject changes.

## Skill guide

One line per skill: what it is for; when to use it. `<kind>` stands for each kind that
`.aid/runtime/templates/shortcut-catalog.yml` lists for that action.

### Phase skills

- `/aid-discover` -- build the Knowledge Base from existing code; when a project has none yet
- `/aid-describe` -- gather the requirements by interview; when a new work needs them written
- `/aid-define` -- split approved requirements into features; after the requirements are approved
- `/aid-specify` -- write a feature's technical specification; after the features are defined
- `/aid-plan` -- group the specified features into deliveries; after the specifications are approved
- `/aid-detail` -- break a delivery into small typed tasks; after the plan is approved
- `/aid-execute` -- carry out and review each planned task; when a delivery's tasks are ready
- `/aid-deploy` -- package completed deliveries into a release; when deliveries are ready to ship
- `/aid-monitor` -- watch production and route what it finds; after a release, or when it misbehaves

### Knowledge Base skills

- `/aid-ask` -- answer a question about the project, with sources; when the user asks one
- `/aid-update-kb` -- apply one confirmed change to the Knowledge Base; when a fact changes
- `/aid-summarize` -- build `kb.html`, the Knowledge Base web view; when someone wants to read it
- `/aid-housekeep` -- re-sync drifted docs and sweep stale works; when the project has drifted

### Supporting skills

- `/aid-orchestrate` -- start, resume, close or cancel a work; when a plain request asks for one
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
