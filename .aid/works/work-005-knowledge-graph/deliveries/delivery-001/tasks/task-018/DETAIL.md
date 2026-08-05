# task-018: feature-008's GC canvas suite

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-018/STATE.md.
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

**Source:** feature-008-interactive-graph-canvas -> delivery-001 (Wave 3)

**Depends on:** task-014, task-017

**Scope:**
- Author `tests/canonical/test-graph-canvas.sh` carrying the `GC01`-`GC19` series the SPEC names,
  asserted against D3's **published draw record** rather than against pixels.
- Carries the **AC-9 reduced-motion clause** and the **AC-15 canvas half** that the delivery gate
  requires evidenced — the gate cannot close on one half plus an assumption.
- The `GC*` prefix is available because task-014 renamed the shipped
  `test-graph-view.sh` ids that occupied it.

**Acceptance Criteria:**
- [ ] The `GC*` series is contiguous, `GC01`-`GC19`, and collides with no sibling prefix — verified by
      grep across `tests/canonical/` after task-014's rename
- [ ] Every assertion reads the published draw record; none reads pixels or a screenshot
- [ ] `GC10` greps for `prefix` and for a prefix literal, and `GC13` compares every mark against the
      `ViewModel` entry for its own id — the two halves of the Q21 obligation, neither left to
      argument
- [ ] `GC11` asserts the two gap classes distinguishable from each other **including with one of them
      selected** — the case a class-derived badge would fail
- [ ] `GC04` supplies the AC-6a instrumentation reading and asserts **no figure**
- [ ] `GC09` and `GC12` assert the canvas hosts no control and takes no tab stop, and that every
      viewport action is keyboard-driven through the shell's control
- [ ] `GC19` asserts both unavailability paths — library global absent, and no WebGL context
- [ ] A `# COVERS:` manifest header naming the canvas module and the templates it consumes
- [ ] S1, S2, S4 honoured; S3 mutation cases behind `--self-mutate`; S5 proves the tree untouched
- [ ] Suite passes; total read from the script's own summary line
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
