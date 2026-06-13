# task-053: CLI home `index.html` (LC-HOME) — machine panel + repo-card grid + poll `/api/home` + unavailable/prune

**Type:** IMPLEMENT

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-052, task-050, task-054

**Scope:**
- Implement the CLI home page `dashboard/index.html` (LC-HOME) per task-052's breakdown — the NEW machine/CLI entry point served at `/` by the multi-repo server (DR-2). A single ready-to-serve HTML+inlined-CSS/JS file (no build, no CDN, NFR8); reuses feature-003's shell/top-bar/theme/freshness-badge/interval-control/poll-loop machinery wholesale.
- **FF-3 poll loop:** self-rescheduling `setTimeout`, single in-flight, default 5000ms from `localStorage`; `fetch('/api/home')` same-origin; on 200 check `schema_version !== EXPECTED` → stale-assets banner + keep-last-good; render machine panel (`machine.*`) + repo-card grid (`repos[]`); on error/timeout keep-last-good + "reconnecting" badge (never blank).
- **Render (UI-H1/H2/H3):** machine panel (the three parity-stable fields; `cli_runtime` NOT rendered); repo-card grid (name with folder-basename fallback / never path-as-title, em-dash null description, `aid_version` chip, `tools_installed` chips, `has_kb` affordance, whole-card click → `/r/<id>/home.html`, `has_home=false` non-clickable note); unavailable cards (muted ⊘ + path + FR18 prune *guidance*, not a write); empty-state.
- **`EXPECTED` constant** = the DM-2 `/api/home` `schema_version` (its own wire-shape int, independent of `/api/model`'s).
- **Invariants (LC-HOME, NFR2/NFR7):** mutate no `.aid/`; no agent/LLM; same-origin `fetch` only; no runtime CDN/web-font. This is a NEW file at `dashboard/index.html`. The path was previously the per-repo main page, which **task-054 renames away to `home.html` first** — this task encodes a `Depends on: task-054` edge so the create-new lands strictly after the rename-away, making the same-path non-collision **dependency-enforced** (not merely wave-derived). After task-054, the two front-end writers own different files (task-054 → `home.html`; this task → the new `index.html`) and never contend.
- Responsive per UI-H4. The Playwright R5 visual validation is task-058 (not here).

**Acceptance Criteria:**
- [ ] `index.html` boots, polls `/api/home`, and renders the machine panel (version/install-location/tools_catalog only — `cli_runtime` not shown) + a repo-card per `repos[]`; clicking an available card navigates to `/r/<id>/home.html`.
- [ ] A null `machine.aid_version` shows "CLI version unavailable" (no error); a null repo `description` shows `—`; a card never shows the raw path/id as its title (folder-basename fallback); `has_home=false` renders a non-clickable "dashboard not generated yet" note; `has_kb` shows the KB affordance.
- [ ] An `available=false` card renders the muted unavailable treatment + the FR18 prune *guidance* (no write surface, NFR2); the empty registry renders the friendly empty-state, never blank/error.
- [ ] `schema_version !== EXPECTED` raises the stale-assets banner and keeps last-good; an error/timeout keeps last-good + "reconnecting" badge.
- [ ] Static self-checks: no `.aid/` write, no agent/LLM import, same-origin fetch only, no runtime CDN/web-font; responsive collapse per UI-H4.
- [ ] All §6 quality gates pass; IMPLEMENT default — static/DOM assertions for the render paths added; existing tests pass (visual R5 gate is task-058).
