# task-002: Scope-fidelity guardrails

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

**Type:** IMPLEMENT

**Source:** work-020-update-kb-intent-alignment -> delivery-001

**Depends on:** task-001 (consumes `Confirmed Scope` and the Scope Plan schema it defines)

**Scope:**
- `canonical/skills/aid-update-kb/references/state-apply.md`: bound edits to confirmed Scope Plan items only; repeat the "targeted edit, NOT a rewrite" guard inside the sub-agent dispatch prompt (not only the inline path); remove the open-ended "add cross-references as needed" cascade (old `:79-80`) — cross-refs happen only as confirmed items. Preserve calibration/altitude discipline, native-spine invariant, and the `approved_at_commit:` no-restamp-in-APPLY rule.
- `canonical/skills/aid-update-kb/references/state-review.md`: add a mechanical **scope-diff guard** that runs first and **derives the edited-doc set from disk** — `git status --porcelain .aid/knowledge/` (or `git diff --name-only` against the `Pre-APPLY baseline`), **never** from APPLY's self-reported `Edited Docs` — and requires it to equal `Confirmed Scope` → hard fail otherwise (flag confirmed-but-untouched docs). Add a **traceability mandate** (each edit maps to a confirmed item); then invoke the unchanged f005 four-mandate panel. Bound the FIX loop to `Confirmed Scope` (HL-7); an out-of-scope-only fix routes to a user escalation back to CONFIRM instead of expanding. Also rename the residual `Change Plan` fallback reference (old `state-review.md:30`) to `Scope Plan`.
- `canonical/skills/aid-update-kb/references/state-approval.md`: present the disk-derived scope-fidelity result + a real diff pointer; make `[2] Additional consideration` re-scope (route back to CONFIRM/SCOPE), not blindly back to APPLY (old `:96-98`). Specify the **re-scope revert**: when re-scoping after APPLY has written edits, revert (`git restore -- <doc>` against `Pre-APPLY baseline`) any working-tree edit to a doc dropped from the revised `Confirmed Scope` before APPLY re-runs.
- `canonical/skills/aid-update-kb/references/state-done.md`: on a closure re-check shortfall that needs an out-of-scope addition, **escalate to the user** rather than auto-pushing to APPLY (HL-7). Rename the residual `Change Plan` reference in the commit-message template (old `state-done.md:111`) to `Scope Plan`. Keep the existing restamp/commit/clean flow otherwise.

**Acceptance Criteria:**
- [ ] APPLY edits only confirmed items; the no-rewrite guard is present on the sub-agent path; the open-ended cross-ref cascade is gone (HL-2/HL-5).
- [ ] REVIEW's scope-diff guard derives the edited-doc set from disk (`git status`), not from APPLY's self-report, and hard-fails when it ≠ `Confirmed Scope`; a traceability mandate is defined (AC-4).
- [ ] The REVIEW FIX loop and DONE closure re-check are explicitly bounded to `Confirmed Scope` with a user-escalation branch; a post-APPLY re-scope reverts (`git restore`) out-of-scope edits before re-applying (AC-5, HL-7).
- [ ] APPROVAL `[2]` re-scopes to CONFIRM/SCOPE (with the re-scope revert); the scope-fidelity result is shown.
- [ ] The residual `Change Plan` references in `state-review.md` (fallback) and `state-done.md` (commit template) are renamed to `Scope Plan`.
- [ ] f005 panel, human-commit invariant, the FR-33/34 aid-housekeep boundary, and the `approved_at_commit:` rule are unchanged (AC-7).
- [ ] All section-6 quality gates pass.
