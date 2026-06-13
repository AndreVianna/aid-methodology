# task-013: M6 — reader cutover: retire fallback per fully-migrated signal

**Type:** REFACTOR

**Source:** feature-002-state-reader-foundation / feature-001-pipeline-state-architecture → delivery-001

**Depends on:** task-009, task-011

**Scope:**
- Reader-readiness cutover (feature-001 §4 M6 + feature-002 LC-3 "temporary by construction"): for each signal feature-001 has now fully migrated (M1-M5 shipped + walk-through-verified in task-009), switch the reader off its legacy fallback branch.
- Delete the corresponding LC-3 fallback derivation path(s) and close the matching temporary tech-debt entry; update the KI-003 IMPEDIMENT-path coupling now that task-001 reconciled the canonical path (the reader's hard-coded flat scan stays correct, the coupling note is resolved).
- Confirm `source_mode=normalized` is now produced for a freshly-run work (the `## Pipeline Status` block present), with fallback retained only for not-yet-migrated/legacy works.
- No behavior change to a reader consumer — same `RepoModel` shape, same lifecycle results; only the derivation source for migrated signals changes.

**Acceptance Criteria:**
- [ ] For each fully-migrated signal, the reader returns the normalized `## Pipeline Status` value and the corresponding LC-3 fallback branch is removed; the temporary tech-debt entry is closed.
- [ ] KI-003's IMPEDIMENT-path coupling is resolved in lockstep with task-001's reconciliation (reader scan path remains the flat canonical path).
- [ ] A freshly-run work reads as `source_mode=normalized`; legacy works still read correctly via the retained fallback; lifecycle results are identical before and after (no behavior change).
- [ ] `ReadMeta.fallback_works` accurately reflects the reduced fallback surface.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] **C4 behavior preservation:** reader tests (task-012 suite) pass before and after the cutover with no observable behavior change; build passes; any observable pipeline-behavior change is a CRITICAL finding.
