# task-093: FR-28 full-rubric run over both artifacts

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

**Source:** work-005-knowledge-graph -> delivery-006

**Depends on:** task-084, task-086

**Scope:**
- Run feature-010's FR-28 rubric (§ D4) in full for the first time, over **both** artifacts.
  `grade-graph.sh` (task-029) orchestrates the whole D4 table over the reused leaf validators; in
  delivery-002 only the `R*` data checks had an artifact to run against, so the first-run subject
  here is the `R*` rows **plus** the view rows `V-A`, `V-C` and `V-T`, which had none.
- **The data checks over `.aid/knowledge/relationships.md`:** `R1` id resolvability `[HIGH]`,
  `R2` inverse-pair consistency `[HIGH]`, `R3` no duplicate relationship `[MEDIUM]`, `R4`
  provenance population `[HIGH]`, `R5` frontmatter validity `[HIGH]`.
- **The view checks over `.aid/knowledge/graph.html`:** `V-A` accessibility baseline
  (`validate-html-output.sh` A1-A5, `[MEDIUM]`), `V-C` contrast in both themes
  (`contrast-check.mjs`, `[MEDIUM]`), and `V-T` visual fidelity (`validate-visuals.mjs` T1-T4,
  with T1, T3 and T4 at `[HIGH]` and T2 alone at `[MEDIUM]`, because T2 means content is present
  but crowded while the other three mean content is not available).
- **It scores the skill's own artifacts only, never the Knowledge Base's completeness (FR-28).**
  There is no `COV` analogue and no rubric row whose subject is the Knowledge Base. The omission
  is structural, not disciplinary: the gap count lives in a different ledger file
  (`graph-kb-gaps.md`) that no grading state ever passes to `grade.sh`, so the gate cannot reach
  it.
- **The grade model.** Every failed check becomes a `Pending` row in
  `.aid/.temp/review-pending/graph.md`; a passing check adds no row. `grade.sh` -- unmodified --
  turns severities into the letter, and because the resolved floor here is `A+`, any finding at
  any severity drops the Machine Grade below the floor and routes to FIX. The severity column
  decides band and repair order, not pass or fail.
- **Record the human gate's state.** `G1` is the single mandatory human visual check -- opened in
  a real browser, is the graph legible and usable? -- and Overall Grade is `min(Machine, Human)`.
  When Playwright is absent, `validate-visuals.mjs` SKIPs to exit 0, `V-T` emits no rows and
  cannot lower the Machine Grade; the closing summary must record that `G1` is then the sole
  carrier of visual assurance, so the grade is not read as stronger evidence than it is.
- **Out of scope:** implementing or fixing any check -- each check's implementation belongs to the
  feature that produces the artifact, and this task owns only the run; the ledger's gap rows,
  which are structurally unreachable from this gate; and the aggregate canonical-suite run
  (task-096).

**Acceptance Criteria:**
- [ ] Tests are deterministic: the same artifacts produce the same rubric result on every run.
- [ ] Clean setup and teardown: the run writes only to `.aid/.temp/review-pending/graph.md` and
      leaves both artifacts unmodified.
- [ ] `R1` through `R5` each run against `relationships.md` and each emits rows at the severity
      D4 assigns, or no row on pass.
- [ ] `V-A`, `V-C` and `V-T` each run against `graph.html` for the **first** time and emit rows at
      their D4 severities.
- [ ] `V-T` reports T1-T4 with T1, T3 and T4 at `[HIGH]` and T2 at `[MEDIUM]`.
- [ ] No rubric row's subject is the Knowledge Base's completeness, and `graph-kb-gaps.md` is not
      passed to `grade.sh` in this run.
- [ ] `grade-graph.sh` shares no check body with `grade-summary.sh` -- verifiable by diffing the
      two orchestrators and finding none, because `grade-graph.sh` invokes the same leaf
      validators rather than copying them (AC-17).
- [ ] Every failed check appears as a `Pending` row in `.aid/.temp/review-pending/graph.md` and
      every passing check adds no row.
- [ ] The `G1` human visual gate is performed and its verdict recorded, and Overall Grade is
      computed as `min(Machine, Human)`.
- [ ] If Playwright is absent, `V-T` emits no rows, the run continues, and the closing summary
      records that `G1` is the sole carrier of visual assurance for that run.
- [ ] All acceptance criteria from feature-010's FR-28 gate are covered for this first full run.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
