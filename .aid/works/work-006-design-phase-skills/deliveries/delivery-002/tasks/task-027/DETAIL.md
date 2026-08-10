# task-027: The `document` pair's two hand-authored seed reads and its routing clause

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-027/STATE.md.
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

**Depends on:** task-026

**Scope:**
- Source spec: `features/feature-005-design-grid-and-brainstorm/SPEC.md` §4b (the one paired
  artifact the engine does not reach, and the one-line read that closes it), §7a's
  `aid-create-document` row (the routing clause), and §1's table rows `c` and `d`. It follows
  task-026 because the two lines here **mirror** the engine bullet's three properties and must
  not diverge from the text that fixes them.
- **Why these two files at all.** Thirteen of the fourteen paired artifacts reach the seed
  through task-026's engine bullet. `document` does not: `aid-create-document` and
  `aid-update-document` are the `repurpose: true` G8 collapse skills
  (`canonical/aid/templates/shortcut-catalog.yml:459-474`) and never execute
  `shortcut-engine.md`. Left implicit, AC-7 would be **false for one of the fourteen while
  appearing satisfied** -- which is the whole reason feature-005 §4b exists.
- Add the equivalent one-line read to both bodies, phrased for their own flow and carrying the
  same three properties (**conditional**, **non-mutating**, **additive**): *"If
  `.aid/design/document.md` exists, read it as prior context before drafting; it is an input,
  never a substitute, and is not modified by this run."*
- **Where "before drafting" is, concretely.** Both bodies run `## State: INTAKE` ->
  `## State: AUTHOR`, so the read is a new final numbered step of **INTAKE** in each:
  `canonical/skills/aid-create-document/SKILL.md` after its step 5 (INTAKE at `:40`, AUTHOR at
  `:66`) and `canonical/skills/aid-update-document/SKILL.md` after its step 4 (INTAKE at `:32`,
  AUTHOR at `:55`). Placing it in AUTHOR would put the read after the state that drafts.
- Add the routing clause to `canonical/skills/aid-create-document/SKILL.md`'s frontmatter
  `description:` block (`:1-15` today, delimited by the two `---` lines) naming
  `/aid-design-document` -- feature-005 §7a assigns it here rather than to task-028 precisely
  because this file is already in this task's change set, so the edit adds no new file.
- Out of scope: `canonical/skills/aid-document/SKILL.md`'s own route to `/aid-design-document`
  (task-028 owns it, and the two texts must agree in substance); any other change to these two
  bodies -- feature-005 §1 permits **only** the seed read and this routing clause, and calls
  neither a rewrite; and the other 26 paired `create`/`update` doorways, which this delivery
  does not touch at all.

**Acceptance Criteria:**
- [ ] feature-005 V12, this task's share:
      `grep -l '\.aid/design/document\.md' canonical/skills/aid-create-document/SKILL.md canonical/skills/aid-update-document/SKILL.md`
      lists **both** files
- [ ] Each read sits in INTAKE, not AUTHOR. Per file, capture
      `I = grep -n '^## State: INTAKE'`, `L = grep -n '\.aid/design/document\.md'` and
      `A = grep -n '^## State: AUTHOR'`, and assert `I < L < A`
- [ ] Each read carries all three properties in its own text: it is conditional on the file
      existing, it says the seed is an **input, never a substitute**, and it says the run does
      **not modify** it. A line that only names the path fails this criterion
- [ ] Additive and bounded, per file: `git diff --numstat master -- <file>` shows **0
      deletions** for `canonical/skills/aid-update-document/SKILL.md`, and for
      `canonical/skills/aid-create-document/SKILL.md` any deletion is confined to the
      frontmatter `description:` block that the routing clause rewords. Non-zero deletions in
      the body of either file mean an existing step was altered, which feature-005 §1 forbids
- [ ] `aid-create-document`'s `description:` names `/aid-design-document` **inside** the
      frontmatter block: with `F = ` the line number of the closing `---` of the frontmatter
      (today `:15`), the `aid-design-document` hit's line number is `< F`. A hit in the body
      would satisfy a bare `grep -q` and leave the published description unchanged
- [ ] Neither body's `name:` changes and neither loses its `repurpose` status: after this task
      `grep -c '^name: aid-create-document$'` and `grep -c '^name: aid-update-document$'` each
      return `1`, and the two catalog rows still carry `repurpose: true`
- [ ] `canonical/skills/aid-document/SKILL.md` is **not** touched here:
      `git diff --exit-code master -- canonical/skills/aid-document/SKILL.md` is clean at the
      end of this task. A second writer on that file would be a defect, not a duplicate
- [ ] `git diff --exit-code -- tests/ site/scripts/__tests__/` is clean and
      `git status --porcelain profiles/ .claude/ .cursor/` is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
