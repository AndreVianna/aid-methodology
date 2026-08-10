# task-061: The render proved fresh, which byte-identity structurally cannot do

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-061/STATE.md.
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

**Source:** work-006-design-phase-skills -> delivery-003

**Depends on:** task-060

**Scope:**
- Source: `features/feature-006-integration-and-close-out/SPEC.md` §6 step 5 and its §10 row *Render
  **fresh**, and C-5 (full render, never partial)*. It closes BLUEPRINT criterion **3** -- *"The
  render is provably **fresh**, not merely self-consistent"*.
- **It is a separate task from task-060 because it is a separate property, and the two do not imply
  each other.** `test-dogfood-byte-identity.sh`'s own header (`:35-58`) records that all three
  artifacts each direction compares -- manifest, profile tree, dogfood tree -- are outputs of the
  **same** generator run, and that `canonical/`, the generator's input, is not among them: *"if all
  three artifacts are consistently stale, this suite is green."* The header is not speculating; it
  records that the suite was green over the stale trees a previous re-render existed to replace, both
  before and after. So byte-identity cannot fail on a stale or partial render, and this is the only
  oracle in the delivery that can.
- The check: re-run `python .claude/skills/generate-profile/scripts/run_generator.py`, then
  `git diff --exit-code -- profiles/`. That is CI's `render-drift` job
  (`.github/workflows/test.yml:44-63`), which runs the same two steps and turns a non-empty diff into
  an error. Running it locally here means the property is established at this gate rather than
  discovered when the pull request is opened.
- **The exec-bit caveat, because CI sets it and a local run does not.** `test.yml:51-53` runs
  `git config core.fileMode false` before regenerating, since the repository is maintained with that
  setting. A local run that has not set it can report mode-only differences that are not drift; the
  record must state which setting was in effect, so a mode-only diff is not mistaken for a defect and
  a real diff is not excused as one.
- **This task writes nothing.** A re-run of the generator over an already-fresh tree is a no-op by
  construction -- which is exactly the property being asserted -- so any file this task leaves changed
  is the finding, not a side effect to clean up.
- Out of scope: producing or fixing the render, which is task-060's; every count-bearing surface
  (task-062, task-069); the site's generated skill surface, which `run_generator.py` does not write
  at all (task-064); and the `coverage-parity` lane (task-063).

**Acceptance Criteria:**
- [ ] **BLUEPRINT criterion 3 -- the freshness oracle.** `run_generator.py` is re-run as a **full**
      run and `git diff --exit-code -- profiles/` exits **0** with empty output. The record states the
      command, the exit code and the empty diff, not a summary of them
- [ ] **The dogfood trees are fresh too, which the `profiles/`-scoped diff does not cover.**
      `git status --porcelain .claude/ .cursor/` is empty after the re-run, and no untracked file
      remains under either
- [ ] **`core.fileMode` is recorded.** The record states the effective `git config core.fileMode`
      value for the run, and any mode-only difference is reported separately from a content difference
      rather than folded into one verdict
- [ ] **The distinction this task exists for is stated in its own record**, with the header line that
      grounds it quoted: byte-identity proves mutual consistency of three generator outputs and cannot
      prove freshness, so a green `test-dogfood-byte-identity.sh` is **not** evidence for this
      criterion and is not offered as such
- [ ] **This task writes nothing.** `git status --porcelain` over `profiles/`, `.claude/`, `.cursor/`,
      `canonical/`, `tests/`, `site/`, `docs/` and `.aid/knowledge/` is **identical before and after**,
      and `git diff --cached --name-only` is empty
- [ ] Tests are deterministic and setup/teardown is clean -- a generator re-run plus a scoped `git
      diff` over committed content, so two executions produce identical outcomes and there is nothing
      to tear down
- [ ] All acceptance criteria from the source feature that this task covers are covered: feature-006
      §6 step 5 and its §10 *Render **fresh*** row, each recorded with the command that produced its
      result
- [ ] All section-6 quality gates pass
