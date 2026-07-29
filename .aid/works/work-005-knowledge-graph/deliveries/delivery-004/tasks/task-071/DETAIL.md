# task-071: `test-graph-view-shell.sh` GV06-GV08 assertions

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

**Source:** work-005-knowledge-graph -> delivery-004

**Depends on:** task-070

**Scope:**
- Add `GV06`, `GV07` and `GV08` to `tests/canonical/test-graph-view-shell.sh`, completing the
  GV series (`GV01` from task-054, `GV02`-`GV05` from task-070).
- `GV06` -- a fixture with a deliberately wrong `kb_gaps`: the load-time check reports the exact
  `viewOnly` / `ledgerOnly` ids, `coverageGaps.intUndocumented` is the union, and **both
  renderings still mount**.
- `GV07` -- the full zero-row contract, all seven clauses in one labelled assertion group.
- `GV08` -- every rendered copy of `coverage-predicate.mjs` under `profiles/` is byte-identical to
  the canonical file.
- **Out of scope:** `GV01`-`GV05`, which tasks 054 and 070 own and this task must not disturb;
  fixing any product defect a new assertion exposes -- that is the owning IMPLEMENT task's
  (059-065) work, never a reason to soften the assertion.

**Acceptance Criteria:**
- [ ] `GV06` asserts, over a fixture whose `kb_gaps` disagrees with the table in **both**
      directions: the reported `viewOnly` set is exactly the expected ids, the reported
      `ledgerOnly` set is exactly the expected ids, `coverageGaps.intUndocumented` equals the
      sorted union, the `console.error` line carries the stable prefix
      `graph.html: kb_gaps integrity check failed`, and both the table and the graph mount points
      are populated.
- [ ] `GV07` asserts **every** clause of the zero-row contract for a `kb_gaps` entry with no table
      row: a complete `Node` record carrying the entry's `name`; `degree === 0`;
      `coverageOrigin === 'ledger-only'`; **no** mismatch alarm (the `role="alert"` container stays
      empty and no `console.error` is written); presence at `density: 1`; membership of the
      `no relationships` group under both `relation-category` and `provenance` grouping; and a row
      in feature-009's zero-row region.
- [ ] `GV08` compares every `profiles/*/**/coverage-predicate.mjs` to the canonical file byte for
      byte and fails naming any tree that differs -- the fixed-point property boundary rule 5
      buys. The suite may name `canonical/…` freely, since `tests/` sits outside `canonical/` and
      is never rendered.
- [ ] `GV01`-`GV05` are untouched: the diff adds assertions only, and the suite reports the full
      `GV01`-`GV08` series passing -- the delivery gate's requirement.
- [ ] **Tests are deterministic** (TEST default): repeated runs give the same result, with no
      dependence on wall-clock time, network, or file ordering.
- [ ] **Clean setup/teardown** (TEST default): fixtures built under `mktemp -d` and removed on
      exit; no dependence on any work folder (**A-6**); `tests/lib/assert.sh` sourced; the
      `ID + description` label convention followed.
- [ ] Source-feature coverage: with this task the whole of feature-007 § Tests (`GV01`-`GV08`) is
      present, including the view side of AC-15 -- which the delivery gate records as satisfied
      but **not closed**, since feature-006 owns the criterion and feature-008 the graph side.
- [ ] `bash tests/canonical/test-graph-view-shell.sh` exits 0 and is discovered by
      `tests/run-all.sh` with no runner edit.
- [ ] The code baseline of `.aid/knowledge/coding-standards.md` and `.aid/knowledge/quality-gates.md`
      holds, and the delivery gate's `grade.sh` run over `.aid/.temp/review-pending/` reaches the
      resolved `review.minimum_grade` of **A+** -- zero findings with Status `Pending` or
      `Recurred`.
