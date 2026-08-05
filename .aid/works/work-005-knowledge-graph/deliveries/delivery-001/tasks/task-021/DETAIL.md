# task-021: Close feature-010's runtime -- ceiling, render wiring, and the V-rubric half

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-021/STATE.md.
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

**Source:** feature-010-aid-graph-skill-runtime -> delivery-001 (Wave 4)

**Depends on:** task-010, task-013, task-018, task-019

**Scope:**
- feature-010's runtime already ships — eleven states, `grade-graph.sh`, `graph-preflight.sh`,
  `graph-stale-check.sh`, `kb-write-fence.sh`, `assemble-coverage-notes.sh`, three passing suites.
  Its "specified early" half is done; this task is the "closed last" half.
- Write task-010's measured ceiling into `canonical/aid/templates/graph/scale-ceiling.yml`'s
  `node_ceiling`, which ships as a required key with deliberately no value, and wire the
  over-ceiling **warning** — NFR-8 makes it a warning, never a refusal, and no adaptive degradation
  is built anywhere.
- Point `state-render.md`'s router at task-013's real assembly driver and `state-visual-gate.md` at
  task-019's parameterised validators, replacing the invocations that had no implementation to reach.
- Surface the runtime-prerequisite text the view generator prints — neither compose it nor suppress
  it (`state-render.md` is explicit on this).
- Complete D4's `V*` rubric rows, which had no artifact to run against until `graph.html` existed.

**Acceptance Criteria:**
- [ ] `node_ceiling` carries task-010's integer, and its comparand is the total node count across
      every producer stream — the value that the carrier's own header specifies
- [ ] Exceeding the ceiling **warns and proceeds**; no run is refused and no degraded rendering mode
      is introduced
- [ ] `state-render.md` invokes the real assembler and routes on 0/1/2 exactly as its table states
- [ ] `state-visual-gate.md` invokes the validators under `--profile graph`
- [ ] The prerequisite text reaching the console and the page footer is the generator's own output,
      passed through unmodified
- [ ] With `view_expected: false`, RENDER is still skipped, the `V*` rows report as skips, the human
      pool reads `N/A`, and the expected-artifact set never demanded a page
- [ ] The write allowlist and `kb-write-fence.sh` are unchanged in scope — this task widens no write
      permission
- [ ] `test-graph-runtime.sh`, `test-graph-runtime-gate.sh`, `test-graph-runtime-digest.sh` and
      `test-graph-runtime-grade.sh` all pass
- [ ] No `V*` row is left as a placeholder that a gate could read as a pass
- [ ] All section-6 quality gates pass
