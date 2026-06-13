# task-028: feature-006 front-end — hash router + card grid + KB card + L0 panel + empty-state + render(model, selectedWorkId)

**Type:** IMPLEMENT

**Source:** feature-006-project-main-page → delivery-004

**Depends on:** task-027, task-019

**Scope:**
- Implement, front-end-only inside feature-003's `index.html` (no server / `/api/model` / `schema_version` / bind / poll-loop change), per the task-027 breakdown:
  - LC-MV hash router (FC-1/FC-2/FC-3): parse `location.hash` → `""`/`#/` = main, `#/work/<work_id>` = pipeline (find-by-`work_id`, never index-by-position), `#/kb` = KB seam; handle back/forward (`hashchange`) and unknown/stale `work_id` (notice + back link, never blank).
  - LC-CG card grid (`model.works[]`, `work_id`-asc) + LC-WC work-card (name, mini phase rail, lifecycle badge + FR11 amber/red attention emphasis + pin-to-top, `updated`/`tasks.length`/`source_mode` chip; whole card → `#/work/<work_id>`).
  - LC-KB KB summary card (`model.repo.kb_state` summary fields; → `#/kb` SEAM-1; `null` → graceful "No KB yet", non-clickable).
  - LC-L0 Level-0 CLI panel (`model.tool`; `manifest_present:false` → "tool info unavailable", never error).
  - LC-ES FR18 step-by-step empty-state when `works==[]` (exact `/aid-interview` command + verify-on-next-poll; KB card + L0 panel still render).
- Extend feature-003's render to `render(model, selectedWorkId)` so the router can target a specific work's pipeline view (front-end-only extension; PT-1/server untouched). Cards re-render live on the shared poll loop (FR4/NFR3). Responsive (UI-6) + baseline cross-browser primitives; `localStorage`-only client state (NFR2/NFR7).

**Acceptance Criteria:**
- [ ] The main page shows a card per work with its lifecycle state, and clicking a card opens that work's pipeline view (`#/work/<work_id>`, find-by-key) — FR3/FR16; back/forward works; an unknown/stale `work_id` shows a notice, never blanks.
- [ ] Blocked/awaiting-input cards are visually called out (amber Input / red Blocked, color+shape, left-border + pin-to-top) reusing feature-003's scheme (FR11/DD-2); an unrecognized lifecycle renders a neutral badge without throwing.
- [ ] The KB summary card (→ `#/kb` SEAM-1; `null` graceful) and the Level-0 CLI panel (FR7) render; one project per page (FR9, single `project_name` + `works[]`, no aggregation).
- [ ] The FR18 step-by-step empty-state renders when `works==[]` (exact command + verify), with the KB card + L0 panel still shown.
- [ ] No server / `/api/model` / `schema_version` / bind / poll-loop change; cards refresh live on the shared loop; nothing written to `.aid/` and no agent/LLM (NFR2/NFR7); PT-1 unaffected (only client render logic changed).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] IMPLEMENT default: unit/behavior tests for the router + render(model, selectedWorkId) added where feasible; existing tests pass; build passes (Playwright visual validation is task-029).
