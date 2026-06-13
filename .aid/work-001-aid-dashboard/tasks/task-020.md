# task-020: feature-003 Playwright visual validation (R5 hard gate)

**Type:** TEST

**Source:** feature-003-pipeline-dashboard-app → delivery-002

**Depends on:** task-019, task-018

**Scope:**
- Per the project CLAUDE.md web-review gate (R5, hard): render the SERVED dashboard page in Playwright and VISUALLY validate the result — source/markup inspection is not sufficient and is an automatic FAIL.
- Start a server (task-016 or task-017) over the PT-1 fixture `.aid/` (task-018), take snapshots/screenshots, and confirm the page actually renders and behaves: AC1 stage rail + current position; AC2 parallel task chips side-by-side; AC3 attention states (amber Input / red Blocked, color + shape, reasons shown); the freshness badge; the interval control; NFR8 visual-family match; NFR5/NFR6 responsive across mobile/tablet/desktop viewports.
- Tailscale `serve` may be used to view the page privately for visual confirmation if needed.

**Acceptance Criteria:**
- [ ] The page is rendered in Playwright (screenshot/snapshot captured), not inspected as source; a source-only review is graded FAIL (R5).
- [ ] Visual validation confirms AC1 (stages + position), AC2 (parallel tasks side-by-side), AC3 (amber Input vs red Blocked, color+shape, reasons), and the freshness/interval controls behave.
- [ ] Responsive rendering is validated at mobile/tablet/desktop breakpoints (NFR6) and the page matches the `knowledge-summary.html` visual family (NFR8).
- [ ] The validation runs against a live served page (Python and/or Node server) over the fixture, with live ≤-interval updates observed (AC4).
- [ ] All §6 quality gates pass (REQUIREMENTS.md baseline).
- [ ] Tests are deterministic with clean setup/teardown (server start/stop) and cover the source ACs (AC1-AC5 visual surface); build passes.
