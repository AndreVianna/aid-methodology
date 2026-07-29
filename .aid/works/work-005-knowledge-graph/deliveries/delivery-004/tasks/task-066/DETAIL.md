# task-066: `references/state-render.md`

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-007, task-065

**Scope:**
- Author `canonical/skills/aid-graph/references/state-render.md`, the RENDER state body
  feature-007 owns, in the same shape as its sibling `references/state-*.md` files.
- The body sequences what task-065 built: materialise `.aid/.temp/graph/graph-src/`, inline the
  shared predicate first, embed the base64 `text/markdown` payload, invoke `assemble.sh`, write
  `.aid/knowledge/graph.html` (allowlist entry **W2**) and any companion assets under
  `.aid/knowledge/graph-assets/**` (**W3**), and emit the inputs-digest comment.
- State the AC-6 obligation: the run emits the artifact's runtime prerequisites into the page
  footer **and** into the run's console summary.
- Carry the single `**Advance:**` line feature-010's state table fixes for this state.
- **Out of scope:** the SKILL.md dispatch row and the state-map node (task-067); the assembly
  code and manifest themselves (task-065); the `**Advance:**` semantics, which are feature-010's
  to define -- this task only writes the line feature-010 specifies; the six state bodies
  feature-010 owns (task-030).

**Acceptance Criteria:**
- [ ] The file exists at `canonical/skills/aid-graph/references/state-render.md` and follows the
      structure of the sibling state references authored in tasks 030/031/050.
- [ ] Its Advance line is exactly `CHAIN → VALIDATE`, matching feature-010's State Machines table
      row for RENDER; no `PAUSE-FOR-USER-ACTION` and no `PAUSE-FOR-USER-DECISION` appears anywhere
      in the file.
- [ ] The body names **only** W2 (`.aid/knowledge/graph.html`) and W3
      (`.aid/knowledge/graph-assets/**`) as write targets and states that no other
      `.aid/knowledge/` file is written (FR-10), so the E2 fence's verify pass stays clean.
- [ ] The body names the real machinery task-065 authored: `assemble.sh` with its three flags, the
      `.aid/.temp/graph/graph-src` layout, the shared-predicate-first inline order, the
      `text/markdown` base64 payload element, and the `<!-- aid-graph inputs-digest: … -->`
      comment.
- [ ] The body states the AC-6 prerequisite emission into both the page footer and the console
      summary.
- [ ] Accuracy verified against the current tree: every script, flag, path and artifact name in
      the file exists exactly as written after task-065.
- [ ] All existing canonical suites still pass, and no suite is modified by this task; skill state
      machines are not machine-tested by design (`test-landscape.md`), so the coverage for this
      state is the RENDER path exercised by tasks 073/074. *(Stated override of the IMPLEMENT
      default "unit tests for all new public methods": skill prose has no unit-test vehicle.)*
- [ ] Build passes: `python .claude/skills/generate-profile/scripts/run_generator.py` completes and
      emits this file into all five profile trees; the render-drift confirmation is task-069.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
