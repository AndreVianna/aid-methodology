# task-052: CLI home page UI specs (DESIGN) — machine panel + repo-card grid + unavailable/prune + `--target` residual meaning

**Type:** DESIGN

**Source:** feature-010-cli-home-and-registry → delivery-008

**Depends on:** task-048

**Scope:**
- Produce the UI breakdown for the CLI home page (`<install>/dashboard/index.html`, LC-HOME) grounded in the delivered feature-003/006 design family + the current `dashboard/index.html` (the relocated Level-0 `.card.plugin` markup at `index.html:516-523` is the visual donor for the machine panel). DESIGN only — no production code. Output a breakdown artifact under `.aid/work-001-aid-dashboard/design/` that task-053 implements verbatim.
- **UI-H1 shell + machine panel:** reuse feature-003 UI-1 shell (sticky top-bar, freshness badge, interval control, theme toggle, `meta robots noindex`, "served locally / read-only" footer); brand reads **"AID — this machine"**. The relocated Level-0 panel (`.card.plugin` family) renders the THREE parity-stable machine fields: `machine.aid_version` (CLI version; "CLI version unavailable" when null), `machine.aid_home` (install location), `machine.tools_catalog` (the manageable-tool catalog). **`machine.cli_runtime` is NOT rendered** (internal echo, parity-excluded).
- **UI-H2 repo-card grid:** responsive `.grid.g2`/`.g3` of `.card`, one per `repos[]`. Available card: `name` (settings.yml; folder-basename fallback — **never the raw path/id as a title**, feature-009 FR25 discipline), `description` (em-dash `—` when null), `aid_version` chip, `tools_installed` chips (per-repo installed tools; omitted when manifest absent), a "KB" affordance when `has_kb`. **Whole card** is the click target → `/r/<id>/home.html`. `has_home=false` → non-clickable card with a quiet "dashboard not generated yet" note (not a dead link). Client may re-sort by display name (model sorts by `path` for determinism).
- **UI-H3 unavailable/prune + empty-state:** `available=false` → muted "unavailable" treatment (greyed, `--text-dim`, ⊘ glyph reusing UI-4 Canceled vocabulary) showing the registered `path` + a **prune offer = step-by-step FR18 guidance** (`aid remove --target <path>`), **NOT** a write button (NFR2; MEMORY "ask-user-over-auto-proof"). Empty registry → friendly empty-state ("No repos registered yet — run `aid add <tool>`..."), never blank/error.
- **UI-H4 responsive:** reuse feature-003 UI-6 (768px single-column collapse, 2-col tablet, `max-width:1200px` desktop); baseline primitives only; no CDN/web-font at runtime.
- **Resolve residual #2 — `aid dashboard --target` residual meaning** (the CLI-2 detail item): recommend (a) auto-register + deep-link the cwd repo's `/r/<id>/home.html` on open (preserve the "run it in my repo, see my repo" ergonomic) vs (b) no-op-with-note. State the chosen option + rationale so task-049 (register side-effect) / task-055 (`--remote`) know whether `dashboard --target` triggers an auto-register/deep-link.

**Acceptance Criteria:**
- [ ] The breakdown pins UI-H1..UI-H4 grounded in the delivered design family + current `index.html` line refs (machine panel donor markup, top-bar/poll-loop reuse), concrete enough that task-053 implements without re-deciding.
- [ ] The machine panel renders only the three parity-stable fields (version/install-location/tools_catalog); `cli_runtime` is explicitly NOT rendered; per-repo installed tools are specified on the repo cards, not the machine panel (FR7/FR33 reconciliation).
- [ ] The repo card never renders the raw path/id as a title (folder-basename fallback), em-dash for null description, whole-card click → `/r/<id>/home.html`, `has_home=false` non-clickable note, `has_kb` affordance.
- [ ] The unavailable/prune treatment is guidance-only (no write surface, NFR2/FR18) and the empty-registry empty-state is specified.
- [ ] Residual #2 (`aid dashboard --target` meaning) is resolved with a recommended option + rationale, consumed by task-049/task-055.
- [ ] No production code modified (DESIGN).
