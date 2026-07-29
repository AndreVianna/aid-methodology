# task-096: HOME-pinned full canonical suite run

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

**Source:** work-005-knowledge-graph -> delivery-006

**Depends on:** task-090, task-091, task-092, task-093, task-094, task-095

**Scope:**
- Run the aggregate gate on the branch immediately before it ships:
  ```
  HOME="$(mktemp -d)" bash tests/run-all.sh
  ```
- **This is the final barrier, and it must be last.** `.github/workflows/test.yml` triggers on
  push and pull request to `master` only, so the full canonical suite is a **master-only gate**: a
  green feature branch proves nothing about it, and a direct merge can red-master in ways the
  branch never saw. This task is the only place the full suite runs before merge, so it runs after
  every other delivery-006 task and after every other delivery has landed.
- **HOME-pinning is not optional and not stylistic.** `.aid/knowledge/test-landscape.md` records
  it as a real gotcha: the migration scan defaults its root to `$HOME`, so an unpinned run
  migrates the developer's real repositories. Pin `HOME` -- not just `AID_HOME` -- to a throwaway
  `mktemp -d`.
- The runner discovers suites by the `tests/canonical/test-*.sh` glob, so the suites this work
  adds need **no edit to `tests/run-all.sh`**. That is a stated contract of the runner, and the
  run is the proof that each new suite was picked up.
- **Shell note for this machine:** bare `bash` resolves to the WSL launcher, which corrupts git
  worktree paths and is slow. Invoke Git Bash explicitly
  (`"C:\Program Files\Git\bin\bash.exe"`) so the run happens against the real worktree.
- **Out of scope:** fixing a failing suite that belongs to another feature -- a failure here is
  raised against the owning feature, fixed there, and this gate re-run; the registration suite
  itself (task-091); the coverage census (task-092); and the FR-28 rubric run (task-093).

**Acceptance Criteria:**
- [ ] Tests are deterministic: the run is HOME-pinned to a throwaway `mktemp -d`, so no real
      repository is scanned or migrated and the result does not depend on the developer's machine
      state.
- [ ] Clean setup and teardown: the throwaway `HOME` is discarded and the working tree is
      unmodified by the run.
- [ ] `HOME="$(mktemp -d)" bash tests/run-all.sh` completes **green** locally on the branch, and
      the PASS/FAIL summary is recorded as the evidence.
- [ ] The run happens **after** tasks 090, 091, 092, 093, 094 and 095, so it is the last action
      before the branch ships.
- [ ] `tests/run-all.sh` is unmodified; every suite this work added was discovered by the
      `tests/canonical/test-*.sh` glob.
- [ ] Every suite this work added -- including `test-graph-skill-registration.sh` and any
      contingent validator-profile suite that landed -- appears by name in the run's suite list.
- [ ] A failing suite is raised against the feature that owns it and this gate is re-run after the
      fix; no suite is skipped, excluded or timed out away to make the run green.
- [ ] All acceptance criteria from feature-013's aggregate-gate criterion are covered.
- [ ] The reviewer ledger for this task carries no finding with Status `Pending` or `Recurred`, so
      the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches this
      repository's resolved `A+` (`review.minimum_grade`; `.aid/knowledge/quality-gates.md`
      § Minimum-Grade Thresholds).
