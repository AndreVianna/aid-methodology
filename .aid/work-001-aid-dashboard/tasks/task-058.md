# task-058: Playwright R5 visual gate — CLI home renders + click-through into a repo's `home.html`

**Type:** TEST

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-053, task-054, task-056

**Scope:**
- The hard R5 visual gate (project CLAUDE.md policy + feature-010 UI-H4): **render the served pages in Playwright and visually validate** — source-only review is an automatic FAIL. Runs over a live multi-repo server (task-050/051) loaded with the PT-1-H registry fixture (task-056) so the rendered data is real, not invented.
- **CLI home (`/`, task-053) visual validation:** the machine panel (version / install-location / tools_catalog; `cli_runtime` NOT shown); the repo-card grid (name with folder-basename fallback / never path-as-title, em-dash null description, `aid_version` + `tools_installed` chips, `has_kb` affordance); an **unavailable** card (muted ⊘ + path + prune *guidance*, no write button); a `has_home=false` non-clickable card; the **empty-state** (a fixture variant with an empty/absent registry); the stale-assets banner path (schema mismatch); dark theme + responsive collapse (768px). Zero JS console errors.
- **Click-through (the navigation seam, FR27):** click an available repo-card → lands on `/r/<id>/home.html` (the feature-006 per-repo page, task-054); confirm `home.html` renders its work-card grid + the **2-state** KB card and that the **Level-0 `.card.plugin` panel is absent** (FR33 removal verified visually); the per-work hash router still drills.
- Tailscale may serve the page privately for the visual confirmation (per global CLAUDE.md). Capture screenshots for each validated state.
- Read-only / no-write throughout (NFR2) — the gate observes, never mutates.

**Acceptance Criteria:**
- [ ] The CLI home is rendered in Playwright (not source-inspected): machine panel (3 fields, no `cli_runtime`), repo-card grid, an unavailable card (guidance-only prune, no write button), a `has_home=false` non-clickable card, the empty-state, the stale-assets banner, dark theme, and 768px responsive collapse — all visually confirmed with zero JS console errors.
- [ ] Clicking an available repo-card navigates to `/r/<id>/home.html` and that page renders the work-card grid + the **2-state** KB card; the Level-0 `.card.plugin` panel is **visually absent** from `home.html` (FR33 removal); the per-work hash router still drills.
- [ ] Screenshots are captured for each validated state (CLI-home states + the click-through into `home.html`).
- [ ] No `.aid/` is mutated during the gate (read-only, NFR2); the server stayed bound to `127.0.0.1` for the run.
- [ ] All §6 quality gates pass; the R5 hard gate is satisfied by visual (Playwright) validation, not source review.
