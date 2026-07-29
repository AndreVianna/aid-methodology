# task-050: `references/state-gap-report.md`

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

**Type:** IMPLEMENT

**Source:** work-005-knowledge-graph -> delivery-003

**Depends on:** task-007, task-047

**Scope:**
- Create `canonical/skills/aid-graph/references/state-gap-report.md` -- the GAP-REPORT state body,
  owned outright by feature-006 (L1). feature-010 owns the file's `**Advance:**` line and its
  `SKILL.md` Dispatch-table row; the body is this task's. Model its shape on `/aid-summarize`'s
  `canonical/skills/aid-summarize/references/state-*.md` files.
- The body carries feature-006's eight Feature Flow steps in order: (1) enter GAP-REPORT with EMIT's
  postcondition asserted -- `.aid/knowledge/relationships.md` exists and holds the final post-pass-2
  table; (2) load the previous gap ledger from `.aid/.temp/review-pending/graph-kb-gaps.md` if
  present, so only `Status` moves; (3) call the shared predicate over the **full** `nodes.tsv`
  inventory and decorate each returned id with its display name, FR-21 clause and FR-24 evidence;
  (4) write `kb_gaps` into `relationships.md` frontmatter; (5) write the ledger as a single
  seven-column table and nothing else; (6) print the routing block; (7) exit 0, always; (8) advance.
- It **names** the shared predicate the state calls -- `detectKbGaps`, exported from
  `coverage-predicate.mjs` and invoked through `detect-kb-gaps.mjs` -- and **restates no predicate
  logic**. The three coverage conditions appear nowhere in skill prose; there is exactly one
  implementation and this state is not it. `kbUnbacked` is stated as lens-only and is not called
  here.
- It carries the D4 severity rule (`entry-point` / `public-surface` -> `[HIGH]`, `depended-upon` ->
  `[MEDIUM]`, `named-unit` only -> `[LOW]`, highest clause wins, `[CRITICAL]` and `[MINOR]` never
  assigned), the D5 row form (including `Line` = `—` always and the trailing
  `; no relationships in the table` clause for a zero-row node), and the routing block naming
  `/aid-update-kb` and `/aid-housekeep`.
- It carries a **single unconditional** `**Advance:** CHAIN` line to RENDER -- mechanism S3. There is
  no failure branch, no route to FIX, no route to a blocked lifecycle, and no route to a non-zero
  skill exit. Adding one would require editing the Advance line, which is a visible, reviewable
  change. This is a mechanical state with no user interaction, so per
  `.claude/aid/templates/state-machine-chaining.md` §CHAIN it must not pause.
- **Canonical-first.** The file is authored under `canonical/` only. The `profiles/`, `.claude/` and
  `.cursor/` copies are rendered build output and are never hand-edited; the render is task-055.
- Out of scope: the `SKILL.md` Dispatch row and state-map node (**task-051** -- feature-006 L1
  requires that row as its own task precisely so no two tasks edit the same lines of `SKILL.md`);
  the detector scripts (tasks 046 and 047); the predicate module (task-045); the RENDER state body
  (task-066, delivery-004).

**Acceptance Criteria:**
- [ ] `canonical/skills/aid-graph/references/state-gap-report.md` exists and follows the structural
      shape of `/aid-summarize`'s `references/state-*.md` bodies.
- [ ] All eight Feature Flow steps are present, in order, and step 1 states the precondition that
      EMIT has completed so `.aid/knowledge/relationships.md` holds the final post-pass-2 table.
- [ ] The body names `detectKbGaps`, `coverage-predicate.mjs` and `detect-kb-gaps.mjs`, and contains
      **no** restatement of the three coverage conditions -- grep of the file finds no ancestor-path
      rule, no `kb:`-endpoint rule and no `COVERAGE_BEARING` membership rule.
- [ ] `kbUnbacked` is stated as lens-only and explicitly not called in this state.
- [ ] The D4 severity mapping is carried in full, including the highest-clause-wins tie-break and the
      statement that `[CRITICAL]` and `[MINOR]` are never assigned.
- [ ] The D5 seven-column row form is carried, including `Line` = `—` always and the trailing
      `; no relationships in the table` clause for a node appearing in no table row.
- [ ] The routing block is present, names both `/aid-update-kb` and `/aid-housekeep`, and states that
      the skill runs neither and opens no ticket.
- [ ] Step 4 states that `kb_gaps` into `relationships.md` frontmatter is the state's **only** write
      inside `.aid/knowledge/`, and that `relationships.md` is on `/aid-graph`'s own write allowlist
      so AC-13's fence is not tripped.
- [ ] The file carries **exactly one** `**Advance:**` line, reading CHAIN to RENDER, with no
      conditional and no second branch -- grep finds one occurrence.
- [ ] Only the canonical copy is edited: `git status --porcelain` shows no change under `profiles/`,
      `.claude/` or `.cursor/` from this task.
- [ ] All existing canonical suites still pass -- `bash tests/run-all.sh` reports no newly red suite.
- [ ] **The named suites are task-052 and task-053's `tests/canonical/test-graph-gap-ledger.sh`**
      (which asserts the behaviour this prose directs, including `GL07`'s exit-0 contract that
      mechanism S3 depends on) **and task-091's `tests/canonical/test-graph-skill-registration.sh`**
      in delivery-006 (which compares every rendered tree to the canonical source). *This replaces
      IMPLEMENT's "unit tests for all new public methods" default, which has no vehicle for skill
      prose: the `tests/canonical/test-*.sh` suites are the only vehicle, and the one-type-per-task
      rule forces them into separate TEST tasks.*
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
