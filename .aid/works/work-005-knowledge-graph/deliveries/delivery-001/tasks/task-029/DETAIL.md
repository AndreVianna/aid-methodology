# task-029: Disposition the open LOW and MINOR ledger rows

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-029/STATE.md.
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

**Type:** DOCUMENT

> **TYPE OVERRIDE and a scope bound.** DOCUMENT is correct for this task's product -- a disposition
> recorded against every open ledger row. But the Scope below contemplates *fixing* rows, which is not
> DOCUMENT work. The bound: this task **disposes** (Accepted / Invalid / OOS with a stated reason) and
> **routes** anything real-but-deferred into `.aid/knowledge/tech-debt.md`. It does **not** implement
> fixes. A row whose correct disposition is "fix it" is routed to the owning feature as its own work,
> not repaired here -- which also keeps the B- floor's "permitted" and this task's "dispositioned"
> from collapsing into each other.

**Source:** feature-013-tests-and-docs -> delivery-001 (Wave 5)

**Depends on:** task-028

**Scope:**
- **33 `[LOW]` and 24 `[MINOR]` rows were `Pending` when this task was authored.** Those two figures
  were counted on disk and were exact then. **This task deliberately states no file count for the
  ledger directory, and no count stated here may be trusted as current.** That is a correction applied
  twice: the first version said "the fifteen feature-SPEC ledgers", which was simply wrong; the second
  replaced it with a file total that was *also* wrong before the same review finished, because a review
  that produces a ledger writes it into this very directory -- so the denominator moved underneath the
  sentence describing it. A count of this directory is not a fact about the work; it is a fact about how
  many reviews have run.
  **Derive the set at execution time and sweep every file it returns:**
  `find .aid/.temp/review-pending -maxdepth 1 -type f -name "*.md"`
  Expect the feature-scoped SPEC ledgers, the delivery gate, requirements-completeness, the specify
  batches and the Detail-phase task ledgers -- but treat **whatever the command returns** as the scope,
  including files this description did not anticipate, and re-count the Pending rows rather than reusing
  the figures above. The `minimum_grade: B-` floor **permits** them — but
  "permitted" is not "dispositioned", and an undispositioned `Pending` row is indistinguishable from
  a forgotten one.
- Set each row to a terminal status with a reason: `Fixed`, `Accepted`, `Invalid` or `OOS`. Where a
  row is real but deferred, move it into `.aid/knowledge/tech-debt.md` as its own inventory entry
  plus detail, so the deferral is tracked rather than buried in a transient ledger.
- Before fixing anything, **re-validate the row's premise against disk evidence**. If the premise is
  false, close it as `Invalid` with the disproof — no security theatre — and surface any real residual
  the disproof exposes.

**Acceptance Criteria:**
- [ ] **Zero rows left `Pending`** across all ledgers in `.aid/.temp/review-pending/` at the gate
- [ ] Every disposition carries a reason; `Accepted` rows state what makes them acceptable at the B-
      floor, not merely that the floor allows them
- [ ] The 7-column ledger schema is preserved
      (`# | Severity | Status | Doc | Line | Description | Evidence`), with no narrative or summary
      sections added
- [ ] Status values are **plain text** from the closed enum — glyphs are decorative and display-only,
      never machine-parsed values
- [ ] Each row's premise is re-validated against disk before any fix; a false premise closes as
      `Invalid` with the disproof recorded
- [ ] A finding treated as a **class**, not an instance: where a row cites one example, the extent is
      swept and every instance dispositioned together
- [ ] Any row promoted to `tech-debt.md` carries both an inventory line and a detail entry
- [ ] Nothing is silently deleted; every row's outcome is traceable
- [ ] **Accuracy verified against the current codebase** (DOCUMENT type-default,
      `task-decomposition.md`:182). Already discharged in substance by this task's premise re-validation
      rule, and recorded here so the default is not read as missing: a disposition written against a
      premise that no longer holds on disk is exactly the inaccuracy this default guards against
- [ ] All section-6 quality gates pass
