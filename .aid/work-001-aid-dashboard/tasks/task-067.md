# task-067: Playwright R5 visual gate — 5-state KB card (incl. outdated) + served kb.html

**Type:** TEST

**Source:** feature-007-kb-dashboard → delivery-009

**Depends on:** task-065, task-066

**Scope:**
- The hard R5 visual gate (project CLAUDE.md policy + UI-A web-review gate): **render the pages in Playwright and visually validate** — source-only review is an automatic FAIL. Runs over a live d008 multi-repo server loaded with the task-066 fixture (the 5-state variants + a frozen git tip) so the rendered card states are real, not invented.
- **5-state KB card visual validation** (the card on `home.html`, served at `/r/<id>/home.html`): render and screenshot each of the **5** states —
  - `pending` (⊘ "No KB", dead card), `generating` (◴ "Building", non-link), `preparing` (◴ "Preparing", non-link), `approved` (✓ "Ready", **clickable**), `outdated` (⚠ "Outdated", **clickable** + the FR18 refresh prompt "run `/aid-housekeep`").
  Confirm the clickable vs dead affordance is visually distinct per state (only approved/outdated link), the badge color+shape matches UI-A, and the outdated refresh prompt renders.
- **Served `kb.html` + navigation seam (FR31):** click the `approved` (and the `outdated`) card → the browser resolves `./kb.html` to `/r/<id>/kb.html` and the **served `kb.html` renders** (the relocated aid-summarize output, the `knowledge-summary/` visual family) — confirm it loads as a self-contained page, not a 404. Confirm the `outdated` card still opens the stale `kb.html`.
- Validate across the responsive breakpoints + dark theme (NFR8); zero JS console errors. Tailscale may serve the page privately for the visual confirmation (global CLAUDE.md). Capture screenshots for each validated state + the served `kb.html`.
- Read-only / no-write throughout (NFR2) — the gate observes, never mutates `.aid/`; the server stays bound to `127.0.0.1`.

**Acceptance Criteria:**
- [ ] All **5** KB-card states are rendered in Playwright (not source-inspected) and screenshotted: `pending`/`generating`/`preparing` (each a non-link dead card) and `approved`/`outdated` (each clickable), with the badge color+shape per UI-A and the `outdated` FR18 refresh prompt visible; the clickable-vs-dead affordance is visually distinct.
- [ ] Clicking the `approved` (and `outdated`) card resolves `./kb.html` → `/r/<id>/kb.html` and the **served `kb.html` renders** as a self-contained page (relocated aid-summarize output, `knowledge-summary/` visual family) — not a 404; the `outdated` card opens the stale page.
- [ ] Dark theme + responsive breakpoints are visually confirmed; zero JS console errors across all states.
- [ ] Screenshots are captured for each of the 5 card states + the served `kb.html`.
- [ ] No `.aid/` is mutated during the gate (read-only, NFR2); the server stayed bound to `127.0.0.1` for the run.
- [ ] All §6 quality gates pass; the R5 hard gate is satisfied by visual (Playwright) validation, not source review.
