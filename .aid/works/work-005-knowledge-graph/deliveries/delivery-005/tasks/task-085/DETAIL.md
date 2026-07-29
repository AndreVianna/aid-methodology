# task-085: `test-validate-visuals-profiles.sh` VV01-VV04

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

**Source:** work-005-knowledge-graph -> delivery-005

**Depends on:** task-084

**Scope:**
- **Conditional (feature-011 § D3 contingency C2). Firing condition:** the same trigger as
  task-084 -- this suite exists **only if** delivery-001's rendering decision selected an SVG live
  drawing surface and `validate-visuals.mjs` therefore gained `--profile`. It is inseparable from
  task-084: separating a carve-out from its guard is exactly the failure mode the carve-out design
  exists to prevent.
- Author `tests/canonical/test-validate-visuals-profiles.sh`, discovered by the
  `tests/canonical/test-*.sh` glob with **no edit to `tests/run-all.sh`** -- a stated contract of
  the runner. It builds its own fixture under `mktemp -d`, sources `tests/lib/assert.sh`, uses the
  `ID + description` assertion-label convention of `tests/canonical/test-guardrails-d012.sh`, and
  depends on no `.aid/works/` path, so it satisfies A-6 and keeps working after the work folder is
  pruned.
- The four assertions of feature-011 § L3:
  - **`VV01`** -- with no `--profile`, `T1`-`T4` are enforced on every collected visual.
  - **`VV02`** -- `--profile graph` reports `T2` as `[N/A]` for the marked live surface **only**,
    and `T1`, `T3` and `T4` still fail that element when violated.
  - **`VV03`** -- an unmarked `.diagram-box` on the same page is still fully `T1`-`T4` checked.
  - **`VV04`** -- the golden-output proof (feature-011 § D4 proof 4): the `--profile graph` stdout
    differs from the default run's by **exactly one line**. This is the assertion that catches the
    carve-out widening beyond its single named check, which no golden-output test of the default
    path alone can catch.
- **Out of scope:** `test-validate-html-profiles.sh` and its `VP01`-`VP06` assertions (contingency
  C1, task-077); `tests/canonical/test-guardrails-d012.sh`, which stays unmodified and is only
  re-run here as a standing pin; and any edit to the validator itself (task-084).

**Acceptance Criteria:**
- [ ] **If contingency C2 did not fire, this task is a recorded no-op and the gate records why**,
      citing the decision record and task-075's trigger evidence. No suite is authored
      speculatively.
- [ ] Tests are deterministic: the fixture is built under `mktemp -d`, the same run produces the
      same result, and nothing depends on machine state.
- [ ] Clean setup and teardown: the temporary fixture is removed and no state is left outside it.
- [ ] All four assertions `VV01`, `VV02`, `VV03` and `VV04` are present, each labelled with its id
      and description per the `test-guardrails-d012.sh` convention.
- [ ] `VV04` asserts an **exactly one line** stdout diff between the default and `graph` runs, not
      merely a differing verdict.
- [ ] `VV02` asserts both halves: T2 `[N/A]` on the marked element, and T1/T3/T4 still failing it
      when violated.
- [ ] The suite requires no edit to `tests/run-all.sh` and contains no `.aid/works/` path.
- [ ] When Playwright is absent, the run follows `validate-visuals.mjs`'s documented
      `SKIP` -- exit 0 with the `npx playwright install chromium` remediation -- rather than
      failing the run.
- [ ] `bash tests/canonical/test-guardrails-d012.sh` still passes unmodified, and
      `tests/coverage-parity.sh` records a net **addition** of executed assertions, never a
      removal.
- [ ] All acceptance criteria from feature-011's validator-parameterisation criterion are covered
      on the visuals side.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
