# task-002: KB update — schemas.md + project-structure.md for the hierarchy + naming

**Type:** DOCUMENT

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-001

**Scope:**
- Update `.aid/knowledge/schemas.md` §4 (Work State) to describe the uniform unit hierarchy: work/delivery/task folders each with `STATE.md` (+ delivery/task `SPEC.md`); the per-level STATE schemas from task-001; the DERIVED-view rule (work `## Tasks State`, `## Plan / Deliveries`, `## Delivery Gates`, and `## Cross-phase Q&A` are assembled/unioned at read, never written); the delivery's INDEPENDENT lifecycle enum (SD-8: `Pending-Spec | Specified | Executing | Gated | Done | Blocked`, authored-not-derived per SD-9); the per-delivery `## Cross-phase Q&A` partition (moved off the shared work file); the "state" naming. Update §11 (Task File) to note the new path `delivery-NNN/tasks/task-NNN/SPEC.md` and the sibling task `STATE.md`. Update §12 (Delivery Issues Log) path if affected. Add a changelog row in the frontmatter following the §-header convention.
- Update `.aid/knowledge/project-structure.md` to show the new work-artifact tree (work → delivery → task folders) alongside the legacy monolithic layout it must coexist with; note the SD-1 boundary (features/ stays spec-axis, no STATE.md; delivery/ is the execution axis).
- Document SD-2 (advancement ordering), SD-3 (worktree discovery via `git worktree list` using the fixed-argv pattern; no allow-list assumed — optional hardening only), SD-8/SD-9 (independent delivery lifecycle), and the migration/coexistence rule (presence-based per-work detection).
- Regenerate `.aid/knowledge/INDEX.md` via `canonical/scripts/kb/build-kb-index.sh` if doc summaries change.

**Acceptance Criteria:**
- [ ] schemas.md §4/§11/§12 describe the hierarchy, per-level STATE schemas, DERIVED-view rule, and "state" naming; enum values unchanged.
- [ ] project-structure.md shows the new tree + the legacy-coexistence note + the SD-1 features/-vs-delivery/ boundary.
- [ ] SD-2/SD-3/SD-8/SD-9/migration rules are documented in the KB; the delivery lifecycle enum and the per-delivery Q&A partition are described.
- [ ] INDEX.md regenerated via the canonical script if summaries changed; KB-hygiene CI passes.
- [ ] All §6 quality gates pass.
