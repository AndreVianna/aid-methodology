# rules.md inventory (criterion C5)

Old file: 115 lines (`canonical/aid/rules.md` on master). New file: 60 lines. Every sentence of the old file is mapped
below to its new line(s) in `canonical/aid/rules.md` (section and bullet), or to the file that now holds it.
"Kept" means the rule is in the new file, shortened. Nothing is moved into a work folder.

| # | Old lines | Old rule or sentence | Now |
|---|---|---|---|
| 1 | 1-3, 12 | `## Summary` heading and the `AID:SUMMARY` markers | Kept unchanged (installer lifts the bullets into `AGENTS.md` / `CLAUDE.md`) |
| 2 | 4-5 | Record every state change in the STATE file immediately; during /aid-execute write In Progress, In Review, Done/Failed | Summary bullet 3, shortened ("`/aid-execute` included"); full rule in Tracking discipline bullets 1-2 |
| 3 | 6 | Work folders are transient: nothing permanent may depend on them | Summary bullet 4; Tracking discipline bullet 3 |
| 4 | 7 | Never name a work id or work-folder path in `.aid/knowledge/**` | Summary bullet 4 (merged with row 3); Tracking discipline bullet 4 |
| 5 | 8 | Consult the KB before changing anything; it is the source of truth | Summary bullet 2; Knowledge Base section |
| 6 | 9 | Resolve and follow a file's review criteria before writing | Summary bullet 5; Review criteria section |
| 7 | 10 | Review output uses the 7-column ledger | Summary bullet 6; Review criteria section, last sentence |
| 8 | 11 | Write only inside the project directory | Summary bullet 7; Permissions |
| 9 | (new) | Read the project card first, open `INDEX.md` only to find a specific document (replaces "Read `.aid/knowledge/INDEX.md`", old line 61) | Summary bullet 1; Knowledge Base section |
| 10 | 16-18 | Every project, task and deliverable is tracked in a state file (work STATE, plus `.aid/knowledge/STATE.md`); keeping it current is not optional | Tracking discipline intro. `STATE.md` of the work corrected to `STATE.yml`, the file the work-state template produces |
| 11 | 20-23 | ANY change of status, phase, grade, review outcome or artifacts is written IMMEDIATELY, in the same action; untracked work is incomplete | Tracking discipline bullet 1. The sentence "Untracked work is incomplete work" is dropped: it restates the rule it ends |
| 12 | 24-25 | Binds EVERY agent, skill or direct prompt, FULL or LITE path | Tracking discipline bullet 1 |
| 13 | 26-27 | No tracking file yet: create it first from the work-state template | Tracking discipline bullet 1 |
| 14 | 28-33 | During /aid-execute, `State` is written the instant it changes: In Progress, In Review, Done/Failed; Blocked is orchestrator-assigned to a downstream task, never self-written | Tracking discipline bullet 2; the full protocol is in `task-state-template.yml` (header comment) and `aid-execute/references/state-execute.md` (State-Write Protocol) |
| 15 | 33-36 | Binds whoever executes the task, the orchestrator executing it directly included, with no exception or bypass | Tracking discipline bullet 2 ("Its executor, orchestrator included, writes these itself") |
| 16 | 36-38 | A task at Pending for its whole run, then straight to Done, is the failure this rule prevents | Moved: the same rationale is the opening note of `aid-execute/references/state-execute.md` (State-Write Protocol); the rule it justifies stays in Tracking discipline bullet 2 |
| 17 | 39-41 | Work folders are transient, hold disposable per-work state, may be pruned | Tracking discipline bullet 3 |
| 18 | 41-44 | No permanent artifact (code, shared source or its render, tests, docs, KB, context files) may depend on a work folder's contents; tests build their own fixtures | Tracking discipline bullet 3 (artifact list shortened); also `authoring-conventions.md` § No Work References |
| 19 | 44-45 | The KB never cites a work folder as a source | Tracking discipline bullet 4; `authoring-conventions.md` § No Work References |
| 20 | 44-45 | Pipeline skills and scripts that use work folders as live state are exempt | Tracking discipline bullet 3 |
| 21 | 46-48 | `.aid/knowledge/**` holds no work id and no work-folder path, in prose, tables, headings or frontmatter; the `work-042` examples | Tracking discipline bullet 4; the where-it-applies list and the examples are in `authoring-conventions.md` § No Work References and enforced by `tests/canonical/test-kb-no-work-ids.sh` |
| 22 | 49-52 | Two reasons (dangling pointer once the work ships; the KB states current state, not history); cite the durable artifact the work left on disk | Moved: `authoring-conventions.md` § No Work References (new section). Tracking discipline bullet 4 keeps the "cite the durable artifact" instruction and points there |
| 23 | 52-55 | A KB doc carries no `## Change Log` / `## Revision History` section and no `changelog:` field; git records history | Tracking discipline bullet 4; `authoring-conventions.md` § KB Document Layout and § No Work References |
| 24 | 55-56 | The rule binds `.aid/knowledge/` alone; skills, templates and pipeline scripts name works legitimately | Tracking discipline bullet 4 (last sentence); `authoring-conventions.md` § No Work References |
| 25 | 60 | "This project uses the AID methodology" with its link | Knowledge Base section, unchanged |
| 26 | 61 | Read `.aid/knowledge/INDEX.md` | Replaced by row 9 |
| 27 | 62 | Always consult relevant KB documents before making changes | Knowledge Base section |
| 28 | 63 | The KB is the single source of truth for architecture, conventions and patterns | Knowledge Base section |
| 29 | 67 | Read `.aid/connectors/INDEX.md` | Connectors section, unchanged |
| 30 | 69-70 | Connectors are catalogued via `aid-discover` (ELICIT) and changed on demand, without re-running discovery, with `aid-set-connector` / `aid-unset-connector` | Connectors bullet 1 ("add, update or remove" shortened to "change") |
| 31 | 71-73 | Consumption is MCP-first (consumption-protocol path); for a `connection_type: mcp` connector request the connection from the host tool's MCP/plugin; AID resolves nothing and stores no credential | Connectors bullet 2. "Shared by all tools" and "scan the index" are dropped: the first restates what the protocol file says of itself, the second is the "Read ... INDEX.md" line above |
| 32 | 74-75 | aid-managed consumption (`api` / `ssh` / `url` / `cli`) is deferred; descriptors serve discovery and audit only | Connectors bullet 3 |
| 33 | 79 | Every change should be traceable to a task or requirement | Workflow bullet 1 |
| 34 | 80 | Follow the numbered phases Discover to Execute; the sequence ends at Execute; `aid-config` bootstraps before; Deploy and Monitor are optional, separately invoked Deliver paths, not steps in the sequence | Workflow bullet 2 ("not steps in the sequence" dropped: "optional, separately invoked" says it) |
| 35 | 81 | Produce verifiable artifacts at each phase | Workflow bullet 1 |
| 36 | 82 | Quality gates must pass before proceeding | Workflow bullet 1 |
| 37 | 86-88 | Criteria are the writer's contract, not the reviewer's checklist; before authoring or editing any file resolve its review criteria and comply; the reviewer is the backstop, not the enforcer | Review criteria section, first sentences |
| 38 | 90-95 | Satisfy the union of the global, document-type and file criteria (type registry and criteria tables in `authoring-conventions.md`; `review-criteria:` frontmatter); the most specific wins; a `kind: exclude` entry binds like a `validate` one (it names what you must NOT add) | Review criteria section; the collision rule and the `exclude` semantics are stated in `authoring-conventions.md` § Review Criteria |
| 39 | 96-98 | Introducing or retiring a document type owes the KB a registry row (first file adds it with its criteria; last file removes it); every in-scope file resolves to exactly one type | Review criteria section (the add/remove detail is `authoring-conventions.md` § Review Criteria, criterion `G-07`) |
| 40 | 102-103 | Any review output (sub-agent, script validator, ad-hoc) uses the ledger schema file | Review criteria section, last sentence |
| 41 | 104-105 | One markdown table at `.aid/.temp/review-pending/<scope>.md` | Review criteria section, last sentence |
| 42 | 105-106 | The 7-column shape `# \| Severity \| Status \| Doc \| Line \| Description \| Evidence` | Moved: `reviewer-ledger-schema.md` (File: contents) |
| 43 | 107 | Severity tags bracketed; Status enum Pending/Fixed/Recurred/Accepted/OOS/Invalid | Moved: `reviewer-ledger-schema.md` (criteria F-02 and F-03) |
| 44 | 108 | No narrative or summary sections in the ledger | Review criteria section, last sentence ("with no narrative") |
| 45 | 112 | Read any file in the project | Permissions |
| 46 | 113 | Write only within the project directory | Permissions; Summary bullet 7 |
| 47 | 114 | Run build and test commands (Python, Bash, PowerShell) | Permissions |
| 48 | 115 | Do NOT modify files outside the project root | Dropped: duplicate of row 46 |

## Section headings

`## Review output format (global)` is merged into `## Review criteria (before you write)`; the other headings
(`Summary`, `Tracking discipline (IMPERATIVE)`, `Knowledge Base`, `Connectors`, `Workflow`, `Permissions`) are kept, because
the installer's tests and the connector structure tests look for `## Connectors` and `## Workflow`.

## New in the project card (criterion C6)

The card `.aid/knowledge/PROJECT.md` is a new rule carrier, not a move: it holds this repo's commands and its nine
non-negotiable rules, each pointing at its check or KB document. Its template is `canonical/aid/templates/project-card.md`.
