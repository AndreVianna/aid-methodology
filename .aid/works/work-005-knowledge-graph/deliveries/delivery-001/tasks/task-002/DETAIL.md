# task-002: feature-002 Stage 3 -- payload, licence, attribution and the update mechanism

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-002/STATE.md.
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

**Type:** RESEARCH

**Source:** feature-002-graph-rendering-research -> delivery-001 (Wave 1)

**Depends on:** -- (none)

**Scope:**
- feature-002 D6 and D7 for the decided architecture (`d3-force` for physics, PixiJS/WebGL for
  drawing — FR-18 is settled by Q9 and is NOT reopened here). Stage 3 is data-independent and the
  SPEC states explicitly that it does not wait on Stage 1, so this runs in parallel with Stage 2a.
- D6 (Stage 3 part one): the payload figures, the packaging shape the project takes on, and the
  licence and attribution findings for both libraries.
- D7 (Stage 3 part two, the sharpest of the three): the update mechanism and the ongoing
  obligation it creates.
- Produces the firing conditions two downstream features are keyed on and cannot read anywhere
  else: feature-011's `S2` offline-render carve-out (contingent on CDN packaging) and
  feature-012 D6's third-party dependency gate (private, unpublished, exactly pinned, lockfiled,
  monitored, licence recorded).

**Acceptance Criteria:**
- [ ] A research document only. No product code, no vendored library, no manifest edit — per
      `task-type-rules.md` § RESEARCH, research produces documents
- [ ] Every D6 and D7 required part is present, and any part deferred names the stage that owes it
- [ ] The packaging shape is stated unambiguously enough that feature-011 can read its `S2` firing
      condition and feature-012 can read its gate's firing condition off this document without
      inferring either
- [ ] Licence and attribution text is recorded verbatim from the distributions, with versions named
- [ ] Fixtures, where any are used, are self-built per A-6 — no work folder's contents are an input
- [ ] The document is not cited by any permanent artifact (CLAUDE.md § Tracking discipline: work
      folders are transient)
- [ ] Written to `deliveries/delivery-001/research/`, beside the Stage 1 probe
- [ ] **Sources cited** and an **actionable recommendation** stated (RESEARCH type-defaults,
      `task-decomposition.md`:180). Licence and attribution findings in particular are worthless without
      their source: cite the licence file or repository page consulted, with the version it applied to
- [ ] **RECORDED OVERRIDE of the third RESEARCH default, "at least 2 alternatives compared."** It does
      **not** apply to D6's payload and licence findings: the renderer pair is settled by FR-18 and Q9
      and this task is explicitly forbidden from reopening it, so there is no live alternative to
      compare. It **does** apply to D7 -- the update mechanism is a genuine choice, so compare at least
      two mechanisms and state why the chosen one carries the ongoing obligation it does
- [ ] All section-6 quality gates pass
