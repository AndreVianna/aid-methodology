# task-029: feature-006 Playwright visual validation (R5 hard gate)

**Type:** TEST

**Source:** feature-006-project-main-page → delivery-004

**Depends on:** task-028

**Scope:**
- Per the project CLAUDE.md web-review gate (R5, hard): render the served main page in Playwright and VISUALLY validate — source/markup inspection is an automatic FAIL.
- Over a fixture `.aid/` with multiple works in varied lifecycle states (incl. Blocked/Paused, a fallback-`source_mode` work) and a KB present + a KB-absent variant + an empty-works variant: screenshot/snapshot and confirm the page renders the card grid with each lifecycle state, the FR11 attention emphasis (amber/red left-border + pin-to-top), click-to-drill navigation to `#/work/<id>`, the KB-card → `#/kb` seam, the Level-0 panel, and the FR18 step-by-step empty-state — across mobile/tablet/desktop breakpoints (NFR6) and matching the visual family (NFR8).
- Tailscale `serve` may be used to view privately for confirmation if needed.

**Acceptance Criteria:**
- [ ] The page is rendered in Playwright (screenshots captured) and visually validated; a source-only review is graded FAIL (R5).
- [ ] Validation confirms the work-card grid per lifecycle state, FR11 attention emphasis, click-to-drill to the pipeline view, the KB-card `#/kb` seam, the Level-0 panel, and the FR18 empty-state.
- [ ] Responsive rendering validated at mobile/tablet/desktop (NFR6); the page matches the `knowledge-summary.html` visual family (NFR8).
- [ ] Live card refresh on the shared poll loop is observed (a work flipping state updates within one interval).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean setup/teardown (server start/stop) and cover the source ACs (feature-006 ACs); build passes.
