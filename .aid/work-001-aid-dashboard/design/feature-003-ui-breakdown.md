# feature-003 UI Breakdown — single-pipeline progress view (UI-1..UI-6)

**Type:** DESIGN output (task-015). Consumed verbatim by task-019 (`index.html` implementer) and
task-020 (Playwright visual gate). **Source of truth for fields:** `dashboard/reader/models.py`
(feature-002). **Source of truth for visual language:** `canonical/templates/knowledge-summary/`
(`design-tokens.md`, `component-css.css`, `html-skeleton.html`) per NFR8.

> **Scope:** this is the design only — it does NOT contain `index.html`. It reuses the existing
> palette verbatim (no new colors). Every component is mapped to a real `models.py` field and a real
> design-family asset.

> **Token-source note (load-bearing for task-019):** where `design-tokens.md` and
> `component-css.css` disagree on a hex value (`--accent` is `#00A3A1` in the doc but `#007F7D` in the
> CSS, light theme), **`component-css.css` is authoritative** — task-019 inlines the CSS file, not the
> doc. Implementer MUST copy the `:root` / `html[data-theme="dark"]` blocks from `component-css.css`
> verbatim and reference tokens by name (`var(--accent)`), never by literal hex.

---

## 0. Component → {design-family asset, model field} map (the index)

| Component | Reused design-family asset | Model field(s) read | AC |
|-----------|----------------------------|---------------------|----|
| UI-1 shell/header | `html-skeleton.html` `<header class="top-bar" role="banner">`, `.brand`, `.controls`, `#theme-toggle.btn-ghost`, `<main id="top">`, skip-link, `meta viewport`, `meta robots noindex`, system-font stack; `component-css.css` `.top-bar/.brand/.controls/.btn-ghost` | `model.repo.project_name`; `envelope.generated_by` (ENVELOPE-level sibling of `model` in `{schema_version, generated_by, model}` — NOT `model.generated_by`; footer) | NFR8/AC5 |
| UI-2 stage rail | `component-css.css` `.badge` + `.badge-primary`/`.badge-ok`/`.badge-dim`; new `.stage-rail` flex wrapper (design-family-styled) | `model.works[].phase` (`Phase` enum) | AC1 |
| UI-3 task chips | `component-css.css` `.grid.g3`/`.grid.g4`, `.card`, `.kicker`, `.meta`, `.badge-*` | `model.works[].tasks[]` → `.type`,`.wave`,`.status`,`.review_grade`,`.elapsed` | AC2 |
| UI-4 attention badge | `component-css.css` `.badge` + `.badge-accent`/`-warn`/`-err`/`-ok`/`-dim`; `.callout`/`.callout.warn`/`.callout.err` for reason strips; `.card` colored border | `model.works[].lifecycle`; `.pause_reason`,`.block_reason`,`.block_artifact`; `.pending_inputs[]` | AC3 |
| UI-5 interval control | `component-css.css` `.controls` + `.btn-ghost` styling; `<footer>` reword | `localStorage` (UI state, not model); echoed value only | AC4 |
| Freshness/data-note | `component-css.css` `.badge` + `.badge-ok`/`-warn`/`-err`; `.callout`/`.callout.warn` | `model.read.read_at`, `model.read.parse_warnings`, `model.read.fallback_works` | AC4 |
| UI-6 responsive | `component-css.css` `@media (max-width:768px)` (`.grid*→1fr`), `--radius*`, `max-width:1200px`, baseline primitives | — (layout, not data) | NFR5/NFR6 |

---

## UI-1. Design-family reuse (NFR8) — exact assets to inline

Reuse the `knowledge-summary/` shell, dropping the diagram/lightbox machinery the MVP does not need.

| Asset | Reused from | Used for |
|-------|-------------|----------|
| `:root` + `html[data-theme="dark"]` token blocks | `component-css.css` L7–63 | every color; status tokens `--ok/--warn/--err/--accent/--text-dim` carry meaning, reused verbatim |
| `.top-bar`, `.brand`, `.brand .dot`, `.controls`, `.btn-ghost`(+`:hover`,`:focus-visible`) | `component-css.css` L91–135, L604–609 | sticky header: project name · freshness badge · interval control · theme toggle |
| `#theme-toggle` markup (`.btn-ghost`, `#theme-icon`, `#theme-label`) | `html-skeleton.html` L29–34 | light/dark toggle, carried as-is |
| `.badge` + `.badge-ok/-warn/-err/-info/-purple/-primary/-accent/-dim` | `component-css.css` L186–206 | stage pills, task-status, attention, freshness |
| `.card`(+`:hover`), `.card .kicker/.stat/.stat-sub/.meta`, `.card-primary` | `component-css.css` L218–234 | work header card, task chips |
| `.grid` / `.grid.g2/.g3/.g4` | `component-css.css` L209–216 | task-chip clusters within a wave |
| `.callout`(+`.warn/.err/.ok`) | `component-css.css` L282–295 | pause/block reason strips + parse-warning data note |
| shell: `<!DOCTYPE>`, `<html data-theme="light">`, `meta charset/viewport/color-scheme`, `meta robots noindex`, system-font `body`, `* {box-sizing}`, `.skip-link`, `:focus-visible`, `prefers-reduced-motion`, `.sr-only`, `forced-colors`, `.noscript-fallback` | `html-skeleton.html` L1–18 + `component-css.css` L65–88, L575–658 | page skeleton + a11y baseline |
| `<header role="banner">`, `<main id="top">` | `html-skeleton.html` L21,39 | landmark structure |
| `<footer>` | `html-skeleton.html` L62–67 — **reworded** | "served locally by `aid dashboard` · read-only · refreshes every Ns" |
| `lightbox.js`, `mermaid-init.js`, `.lightbox`, `.mermaid-box`, the `<div class="lightbox">` block, `.toc`, `.hero` | `component-css.css` / `html-skeleton.html` | **NOT used in MVP** — drop entirely (no diagrams). Cited only as the cached-once path for a future diagram view. |

Constraints carried verbatim: system fonts only, CSS custom properties, **no web fonts, no CDN, no
external assets at runtime** (matches the footer claim NFR8), zero build step (CSS+JS inlined like
`html-skeleton.html`). `breadcrumb` from the skeleton is **repurposed**: in the single-pipeline MVP it
shows the active work's `work_id` · `name` rather than page nav.

---

## UI-2. Stage rail — "where we are" (AC1, FR8)

A horizontal **stage rail**: one pill per phase the active work carries, rendered from
`model.works[].phase`. Exact `Phase` enum literals (from `models.py` `class Phase`, in order):

`Interview` → `Specify` → `Plan` → `Detail` → `Execute` → `Deploy` → `Monitor`
(+ reader-only sentinel `Unknown`).

- **Pill markup:** `<span class="badge ...">` inside a `.stage-rail` flex strip
  (`display:flex; gap:.4rem; flex-wrap:wrap`). Each pill = one short word (the literal) + an optional
  glyph dot; FR8 "single short words, color + shape, minimal text."
- **Emphasis by position relative to the work's current `phase`:**
  - **current** phase → filled `.badge-primary` (light: `--primary` on `--primary-fg`); add a left
    `▸` marker glyph so "current" reads on shape, not color alone.
  - **prior** phases (ordinal < current in the canonical 7-stop order) → `.badge-ok` muted "done",
    `✓` glyph.
  - **later** phases (ordinal > current) → `.badge-dim` (`--text-dim`) "upcoming", `○` glyph.
- **`phase == null` or `Unknown`** → render a single neutral `.badge .badge-dim` "phase unknown" pill
  (NFR7: never crash on absent/unrecognized data; mirrors feature-002's `Unknown` discipline).
- **Full-vs-lite path is data-driven, not assumed.** The rail does NOT hard-code a fixed 7-stop path.
  It computes ordinal from the canonical order above only to decide done/current/upcoming, but renders
  **exactly the phase the work reports**. A lite-path work that never reaches `Detail` simply never
  shows `Detail` as "done." Do not synthesize phases the work hasn't entered.
- **Single-work MVP (FR9):** the page renders the **one active/selected work** (the multi-work card
  grid is feature-006). "Active" = first work whose `lifecycle` is non-terminal
  (`Running`/`Paused-Awaiting-Input`/`Blocked`), else the highest `work_id` (works arrive
  `work_id`-sorted per DM-2). The work header uses a `.card.card-primary` showing `work_id`, `name`,
  `active_skill`, `updated`.

---

## UI-3. Current + parallel task chips, wave-grouped (AC2, FR14)

Render `model.works[].tasks[]` **grouped by `wave`**; within a wave, **every task is its own chip
side-by-side** — never collapse parallel tasks into one "current task" (FR14). `TaskModel` fields
(from `models.py` `class TaskModel`): `task_id`, `type`, `wave` (`Optional[str]`), `status`,
`review_grade` (`Optional[str]`), `elapsed` (`Optional[str]`), `notes`.

- **Grouping:** stable group key = `wave`; preserve feature-002's source-row order within and across
  waves (DM-2: tasks are emitted in table order, wave grouping is the renderer's job). Tasks with
  `wave == null` form a trailing "ungrouped" cluster. Each wave = a labeled `<section>` with a
  `.kicker` ("Wave {wave}") and a `.grid.g3` (desktop) / `.grid.g4` (many short chips) of chips;
  wave groups stack vertically.
- **Chip = a compact `.card`** showing, top-to-bottom: `.kicker` = `type` (CODE/DESIGN/RESEARCH…);
  the `status` badge (UI-4 status colors below); `review_grade` as a small `.badge-info` if non-null
  ("Grade A" etc.); `.meta` = `elapsed` if non-null. `notes` is NOT surfaced on the chip (kept out of
  the at-a-glance view; available in feature-008 drill-down).
- **`TaskStatus` literals** (from `models.py` `class TaskStatus`) → chip status badge:

  | `TaskStatus` literal | badge class | glyph | shown word |
  |----------------------|-------------|-------|------------|
  | `Pending` | `.badge-dim` | ○ | Pending |
  | `In Progress` | `.badge-accent` | ▶ | In Progress |
  | `In Review` | `.badge-info` | ◑ | In Review |
  | `Blocked` | `.badge-err` | ✕ | Blocked |
  | `Done` | `.badge-ok` | ✓ | Done |
  | `Failed` | `.badge-err` | ✕ | Failed |
  | `Canceled` | `.badge-dim` | ⊘ | Canceled |
  | `Unknown` (reader sentinel) | `.badge` (neutral) | ? | Unknown |

  An **unrecognized** status string (forward-compat: a future feature-001 member) falls back to the
  neutral `.badge` "Unknown" treatment — never throws (DM-2 forward-compat rule, NFR7).
- **Foregrounding (FR14 at-a-glance):** a wave with any `In Progress`/`In Review` task is the **active
  wave** — full opacity, a thin `--accent` left border on the wave section. Waves with only
  `Pending` tasks are dimmed (`opacity:.65`). Terminal-only waves (all `Done`/`Canceled`) collapse to
  a one-line summary row (`✓ Wave {n} — N done`) so attention stays on live work.
- **Reflow (UI-6):** `.grid.g3/.g4` already collapse to `1fr` at ≤768px — N parallel chips that sit
  side-by-side on desktop stack into a column on mobile. No extra rule needed.

---

## UI-4. Attention signals — color **and** shape (AC3, FR11, FR8)

The work-level `model.works[].lifecycle` literal (derived by feature-002, never re-derived here) maps
to a badge pairing **distinct color + distinct glyph/shape + one short word**, so the states are
distinguishable on shape alone (robust under dark theme + the deferred color-blind work). Exact
`Lifecycle` literals from `models.py` `class Lifecycle`:
`Running` | `Paused-Awaiting-Input` | `Blocked` | `Completed` | `Canceled` (+ reader-only `Unknown`).

**Resolved FR16 two-color reading (amber Input / red Blocked) — the implementer/reviewer table:**

| `lifecycle` literal | Color token | CSS class | Glyph / shape | Word | AC3 bucket |
|---------------------|-------------|-----------|---------------|------|-----------|
| `Running` | `--accent` (teal) | `.badge-accent` | ▶ filled (optional subtle pulse on the freshness dot only) | "Running" | active |
| `Paused-Awaiting-Input` | `--warn` (amber) | `.badge-warn` | ❚❚ pause bars (rounded) | "Input" | **awaiting user input** (incl. confirmation/approval — same FR16 state) |
| `Blocked` | `--err` (red) | `.badge-err` | ✕ in octagon | "Blocked" | **error / failure / impediment** |
| `Completed` | `--ok` (green) | `.badge-ok` | ✓ check | "Done" | terminal |
| `Canceled` | `--text-dim` (grey) | `.badge-dim` | ⊘ slash | "Canceled" | terminal |

- **Unknown / unrecognized** `lifecycle` → neutral `.badge` "Unknown" (NFR7 forward-compat).
- **Active call-out (FR11 — "actively calls out," not merely lists):** when the active work is
  `Paused-Awaiting-Input` or `Blocked`, the page (a) gives the work header `.card` a colored left
  border (`--warn` / `--err`) and (b) renders a **top-of-page attention strip** above the stage rail
  using `.callout.warn` (Input) / `.callout.err` (Blocked).
- **Reasons surfaced read-only** (so the operator sees *why* and *where* without opening files):
  - `Paused-Awaiting-Input` → `.callout.warn` shows `pause_reason`; if `pending_inputs[]` is
    non-empty, list each `PendingInput.question_id` + `category`/`impact` as read-only `.meta` lines.
  - `Blocked` → `.callout.err` shows `block_reason` and the `block_artifact` path (e.g.
    `IMPEDIMENT-task-NNN.md`) rendered as inline `<code>`, **not a link** (read-only, no navigation;
    NFR2 — the page writes/opens nothing).
- **Design note worth user attention (carry forward — NOT a blocker, FR16 sub-distinction):** AC3
  literally lists three buckets — *waiting for input*, *waiting for a confirmation/decision*,
  *error/failure*. FR16 (authoritative) collapses the first two into the single
  `Paused-Awaiting-Input` state ("an approval is a kind of input"), and feature-002 derives them
  identically (no sub-kind on the wire). **This spec therefore renders TWO attention colors (amber
  Input / red Blocked), not three.** If an operator must visually distinguish "approval gate" vs "open
  question," that is a sub-distinction *within* the amber state and would require feature-001 to type
  the pause sub-kind — it does not today. **Flagged for confirmation; the spec assumes the FR16
  two-color reading is correct.** Reviewer/implementer: do not "fix" this to three colors without a
  feature-001 type change.

---

## UI-5. Refresh-interval control (FR5, AC4)

A control in `.controls` (top bar), labeled "Refresh", as a numeric input/stepper styled like
`.btn-ghost`.

- **Default 5000 ms** (FR5). On boot, read from `localStorage`; if absent/invalid, use 5000.
- **Clamp to [1s, 600s]** = `[1000, 600000]` ms. A 0/negative value would busy-loop (violates NFR4);
  an absurdly large value is harmless but bounded. Clamp on every change before use AND before
  persist.
- **Persist to `localStorage`** (key suggestion `aid-dashboard-poll-ms`) so it survives reload. This
  is **UI state, not model data** — it touches no `.aid/` file (NFR2).
- **Reschedule on change:** takes effect on the **next tick** (Feature Flow step 4); an in-flight
  `fetch` is allowed to finish. Use the self-rescheduling `setTimeout` loop (preferred over
  `setInterval`) with single-in-flight guard, so the next poll is scheduled only after the current one
  resolves (NFR4).
- **Echoed in footer:** the reworded `<footer>` shows the current effective interval — "served
  locally by `aid dashboard` · read-only · refreshes every Ns" (update the `Ns` live when changed).

---

## Freshness / stale / disconnected badge + parse-warning data note (Telemetry, NFR3/AC4)

A `.badge` in the top bar, computed from `model.read.read_at` (`ReadMeta.read_at`, ISO-8601 UTC) vs
the browser wall clock and the last-successful-fetch time:

| State | Condition | badge class | word + glyph |
|-------|-----------|-------------|--------------|
| **live** | last fetch ok AND `read_at` within ~1× interval | `.badge-ok` | ● Live |
| **stale** | last fetch ok but model older than ~2× interval, OR `parse_warnings` non-empty | `.badge-warn` | ◐ Stale |
| **disconnected** | last fetch failed / non-200 / timeout (server stopped) | `.badge-err` | ○ Reconnecting |

- On a transient miss the page **keeps the last good view** (never goes blank) and shows
  "Reconnecting"; the next tick retries with backoff (no hammering, NFR4).
- **`schema_version` mismatch** (`!== EXPECTED`, envelope DM-1): render a `.callout.warn` banner
  ("dashboard assets are out of date — restart `aid dashboard`") and keep the last good view; do not
  guess-render.
- **`parse_warnings` data note:** if `model.read.parse_warnings` is non-empty, show a small,
  **non-alarming** `.callout` (info, not error) listing the warnings — "data note: N parse warning(s)
  this read" — so a torn/transient read is *visible* but not mistaken for a pipeline failure.
- **`fallback_works` advisory:** if `model.read.fallback_works` is non-empty, append a `.meta` line in
  the data note ("M work(s) read via fallback derivation") — a live tech-debt surface, advisory only.
- **Liveness dot (feature-002 KI-004):** if feature-002 exposes a heartbeat-derived liveness, render
  an advisory "live/stale" dot beside a `Running` work — **repo-level, corroborating only**. Heartbeat
  absence MUST NEVER demote a `Running` work to looking blocked/idle; badge wording is "no recent
  heartbeat" (≠ "stopped").

---

## UI-6. Responsive + cross-browser (NFR6, NFR5)

- **Breakpoints reuse the design family's 768px collapse** (`component-css.css` L554–564:
  `.grid/.grid.g2/.g3/.g4 → 1fr`; `.top-bar` padding shrinks). Three target ranges:
  - **mobile (<768px):** single column; stage rail becomes a horizontally-scrollable strip
    (`overflow-x:auto; flex-wrap:nowrap`) OR a vertical list; task chips stack (grids already `1fr`).
  - **tablet (768–1024px):** 2-col grids (the `auto-fit minmax` in `.grid.g3/.g4` yields 2 cols
    naturally at this width — no extra media query needed).
  - **desktop (>1024px):** full grid, `main { max-width:1200px; margin:0 auto }` centered (design
    tokens "Max content width 1200px").
- **Cross-browser (NFR5 — Chrome/Firefox/Edge/Safari):** uses only broadly-supported baseline
  primitives — CSS custom properties, `grid`/`flex`, `fetch`, `localStorage`,
  `setTimeout`/`clearTimeout`, `JSON.parse`. **No bleeding-edge CSS, no runtime polyfill, no
  transpile.** `color-mix()`/`backdrop-filter` are inherited from the design family for cosmetic
  enhancement only (graceful-degrade; not load-bearing for AC1–AC3).
- **a11y baseline carried from the family:** `.skip-link`, `:focus-visible` rings,
  `prefers-reduced-motion` (disables the Running pulse), `.sr-only` for badge text alternates,
  `forced-colors` borders, `.noscript-fallback`.
- **Visual gate (global CLAUDE.md hard gate):** task-020 MUST render the served page in **Playwright**
  (screenshot/snapshot, both themes, ≥1 mobile + ≥1 desktop viewport) and visually validate AC1–AC3 +
  NFR5/NFR6 — inspecting source is an automatic fail.

---

## AC1–AC5 → component map

| AC | Requirement | Component(s) |
|----|-------------|--------------|
| **AC1** | stages + where-we-are (full/lite path) | UI-2 stage rail from `model.works[].phase`; data-driven path |
| **AC2** | current + parallel tasks with state | UI-3 wave-grouped chips, every concurrent task side-by-side (FR14); `tasks[].status`/`wave` |
| **AC3** | paused/blocked distinction | UI-4 attention badges — amber Input vs red Blocked, color **and** shape; reasons read-only |
| **AC4** | live update ≤ interval | UI-5 interval control (5s default, clamp, persist, reschedule) + Freshness badge from `read.read_at` |
| **AC5** | local, never public | Inherited from LC-S bind-`127.0.0.1` invariant (server, not this front-end); UI-1 footer states "served locally · read-only". Front-end makes only same-origin `fetch('/api/model')` — no external network. |

> AC5 is structurally a server (LC-S) property; the front-end's contribution is making no off-origin
> network call and advertising "served locally · read-only" in the reworded footer.
