# task-087: AC-7 graph-half parity, FR-6 regrouping and FR-2 legibility

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

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-086

**Scope:**
- Verify, headless against the rendered `.aid/knowledge/graph.html`, the three obligations
  delivery-005's gate names for the drawing surface.
- **AC-7's graph half (NFR-3 parity).** With each of the four presets applied -- `coverage`,
  `overview`, `impact`, `provenance` -- the graph interprets the lens **identically to the table
  rendering**. The same `ViewModel` drives both, so for a given `revision` the graph's visible node
  set, visible edge set and per-node emphasis class must match what the table renders. AC-7 itself
  is feature-007's and closed in delivery-004; what is verified here is the parity obligation
  feature-008 must not break, because interpreting a lens differently from the table is an
  explicit violation of NFR-3 and AC-7.
- **FR-6 -- regrouping by relation category.** Switching `grouping` to `'relation-category'`
  regroups the graph: one group frame per `viewModel.groups` entry, each with its visible text
  caption, and the dedicated `no relationships` group present and listed last when its set is
  non-empty. The graph positions the partition feature-007 computed; it must neither invent a
  category nor drop a node.
- **FR-2 -- density, zoom and legibility across the range.** Density levels 1 through 5 and the
  zoom steps each respond, and the graph stays legible across the range at this project's node
  counts (A-5: hundreds, not tens of thousands). Legibility is measured concretely: no label
  painted below the 10 px rendered size (T1), a non-trivial bounding rect (T3), and no horizontal
  overflow at the 732 px and 390 px viewports (T4). Density level 1 performs no thinning at all.
- **Out of scope:** the reduced-motion, NFR-5 and NFR-6 obligations and the AC-9 closure
  (task-088); the AC-15 Coverage-lens equality (task-089); the table-side parity, already verified
  in delivery-004 task-072; and any fix to `graph-canvas.js`, which belongs to tasks 079-082.

**Acceptance Criteria:**
- [ ] Tests are deterministic: the same rendered artifact yields the same result on every run,
      with no dependence on timing or machine state.
- [ ] Clean setup and teardown: any working directory is created under `mktemp -d` and removed,
      and the run leaves `.aid/knowledge/graph.html` unmodified.
- [ ] For each of the four presets, the graph's visible node ids, visible edge keys and per-node
      emphasis classes equal the table's for the same `ViewModel` revision.
- [ ] A divergence is reported as an NFR-3 / AC-7 violation naming the differing ids, not as a
      generic failure.
- [ ] `grouping: 'relation-category'` produces exactly the group frames `viewModel.groups`
      declares, each captioned with its `label` as text.
- [ ] A zero-row node appears in the `no relationships` group under both the `relation-category`
      and `provenance` dimensions, and that group is listed last.
- [ ] Density levels 1 through 5 each render, and level 1 thins nothing -- a zero-degree node is
      present at level 1.
- [ ] Across the tested density and zoom range, no node label renders below 10 px (T1).
- [ ] The surface has a non-trivial bounding rect (T3) and no horizontal overflow of its own
      container at the 732 px and 390 px viewports (T4).
- [ ] All acceptance criteria from feature-008 covering AC-7's graph half, FR-6 and FR-2 are
      covered by this suite.
- [ ] When Playwright is absent the run follows the documented `SKIP` to exit 0 with its
      remediation message rather than failing, and the summary records that feature-010's `G1`
      human visual gate is then the sole carrier of visual assurance.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
