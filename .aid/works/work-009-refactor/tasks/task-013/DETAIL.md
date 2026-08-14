# task-013: Test the state-file review exclusion, in the RS03 shape

[!NOTE]
This is the TASK-LEVEL DETAIL.md file. It is the IMMUTABLE DEFINITION for this task.
Written once by the `/aid-refactor` shortcut engine's DETAIL state; not a state file. This is a
flattened Lite work, so there is NO sibling `task-013/STATE.md` -- this task's mutable cells live
only in the work-root state file's `### Tasks lifecycle` table.
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

**Source:** work-009-refactor -> delivery-001

**Depends on:** task-012

**Scope:**
- A NEW canonical suite (`SPEC.md § L-8` item 4), in the shape
  `tests/canonical/test-kb-review-surface.sh` RS03 already uses for the KB's meta ledgers: extract
  the filter function from `canonical/aid/templates/reviewer-dispatch.md § ARTIFACTS UNDER REVIEW`
  and assert its behavior, so the doc and the asserted behavior cannot drift apart.
- `tests/canonical/test-kb-review-surface.sh` itself must NOT be edited -- it references only the
  out-of-scope discovery-area ledger, and editing it is a scope defect. This is a sibling suite,
  e.g. `tests/canonical/test-state-review-surface.sh`, discovered by `tests/run-all.sh`'s glob.
- Assertions: the extracted filter drops every state-file path shape (work level,
  `deliveries/delivery-NNN/`, `deliveries/delivery-NNN/tasks/task-NNN/`, both layouts, both
  `STATE.md` and `STATE.yml`) and keeps every authored-artifact path (`REQUIREMENTS.md`, `SPEC.md`,
  `PLAN.md`, `BLUEPRINT.md`, `tasks/task-NNN/DETAIL.md`), plus a static assertion that no brief
  template names a state file inside an `ARTIFACTS` block -- scanning
  `canonical/aid/templates/reviewer-dispatch.md`, every
  `canonical/skills/*/references/reviewer-brief.md`, and
  `canonical/aid/templates/shortcut-engine.md § GATE`.
- The discovery-area ledger path `.aid/knowledge/STATE.md` is asserted to remain outside this
  filter's concern -- it is already excluded by `list_reviewable`, and this suite must not claim
  ownership of it.
- Follows the repo's suite conventions (`test-landscape.md § Suite Authoring (S1-S5)`): its own
  summary line, per-assertion ids, `timeout`-safe, hermetic temp dirs, no network.
- OUT of this task: the mechanism itself (task-012); the grading half of SP-13, which is asserted
  by inspection of a real cycle in task-019, not by this static suite; `grade.sh`.

**Acceptance Criteria:**
- [ ] A new suite exists under `tests/canonical/`, is discovered by `tests/run-all.sh`, and prints
      its own PASS/FAIL summary line with per-assertion ids (`test-landscape.md`).
- [ ] The suite extracts the filter from `reviewer-dispatch.md` rather than re-implementing it, so a
      drift between doc and behavior fails the suite (the RS03 anti-drift property, SP-13).
- [ ] The filter drops all six state-file path shapes (three levels x `.md`/`.yml`, both layouts)
      and keeps all five authored-artifact shapes; each case is a named assertion (SP-13).
- [ ] A static assertion confirms no brief template names a state file inside an `ARTIFACTS` block,
      covering `reviewer-dispatch.md`, every per-skill `reviewer-brief.md`, and
      `shortcut-engine.md § GATE` (SP-13).
- [ ] `tests/canonical/test-kb-review-surface.sh` is byte-unchanged, and so are the other four
      discovery-ledger-only suites (`test-discover-preflight.sh`, `test-summarize-preflight.sh`,
      `test-kb-freshness-check.sh`, `test-grade-summary.sh`).
- [ ] The suite is deterministic, hermetic (its own temp dir, no `HOME` leakage), needs no network
      and cleans up after itself (`task-type-rules.md § TEST`).
- [ ] `HOME="$(mktemp -d)" bash tests/run-all.sh` includes the new suite in its aggregate and stays
      green, per its own summary line.
- [ ] A first-run failure is reported as a finding, not hidden.
- [ ] All section-6 quality gates pass.
