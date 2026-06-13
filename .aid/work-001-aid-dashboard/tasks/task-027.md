# task-027: feature-006 UI Specs — main-page cards/layout (work cards, KB card, L0 panel, empty-state)

**Type:** DESIGN

**Source:** feature-006-project-main-page → delivery-004

**Depends on:** task-019

**Scope:**
- Produce the implementable UI breakdown for the Level-1 project main page (feature-006 UI-1..UI-6), grounded in the `knowledge-summary/` design family (NFR8) and reusing feature-003's app shell (top bar / theme / footer / freshness badge) — the main page swaps only the `<main>` body.
- Specify: the two-section layout (Pipelines `.grid.g3` work cards + Knowledge & Tool `.grid.g2`); the work-card (UI-3 — `work_id` kicker, name, mini phase rail, lifecycle badge mapping reusing feature-003 UI-4's two-color amber/red color+shape scheme, attention emphasis amber/red left-border + pin-to-top for Paused/Blocked, `updated`/`tasks.length`/`source_mode` meta, whole-card click → `#/work/<work_id>`); the KB summary card (UI-4 — `doc_count`/`summary_approved`/`last_summary_date`, click → `#/kb` SEAM-1, `null` → graceful non-clickable "No KB yet"); the Level-0 CLI panel (UI-5 — `model.tool` as a `.card.plugin` dl, `manifest_present:false` → "tool info unavailable"); the FR18 step-by-step empty-state when `works==[]` (UI-5 — exact `/aid-interview` command + verify-on-next-poll).
- Specify the hash-router seams (DD-1 — `#/`, `#/work/<id>`, `#/kb`) and the `render(model, selectedWorkId)` selection-param extension to feature-003's render. Responsive (UI-6 — 768px collapse, auto-fit minmax) + baseline cross-browser primitives.

**Acceptance Criteria:**
- [ ] The breakdown names the exact `knowledge-summary/` assets per component (`.card`/`.grid.g2/g3`/`.badge-*`/design tokens + feature-003 shell), satisfying NFR8; no new palette.
- [ ] The work-card lifecycle badge reuses feature-003 UI-4's two-color amber-Input/red-Blocked color+shape mapping verbatim (DD-2), with FR11 attention emphasis (left-border + pin-to-top) for Paused/Blocked and the unrecognized-literal neutral fallback.
- [ ] The KB card (SEAM-1 `#/kb`), Level-0 panel (FR7), one-project-per-page (FR9), and the FR18 step-by-step empty-state (command + verify, not a one-line hint) are each specified against the `/api/model` slice they read (no new model).
- [ ] The hash-routing decision (DD-1, no `pushState`) and the `render(model, selectedWorkId)` front-end-only extension are documented; responsive breakpoints + the AC → component map are included.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] DESIGN default: design tokens reused + responsive layout specified; rationale + trade-offs documented; grounded in the feature-006 SPEC.
