# task-030: feature-007 UI Specs — KB dashboard (doc inventory, freshness/summary, FR18 remediation)

**Type:** DESIGN

**Source:** feature-007-kb-dashboard → delivery-005

**Depends on:** task-028

**Scope:**
- Produce the implementable UI breakdown for the dedicated KB dashboard behind feature-006's `#/kb` route (SEAM-1), grounded in the `knowledge-summary/` design family (NFR8) and feature-003's shared app shell (feature-007 UI-1..UI-6).
- Specify the layout: the at-a-glance `.grid.g3` row (KB completeness card, INDEX freshness card, Summary status card) + the DOCUMENTS doc inventory (table on desktop, stacked `KbDoc` cards on mobile).
- Specify the doc table (UI-2 — name/category-badge/status-badge/last-reviewed/notes from `KbModel.docs[]`; known status literal "Populated" → `.badge-ok`, Pending/Stub-like → `.badge-warn`, unrecognized → `.badge-dim` verbatim, never throws; status rendered, never re-derived); the freshness + summary panels (UI-3 — `index.state` fresh/stale/unknown chip with the cheap-proxy reason + "likely stale" wording per KI-007; `summary` approval/grade/dates + `output_present`); and the FR18 step-by-step remediation panels (UI-4 — no-KB, INDEX stale, docs incomplete, summary unapproved/behind — each with the exact verified command + a verify-on-next-poll step). Responsive (UI-6) + baseline primitives.

**Acceptance Criteria:**
- [ ] The breakdown names the reused `knowledge-summary/` assets per component (same family as feature-006), satisfying NFR8; no new palette.
- [ ] The doc inventory maps `KbModel.docs[]` columns verbatim (name/category/status/last-reviewed/notes) with status rendered literally (known→colored badge, unknown→neutral, never re-derived/no LLM, NFR7).
- [ ] The freshness chip reflects the DD-3/KI-007 cheap-proxy semantics ("likely stale", authoritative gate is CI) and the summary panel surfaces approval/grade/dates/output presence.
- [ ] The four FR18 remediation panels are specified with their exact verified commands (`build-kb-index.sh` invocation, `/aid-discover`, `/aid-housekeep`, `/aid-summarize`) + verify-on-next-poll steps, appearing only when the trigger is active.
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] DESIGN default: design tokens reused + responsive layout specified; rationale + trade-offs documented; grounded in the feature-007 SPEC.
