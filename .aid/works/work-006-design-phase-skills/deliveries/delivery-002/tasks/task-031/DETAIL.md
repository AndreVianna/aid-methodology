# task-031: Four `design` grid doorways and rows -- infra, test, document, dashboard

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-031/STATE.md.
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

**Depends on:** task-030

**Scope:**
- Source spec: `features/feature-005-design-grid-and-brainstorm/SPEC.md` §2, §3a, §3b, §6a, §6b,
  §7b and §7c -- the last four members of the positive selection, and the three of its rows that
  carry more than one neighbour. It binds feature-002 §3g's **Class 2** column unchanged.
- Follows task-030 for the same single reason: one catalog file, one append at a time.
- Author four hand-authored bodies --
  `canonical/skills/aid-design-{infra,test,document,dashboard}/SKILL.md` -- on feature-002 §3e's
  shape, structurally identical to task-029's and task-030's: frontmatter (`name` == directory
  name, `description`, `allowed-tools`, `argument-hint`); states
  `INTAKE -> DESIGN -> VERIFY -> PRESENT -> DONE`; allocation through the Work Initiation Gate
  with `pipeline.path: lite`, `initiator: aid-design-<artifact>`, `lifecycle: Running`, **`phase`
  not driven**; `aid-architect` tiered, verifier tier >= producer tier; **full verify**; PRESENT
  a hard stop; DONE `lifecycle: Completed`, seed persists.
- Each body carries feature-005 §6a's binding line to
  `canonical/aid/templates/design-lifecycle.md` and **restates no rule the contract states**.
  §6b's four variations only: the bound pair and `.aid/design/<artifact>.md`, the negative route,
  the `argument-hint` (a subject, never a question), and one to three DESIGN slot hints -- for
  `infra` the resources, their environments and their lifecycle; for `test` the level, the cases
  and the fixtures; for `document` the genre, the audience and the structure; for `dashboard` the
  questions it answers, its panels and its data sources.
- **The three multi-neighbour descriptions** (§7b), all of them naming skills feature-004
  authors later in this delivery:
  - `/aid-design-infra` -> `/aid-create-infra` **and** `/aid-design-cicd` -- designing a resource
    versus designing the pipeline that ships to it.
  - `/aid-design-test` -> `/aid-create-test`, **`/aid-design-testing-strategy`** and
    **`/aid-test`** -- one designs a test, the second designs the policy, the third *runs* suites
    (`canonical/aid/templates/shortcut-catalog.yml:378`).
  - `/aid-design-document` -> `/aid-create-document` **and** bare **`/aid-document`** -- design
    the document versus write it. That trio is one §7c owns end to end, and both counterpart
    sides were written by task-027 and task-028, so it is **mutual at this task's close**.
  Naming a feature-004 skill needs no ordering edge -- a `description` names a skill rather than
  reading its file -- while the two `document` counterparts do sit upstream, which is why this
  task follows them.
- Append four rows to `canonical/aid/templates/shortcut-catalog.yml` in §3a's shape, directly
  after task-030's five and still ahead of the G8 `Document family` comment block:
  `verb: design`, `artifact: infra|test|document|dashboard`, `alias_of: null`,
  `default_type: DESIGN`, `group: G3`, `intent` in the single form §3a fixes on
  `aid-design-api`, `repurpose: true`.
- **`artifact: document` is a `design` row, not a change to the `document` family.** The G8
  collapse skills keep their own `{verb, artifact}` keys; `{design, document}` is a new key and
  collides with none.
- Out of scope: the three stale count comments inside `shortcut-catalog.yml`; the full
  `run_generator.py` render; any further change to `canonical/skills/aid-create-document/SKILL.md`
  or `canonical/skills/aid-update-document/SKILL.md` (task-027 owns both of their edits, and a
  second write there is a defect rather than a duplicate); and every count-bearing assertion.

**Acceptance Criteria:**
- [ ] feature-005 V1, this task's share:
      `ls -d canonical/skills/aid-design-{infra,test,document,dashboard}` returns 4 lines, exit
      0, and each holds a `SKILL.md`. With task-029's five and task-030's five, V1's fourteen
      `design` directories now exist; `/aid-brainstorm` is task-032's
- [ ] `grep -cE '^  - name: aid-design-(infra|test|document|dashboard)$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `4`, and for each, frontmatter `name:` == directory name == row
      `name`
- [ ] Each row carries all eight fields, `default_type: DESIGN`, `group: G3`, `alias_of: null`,
      `repurpose: true`
- [ ] The **fourteen** grid rows are now contiguous and correctly bracketed: every
      `^  - name: aid-design-` line number lies strictly between
      `A = grep -n '^  - name: aid-design$'` and `G = grep -n '^  # --- G8: Document family'`,
      and the count of such lines captured to a variable is `14`
- [ ] feature-005 V15, this task's share:
      `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-design-{infra,test,document,dashboard}/SKILL.md`
      produces **empty** output
- [ ] feature-005 V16, this task's share: a reviewer confirms no body restates the `design`
      invariant, the allocation steps, the seed headings or the verify depth
- [ ] feature-005 V10, this task's share: `aid-design-dashboard` names `/aid-create-dashboard`;
      `aid-design-infra` names `/aid-create-infra` and `/aid-design-cicd`; `aid-design-test`
      names `/aid-create-test`, `/aid-design-testing-strategy` and `/aid-test`;
      `aid-design-document` names `/aid-create-document` and `/aid-document`. **No** description
      names a neighbour §7b does not assign it
- [ ] feature-005 V9 is satisfiable at this task's close and is asserted here:
      `canonical/skills/aid-design-document/SKILL.md` names **both** neighbours, and
      `canonical/skills/aid-document/SKILL.md` and
      `canonical/skills/aid-create-document/SKILL.md` each name `/aid-design-document` -- the
      three hits confirmed inside each file's frontmatter `description:` block
- [ ] Each `argument-hint` names a **subject**, not a question
- [ ] No `intent` value contains a backtick or any other markdown, and its em-dashes are ASCII
      `--`
- [ ] Each body drives no `phase:` value and states that `design` never writes
      `.aid/knowledge/` and never writes production code
- [ ] `git diff --exit-code master -- canonical/skills/aid-create-document/SKILL.md canonical/skills/aid-update-document/SKILL.md`
      shows **only** the hunks task-027 committed -- this task adds none
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean; no count comment inside
      `shortcut-catalog.yml` is edited; `git diff --exit-code -- tests/ site/scripts/__tests__/`
      is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
