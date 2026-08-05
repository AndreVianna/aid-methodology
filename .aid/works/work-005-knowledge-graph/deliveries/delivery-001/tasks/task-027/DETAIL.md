# task-027: Measure the graph suites against tests/run-all.sh's per-suite timeout on CI

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-027/STATE.md.
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

**Type:** REFACTOR

**Source:** feature-013-tests-and-docs -> delivery-001 (Wave 5)

**Depends on:** task-009, task-014, task-016, task-020, task-025

**Scope:**
- `tests/run-all.sh:93` runs each suite under a hard `timeout 300`. On a Windows dev shell
  `test-graph-extraction.sh` runs **783s** and `test-graph-runtime-gate.sh` **318s**, both over the
  budget. A spawn costs ~110ms locally against under 1ms on Linux CI, so CI may pass comfortably —
  but **the margin is unmeasured and `timeout 300` is a hard kill.**
- **Settle it with a CI run, not by inference from a dev machine.** That is this task's whole point,
  and it is the delivery gate's third bullet.
- If any suite exceeds the budget on CI, reduce **spawns** (S1, S2) — never coverage (S4 forbids the
  trade).
- Also discharges `AC-T7`: both gates the project documents run locally and pass — the HOME-pinned
  canonical suite, and the site suite plus build — because neither fires on a feature branch.

**Acceptance Criteria:**
- [ ] Per-suite wall times for every graph suite are taken from an actual CI run and recorded; no
      figure in the conclusion is extrapolated from the dev machine
- [ ] Every graph suite completes inside `timeout 300` on CI, or is reduced until it does
- [ ] Any reduction is shown to preserve the assertion count, with before and after totals read from
      each script's **own summary line** — grep over stdout undercounts on hang or timeout, which is
      exactly the failure this task is about
- [ ] `AC-T7`'s two local gates both run and pass; the canonical suite run pins `USERPROFILE` (plus
      `HOMEDRIVE`/`HOMEPATH`), not only `HOME` — native pwsh derives `$HOME` from `USERPROFILE`, so a
      HOME-only sandbox reaches the real `~/.aid`
- [ ] A `--watch` exit code of 0 is not accepted as all-pass; each job is verified individually
- [ ] Windows-local path, 8.3 and ESM-URL failures are distinguished from real defects rather than
      counted as either
- [ ] The mutation-harness cost defect (tech-debt W5-4) is **not** fixed here — it is deliberately out
      of this work's scope
- [ ] **All tests pass before AND after**, and **no behaviour change** (REFACTOR type-defaults,
      `task-decomposition.md`:177). Stated with its oracle: capture each suite's own summary-line
      totals before the spawn reduction and compare after -- identical PASS counts and identical
      assertion ids, per S4, so a reduction that drops an assertion is caught rather than read as a
      speed-up. `tests/coverage-parity.sh` is the mechanical check for the assertion-id half
- [ ] All section-6 quality gates pass
