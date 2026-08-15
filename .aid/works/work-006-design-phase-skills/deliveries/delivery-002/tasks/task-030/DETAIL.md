# task-030: Five `design` grid doorways and rows -- data-pipeline, messaging, integration, job, config

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-030/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-002

**Depends on:** task-029

**Scope:**
- Source spec: `features/feature-005-design-grid-and-brainstorm/SPEC.md` §2, §3a, §3b, §6a, §6b,
  §7b -- the same rules task-029 binds, over the next five members of the positive selection.
  It binds feature-002 §3g's **Class 2** column unchanged.
- **Why it follows task-029 rather than running beside it.** Both append to the single file
  `canonical/aid/templates/shortcut-catalog.yml`. Two concurrent appends to one file is the
  hazard the writer chain exists to prevent; the five bodies themselves are disjoint from
  task-029's five.
- Author five hand-authored bodies --
  `canonical/skills/aid-design-{data-pipeline,messaging,integration,job,config}/SKILL.md` -- on
  feature-002 §3e's shape, identical in structure to task-029's five: frontmatter (`name` ==
  directory name, `description`, `allowed-tools`, `argument-hint`); states
  `INTAKE -> DESIGN -> VERIFY -> PRESENT -> DONE`; allocation through the Work Initiation Gate
  with `pipeline.path: lite`, `initiator: aid-design-<artifact>`, `lifecycle: Running`, and
  **`phase` not driven**; `aid-architect` tiered by complexity with verifier tier >= producer
  tier; **full verify**; PRESENT a hard stop; DONE `lifecycle: Completed` with the seed
  persisting (feature-002 §2c Entry C).
- Each body carries feature-005 §6a's binding line -- *"Bind **VERB=`design`**,
  **ARTIFACT=`<artifact>`** ... then follow the shared contract at
  `canonical/aid/templates/design-lifecycle.md`"* -- and **restates no rule the contract
  states**. Only §6b's four things vary: the bound pair and its seed path
  `.aid/design/<artifact>.md`, the `description`'s negative route, the `argument-hint` (a
  subject, never a question), and one to three lines of artifact-specific slot hints in DESIGN
  -- for `data-pipeline` the sources, the transform stages and the failure/replay behavior; for
  `messaging` the topics, the message contract and the delivery semantics; for `integration` the
  external system, the direction and the failure mode; for `job` the trigger, the schedule and
  idempotence; for `config` the keys, their defaults and where they are read.
- Append five rows to `canonical/aid/templates/shortcut-catalog.yml` in §3a's shape, **directly
  after task-029's five** and still ahead of the G8 `Document family` comment block: `name` ==
  directory, `verb: design`, `artifact: data-pipeline|messaging|integration|job|config`,
  `alias_of: null`, `default_type: DESIGN`, `group: G3`, the `intent` string, `repurpose: true`.
- **`intent` follows the single form feature-005 §3a fixes** on `aid-design-api` -- *"Develop
  a{n} <artifact> design in .aid/design/ before building it; writes a seed, builds nothing."* --
  with the artifact's own noun substituted. No row departs from it.
- **`/aid-design-config` carries one extra neighbour**, `/aid-design-stack` (feature-004,
  authored by task-033): configuring a stack versus choosing one. feature-004 §10's
  `aid-design-stack` row names `/aid-design-config` back, so the pair becomes mutual when
  task-033 lands; naming the counterpart here needs no ordering edge, because a `description`
  names a skill rather than reading its file.
- Out of scope: the three stale count comments inside `shortcut-catalog.yml` (delivery-003's);
  the full `run_generator.py` render (delivery-003's single run, C-5); any change to the paired
  `create`/`update` doorways for these five artifacts (feature-005 §1); and every count-bearing
  assertion.

**Acceptance Criteria:**
- [ ] feature-005 V1, this task's share:
      `ls -d canonical/skills/aid-design-{data-pipeline,messaging,integration,job,config}`
      returns 5 lines, exit 0, and each holds a `SKILL.md`
- [ ] `grep -cE '^  - name: aid-design-(data-pipeline|messaging|integration|job|config)$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `5`, and for each of the five, frontmatter `name:` == directory
      name == row `name`
- [ ] Each row carries all eight fields, with `default_type: DESIGN` from the closed 8-enum
      (enforced at `.claude/skills/generate-profile/scripts/build-shortcut-skills.py:219-224`)
      and `group: G3`
- [ ] `repurpose: true` on all five. It is the one field the parser does not enforce
      (that same file's `:354` reads it with `r.get("repurpose", False)`), so its byte-identity
      oracle is task-039's
- [ ] Placement: every new row's line number lies strictly between
      `A = grep -n '^  - name: aid-design$'` and `G = grep -n '^  # --- G8: Document family'`,
      and **after** all five of task-029's rows -- so the fourteen stay contiguous ahead of
      task-033's four foundation rows (feature-004 §1b)
- [ ] feature-005 V15, this task's share:
      `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-design-{data-pipeline,messaging,integration,job,config}/SKILL.md`
      produces **empty** output
- [ ] feature-005 V16, this task's share: a reviewer confirms no body restates the `design`
      invariant, the allocation steps, the seed headings or the verify depth
- [ ] feature-005 V10, this task's share: each `description` names `/aid-create-<artifact>`,
      `aid-design-config` **additionally** names `/aid-design-stack`, and **no** description
      names a neighbour §7b does not assign it
- [ ] Each `argument-hint` names a **subject**, not a question, and each INTAKE requires a
      subject
- [ ] No `intent` value contains a backtick or any other markdown, and its em-dashes are ASCII
      `--`
- [ ] Each body drives no `phase:` value and states that `design` never writes
      `.aid/knowledge/` and never writes production code
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean; no count comment inside
      `shortcut-catalog.yml` is edited; `git diff --exit-code -- tests/ site/scripts/__tests__/`
      is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
