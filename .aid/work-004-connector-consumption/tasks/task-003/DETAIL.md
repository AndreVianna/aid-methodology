# task-003: aid-unset-connector skill

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

**Type:** IMPLEMENT

**Source:** work-004-connector-consumption -> delivery-001

**Depends on:** task-001

**Scope:**
- Author `canonical/skills/aid-unset-connector/SKILL.md` — `aid-unset-connector <tool>`: remove a
  connector, **single-stem**, on-demand / off-pipeline (never invokes or requires `aid-discover`).
- **Feature flow:** resolve `<tool>` → descriptor stem → run the shared `reconcile.md` **single-stem
  REMOVE** (`connector-secret purge` → delete the one descriptor) → `build-connectors-index`
  rebuilds `INDEX.md` from the remaining descriptors. Never diffs the registry (no `list`, no `read`
  on the missing stem); `connector-secret purge` runs **unconditionally** against `<tool>`'s stem
  whether or not it is currently catalogued — on an **absent** stem it is a clean idempotent no-op
  (deletes nothing, exits 0), never a special-cased branch that checks first and skips the purge.
- **Write-zone:** only `.aid/connectors/` (P7 exemption). Reuses existing scripts only
  (`connector-secret`, `build-connectors-index`); **no new scripts**.

**Acceptance Criteria:**
- [ ] `aid-unset-connector Jira` removes `.aid/connectors/jira.md`, purges its secret via
  `connector-secret purge`, and drops the `INDEX.md` row (traces to AC5).
- [ ] A second `aid-unset-connector Jira` on an already-absent stem is a clean no-op (idempotent) —
  no error, no registry churn (traces to AC5).
- [ ] With ≥2 connectors catalogued, `aid-unset-connector` on one stem leaves every other
  connector's descriptor + secret untouched (single-stem REMOVE via `reconcile.md`, never a
  whole-registry diff) (traces to AC6).
- [ ] The skill writes only within `.aid/connectors/` (write-zone confinement) (traces to AC10).
- [ ] All section-6 quality gates pass.
