# task-003: Rendering bench scale and screened candidate option space

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

**Type:** RESEARCH

**Source:** work-005-knowledge-graph -> delivery-001

**Depends on:** -- (none)

**Scope:**
- Execute feature-002's Feature Flow **Steps 2-4** and write the findings to
  `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/rendering-bench-and-options.md`.
  Step 1's reading list is preparation inside this task, not a separate deliverable: REQUIREMENTS.md
  §5.6 as rewritten, §6.1 in full, FR-3, FR-9, FR-13, FR-14, A-4, A-5, A-6, AC-6-AC-10 and C-1's
  withdrawal; STATE.md Q2; then `.aid/knowledge/decisions.md` D18, `technology-stack.md`
  § "Frameworks & Tooling" and § "Key Dependencies", and `infrastructure.md` § "The Build:
  Multi-Profile Render".
- **Step 2 -- derive the bench scale.** Do not spike at an assumed size. Compute this repository's
  candidate `int:` node count under FR-21's significance rule and FR-22's exclusions, add the KB
  document and concept count from `.aid/knowledge/`, and record how the figure was derived. Also
  bench a deliberate **order-of-magnitude overshoot**, so the recommendation says something honest
  about the case where A-5's "hundreds" does not hold.
- **Step 3 -- enumerate the option space** over two independent axes. Renderer class: SVG, DOM,
  Canvas, WebGL, multi-renderer, hand-rolled. Packaging shape: (1) inlined vendored subset,
  (2) inlined vendored whole library, (3) companion files beside `graph.html`, (4) CDN fetch at view
  time, (5) maintainer-time build with the output committed and shipped. A library evaluated under
  two shapes is two rows.
- **Step 4 -- screen before measuring.** Five hard screens; failing one **removes** the candidate,
  it does not lower a score: (1) can reach WCAG AA for the graph rendering with the accessibility
  work priced in (NFR-1); (2) can be driven from `relationships.md` alone via feature-007's lens
  view-model, with no second extraction path (FR-3, AC-10); (3) can honour reduced-motion settling,
  keyboard zoom and pan, and non-colour encoding (NFR-4-NFR-6); (4) can express the four lenses
  including Impact's adjustable-depth neighbourhood, with manual controls live after arriving via a
  preset (FR-13, FR-14, AC-8); (5) licence permits redistribution inside an artifact generated into
  a third party's repository, compatibly with this project's own MIT terms (root `LICENSE`).
- Seed the empty comparison matrix: one row per surviving `Candidate` x `Packaging shape` pair, with
  every field of feature-002 § The comparison matrix as a column and every cell unfilled. Task-004
  fills them from measurement.
- feature-002 § Research inputs / prior art is an **input to verify, not a fact to copy**. Every
  licence claim is re-read from the candidate's upstream LICENSE file at the exact evaluated
  version. Data Navigator belongs in the enumeration as a **composable accessibility-layer row**,
  not only as an alternative to the renderers.
- **This task writes no product code and builds no spike.** Spiking is task-004. Per
  `task-type-rules.md` § RESEARCH and delivery-001's gate criterion, nothing under `canonical/`,
  `profiles/`, `tests/` or `.aid/knowledge/` changes.
- Out of scope: the spikes and the filled matrix cells (task-004); the fifteen-part decision record,
  the resolved tension and the drafted KB entries (task-005); implementing the recommended renderer
  (delivery-005); the validator carve-outs (tasks 076/077, 084/085); the dependency-packaging gate
  (task-083).

**Acceptance Criteria:**
- [ ] The report exists at `.../deliveries/delivery-001/research/rendering-bench-and-options.md`.
- [ ] The bench scale is a **measured** figure: the report states the candidate `int:` node count and
      the edge count it implies, the FR-21/FR-22 rule set used to compute them, and the command or
      procedure a reader can re-run to reproduce the number.
- [ ] A-5's "hundreds" assumption is reported as confirmed or contradicted by that measurement,
      explicitly rather than by implication.
- [ ] A second, roughly order-of-magnitude overshoot bench is stated alongside it, with what it is
      for.
- [ ] The option space is enumerated across both axes -- the six renderer classes against the five
      named packaging shapes -- with the combinations carried forward listed explicitly and every
      combination dropped before screening given a one-line reason.
- [ ] All four renderer classes the first completion criterion names -- minimal layout/zoom modules,
      a higher-level graph library, a WebGL-class renderer, and hand-rolled -- appear in the
      enumeration, including where they are screened out.
- [ ] Each of the five hard screens is applied per candidate with a pass/fail verdict and its
      evidence; a failure removes the candidate from the survivor set and the report says so rather
      than scoring it down.
- [ ] Every candidate names an exact evaluated version and its project URL. "latest" appears nowhere
      as a version.
- [ ] Every candidate's licence is recorded from its upstream LICENSE file at that version, with the
      SPDX identifier and whether attribution must appear in the artifact; each dossier claim is
      marked verified or corrected, and no licence claim is carried over unverified.
- [ ] Data Navigator is present as a composable accessibility-layer row evaluated independently of
      the renderer choice, not only as a renderer alternative.
- [ ] At least two alternatives compared, sources cited, trade-offs documented explicitly (RESEARCH
      defaults), each attributed and dated.
- [ ] The survivor set is named and counted, and the empty matrix is seeded with one row per
      survivor and one column per feature-002 § The comparison matrix field, so task-004 has nothing
      to invent. **If the survivor count is more than a few, the report says so explicitly**, because
      task-004's size is unbounded from the SPEC and that count is what bounds it.
- [ ] `git status --porcelain` shows no change outside `.aid/works/work-005-knowledge-graph/` -- no
      product code, no Knowledge Base write, no committed spike harness.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
