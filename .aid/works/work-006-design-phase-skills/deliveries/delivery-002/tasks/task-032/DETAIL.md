# task-032: `/aid-brainstorm` -- the exploratory doorway and its new-verb row

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-032/STATE.md.
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

**Depends on:** task-031

**Scope:**
- Source spec: `features/feature-005-design-grid-and-brainstorm/SPEC.md` §5a (why a new skill
  rather than a mode of `/aid-research`), §5b (row, doorway, allocation, the artifact-less
  naming rule), §5c (not in the pipeline), §6a and §6b (the body and the three places it differs
  from the fourteen), §7b's last row. It binds feature-002 §3g's **`/aid-brainstorm`** column --
  which differs from Class 2 in exactly three cells: the confirmed-slug name, an **optional**
  `## Destination`, and no `create` counterpart to route to.
- Follows task-031 for one reason: the shared catalog file.
- Author `canonical/skills/aid-brainstorm/SKILL.md` on feature-002 §3e's shape: frontmatter
  (`name: aid-brainstorm`, `description`, `allowed-tools`, `argument-hint`); states
  `INTAKE -> DESIGN -> VERIFY -> PRESENT -> DONE`; allocation through the Work Initiation Gate
  with `pipeline.path: lite`, `initiator: aid-brainstorm`, `lifecycle: Running`, and **`phase`
  not driven**; `aid-architect` tiered by complexity with verifier tier >= producer tier;
  **full verify**; PRESENT a hard stop; DONE `lifecycle: Completed` with the seed persisting.
- **It allocates a `work-NNN` folder like every other skill in this family.** feature-005 §5b
  records and corrects an earlier draft that said otherwise: REQUIREMENTS FR-3 defines these
  skills as taking *"the same shape `/aid-design` and `/aid-prototype` already have: allocate a
  `work-NNN` folder, run single-shot, get graded"*, and feature-002 §6 records that the two
  specs now agree. The seed being the whole deliverable does not remove the folder -- the folder
  is where `STATE.md` and the review gate live.
- **The seed path uses the artifact-less rule, and that is the one place the body genuinely
  differs.** `artifact` is `""`, so feature-002 §4's `<token>` = `artifact` rule does not apply:
  the output is `.aid/design/<slug>.md` with a kebab-case slug derived from the subject and
  **confirmed with the user at INTAKE**. `## Destination` is **optional** in the seed, because
  FR-7 gives `/aid-brainstorm` no fixed destination.
- Append one row to `canonical/aid/templates/shortcut-catalog.yml`, verbatim in §5b's shape:
  `name: aid-brainstorm`, `verb: brainstorm`, `artifact: ""`, `alias_of: null`,
  `default_type: DESIGN`, `group: G3`,
  `intent: "Diverge on an unformed problem, then converge to a .aid/design/ seed; resolves nothing."`,
  `repurpose: true`. Placed after task-031's `aid-design-dashboard` row and still ahead of the
  G8 `Document family` comment block, so feature-004's four foundation `design` rows (task-033)
  still land after all fourteen grid rows as feature-004 §1b requires.
- **`brainstorm` is a new verb, with two consequences both already verified in the spec.**
  `site/scripts/skills/groups.mjs` derives families by walking `catalog.rows` in file order and
  appending each newly-seen verb (the loop at `:254-262`), and `aid-brainstorm` is not in
  `CURATED_GROUPS` (`:63` onward), so a one-card `brainstorm` section appears on the published
  index with **no code change**; single-card families are the norm. And the engine's verb ->
  family table gains **no** `brainstorm` entry, for the same `repurpose` reason task-026's
  `query`-paragraph edit records.
- Out of scope: any `phase:` enum value or pipeline step (§5c -- it is an on-demand skill, and
  feature-006's closing sweep is the oracle); any `shortcut-scaffolding/` file; any edit to
  `canonical/skills/aid-research/SKILL.md`, whose `/aid-brainstorm` side task-028 already wrote
  -- a second write there is a defect, not a duplicate; the three stale catalog count comments;
  the render; and every count-bearing assertion, `check-skill-counts.mjs` included.

**Acceptance Criteria:**
- [ ] feature-005 V1's last line: `ls -d canonical/skills/aid-brainstorm` succeeds and the
      directory holds a `SKILL.md`; with task-029..031 the row's fifteen directories now exist
- [ ] `grep -cE '^  - name: aid-brainstorm$' canonical/aid/templates/shortcut-catalog.yml`
      captured to a variable -> `1`, and frontmatter `name:` == directory name == row `name`
- [ ] The row carries all eight fields exactly as §5b prints them, including `artifact: ""`,
      `verb: brainstorm`, `group: G3`, `default_type: DESIGN` and `repurpose: true`
- [ ] Placement: the row's line number lies strictly between
      `D = grep -n '^  - name: aid-design-dashboard$'` and
      `G = grep -n '^  # --- G8: Document family'`
- [ ] feature-005 V7 is satisfiable at this task's close and is asserted here:
      `grep -q 'aid-brainstorm' canonical/skills/aid-research/SKILL.md` **and**
      `grep -q 'aid-research' canonical/skills/aid-brainstorm/SKILL.md`, both hits inside the
      respective frontmatter `description:` block. task-028 wrote the `aid-research` side
- [ ] feature-005 V11 (AC-2): the `argument-hint` names a **subject**, not a question, **and**
      INTAKE has no step that refuses on a non-question argument. Both halves are readings of the
      authored body -- "names a subject, not a question" is a judgement no grep settles -- so
      both are recorded as reviewer findings with the text quoted
- [ ] feature-005 V15/V16, this task's share:
      `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-brainstorm/SKILL.md`
      is empty, and a reviewer confirms the body restates none of the contract's rules
- [ ] The body allocates a `work-NNN` folder through the Work Initiation Gate and says so, and
      drives **no** `phase:` value
- [ ] The artifact-less naming rule is written out, not implied: the body states that the output
      is `.aid/design/<slug>.md` with the kebab-case slug **confirmed with the user**, and that
      `## Destination` is optional
- [ ] `test ! -f canonical/aid/templates/shortcut-scaffolding/brainstorm.md`, and the engine's
      verb -> family table carries no `brainstorm` row
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean; no count comment inside
      `shortcut-catalog.yml` is edited; `git diff --exit-code -- tests/ site/scripts/__tests__/`
      is clean
- [ ] Accuracy verified against the current codebase (DOCUMENT type default)
- [ ] All section-6 quality gates pass
