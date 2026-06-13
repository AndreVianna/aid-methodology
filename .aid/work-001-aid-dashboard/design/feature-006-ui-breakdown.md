# feature-006 UI Breakdown — Level-1 project main page (UI-1..UI-6 + DD-1 hash router)

**Type:** DESIGN output (task-027). Consumed **verbatim** by task-028 (`index.html` implementer) and
the Playwright visual gate that follows it.
**Source of truth for fields:** `dashboard/server/server.py` serializers (the actual `/api/model`
wire shape) + `dashboard/reader/models.py` (feature-002 types).
**Source of truth for the render seam:** the CURRENT `dashboard/index.html` (d006/d007 reality) —
NOT feature-003's original SPEC layout.
**Source of truth for visual language:** `canonical/templates/knowledge-summary/`
(`design-tokens.md`, `component-css.css`) per NFR8 — but the **already-shipped** CSS inside
`dashboard/index.html` is what task-028 extends; see §0.1 for the one divergence to fix.

> **Scope:** this is design only — it does NOT contain `index.html`. It reuses the existing palette
> verbatim (no new colors). Every component maps to a real serialized `/api/model` field and a real
> design-family asset. The only net-new client code is a hash router + the five main-page card
> components; the server, `/api/model` bytes, `schema_version` (3), and poll loop are untouched.

---

## 0. Component → {design-family asset, model field, AC} index

| Component (SPEC) | Reused asset (already in `dashboard/index.html` unless noted) | Serialized `/api/model` field(s) read | task-027 AC |
|---|---|---|---|
| §3 App shell (top bar / theme / footer / freshness / data-note) | `.top-bar`,`.brand`,`.controls`,`.btn-ghost`,`#theme-toggle`,`#freshness-badge`,`#data-note-chip`,`<footer>` — feature-003 shell, **reused, not duplicated** | `model.repo.project_name`; `model.read.*`; `envelope.generated_by` | AC1 (NFR8 shell) |
| §1 Page layout (two sections) | `<main>` body swapped; `.grid.g3` (Pipelines), `.grid.g2` (Knowledge & Tool); `<h2>` section heads | `model.works[]`, `model.repo.kb_state`, `model.tool` | AC1, AC3 |
| §2 Work-card (UI-3) | `.card`(+`:hover`), `.card .kicker/h3/.meta`, `.badge-*`, `.badge`; **new** `.card-link` + `.work-card.attn-warn/.attn-err` left-border | `model.works[]`: `work_id`,`name`/`title`,`lifecycle`,`phase`,`updated`,`tasks`(`.length`),`source_mode`,`pause_reason`,`block_reason`,`block_artifact` | AC2 |
| §3 KB summary card (UI-4) | `.card`(+`:hover`), `.kicker`,`.stat`,`.stat-sub`,`.meta`,`.badge-ok`/`.badge-warn` | `model.repo.kb_state`: `doc_count`,`summary_approved`,`last_summary_date` (nullable whole object) | AC3 (SEAM-1) |
| §4 Level-0 CLI panel (UI-5) | `.card.plugin` (`dl/dt/dd`) — **MUST be added to the shipped CSS, see §0.1**; `.badge-info` | `model.tool`: `manifest_present`,`aid_version`,`installed_at`,`tools_installed[]` | AC3 (FR7) |
| §5 Empty-state (FR18) | `.card`, `.empty-state` (centered), `code`, `.meta` | `model.works == []` (no field; the empty array) | AC3 (FR18) |
| §6 Hash router (DD-1) | `location.hash`,`hashchange`; **new** `parseRoute()` + `render(model, selectedWorkId)` | derives selection from hash; reads `model.works[].work_id` (find-by-key) | AC4 |
| §7 Responsive (UI-6) | `@media (max-width:768px)` collapse, `@media (769–1024px)` 2-col; `auto-fit minmax` | — (layout) | AC1, AC4 |

### 0.1 The ONE CSS divergence task-028 MUST reconcile (load-bearing)

The `knowledge-summary/` source family and the **shipped** `dashboard/index.html` disagree on two
points the main page depends on. The main page needs the `knowledge-summary/` behavior, so task-028
edits the shipped CSS as follows:

1. **`.grid.g3` is the wrong rule in the shipped file.** Shipped `index.html:183` has
   `.grid.g3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }` — a **fixed 3-column** grid (it
   was added for the per-work task-chip clusters). UI-2/UI-6 require the design-family's
   **auto-fit reflow** so a repo with 1, 2, 5, or 9 works lays out cleanly and collapses responsively
   without per-count JS. **Do NOT mutate the shared `.grid.g3`** (the per-work view uses it). Instead
   add a **main-page-scoped** class:
   ```
   .pipelines-grid { grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); }
   ```
   applied as `class="grid pipelines-grid"`. It inherits `.grid`'s `display:grid; gap:1rem` and
   overrides only the columns. The existing `@media (max-width:768px)` rule already lists `.grid.g3`
   etc.; add `.pipelines-grid` to that `1fr` collapse selector (and to the 769–1024px 2-col selector
   is optional since auto-fit already reflows — prefer leaving auto-fit to do it).
2. **`.card.plugin` is NOT in the shipped CSS.** The shipped `index.html` never defined the plugin
   (definition-list) card variant; only the `knowledge-summary/` source has it (`component-css.css`
   :235–242). The Level-0 panel (§4) needs it. task-028 **copies these eight rules verbatim** from
   `component-css.css:235–242` into the shipped `<style>` (`.card.plugin`, `.plugin-name`,
   `.plugin-stats`, `.plugin-body`, `dl`, `dt`, `dd`, `.foot`). No palette change — they use existing
   tokens (`--accent`, `--text-dim`, `--text`, `--text-muted`).

Everything else the main page needs (`.card`+hover, `.badge-*`, `.kicker/.stat/.stat-sub/.meta`,
`.empty-state`, `.callout`, the 768px collapse, all `:root` tokens, the app shell) **already exists**
in the shipped `index.html` and is reused as-is — no new palette, satisfying AC1/NFR8.

---

## 0.2 Wire-field verification (all exist at `schema_version` 3)

Confirmed against `dashboard/server/server.py` serializers (the bytes the client actually receives).
The client reads the **serialized JSON field names**, listed here exactly:

| Main-page read | Exact serialized path | Serializer (server.py) | Notes |
|---|---|---|---|
| project name | `model.repo.project_name` | `_ser_repo_info` :72 | string, always present |
| KB state (nullable) | `model.repo.kb_state` | `_ser_repo_info` :74 → `_ser_kb_state` :58 | `null` when no KB |
| KB doc count | `model.repo.kb_state.doc_count` | `_ser_kb_state` :65 | nullable int |
| KB approved | `model.repo.kb_state.summary_approved` | `_ser_kb_state` :63 | bool |
| KB freshness | `model.repo.kb_state.last_summary_date` | `_ser_kb_state` :64 | nullable string |
| tool present | `model.tool.manifest_present` | `_ser_tool_info` :51 | bool |
| tool version | `model.tool.aid_version` | `_ser_tool_info` :52 | nullable string |
| tool installed_at | `model.tool.installed_at` | `_ser_tool_info` :53 | nullable string |
| tool tools | `model.tool.tools_installed` | `_ser_tool_info` :54 | list<string> |
| works array | `model.works[]` | `_ser_repo_model` :166 | **sorted by `work_id` asc** server-side |
| work key | `model.works[].work_id` | `_ser_work` :126 | the stable nav key |
| work display name | `model.works[].title` (authored) / `model.works[].name` (slug) | `_ser_work` :127,140 | see §2 fallback |
| lifecycle literal | `model.works[].lifecycle` | `_ser_work` :128 | `Lifecycle` enum `.value` |
| phase literal | `model.works[].phase` | `_ser_work` :129 | nullable (enum `.value` or `null`) |
| updated | `model.works[].updated` | `_ser_work` :131 | nullable string |
| task count | `model.works[].tasks.length` | `_ser_work` :135 | length of serialized tasks array |
| provenance | `model.works[].source_mode` | `_ser_work` :137 | `"normalized"`/`"fallback"`/`"mixed"` |
| pause reason | `model.works[].pause_reason` | `_ser_work` :132 | nullable |
| block reason / artifact | `model.works[].block_reason` / `.block_artifact` | `_ser_work` :133,134 | nullable |
| freshness/warnings | `model.read.read_at` / `.parse_warnings` / `.fallback_works` | `_ser_read_meta` :150 | reused verbatim from f-003 |
| schema gate | `envelope.schema_version` (== 3) / `envelope.generated_by` | `serialize_model` :179,180 | envelope-level, not under `model` |

**Every field the main page reads already crosses the wire at `schema_version` 3. No new model, no
schema bump.** This satisfies the AC3 clause "specified against the `/api/model` slice they read (no
new model)."

> **SPEC reconciliation note (DM-2 vs serialized shape):** the feature-006 SPEC DM-2 lists
> `model.works[].name` as the card title source. The CURRENT reader/serializer carries **both**
> `name` (slug) and `title` (authored Name from REQUIREMENTS.md). The shipped per-work header
> (`renderWorkHeader`, index.html:1148–1165) prefers `title` and de-slugs `work_id` as a labelled
> fallback when `title` is null — it deliberately never shows the raw slug as if it were the name.
> The work-card §2 **reuses that exact precedence** (`title` → de-slug fallback) for cross-view
> consistency, rather than the SPEC's bare `name`. This is a reconciliation of pre-d006 SPEC text to
> the d006 reality, not a new decision.

---

## 1. Page layout — two sections (UI-2, FR3, FR9)

The main page **swaps only the `<main>` body**; the `.top-bar`, `#freshness-badge`, `#data-note-chip`,
theme toggle, and `<footer>` are feature-003's shell, rendered once and shared by both views (§6).
Two grouped sections answer "what are my runs doing?" first, then "what's the KB / tool state?":

```
DESKTOP ( > 1024px )
┌─ .top-bar (SHARED shell) ── <project_name> ········· [! 2 fallbacks] [● Live] [Refresh 5s] [◑ Dark] ─┐
├─ <main id="top"> ────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                        │
│  Pipelines                                                                  (h2)                        │
│  ┌──────────── .grid.pipelines-grid (auto-fit minmax 260px) ──────────────────────────────────────┐    │
│  │ ┌─ work-card ──────┐ ┌─ work-card ──────┐ ┌─ work-card ──────┐ ┌─ work-card ──────┐            │    │
│  │ │▎work-002 (kicker)│ │▎work-005 (kicker)│ │ work-001 (kicker)│ │ work-003 (kicker)│            │    │
│  │ │ Canonical Gen.   │ │ Remote Expose    │ │ AID Dashboard    │ │ Reader Hardening │            │    │
│  │ │ ▸Specify rail··· │ │ ▸Execute rail··· │ │ ▸Deploy rail···· │ │ ✓done rail······ │            │    │
│  │ │ [❚❚ Input] amber │ │ [✕ Blocked] red  │ │ [▶ Running] teal │ │ [✓ Done] green   │            │    │
│  │ │ pause_reason···· │ │ block_reason···· │ │                  │ │                  │            │    │
│  │ │ 3m ago·8 tasks   │ │ 1m ago·12 tasks  │ │ 30s ago·42 tasks │ │ 2d ago·6 tasks   │            │    │
│  │ └──────────────────┘ └──────────────────┘ └──────────────────┘ └──────────────────┘            │    │
│  │   ▎=amber left-border (attn)  ▎=red left-border (attn) — these two PINNED to grid front (§2.3)  │    │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                                        │
│  Knowledge & Tool                                                          (h2)                         │
│  ┌──────────── .grid.g2 (auto-fit minmax 380px) ─────────────────────────────────────────────────┐    │
│  │ ┌─ KB summary card (→ #/kb) ──────────────┐  ┌─ Level-0 CLI panel (.card.plugin) ───────────┐  │    │
│  │ │ KNOWLEDGE BASE (kicker)                 │  │ AID CLI (this machine) (kicker)              │  │    │
│  │ │   12  docs   [✓ Approved]               │  │  version   [info 1.0.0]                      │  │    │
│  │ │ summary updated 2026-06-09 (meta)       │  │  installed  2026-05-01                       │  │    │
│  │ │ (whole card clickable; hover lifts)     │  │  tools      [claude-code]                    │  │    │
│  │ └─────────────────────────────────────────┘  └──────────────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘

MOBILE ( ≤ 768px ) — design-family collapse, all grids → 1fr (single column, stacked)
┌─ .top-bar (wraps; controls drop to own row, breadcrumb hidden < 420px) ─┐
├─ <main> ────────────────────────────────────────────────────────────────┤
│  Pipelines (h2)                                                          │
│  ┌─ work-card (full width) ──┐   ← attention cards (amber/red) first     │
│  ├─ work-card (full width) ──┤   ← then normal cards in work_id order    │
│  ├─ work-card (full width) ──┤   phase rail becomes horiz-scroll strip   │
│  └───────────────────────────┘                                          │
│  Knowledge & Tool (h2)                                                   │
│  ┌─ KB summary card ────────┐                                            │
│  ├─ Level-0 CLI panel ──────┤  (stacked, full width)                     │
│  └──────────────────────────┘                                           │
└──────────────────────────────────────────────────────────────────────────┘
```

- **One project per page (FR9):** brand shows the single `model.repo.project_name`; no project
  switcher, no cross-repo aggregation. Multiple projects = multiple browser tabs (each its own served
  dashboard).
- Section heads are plain `<h2>` ("Pipelines", "Knowledge & Tool") matching the shipped `h2` style
  (index.html:89). No new heading component.

---

## 2. Work-card (UI-3) — lifecycle + FR11 attention (AC2)

Each card renders one entry of `model.works[]`. It is a **single anchor-like clickable element**
(`<a class="card card-link work-card" href="#/work/<work_id>">` — see §2.4) so it is natively
keyboard-focusable and back/forward works (DD-1). The whole card is the click target.

### 2.1 Field map (each card element → exact serialized field)

| Card element | Serialized field | Render rule |
|---|---|---|
| `.kicker` | `model.works[].work_id` | shown verbatim, e.g. `work-002` (the stable nav key). |
| `<h3>` title | `model.works[].title` ?? de-slug(`work_id`) | **reuse `renderWorkHeader` precedence** (index.html:1148–1165): prefer `title`; if null, strip `work-NNN-` prefix, `[-_]`→space, Title-Case, dim at `opacity:0.6` with `title=` tooltip "Name not yet recorded". Never show raw slug as the name. (`name` slug is available but `title` is the human label.) |
| mini phase rail | `model.works[].phase` | see §2.2 |
| lifecycle badge | `model.works[].lifecycle` | **reuse `makeLifecycleBadge`** (index.html:1777, see §2.3) verbatim — same factory the per-work header uses. |
| attention detail | `pause_reason` / `block_reason` + `block_artifact` | for `Paused-Awaiting-Input` show `pause_reason` as one muted `.meta` line; for `Blocked` show `block_reason` + `block_artifact` (as `<code>`) — read-only, so the operator sees why/where without opening files. Both straight from the serialized work. |
| `.meta` footer | `updated`, `tasks.length`, `source_mode` | `updated` relative-ish (reuse the shipped "Updated: …" string treatment, index.html:1202; a relative formatter is optional, not required); `tasks.length` → "N tasks"; `source_mode` chip **only when `!== "normalized"`** → a small `.badge.badge-dim` "approx" so a fallback-derived card reads honestly. |

### 2.2 Mini phase rail (condensed `renderStageRail`)

The per-work view's `renderStageRail` (index.html:1417) renders the full 7-pill `PHASE_ORDER` rail.
The card needs a **condensed** version (FR8 glance-readable, limited card width):

- Reuse the same `PHASE_ORDER = ['Interview','Specify','Plan','Detail','Execute','Deploy','Monitor']`
  constant and the same prior/current/later coloring semantics
  (prior `.badge-ok` ✓ · current `.badge-primary` ▸ · later `.badge-dim` ○).
- **Condensed form for the card:** render the **current phase pill in full** (`▸ Execute`) plus a
  compact progress hint (e.g. current index `4/7`), OR the full strip inside a horizontally
  scrollable flex row reusing the `.stage-rail` `overflow-x:auto` behavior the 768px media query
  already applies (index.html:247). task-028 may pick either; the **current pill MUST always be
  visible** without scroll. Prefer the "current pill + `N/7`" compact form on the card to keep cards
  short; reserve the full rail for the per-work view.
- **`phase == null` or `"Unknown"`** (fallback path): omit the rail entirely and show only the
  lifecycle badge — exactly the shipped neutral-sentinel posture (`renderStageRail` lines 1423–1442),
  never a garbage "phase unknown" error pill.

### 2.3 Lifecycle badge + attention emphasis (DD-2, FR11) — reuse VERBATIM

The card maps the `lifecycle` literal using the **already-shipped `makeLifecycleBadge`** factory
(index.html:1777–1796), unchanged. That factory already encodes feature-003 UI-4's two-color
color+shape scheme. Reproduced here so task-028 confirms the card matches it pixel-for-meaning:

| `lifecycle` literal | Badge class | Color token | Glyph (shape) | Word | Card attention (FR11) |
|---|---|---|---|---|---|
| `Running` | `.badge-accent` | `--accent` teal | ▶ filled | "Running" | normal card; no border |
| `Paused-Awaiting-Input` | `.badge-warn` | `--warn` amber | ❚❚ pause bars | "Input" | **amber left-border + pinned to top** |
| `Blocked` | `.badge-err` | `--err` red | ✕ | "Blocked" | **red left-border + pinned to top** |
| `Completed` | `.badge-ok` | `--ok` green | ✓ | "Done" | normal, muted |
| `Canceled` | `.badge-dim` | `--text-dim` grey | ⊘ | "Canceled" | normal, muted |
| *(unrecognized literal)* | `.badge` (neutral) | `--text-dim` | ? | "? Unknown" | **neutral, never throws** (matches factory `else` branch) |

- **Two attention colors only (DD-2).** Amber Input vs red Blocked — the same two-color scheme
  feature-003 ships, because FR16 folds approval/confirmation into the single
  `Paused-Awaiting-Input` state. This is a conscious inheritance, not a re-decision.
- **Left-border treatment — reuse the shipped class pattern.** The shipped CSS already defines
  `.card.border-warn { border-left: 4px solid var(--warn); }` and `.card.border-err { …var(--err); }`
  (index.html:507–508) for the per-work header card. The work-card **reuses these exact classes**:
  add `border-warn` for `Paused-Awaiting-Input`, `border-err` for `Blocked`, nothing for the rest.
  No new border CSS. (Apply on the `.card.work-card` element.)
- **Pin-to-top (FR11) is a render-order treatment, NOT a data re-sort.** Works arrive
  `work_id`-sorted from the server (server.py:166). The card grid renders in **two stable passes** so
  the nav key never shifts:
  1. **Attention pass:** all works with `lifecycle ∈ {Paused-Awaiting-Input, Blocked}`, in their
     server `work_id` order.
  2. **Normal pass:** all remaining works, in their server `work_id` order.
  Concatenate pass-1 then pass-2. This pins attention cards to the front while preserving stable
  relative order within each group — the visual emphasis is a CSS+order treatment, never a
  destructive re-sort of the array used for navigation.

### 2.4 Click → `#/work/<work_id>` (whole card)

- Implement the card as `<a class="card card-link work-card …" href="#/work/<work_id>">`. Using a
  real `<a href="#/work/…">` gives: native focusability + keyboard activation, real
  back/forward/bookmark, and `.card:hover` lift (index.html:195) signaling clickable — **for free**,
  no JS click handler needed (the router listens to `hashchange`, §6).
- **New CSS (one rule, no palette):** `.card-link { display:block; color:inherit; text-decoration:none; }`
  and `.card-link:hover { text-decoration:none; }` to neutralize the global `a { color:var(--accent) }`
  / `a:hover{underline}` (index.html:86–87) so the card body keeps card typography, not link styling.
- Set `cursor:pointer` (inherited from `.card`-as-anchor; add explicitly if needed). The deferred full
  a11y pass is REQUIREMENTS §4 out-of-scope, but a plain focusable anchor costs nothing and is used.

---

## 3. KB summary card (UI-4) + the feature-007 seam (SEAM-1) (AC3)

A single card in the **Knowledge & Tool** `.grid.g2`, summarizing `model.repo.kb_state` (the f-002
DM-3 hook set — *summary only*; the rich inventory is feature-007 behind the seam).

| Card element | Serialized source | Display |
|---|---|---|
| `.kicker` | — | "KNOWLEDGE BASE" |
| `.stat` + `.stat-sub` | `model.repo.kb_state.doc_count` | the count (e.g. "12") + `.stat-sub` "docs"; if `doc_count == null` show "—" |
| approval chip | `model.repo.kb_state.summary_approved` | `true` → `.badge-ok` "Approved"; `false` → `.badge-warn` "Draft" |
| freshness `.meta` | `model.repo.kb_state.last_summary_date` | "summary updated {date}"; omit line if null |
| affordance | — | whole card is `<a class="card card-link" href="#/kb">` (SEAM-1); `.card:hover` lift signals drill-in |

- **`model.repo.kb_state == null`** (repo never ran `/aid-discover`; `_ser_kb_state` returns `null`):
  render a graceful, **non-clickable** "No Knowledge Base yet" card — `.kicker` "KNOWLEDGE BASE",
  `<h3>` "No Knowledge Base yet", a one-line `.meta` hint "run `/aid-discover` to build the KB". It is
  a plain `<div class="card">` (NOT an `<a>`), no `href`, no hover-drill affordance, because there is
  no KB view to open. This is a light hint, not a full FR18 procedure (building the KB is optional,
  not a blocking happy-path intervention).
- **Seam contract (SEAM-1):** clicking sets `location.hash = "#/kb"`; the router (§6) recognizes
  `#/kb` and hands rendering to feature-007. This feature owns **only** the route + the summary card;
  feature-007 owns the dedicated KB dashboard body. In THIS delivery, `#/kb` may render a minimal
  placeholder ("KB dashboard — coming in feature-007") + a "back to main" link so the seam is live and
  testable without implementing feature-007.

---

## 4. Level-0 CLI panel (UI-5 → FR7) (AC3)

The machine-level AID CLI card — the only non-repo-scoped data (REQUIREMENTS §3a/§4), read locally on
the host the server runs on, identical regardless of which repo's dashboard is open. Rendered with the
`.card.plugin` definition-list variant (added to the shipped CSS per §0.1):

```
┌─ .card.plugin ─────────────────────────────┐
│  AID CLI (this machine)   (.kicker)         │
│  ┌ dl ───────────────────────────────────┐ │
│  │ dt version   dd [.badge-info 1.0.0]    │ │
│  │ dt installed dd 2026-05-01  (.meta)    │ │
│  │ dt tools     dd [claude-code] chips    │ │
│  └────────────────────────────────────────┘ │
└──────────────────────────────────────────────┘
```

| Row | Serialized source | Render |
|---|---|---|
| `.kicker` | — | "AID CLI (this machine)" |
| version | `model.tool.aid_version` | `<dd>` with a `.badge.badge-info` chip (e.g. `1.0.0`); "—" if null |
| installed | `model.tool.installed_at` | `<dd>` ISO date as `.meta`; "—" if null |
| tools | `model.tool.tools_installed[]` | `<dd>` small `.badge.badge-dim` chips, one per entry; "—" if empty |

- **Degraded — `model.tool.manifest_present == false`:** render the card with `.kicker`
  "AID CLI (this machine)" and a single `.meta` line **"tool info unavailable"** — **never error,
  never throw** (the serializer null-fills the fields; f-002 DM-2). Do not render empty `dt/dd` rows
  in this case.
- This panel is **NOT clickable** (no drill target) — plain `<div class="card plugin">`.
- It renders in **both** the populated and empty-works cases (it does not depend on `works`).

---

## 5. Empty-state — no works yet (FR18 step-by-step) (AC3)

When `model.works` is `[]` (a valid `RepoModel` per feature-002), the **Pipelines section** replaces
the grid with a guided panel. FR18 requires a **step-by-step procedure** (what to do, the exact
command, how to verify) — NOT a one-line hint — because starting a pipeline is a user intervention the
tool cannot perform. The shipped one-liner empty-state (index.html:828–830, "No works found … Start a
pipeline to see progress here.") is **insufficient for FR18** and task-028 replaces the Pipelines-area
empty content with this:

```
┌─ .card .empty-state (centered, full width of Pipelines section) ─────────────┐
│  NO PIPELINES YET                                  (.kicker)                  │
│  This repo has no AID works in .aid/ yet.          (h3)                       │
│                                                                              │
│  To start your first pipeline:                                               │
│   1. In this repo, run:   /aid-interview                                     │
│        — begins a new work (creates .aid/work-NNN-<name>/ + its STATE.md).   │
│   2. Follow the interview prompts to capture requirements.                    │
│   3. Verify: a work-NNN-* folder now appears under .aid/, and this page       │
│      shows a card for it on the next refresh (within the poll interval).      │
│                                                                              │
│  this page refreshes every Ns — the card appears automatically.  (.meta)     │
└──────────────────────────────────────────────────────────────────────────────┘
```

- `/aid-interview` is rendered in a `<code>` element. The "every Ns" value is the live `pollMs/1000`
  (reuse `updateFooterInterval`'s value).
- **The KB card (§3) and Level-0 panel (§4) STILL render** in the empty case — only the Pipelines
  grid is swapped for this panel. The "Knowledge & Tool" section is unchanged.
- The "verify" step ties back to the live poll (FR4): the user does not reload — the new work-card
  appears within one interval, which the empty-state explicitly promises.

---

## 6. Hash router (DD-1, no `pushState`) + the `render(model, selectedWorkId)` seam (AC4)

### 6.1 Why hash routing (DD-1)

`location.hash` (`#/`, `#/work/<id>`, `#/kb`) — NOT History-API path routing. The feature-003 server
is a closed two-route allowlist (`/` + `/api/model`, no catch-all); a path router would 404 on
reload/bookmark of `/work/<id>`. Hash routing keeps the server's bind/no-write/no-LLM invariants and
zero-build posture completely untouched while giving real back/forward/bookmarkable navigation.
Clean-URL path routing is deliberately deferred (it would require a server catch-all + invariant
re-test).

### 6.2 Route table

| `location.hash` | Route | Renders |
|---|---|---|
| `""` or `"#/"` | `{ view: "main" }` (default) | the main page (§1–§5): card grid + KB card + Level-0 panel |
| `"#/work/<work_id>"` | `{ view: "work", workId }` | the existing per-work pipeline view, scoped to `works[]` entry where `work_id === workId` (**find-by-key, never by index**) |
| `"#/kb"` | `{ view: "kb" }` | feature-007's view (SEAM-1); placeholder + back-link in this delivery |
| anything else | treat as `{ view: "main" }` | unknown top-level hash falls back to main (never blank) |

`parseRoute(hash)` (new, ~10 lines): strip leading `#`, match `^/work/(.+)$` → `{view:"work", workId}`;
`^/kb$` → `{view:"kb"}`; else `{view:"main"}`.

### 6.3 The exact refactor seam in CURRENT `index.html` (name the functions/lines)

The CURRENT render entry is `renderModel(model)` (index.html:1064). It unconditionally:
1. updates title/brand (1069–1073) and parse-warnings (1076) — **shell concerns, route-independent**,
2. calls `selectActiveWork(works)` (1080, defined 1112) to pick the ONE displayed work,
3. branches: empty → show `#empty-state`; else render the per-work view via `renderWorkHeader` /
   `renderAttentionStrip` / `renderStageRail` / `renderTasks` (1090–1096).

feature-006 refactors this into a router-driven entry. **Precise changes:**

1. **Rename the entry to `render(model, selectedWorkId)`** (keep a thin `renderModel(model)` wrapper
   that calls `render(model, currentRoute().workId)` so the poll loop's existing call site,
   `onSuccess`→`renderModel(envelope.model)` at index.html:999, needs no change — or update that one
   call site to `render(envelope.model, parseRoute(location.hash))`). Either is acceptable; prefer the
   thin wrapper to minimize the diff.
2. **Keep the route-independent head of `renderModel` as-is** (title/brand at 1069–1073;
   `renderParseWarnings(model.read)` at 1076; the freshness badge update). These run for **every**
   route — the shell is shared (no duplication, AC requirement).
3. **Insert the view branch** where the body currently begins (replacing the block at 1078–1105):
   ```
   var route = parseRoute(location.hash);     // {view, workId?}
   if (route.view === "main") {
       renderMainPage(model);                 // §1–§5 (NEW)
   } else if (route.view === "work") {
       var work = findWorkById(model.works, route.workId);    // find-by-KEY (§ note below)
       if (!work) { renderStaleWorkNotice(route.workId); }   // FC-3 (§6.5)
       else { renderWorkView(work); }         // the EXISTING per-work path (see 4 below)
   } else if (route.view === "kb") {
       renderKbView(model);                   // SEAM-1 placeholder/feature-007
   }
   ```
4. **`selectActiveWork(works)` (1112–1122) is NO LONGER the selector for the per-work view.** Under
   the router, the per-work view is selected by **`work_id` from the hash** (find-by-key), not by
   "first non-terminal / else highest work_id". Two options for `selectActiveWork`:
   - **(preferred) Keep it, repurposed as the default-work picker for a bare `#/work` or a
     convenience redirect:** it is still useful if the user lands on `#/work` with no id — but the
     main page is the default route now, so this is optional. Mark it as no longer on the default
     render path.
   - The existing per-work render statements (1093–1096) move **verbatim** into a new
     `renderWorkView(work)` function that takes the resolved work — the four calls
     (`renderWorkHeader`/`renderAttentionStrip`/`renderStageRail`/`renderTasks`) are **unchanged**;
     only their *caller* changes from "the auto-selected active work" to "the hash-targeted work."
   This is the whole point of the SPEC's `render(model, selectedWorkId)` extension: selection moves
   from an implicit heuristic (`selectActiveWork`) to an explicit hash key, while the per-work
   rendering functions are reused untouched.
   - **Style note:** the shipped file is ES5-idiom (all `var`, classic `for` loops, no arrow
     functions, zero `Array.prototype.find` uses today). `findWorkById(works, id)` is a 4-line classic
     `for` loop returning the matching work or `null` — do **not** introduce arrow functions / `.find`
     to keep the diff stylistically consistent with the surrounding code.
5. **`renderMainPage(model)` (NEW)** is the only large net-new render function. It must show/hide the
   right top-level containers: when on `#/` it shows the main grid and **hides** `#work-header`,
   `#attention-strip`, and the old `#empty-state`; when on `#/work/<id>` it shows `#work-header` and
   hides the main grid. task-028 adds a `<div id="main-page" style="display:none">` sibling of
   `#work-header` inside `<main>` to host the two sections; the router toggles `display` between
   `#main-page` and `#work-header`/`#kb-view`.

### 6.4 `hashchange` handling

- On boot, after the existing immediate first fetch is wired, also `window.addEventListener('hashchange', onHashChange)`. `onHashChange` re-renders the **current** `lastGoodModel` against the new route (no new fetch — navigation is pure client-side):
  ```
  function onHashChange() { if (lastGoodModel) render(lastGoodModel, parseRoute(location.hash)); }
  ```
- The poll loop is **unchanged**: each tick still calls `renderModel(envelope.model)` (index.html:999), which now
  routes to the current view — so the main page's cards refresh live every interval (FR4/NFR3), exactly
  as the per-work view does today. No page-specific polling.
- Back/forward "just works": the browser fires `hashchange`, `onHashChange` re-renders. FR3 drill is
  reversible.

### 6.5 Unknown / stale `work_id` (FC-3) — never blank

When `#/work/<id>` targets a `work_id` not in the current `model.works` (folder removed since last
poll, or a stale bookmark), `renderStaleWorkNotice(workId)` shows a small `.callout.warn` inside
`<main>`: "That pipeline (`<work_id>`) is no longer in this repo." + a "← back to main" link
(`<a href="#/">`). It must **NOT blank the page** — mirrors the shipped "never goes blank on a
transient miss" posture (`onError`, index.html:1003–1013). Use `<code>` for the id and the existing
`.callout.warn` class (index.html:217).

---

## 7. Responsive (UI-6) + cross-browser (AC1, AC4)

- **Breakpoints (reuse the design family's 768px collapse):** the shipped
  `@media (max-width:768px) { .grid, .grid.g2, .grid.g3, .grid.g4, .grid.g-lane { grid-template-columns: 1fr; } }`
  (index.html:241–249) — **add `.pipelines-grid` to that selector** so the work grid collapses to a
  single column on mobile. The shipped `@media (min-width:769px) and (max-width:1024px)` 2-col rule
  (index.html:237–239) need not include `.pipelines-grid` because its `auto-fit minmax(260px,1fr)`
  already reflows to ~2 columns in that range; leaving auto-fit to do it avoids a fixed-count override.
- **Desktop ( >1024px ):** `<main>` keeps `max-width:1200px` centered (index.html:148); the work grid
  shows multiple cards per row via auto-fit.
- **Tablet (768–1024px):** auto-fit reflows to ~2 columns.
- **Mobile ( <768px ):** single column, cards stack; the card phase-rail uses the existing
  `.stage-rail { overflow-x:auto; flex-wrap:nowrap; }` mobile rule (index.html:247) if the full-rail
  variant is chosen.
- **Cross-browser (NFR5):** only baseline primitives — CSS custom properties, `grid`/`flex`, `fetch`,
  `localStorage`, `setTimeout`, `location.hash`/`hashchange`, `Array.prototype.find` — all supported
  across Chrome/Firefox/Edge/Safari. No bleeding-edge CSS, no polyfill, no transpile (same posture as
  feature-003). The find-by-key uses a classic `for` loop (`findWorkById`, §6.3), not `Array.find`, to
  match the shipped ES5 idiom — so even the oldest baseline target is covered.
- **Playwright gate (global CLAUDE.md + UI-6):** the reviewer MUST render this page in Playwright (not
  inspect source) and visually validate: the card grid with each lifecycle state, FR11 amber/red
  attention + pin-to-top, whole-card click → `#/work/<id>`, the KB-card → `#/kb` seam, the Level-0
  panel (and its `manifest_present:false` degraded text), the FR18 empty-state, the stale-work notice,
  and the 768px collapse. A source-only review is an automatic fail.

---

## 8. AC → component map (task-027 ACs)

| task-027 AC | Satisfied by |
|---|---|
| AC1 — names exact `knowledge-summary/` assets per component; no new palette (NFR8) | §0 index + §0.1 (the two reused/added CSS rules) + §1 (`.grid.pipelines-grid`/`.grid.g2`) + §2–§5 (`.card`, `.badge-*`, `.card.plugin`, `.kicker/.stat/.meta`, `.callout`, all from the shipped/`knowledge-summary` CSS) |
| AC2 — lifecycle badge reuses f-003 two-color amber/red color+shape (DD-2) verbatim + FR11 left-border + pin-to-top for Paused/Blocked + unrecognized neutral fallback | §2.3 (reuses `makeLifecycleBadge` + `.card.border-warn/.border-err` verbatim; two-pass pin-to-top in §2.3; neutral `else` branch) |
| AC3 — KB card (SEAM-1 `#/kb`), Level-0 panel (FR7), one-project-per-page (FR9), FR18 step-by-step empty-state — each against the `/api/model` slice (no new model) | §3 (KB card + null state), §4 (Level-0 + degraded), §1 (FR9 single project), §5 (FR18 step-by-step), §0.2 (no new model — all fields verified at schema 3) |
| AC4 — hash routing (DD-1, no pushState) + `render(model, selectedWorkId)` front-end-only extension documented; responsive breakpoints + AC→component map | §6 (route table, hashchange, find-by-key, stale-work notice, exact `renderModel`→`render` refactor with line numbers), §7 (breakpoints), this table |
| AC5 — §6 quality gates pass (REQUIREMENTS baseline) | front-end-only; no server/schema change; reuses tokens; Playwright gate noted (§7) |
| AC6 — DESIGN default: tokens reused + responsive specified; rationale + trade-offs documented; grounded in feature-006 SPEC | §0.1/§6.1 rationale + trade-offs (DD-1 deferral, two-pass vs re-sort, anchor-card); §7 responsive; grounded in SPEC throughout, with §0.2 reconciliation note |

---

## 9. Reconciliations of pre-d006 SPEC text → current code (for task-028)

The feature-006 SPEC was written against feature-003's *original* single-pipeline SPEC. The CURRENT
`dashboard/index.html` is the d006/d007 reality. Where they differ, task-028 follows the CURRENT code:

1. **Title source (`name` vs `title`).** SPEC DM-2 says cards read `model.works[].name`. Current code
   carries `title` (authored Name) + `name` (slug) and the per-work header prefers `title` with a
   de-slug fallback. The card **reuses the `title`→de-slug precedence** (§2.1) for cross-view
   consistency. (Resolved in §0.2 note.)
2. **`.grid.g3` semantics.** SPEC UI-1/UI-6 assume `.g3 = auto-fit minmax(240px,1fr)` (the
   `knowledge-summary/` source). The shipped `index.html` overrode `.g3` to fixed
   `repeat(3, minmax(0,1fr))` for the per-work task clusters. The main page must NOT mutate the shared
   `.g3`; it uses a new `.pipelines-grid` auto-fit class instead (§0.1.1). (Resolved.)
3. **`.card.plugin` not shipped.** SPEC UI-5 cites `component-css.css:235–242`; those rules were never
   copied into `index.html`. task-028 copies them verbatim (§0.1.2). (Resolved.)
4. **Render seam shape.** SPEC says "add a `work_id` selection parameter to `render(model)`." The
   CURRENT entry is `renderModel(model)` (1064) selecting via `selectActiveWork`. §6.3 gives the exact
   refactor: keep the shell head, add a route branch, move the per-work calls into `renderWorkView`,
   demote `selectActiveWork` off the default path. (Resolved.)
5. **Empty-state.** SPEC FR18 wants step-by-step; the shipped `#empty-state` is a one-liner. The main
   page replaces the Pipelines-area empty content with the §5 procedure while keeping the KB/Level-0
   cards. (Resolved.)
</content>
</invoke>
