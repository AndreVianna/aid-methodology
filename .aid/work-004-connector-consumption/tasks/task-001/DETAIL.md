# task-001: Extract the shared connectors/reconcile.md (bulk + single-stem) and refactor state-elicit.md to reuse it

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

**Source:** work-004-connector-consumption -> delivery-001

**Depends on:** — (none)

**Scope:**
- Extract the registry-reconcile logic currently inline in
  `canonical/skills/aid-discover/references/state-elicit.md` (the "Reconcile the registry (Steps
  R0-R5)" block) into a new shared reference `canonical/aid/templates/connectors/reconcile.md`.
- `reconcile.md` documents **both** modes explicitly:
  - **bulk** (ELICIT): reconciles the whole *declared* set against the *persisted* registry —
    REMOVE = stems in `persisted ∖ declared`. This is ELICIT's existing R0–R5 logic, relocated
    **verbatim** (same E2 markers `ENGAGED`/`DECLARED-EMPTY`/`SKIPPED`; same ADD/UPDATE/NO-OP/REMOVE
    classification; same purge + INDEX-rebuild + trace outcomes).
  - **single-stem** (set/unset): operates on **exactly one** target stem — ADD/UPDATE for `set`,
    REMOVE for `unset` — and **never** diffs against the rest of the registry, so other connectors
    are never classified REMOVE. `build-connectors-index` then rebuilds `INDEX.md` from whatever
    descriptors remain on disk. This is the only net-new reconcile behavior documented here.
- Replace the extracted block in `state-elicit.md` with a pointer to `reconcile.md` (bulk mode);
  the E2 branch and the R0–R5 outcomes remain behaviorally identical (regression-free — AC7).
- Markdown-only: no changes to `connector-registry`, `connector-secret`, or
  `build-connectors-index`. `reconcile.md` lives under `canonical/aid/templates/connectors/`
  (rendered verbatim by `/generate-profile` in task-006).

**Acceptance Criteria:**
- [ ] `canonical/aid/templates/connectors/reconcile.md` exists and documents both the **bulk**
  (ELICIT) and **single-stem** (set/unset) reconcile modes, including the single-stem guarantee that
  connectors other than the target stem are never classified REMOVE and never touched (traces to AC6, AC7).
- [ ] `state-elicit.md`'s inline R0–R5 reconcile block is replaced by a pointer to `reconcile.md`
  bulk mode; the E2 branch (`ENGAGED`/`DECLARED-EMPTY`/`SKIPPED`) and R0–R5 ADD/UPDATE/NO-OP/REMOVE
  outcomes are behaviorally unchanged (traces to AC7).
- [ ] No changes to `connector-registry`, `connector-secret`, or `build-connectors-index` — the
  extraction is markdown-only (traces to AC7).
- [ ] All section-6 quality gates pass.
