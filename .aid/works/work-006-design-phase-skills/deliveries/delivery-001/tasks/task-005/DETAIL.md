# task-005: Shipped-footprint audit of the lifecycle machinery over its own commit range

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-005/STATE.md.
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

**Type:** TEST

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-004

**Scope:**
- Source spec: `features/feature-002-design-lifecycle-machinery/SPEC.md` §7 G3, §7 B4,
  AC-11; BLUEPRINT § Gate Criteria, criterion 2. This task closes feature-002's block and
  is the reason tasks 001-004 are ordered first in the delivery.
- Establish and **record** feature-002's commit range -- `<first-parent-before>..<last>`
  over the task-001..task-004 block -- as two commit shas in this task's STATE.md notes, so
  the delivery gate and delivery-003 can re-evaluate criterion 2 without re-deriving it.
- Run the scoped diff
  `git diff --name-status <first-parent-before>..<last> -- lib/ canonical/ install.sh install.ps1`
  and assert its content. A branch-wide diff is explicitly **not** used: this delivery also
  carries feature-001 (which edits `concern-model.md`, `domain-doc-matrix.md`,
  `document-expectations.md` and both `kb-*.sh` twins) and feature-003 (which adds nine
  `canonical/skills/*/SKILL.md` files), so a branch-wide diff makes the criterion
  meaningless.
- Run §7 B4 against a scratch install target: after a fresh install with no `design`-stage
  run, the target has no `.aid/design/`.
- Reconcile feature-002 §7's rows: state, row by row, which are evaluated here, which were
  evaluated in tasks 001-004, and which are deferred with the task or delivery that carries
  them -- so no row is silently dropped.
- Out of scope, each named with its evaluator so the reconciliation is complete rather than
  partial: §7 **I1** (the `profiles/` half of the footprint) and the fifteen renders --
  feature-006's single render, delivery-003; §7 **B2 part (a)** -- it needs a rendered tree,
  and is asserted by task-024 over the delivery's throwaway local render; §7 **B2 part (b)**,
  **B3** and **E1** -- they need skills that do not exist until task-010..task-013, and are
  exercised in task-016; §7 **E3** -- it needs `/aid-update-mvp`, authored in task-014, and
  is exercised in task-022; §7 **E2** -- feature-004's, delivery-002; §7 **G1** (bare `/aid-design`'s
  scoped frontmatter diff) -- feature-005 makes that edit, so it is **delivery-002**, where
  PLAN.md gives feature-002 AC-9 its gate criterion; §7 **H1** (the count sweep's completion
  oracle) -- feature-006's, delivery-003.

**Acceptance Criteria:**
- [ ] §7 G3: over the recorded range with the path filter `-- lib/ canonical/ install.sh
      install.ps1`, `git diff --name-status` shows **exactly three `A` entries** --
      `canonical/aid/templates/design-{lifecycle,seed,folder-readme}.md` -- and **no `M` and
      no `D` entry at all**
- [ ] The range is recorded as two shas and the diff is reproducible from that record; the
      recorded range contains only tasks 001-004's commits
- [ ] `profiles/` is deliberately outside the path filter and the reason is recorded: the
      fifteen renders are feature-006's, and that render also rewrites the five
      `profiles/*/emission-manifest.jsonl` build indexes, which are generated, excluded from
      every install and release path, and would otherwise make "no `M` entry at all" false by
      construction
- [ ] §7 B4: after a fresh install into a scratch target with no `design`-stage run,
      `test ! -d "$TARGET/.aid/design"` succeeds
- [ ] `git diff --name-only <first-parent-before>..<last> -- tests/ site/ .github/` returns
      **nothing** -- the range goes inside the command, since `git diff --exit-code -- <paths>`
      takes no range and compares the working tree to the index instead. feature-002 adds no
      bash assertion id and forces no `coverage-parity` re-bootstrap (§2d, rejected
      alternative, ground 3)
- [ ] `git status --porcelain profiles/ .claude/ .cursor/` is clean
- [ ] Every feature-002 §7 row is accounted for: evaluated here, evaluated in tasks 001-004,
      or named with the task/delivery that evaluates it (TEST default -- all acceptance
      criteria from the source feature covered)
- [ ] Tests are deterministic and setup/teardown is clean: the scratch target is created
      under `mktemp -d` and removed on exit including on failure, and no assertion depends
      on execution order or a previous run's residue
- [ ] All section-6 quality gates pass
