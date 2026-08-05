# task-023: The third-party packaging gate for d3-force and PixiJS

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-023/STATE.md.
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

**Type:** IMPLEMENT

**Source:** feature-012-canonical-registration -> delivery-001 (Wave 3)

**Depends on:** task-011, task-017

**Scope:**
- feature-012 D6's dependency gate, which **fires** because a third-party dependency is adopted:
  `d3-force` and PixiJS must be private and unpublished, exactly pinned, lockfiled, monitored, and
  licence-recorded — in the packaging shape task-002 reported and task-011's decision record states.
  **This task does not choose the packaging shape**; it implements the one already decided.
- Register the new view and canvas files task-017 produced in the emission path and in
  `canonical/aid/templates/generated-files.txt`, alongside the `graph.html` entry that is already
  there.
- **Depends on task-011 because this is BLUEPRINT edge 2** — feature-002 conditions feature-012's
  dependency packaging — and on task-017 because the file set to register does not exist until the
  canvas does.

**Acceptance Criteria:**
- [ ] The packaging shape implemented matches task-011's decision record; no fresh choice is made
      here, and any divergence is raised against feature-002 rather than absorbed
- [ ] Dependencies are private and unpublished, **exactly** pinned (no range), lockfiled, and covered
      by the monitoring the record names
- [ ] Licence and attribution land in a **permanent** artifact, not a work folder — work folders are
      transient and no permanent artifact may depend on one
- [ ] D7's update mechanism is recorded as an owned, ongoing obligation with its trigger named
- [ ] Companion files travel beside `graph.html` under `.aid/knowledge/` (FR-9, A-4, C-8)
- [ ] Every new file is present in `generated-files.txt` and reachable by the emission machinery; a
      file the generator cannot see is named as hand-maintained rather than assumed emitted
- [ ] If the decided shape is CDN packaging, feature-011's `S2` carve-out is confirmed as **in force**
      and task-019's waiver text matches; if it is not, `S2` is confirmed as a recorded no-op
- [ ] All section-6 quality gates pass
