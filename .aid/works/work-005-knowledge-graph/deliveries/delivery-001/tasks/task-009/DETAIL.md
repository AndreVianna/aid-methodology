# task-009: Assert the coverage-notes hand-off end to end

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-009/STATE.md.
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

**Source:** feature-005-two-pass-extraction -> delivery-001 (Wave 1)

**Depends on:** task-008

**Scope:**
- Add the hand-off assertions to `tests/canonical/test-graph-extraction.sh`: the renderer reads
  `.aid/.temp/graph/coverage-notes.md`; an absent, empty or truncated hand-off fails rather than
  falling back to a self-render; the emitted section is byte-identical to the assembler's output;
  and two runs over one input produce identical bytes (AC-19, AC-20).
- This is the oracle that would have caught the defect task-008 fixes. Name it as such: 196
  assertions passed over a renderer that referenced the hand-off path zero times, so the assertions
  added here must be ones that go RED against the pre-fix code.

**Acceptance Criteria:**
- [ ] Every added assertion is demonstrated to fail against the pre-task-008 renderer — a hand-off
      assertion that passes both before and after the fix is asserting nothing
- [ ] S3 mutation matrix behind `--self-mutate` for each added assertion, because this is precisely
      the vacuity class S3 exists for: an assertion over a file that is never read
- [ ] S5: mutation operates on a copy and the suite proves the working tree is untouched
- [ ] S1 and S2 honoured; no new per-assertion command substitution added to the slowest graph suite
- [ ] `# COVERS:` manifest lists `assemble-coverage-notes.sh` as well as `build-relationships.sh`, so
      `select-suites.sh` selects this suite when either side of the hand-off changes
- [ ] Suite passes; total read from the script's own summary line
- [ ] **Tests are deterministic** and **setup/teardown is clean** (TEST type-defaults,
      `task-decomposition.md`:176). Neither is implied by the S1-S5 conventions this task cites: S5
      covers only leaving the source tree untouched. Concretely -- two runs over one input produce
      identical PASS/FAIL sets and identical counts, every fixture is built under `mktemp -d` and
      removed on exit including on failure, and no assertion depends on execution order or on a
      previous run's residue
- [ ] All section-6 quality gates pass
