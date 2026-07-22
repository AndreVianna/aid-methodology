# task-004: Hard-limit invariant tests

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
> `aid-execute/references/state-execute.md § MANDATORY: State-Write Protocol`.

**Type:** TEST

**Source:** work-020-update-kb-intent-alignment -> delivery-001

**Depends on:** task-001, task-002, task-003

**Scope:**
- Add structural/consistency tests (in the repo's existing skill-test harness) that assert the redesign's invariants (AC-1..AC-8) are encoded in `canonical/skills/aid-update-kb/`:
  - **AC-1/HL-1:** APPLY's entry precondition requires a `Confirmed: yes` / frozen `Confirmed Scope`; there is no path from SCOPE/CONFIRM to APPLY without it.
  - **AC-2/HL-2/HL-5:** `state-analyze.md` has no tag-overlap candidate net; `state-scope.md` requires a `Traces-to` per item and emits a Not-Changing list.
  - **AC-3/HL-4:** `state-confirm.md` surfaces contradictions as questions; no silent-correction path exists.
  - **AC-4:** `state-review.md` defines the scope-diff guard as a hard fail that **derives the edited set from disk** (`git status`/`git diff`) vs `Confirmed Scope`, plus a traceability mandate.
  - **AC-5/HL-7:** the FIX loop and `state-done.md` closure re-check are bounded to Confirmed Scope with a user-escalation branch, and a post-APPLY re-scope reverts out-of-scope edits (`git restore`).
  - **AC-6/HL-6:** new-file creation is gated on a `new-file` kind confirmed at CONFIRM.
  - **AC-8/HL-3:** a LIKELY/UNCERTAIN inference is routed to a CONFIRM question, not applied silently.
  - **Structure:** the two new reference files exist; the 7-state resume table and dispatch table are internally consistent (every state referenced by SKILL.md has a reference doc and vice-versa); the mandate count reads "four-mandate" consistently.
- **Source-doc sweep:** confirm no lingering `Change Plan` references remain in ANY source doc (specifically `state-review.md` fallback and `state-done.md` commit template), not only tests/fixtures.
- **Settings-floor verification:** confirm `.aid/settings.yml` has no per-skill `update-kb` override and the `aid-update-kb` floor still resolves to the project global `minimum_grade` (currently `A+`; skill hardcoded fallback `A`) — unchanged by this work.
- Follow the local-test-safety rules: no port-binding/hanging suites; structural assertions run bounded; defer any canonical parity/byte-identity checks to CI/Linux.

**Acceptance Criteria:**
- [ ] Tests assert AC-1..AC-8 are encoded in the skill's reference docs — including AC-4's disk-derived scope-diff guard and AC-5's re-scope revert.
- [ ] Tests assert structural consistency of the 7-state machine (states ↔ reference docs ↔ resume/dispatch tables) and a consistent "four-mandate" count.
- [ ] The `Change Plan` → `Scope Plan` rename leaves no stale references in any source doc (state-review.md fallback, state-done.md commit template) or test/fixture.
- [ ] The settings-floor verification confirms no `update-kb` override and an unchanged resolved floor.
- [ ] Tests are added outside any hanging/port-binding suite and pass locally within bounds (canonical parity deferred to CI).
- [ ] All section-6 quality gates pass.
