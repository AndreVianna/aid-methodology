# task-009: Reader (Python) — hierarchical per-unit STATE derivation + legacy fallback

**Type:** IMPLEMENT

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Extend the Python reader (`dashboard/reader/reader.py` `_read_work` + the parsers) to detect and derive from the hierarchy: if `delivery-NNN/tasks/task-NNN/STATE.md` files are present for a work, assemble the work model from the per-unit STATE.md files — per-task State/Review/Elapsed/Notes from each task STATE.md; the delivery's INDEPENDENT lifecycle enum (SD-8) + gate block + `## Cross-phase Q&A` from each `delivery-NNN/STATE.md`; the work-level `## Tasks State`, `## Plan / Deliveries`, `## Delivery Gates`, and `## Cross-phase Q&A` as DERIVED union views (per-delivery contributions plus any work-owner-authored work-level Q&A). Surface the delivery lifecycle state directly (it is authored, not derived from the task rollup — a delivery may be `Pending-Spec` with zero tasks per SD-9). Read the delivery/task `SPEC.md` for task definitions where needed.
- Presence-based per-work detection (Pillar 6): if no per-task STATE.md exists, fall back to the current monolithic inline-table parse (`reader.py:363-377` behavior preserved).
- Honor the renamed "state" section/field names; keep accepting legacy "Status" names on the fallback path for old works.
- Read-only by construction; never throws (parse_warnings on error). No reconcile yet (task-011) and no worktree enumeration yet (task-010) — single-root only.

**Acceptance Criteria:**
- [ ] For a hierarchical work, the reader derives the work model from per-unit STATE.md/SPEC.md files; `## Tasks State`/`## Plan / Deliveries`/`## Delivery Gates`/`## Cross-phase Q&A` are assembled union views; each delivery's independent lifecycle enum is surfaced (a `Pending-Spec` zero-task delivery renders correctly alongside an `Executing` sibling).
- [ ] For a legacy monolithic work, the reader falls back to the inline-table parse; both render in the same repo (presence-based detection).
- [ ] New "state" names parsed for hierarchical works; legacy "Status" names still parsed on the fallback path.
- [ ] Reader stays read-only and never throws (warnings on malformed input).
- [ ] All §6 quality gates pass.
