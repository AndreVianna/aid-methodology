# task-011: feature-002 fallback adapter + SM-2/SM-3 lifecycle derivation

**Type:** IMPLEMENT

**Source:** feature-002-state-reader-foundation → delivery-001

**Depends on:** task-010

**Scope:**
- Implement LC-3 Fallback Adapter (feature-002 Layers): reconstruct a work's lifecycle from LEGACY fragmented signals when `## Pipeline Status` is absent (migration window); set `source_mode=fallback`/`mixed`; register each fallback path as temporary tech-debt.
- Implement `derive_lifecycle(work) -> Lifecycle` (SM-2): preferred path returns the `## Pipeline Status` `Lifecycle` literal verbatim; fallback path applies the priority-ordered rules (1 Canceled → 2 Completed → 3 Blocked → 4 Paused-Awaiting-Input → 5 Running, first-match-wins, total) over today's template (feature-002 SM-2 table).
- IMPEDIMENT scan uses the FLAT `.aid/{work}/IMPEDIMENT-task-NNN.md` path (KI-003 — tracks task-001's KI-002 doc reconciliation); the top-blockquote `**User Approved:**` work-completion gate is deliberately EXCLUDED from the Paused primitive (feature-002 SM-2 prio-4 note).
- Implement SM-3 work-level rollup over per-task `Status` (FR14) — mirrors feature-001 §3 exactly so normalized and fallback agree; the rollup does not flatten the per-task list.
- Populate `pause_reason`/`block_reason`/`block_artifact`/`updated` per SM-1; heartbeat stays corroborating-only (never a lifecycle primitive); record `fallback_works` in `ReadMeta` (AC4 audit surface).

**Acceptance Criteria:**
- [ ] For any work, `derive_lifecycle` produces exactly one of {Running, Paused-awaiting-input, Blocked, Completed, Canceled} (FR16/AC3); the fallback priority order resolves multi-signal cases (e.g. Failed task + pending Q&A → Blocked).
- [ ] When `## Pipeline Status` is absent the fallback supplies the signals and `source_mode ≠ normalized` is recorded; `ReadMeta.fallback_works` lists those works (feature-002 AC4).
- [ ] The Blocked IMPEDIMENT scan uses the flat path (KI-003); the `**User Approved:**` terminal gate is excluded from the Paused primitive (no false Paused for a live work).
- [ ] SM-3 rollup matches feature-001 §3 and never collapses the per-task `tasks[]` list (FR14); heartbeat never demotes a Running work.
- [ ] Each fallback derivation path is tracked as temporary tech-debt (KI-003/KI-004 referenced), so M6 cutover (task-013) is auditable.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Unit tests for the new derivation + adapter functions added (fixture suite is task-012); existing tests pass; build passes.
