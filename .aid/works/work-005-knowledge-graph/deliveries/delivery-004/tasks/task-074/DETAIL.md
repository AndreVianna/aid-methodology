# task-074: AC-6 entry-point render and documented-prerequisite verification

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-069

**Scope:**
- Open the real `.aid/knowledge/graph.html` by its **documented entry point** -- a local `file://`
  open (STATE.md Q5, FR-9, A-4) -- and verify what the artifact actually delivers in this
  delivery: the shell, the controls, and the peer table, rendering from `relationships.md` alone.
- Verify the runtime-prerequisite disclosure AC-6 requires: the footer statement and the run's
  console summary, checked against the prose delivery-001's rendering decision record wrote
  (task-005).
- **Stated limitation, recorded rather than waived:** AC-6 as worded says the artifact "renders
  the graph successfully". The graph canvas is feature-008 and lands in delivery-005, so that
  clause **cannot** be verified here. This task verifies the surfaces that exist -- shell plus peer
  table -- and the gate records AC-6 as met for those surfaces with the graph clause deferred to
  delivery-005, rather than passing a gate on a half-met wording. This is a known finding already
  reported to the owner.
- **Out of scope:** the WCAG checks (task-073); `S2`/`NM` and the contingency determination
  (task-075); the canvas itself and its own AC-6 re-check (delivery-005).

**Acceptance Criteria:**
- [ ] Opened as `file://` at `.aid/knowledge/graph.html`, the page loads and the shell renders:
      skip link, `<header role="banner">`, the preset `<nav>`, the control panel, `<main>`, the
      table `<section>`, the legend and the footer.
- [ ] The peer table renders its rows from the embedded payload, the four presets are operable, and
      the console carries no error other than one deliberately induced by a fixture.
- [ ] The page renders **from `relationships.md` alone** (AC-10): the browser's network panel
      records zero requests, and the only data source in the page is the
      `<script type="text/markdown" id="graph-relationships">` payload -- including the zero-row
      case, whose `kb_gaps` lives in that same file's frontmatter.
- [ ] The footer states the artifact's runtime prerequisites explicitly -- network access,
      companion asset files, build output -- and the statement **matches delivery-001's decision
      record prose** (task-005); any divergence is recorded as a finding against whichever of the
      two is wrong, and is not silently reconciled by editing the footer.
- [ ] The same prerequisites appear in the run's console summary, not only in the page.
- [ ] The AC-6 limitation is recorded in the delivery's review-pending ledger and in the gate note:
      the "renders the graph successfully" clause is deferred to delivery-005 because the canvas
      does not exist yet; everything else in AC-6 is verified here.
- [ ] **Tests are deterministic** (TEST default): the procedure is re-runnable against an unchanged
      artifact and yields the same result; the browser and version used are recorded.
- [ ] **Clean setup/teardown** (TEST default): the verification writes nothing into
      `.aid/knowledge/` and leaves no temporary file behind.
- [ ] Source-feature coverage: AC-6 and AC-10 of feature-007 are each covered, with AC-6's
      unverifiable clause named explicitly rather than assumed.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
