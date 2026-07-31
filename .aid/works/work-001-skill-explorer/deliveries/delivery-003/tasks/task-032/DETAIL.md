# task-032: `flow-graph.test.mjs` AC-3 / AC-4 corpus tier

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-032. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-032/STATE.md.
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

**Source:** work-001-skill-explorer -> delivery-003 (feature-003-authored-flow-charts)

**Depends on:** task-031

**Scope:**
- Append the remaining three tiers to `site/scripts/__tests__/flow-graph.test.mjs`. This task and task-031 own the same file and are a strict sequence.
- **AC-4 corpus fixtures**, asserted as *structural properties plus named landmarks* so prose edits inside a skill do not break the suite while a real change to its state set does: `aid-describe` (dispatch-table), `aid-review` (inline-states) and `aid-test` (inline-states, added for KI-008 to pin the ` then ` form).
- **Whole-corpus tier:** every directory under `canonical/skills/` classifies into exactly one shape; the shape counts **sum** to the on-disk directory count with no per-shape figure asserted; every chart passes `validateChart`; `serializeChart` and `renderMermaid` are equal across two runs on the same input.
- **The unparsed-advance allow-list** -- the standing guard against a KI-008 repeat. The set of `(skill, state)` pairs emitting a W-1 residual-text warning must equal a checked-in expected set, each entry carrying a one-line reason. A connective the separator set does not yet know changes that set and fails CI, converting "an edge was silently dropped" into "a test went red". Because V9 already throws on the dangerous subset (task-023), the allow-list only ever holds benign residues and stays short enough to review by eye.
- **This task completes feature-003.** No feature-004 task may start until it is Done -- feature-004 edits `flow-graph/index.mjs` and `skills/body.mjs`, both owned by feature-003 tasks, and the BLUEPRINT requires the two features to be sequenced rather than concurrent.

**Acceptance Criteria:**
- [ ] `aid-describe`: `CONTINUE` has out-degree **3** with kinds `{branch, branch, loop-back}`; `CONTINUE.kind === 'decision'`; a `re-entry` edge enters `Q-AND-A`; `COMPLETION` is in `exits` with `terminal.advanceType === 'PAUSE-FOR-USER-DECISION'` and a `terminal.handoff` mentioning `/aid-define`.
- [ ] `aid-review`: a `loop-back` edge `VERIFY -> REVIEW`; `PRESENT-FINDINGS` has exactly two `branch` edges to `PUBLISH` and `DONE` and `kind === 'decision'`; `VERIFY.kind === 'loop-back'` and **not** `decision`, since its one `PRESENT-FINDINGS` edge is `sequence`; `DONE` is in `exits`.
- [ ] `aid-test`: a `loop-back` edge `VERIFY -> RUN` derived from the **line-wrapped** back-reference; `PRESENT` has exactly two `branch` edges to `HANDOFF` (condition `optional`) and `DONE` (condition `null`) with `kind === 'decision'`; `HANDOFF -> DONE` is asserted alongside, so the skip path and the through path are distinguished; `DONE` is in `exits`.
- [ ] All three fixtures additionally assert `validateChart(chart).ok === true`, `entries.length >= 1`, `exits.length >= 1`, that every node's `provenance.excerpt` equals the live slice of its cited `canonical/` file, and that the chart emits **no** W-1 residual-text warning.
- [ ] Out-degree assertions are written over **edge kinds**, not just counts, so neither a change to rule 5 nor a regression of KI-008 can pass by accident.
- [ ] The whole-corpus tier enumerates directories from disk, asserts exactly one shape per directory, and asserts only that the shape counts **sum** to the directory count -- **no per-shape figure is asserted anywhere**.
- [ ] Every chart in the corpus passes `validateChart`, and `serializeChart` / `renderMermaid` are byte-equal across two runs.
- [ ] The unparsed-advance allow-list is checked in, every entry carries a one-line reason, and the suite fails when the observed W-1 set differs from it in either direction.
- [ ] **No numeric corpus or per-shape count literal appears** anywhere in the tier.
- [ ] Tests are deterministic with clean setup/teardown and read nothing under `.aid/works/`.
- [ ] Feature-003's AC-3 and all three of its AC-4 fixtures are covered.
- [ ] All section-6 quality gates pass
