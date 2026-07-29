# task-004: Renderer spike measurements and the candidate comparison matrix

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

**Depends on:** task-003

**Scope:**
- Execute feature-002's Feature Flow **Step 5** and write the filled matrix and its measurements to
  `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/rendering-spike-matrix.md`.
- Build a **throwaway spike harness per surviving candidate** from task-003, against a **self-built
  synthetic fixture** at task-003's derived bench scale -- self-built and independent of any work
  folder's contents, per A-6.
- **Measure, do not estimate.** Per candidate: legibility across the density range at the bench
  scale and at the overshoot bench; the FR-13/FR-14 interaction inventory as a per-behaviour verdict
  rather than a score; keyboard reachability and focus visibility; screen-reader behaviour;
  reduced-motion settling; and payload in bytes with where those bytes live (inlined / companion
  file / fetched).
- **Fill every cell of every surviving row** of the matrix task-003 seeded: `Candidate`, `Renderer`,
  `Packaging shape`, `Licence`, `Payload`, `Build requirement` (`none` / `maintainer-time` /
  `adopter-time`, plus the toolchain it implies), `Legibility at bench scale`, `Interaction
  coverage`, `Accessibility cost`, `Validator impact`, `Update story`, `feature-008 size`, and
  `Verdict`. A cell that cannot be filled is recorded as a **finding about that candidate**, never
  left blank.
- `Validator impact` names the specific shared assertions rather than describing them:
  `validate-html-output.sh`'s `S2` (offline render, CDN grep) and `NM` (the three `mermaid`-keyed
  sub-checks), and `validate-visuals.mjs`'s `S7` collector plus `T1`-`T4` -- `T2` (sibling `<g>`
  bounding boxes overlapping by more than 20% of the smaller area) being the by-design collision for
  an SVG live surface, and a `<canvas>`/WebGL surface matching none of the three selectors at all.
- **Sizing note -- read before starting.** The number of surviving candidates is not knowable from
  the SPEC, so this task's size is unbounded from it. Written as tabled; but **if more than a few
  candidates survive task-003's screens, split this task one-per-candidate at execution time** -- one
  spike per candidate, each writing its own matrix row into the same report -- rather than
  overrunning a session. That split is an execution-time decision recorded in this task's `STATE.md`
  `notes`; it does not change the task table and does not renumber anything.
- **Spikes are throwaway and are not committed.** Nothing from them ships, and none of them touches
  product code. Per `task-type-rules.md` § RESEARCH and delivery-001's gate criterion, nothing under
  `canonical/`, `profiles/`, `tests/` or `.aid/knowledge/` changes.
- Out of scope: naming the recommendation and writing the fifteen-part decision record (task-005);
  the drafted `technology-stack.md` / `infrastructure.md` entries (task-005); adopting anything
  (delivery-005 tasks 078-082, and task-083's packaging gate).

**Acceptance Criteria:**
- [ ] One spike exists per surviving candidate row from task-003, each run against a self-built
      synthetic fixture at the derived bench scale, and each also exercised at the overshoot bench
      unless the candidate failed outright at the bench scale (in which case the report says so).
- [ ] Every matrix cell of every surviving row is filled from a measurement or a primary source. No
      cell is filled from reputation, and every cell that could not be filled carries an explicit
      finding stating why -- the missing cell is itself reported as a fact about the candidate.
- [ ] `Payload` is a measured byte count taken from the spike's own output, with where the bytes live
      (inlined / companion file / fetched).
- [ ] `Build requirement` distinguishes `none`, `maintainer-time` and `adopter-time` and names the
      toolchain each implies -- the three are not equivalent costs, and `adopter-time` is the one
      §5.6 consequence 2 warns about.
- [ ] The accessibility measurements are behavioural, not asserted: keyboard reachability, focus
      visibility, screen-reader behaviour and reduced-motion settling are each recorded as what was
      observed on the running spike.
- [ ] `Interaction coverage` is a per-behaviour verdict over FR-13/FR-14 -- which behaviours are
      built in and which need writing -- not a single score.
- [ ] `Validator impact` names the concrete assertions by id (`S2`, `NM`, `S7`, `T1`-`T4`) for every
      row, so task-005 can decide whether the conditional tasks 076/077 and 084/085 fire.
- [ ] Exactly one row's `Verdict` is `recommended`; every other row is `rejected` with a one-line
      reason.
- [ ] Sources cited and trade-offs documented explicitly (RESEARCH defaults). The "at least 2
      alternatives compared" default is satisfied by the surviving candidate set; **if only one
      candidate survived task-003's screens, the report presents the screened-out candidates as the
      comparison and states that this is the reason.**
- [ ] No spike harness and no fixture is committed. `git status --porcelain` shows no change outside
      `.aid/works/work-005-knowledge-graph/`, which is the evidence for delivery-001's gate criterion
      that no spike harness was committed.
- [ ] If this task was split one-per-candidate at execution time, the split is recorded in this
      task's `STATE.md` `notes` and every candidate row is still present in the one report.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
