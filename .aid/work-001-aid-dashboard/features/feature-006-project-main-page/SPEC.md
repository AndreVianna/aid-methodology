# Project Main Page (Level-1 "Dashboard of Dashboards")

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-10 | Feature identified from REQUIREMENTS.md §5 FR3, FR7, FR11, FR16 | /aid-interview |
| 2026-06-12 | **REVISED for the two-level re-architecture** (charter only; Technical Specification below is the as-delivered d004 record and is NOT rewritten here — the go-forward revision is captured in "Re-architecture Revision" immediately below). This view becomes the **per-repo `home.html`** and the **Level-0 / CLI panel is REMOVED** (relocated to feature-010's CLI home, FR33). | /aid-interview |

## Re-architecture Revision (2026-06-12)

> _This feature was **already delivered as delivery-004** (commit `2a4ddd1`→`ea40fe7`, Playwright-gated)
> as the Level-1 project main page **inside feature-003's `index.html`**, including the Level-0 CLI
> panel. The two-level re-architecture **revises** it — this is a **go-forward revision, not a
> rebuild**. The Acceptance Criteria, User Stories, and Technical Specification below predate the
> revision and remain as the historical d004 record; the deltas that supersede them are listed here
> and will be re-specified for the revised slice in /aid-specify._

**Status: REVISED — charter.** Two go-forward changes:

1. **This view becomes the per-repo `home.html`** at `<repo>/.aid/dashboard/home.html` (FR27 Level B),
   reached from feature-010's CLI-home repo-card (no longer the dashboard's *top* entry point — the
   CLI home is now above it). Its content — the work-card grid (FR3/FR16), FR11 attention emphasis,
   and the KB card (now feature-007's 5-state card, FR32) — is otherwise unchanged.
2. **The Level-0 / "AID CLI (this machine)" panel is REMOVED from this page** (FR33). It is
   machine-scoped and **relocates to feature-010's CLI home**. This feature **owns the removal half**
   of FR33; feature-010 owns the receiving half. The delivered d004 panel (`.card.plugin`,
   "tool info unavailable") is dropped from the per-repo page in the revised slice.

**Owned requirements (revised):** FR3, FR11, FR16, FR27 (Level B `home.html` half), FR33 (**removal**
half). FR7 / Level-0 is **no longer owned here** — it moves to feature-010. The KB-card *behavior*
(5-state, FR32) is owned by feature-007; this page hosts that card.

**Priority (revised):** Must (part of the two-level refactor spine).

**Net delta scope:** small and front-end-only — re-home the existing main-page view to
`home.html` + delete the Level-0 panel + ensure the KB card consumes feature-007's 5-state status.
No new model owned here.

## Source

- REQUIREMENTS.md §5 FR3 (project main page — cards + click-to-drill)
- REQUIREMENTS.md §5 FR7 (Level-0 CLI info panel)
- REQUIREMENTS.md §5 FR11 (attention signals on cards)
- REQUIREMENTS.md §5 FR16 (lifecycle state displayed on cards)
- REQUIREMENTS.md §3a (Level 1 scope; Level-0 exception)

## Description

The **Level-1 project main page** — the dashboard's entry point and primary navigation. It shows a
**card for every pipeline/work** in the repo (current and completed), each displaying that
pipeline's **lifecycle state** (FR16) with **attention emphasis** for blocked/awaiting-input
(FR11). The page also hosts the **KB summary card** (opening the KB dashboard, feature-007) and the
**Level-0 AID CLI info panel** (version, install location, read locally). **Clicking a card opens
that item's detail view** (a pipeline card → the pipeline dashboard app). Two projects are never on
one screen (per-repo independence; browser tabs for more).

## User Stories

- As an **operator**, I want one page listing all my pipelines with their state, so I can see
  everything at a glance and jump into any one.
- As an **operator**, I want pipelines needing attention (blocked / waiting on me) visually flagged,
  so I notice them immediately.

## Priority

Should.

## Acceptance Criteria

- [ ] Given a repo with one or more works, when I open the main page, then I see a card per work
      with its lifecycle state, and clicking a card opens that pipeline's view (FR3, FR16).
- [ ] Given a blocked/awaiting-input work, when shown on the main page, then its card is visually
      called out (FR11).
- [ ] Given the page, then it includes a KB summary card (→ feature-007) and a Level-0 CLI info
      panel (FR7), and shows only one project (per-repo independence).

---

## Re-architecture Revision (Technical)

> _**Scope of this section.** This is a **small, bounded go-forward delta** on the **already-delivered
> d004** main page (above). The d004 Technical Specification that follows remains the historical record
> and is **not rewritten**; this section captures **only** what the two-level re-architecture changes.
> Three deltas (R-1 re-home, R-2 drop the Level-0 panel, R-3 KB card → feature-007's 5-state model);
> **everything else from d004 carries over unchanged** (R-4). Per the charter block above, this feature
> owns the **removal** half of FR33; the **serving** of the page is owned by feature-010, and the **KB
> card's state behavior** is owned by feature-007 — both cross-referenced, not re-specified, here._

This view, delivered by d004 as the Level-1 main page **inside feature-003's `index.html`** (with the
Level-0 CLI panel), becomes the **per-repo `home.html`** of the two-level dashboard (FR27 Level B). It is
re-homed, the machine-scoped Level-0 panel is dropped, and its KB card adopts feature-007's 5-state model.
There is **no change** to the read-only / no-LLM contract, the per-work pipeline view, or the in-SPA
router's `#/` and `#/work/<work_id>` routes (FC-1/FC-2/FC-3) — the only structural changes are the rename,
the dropped panel, the KB-card state source, and the KB card's `#/kb` target (now feature-007's served
`kb.html`). Net: a **small front-end delta** (rename + delete the L0 panel + repoint the KB card at
feature-007's state source + `kb.html`) plus a **serving move owned by feature-010** (not this feature's
code).

### R-1. Re-home: `index.html` → `home.html` (the per-repo app shell) — FR27 Level B

- **The page file moves.** The delivered `dashboard/index.html` (d004) is renamed/relocated to
  **`<repo>/.aid/dashboard/home.html`** — the per-repo Level-B artifact, co-located with `kb.html`
  (feature-007) under `.aid/dashboard/` (NFR11). The d004 file is **renamed in place**: same SPA app
  shell, same `<main>` body (work-card grid + the Knowledge section), same client router, **minus** the
  Level-0 panel (R-2) and with the KB card driven by feature-007 (R-3). This is a **file rename + a small
  body edit**, not a rebuild.
- **`index.html` is no longer this feature's file.** The shared CLI-level `index.html` is now
  **feature-010's CLI home** (the repo-list / machine page, served at `/`). This page is **not** the
  dashboard's top entry point anymore: the CLI home sits **above** it, and the user reaches this
  `home.html` by clicking a **repo card** on the CLI home (feature-010 UI-H2 / FF-3 step 4). The page
  `<title>`/brand still shows the single `model.repo.project_name` (FR9, unchanged), but the page is now
  one repo's view within the multi-repo navigation tree, not the root.
- **`home.html` is the live per-repo app shell.** It remains the same polling SPA: it fetches its repo's
  `/api/model` and renders the work-card grid + KB card live (FR4/NFR3). The **only** change to the poll
  is the **URL it polls**: under feature-010's multi-repo server (FR30) this repo is addressed by a
  per-repo route, so `home.html` is served at **`/r/<id>/home.html`** and polls **`/r/<id>/api/model`**
  (feature-010 DM-2 `<id>`, FF-2 routes) rather than the bare `/` + `/api/model` d004 used. The
  `/api/model` **envelope and `RepoModel` shape are unchanged** (feature-003 DM-1) — feature-010 runs
  feature-002's `read_repo` against this repo's root and returns the same body; only the route prefix is
  new, and that prefix is owned/parameterized by feature-010's front-end seam, not re-specified here.
- **Routing is unchanged inside the page** (except the `#/kb` target, R-3). The in-SPA hash router
  (FC-1/FC-2/FC-3) is **untouched** for the navigation routes — `#/` (this main page) and
  `#/work/<work_id>` (per-work pipeline view) behave exactly as d004. The **`#/kb` seam (SEAM-1) is the
  one routing change**, and it is owned by R-3 (the KB card now targets feature-007's served `kb.html`
  rather than an in-SPA `#/kb` view). The remaining hashes are repo-local and live *within* the
  `/r/<id>/home.html` document; feature-010's per-repo route prefix and the page's own hash router compose
  cleanly (the prefix selects the repo + document; the hash selects the view within it). DD-1 (hash- not
  path-routing) still holds and for the same reason.

### R-2. Remove the Level-0 "AID CLI (this machine)" panel — FR33 (removal half)

- **The Level-0 panel is deleted from this page.** The d004 `LC-L0` panel (`.card.plugin`, kicker
  "AID CLI (this machine)", rendering `model.tool` version/install/tools, with the "tool info
  unavailable" degraded state — d004 UI-5 / `index.html:1589-1645`) is **removed** from `home.html`. It
  is **machine-scoped** (the same value regardless of which repo's dashboard is open) and therefore has
  no place on a per-repo page. This feature **owns the removal half** of FR33.
- **It relocates to feature-010's CLI home.** The receiving surface is feature-010's CLI home `machine`
  panel (feature-010 DM-2 `machine.*`, UI-H1). The d004 `model.tool` fields no longer need to be read by
  this page; this view **no longer consumes `model.tool`** at all (it remains in the `/api/model`
  envelope for compatibility, but `home.html` ignores it).
- **Per-repo `tools_installed`, if shown at all, is not on this page.** The per-repo installed-tools
  info (`.aid/.aid-manifest.json` tools — feature-002 DM-2) is surfaced on **feature-010's CLI-home repo
  card** (feature-010 DM-2 `repos[].tools_installed`, UI-H2), not here. `home.html` shows **only
  project-scoped content**: the **work-card grid** + the **KB card**. The d004 two-section layout
  ("Pipelines" + "Knowledge & Tooling") collapses to a **Pipelines section + a single KB card** — the
  "& Tooling" half of that section (the L0 panel) is gone.

### R-3. KB card → feature-007's 5-state model + link to `kb.html` — FR32 (hosted here, owned by f-007)

> **Delivery sequencing (d008 vs d009 — PLAN-ratified):** the 5-state repoint described in this R-3 is a
> **delivery-009 step**, not delivery-008. d008 (the feature-006 `home.html` re-home + L0-panel removal,
> task-054) ships the KB-card slot in its **carried-over d004 2-state form** (Approved/Draft/`null`→"no KB"),
> so there is no broken intermediate; the repoint of that slot to feature-007's **5-state** model + the
> `/r/<id>/kb.html` target lands in d009 (see PLAN.md d008 "KB-card intermediate state" note and d009's
> Slice-2 KB-card repoint). The state model described below is the **d009 end-state**, not d008's delta.

- **The KB card's state model is now feature-007's, not d004's two-state.** d004's `LC-KB` card showed a
  two-state summary (Approved/Draft from `summary_approved`, with a `null` → "no KB" case — d004 UI-4).
  The revised card reflects feature-007's **5-state reader-derived model** (FR32):
  **pending → generating → preparing → approved → outdated**. Only **approved** and **outdated** are
  **clickable**; **outdated** opens the stale page with a refresh prompt (feature-007 FR32). The card's
  *state derivation and per-state rendering are owned by feature-007* — this page **hosts** the card and
  provides its slot in the Knowledge section; it does **not** re-spec the state machine, the reader
  KB-status (FR35 git read), or the state-to-badge mapping. **Cross-reference feature-007** for all of it.
- **The card links to `kb.html`, not (only) a hash route.** d004's card opened the in-SPA `#/kb` seam
  (SEAM-1) to feature-007's *client-rendered* view. Under the re-architecture, the KB detail is a
  **pre-rendered `kb.html`** (FR31) that `aid-summarize` produces and feature-010's server serves at
  **`/r/<id>/kb.html`**. The KB card's clickable target is therefore that served page. **Feature-007 owns
  the KB card (its 5 states + its click/disabled behavior) and `kb.html`** (FR31/FR32); this feature owns
  only the **slot** the card occupies on `home.html`. The d004 `#/kb` hash seam is **superseded** by
  feature-007's served-`kb.html` target; the exact link form (a `/r/<id>/kb.html` href vs. a feature-007
  handler) is feature-007's to specify.

### R-4. Everything else from d004 carries over UNCHANGED (the delta is bounded)

The following d004 behavior is **explicitly unchanged** by this revision — it is re-homed verbatim, not
re-specified:

- **Work-card grid** (UI-2/UI-3 `LC-CG`/`LC-WC`): one card per `model.works[]` entry, lifecycle badge +
  phase rail + `.meta`, the f-002 `lifecycle`→f-003 badge mapping, the unknown-literal tolerance.
- **FR11 attention / pin-to-top** (UI-3, DD-2): amber **Input** / red **Blocked** two-color emphasis +
  left-border + the two-pass "attention cards first" sort (`index.html:1262-1273`), unchanged.
- **The progress model** (the per-card phase rail mini, `tasks.length`, `source_mode` "approx" chip).
- **Local date formatting** (`_fmtLocalDateTime`, `index.html:1296` — browser-local date/time, date-only
  values rendered without a TZ shift), unchanged.
- **The per-work drill route** (`#/work/<work_id>`, find-by-key never index, FC-3 stale-work notice) and
  the **in-SPA router** (FC-1/FC-2/FC-3), unchanged.
- **The FR18 step-by-step empty-state** (`works == []` → guided "start your first pipeline" panel, UI-5),
  unchanged.
- **The read-only / no-LLM contract** (NFR2/NFR7): `home.html` writes nothing to `.aid/`, runs no
  agent/LLM, persists only `localStorage` view-state — unchanged. The serving move (R-1) is owned by
  feature-010, whose multi-repo server **preserves** feature-003's bind/no-write/no-LLM invariants
  (feature-010 SEC-1..3 / FR30 / C6); no read-only surface is weakened by this revision.

### R-5. Revised owned-requirements + cross-feature dependencies

- **Owned (revised):** FR3, FR11, FR16, **FR27 (Level-B `home.html` half)**, **FR33 (removal half)**.
  **No longer owned here:** FR7 / Level-0 (→ feature-010, render half). **Hosted, not owned:** the KB card
  behavior (FR32 → feature-007); `kb.html` (FR31 → feature-007).
- **Dependency on feature-010 (serving).** `home.html` is reachable and live **only through** feature-010's
  multi-repo server: the `/r/<id>/home.html` static route, the `/r/<id>/api/model` per-repo poll, the
  `<id>` addressing (feature-010 DM-2 / FF-2), and the CLI-home repo card that links here (feature-010
  UI-H2). This feature **delivers the static `home.html` artifact**; feature-010 **delivers the routing**
  that serves and reaches it. Sequencing: feature-010's server + CLI home must land for `home.html` to be
  reachable at its new address (the rename itself is independent, but the page is only *usable* via
  feature-010's routes).
- **Dependency on feature-007 (KB card states + `kb.html`).** The KB card's 5-state status (FR32) and the
  `kb.html` it links to (FR31) are produced/owned by feature-007 (the reader KB-status derivation FR35,
  the served summary). This page provides the **card slot**; feature-007 fills its states and target. The
  card must degrade gracefully for every state including **pending** (the d004 `null` → "no KB" case maps
  onto feature-007's **pending** state).
- **No new model, no new endpoint, no new schema bump owned here.** The revision adds **no** field to
  `RepoModel` and **no** `schema_version` change of its own (the FR32 reader fields are feature-007's; the
  per-repo route is feature-010's). This page's net code change is: rename the file, delete the L0-panel
  render path, and point the KB card at feature-007's state source + `kb.html`.

### R-6. Migration reality (delivered d004 → revised `home.html`)

The **delivered** d004 `dashboard/index.html` becomes `<repo>/.aid/dashboard/home.html` via a **rename +
two edits**: (a) delete the Level-0 panel render (R-2), (b) repoint the KB card to feature-007's 5-state
source + `kb.html` (R-3). The poll URL becomes per-repo (`/r/<id>/api/model`) but that is consumed via
feature-010's serving — the front-end change here is the rename and the L0/KB body edits; the route
prefixing is feature-010's. This is a **small front-end delta**, not a rebuild; the historical d004
Technical Specification below documents the unchanged majority (R-4).

---

## Technical Specification

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Data Model** (the slice of
> feature-002's `/api/model` JSON this view consumes — `model.works[]` for the card grid, `model.tool`
> for the Level-0 panel, `model.repo.kb_state` for the KB card; **no new model**), **Feature Flow**
> (this is a **route/view inside feature-003's existing SPA** — the main page is the default route,
> renders cards from the **shared** poll loop, card click navigates to the per-work pipeline view
> keyed by `work_id`; KB card → feature-007), **Layers & Components** (the card-grid, work-card, KB
> summary card, Level-0 panel, and the in-SPA router — all front-end-only additions reusing
> feature-003's `index.html`, server, poll loop, and design tokens). Conditional: **UI Specs**
> (REQUIRED by FR3/FR7/FR8/FR9/FR11/FR15/FR16/FR18/NFR6/NFR8 — card layout, lifecycle badge + FR11
> attention emphasis matching feature-003's two-color scheme, KB-card summary fields, Level-0 panel,
> responsive grid, one-project-per-page, and the FR18 step-by-step empty-state). **Skipped:** Data-DB
> (no database — `schemas.md`), Migration (net-new front-end, no on-disk change), API Contracts →
> external (the only API is feature-003's internal `/api/model`; not re-specified here), CLI
> (feature-004), Security / remote exposure (feature-005), State Machines (the FR16 lifecycle is
> derived by feature-002 and rendered as a literal here — not re-derived).

This feature is **front-end only and additive**. It is **not a new app** — it is the **Level-1 default
view inside feature-003's single SPA**, served by feature-003's same thin dual-runtime server from the
same `index.html`, fed by the **same `/api/model` poll loop**, themed with the **same
`knowledge-summary/` design family**. It introduces **no new model, no new endpoint, no new server
route, no new poll mechanism, and no new runtime dependency**. Everything it renders already exists in
feature-002's `RepoModel` (`works[]`, `tool`, `repo.kb_state`) and crosses the wire today in
feature-003's `/api/model` envelope (feature-003 DM-1/DM-2). At runtime it is deterministic
client-side code — **no agent/LLM** (NFR7) and it **writes nothing to `.aid/`** (NFR2; the only
persistence it touches is `localStorage` for client view-state, exactly as feature-003 UI-5 already
does for the poll interval).

**Relationship to feature-003 (the one app, two views).** feature-003 shipped the single-pipeline
progress view (its UI-2/UI-3 explicitly scoped to "the one active/selected work" and deferred the
multi-work card grid to feature-006). This feature delivers the **other view** in that same app: the
project main page that lists *all* works as cards and is the **entry point / primary navigation**
(FR3). The two views share the app shell (feature-003 UI-1 top bar, theme toggle, footer), the poll
loop (feature-003 Feature Flow step 3), the freshness/`parse_warnings` badges (feature-003 Telemetry),
and the design tokens. The net-new code is a **client-side router** + the card components below,
**plus one front-end-only change to feature-003's render path**: feature-003 today renders "the one
active/selected work" via `render(model)` with no selection input, so this feature adds a **`work_id`
selection parameter** to that front-end render call (`render(model, selectedWorkId)`) so the router can
target a specific work card's pipeline view. This is a **front-end-only** extension — feature-003's
**server, `/api/model` contract, `schema_version`, bind, and poll loop are all untouched** (the
"additive / no server change" claim is scoped to the server + wire contract, not the client render
signature). The `work_id` selection extension is in-scope for this feature.

---

### Data Model

No relational schema (AID ships no database — `schemas.md`). This view defines **no model of its own**.
It consumes a **read-only slice** of the `/api/model` JSON that feature-003 already serves (feature-003
DM-1 envelope `{ schema_version, generated_by, model }`; `model` = serialized feature-002 `RepoModel`).
The slice this view reads:

| `/api/model` path | Feature-002 type | Used for | This view's read |
|-------------------|------------------|----------|------------------|
| `model.works[]` | `list<WorkModel>` (f-002 DM-4), sorted by `work_id` asc (f-003 DM-2) | the **work-card grid** (FR3, FR12, FR16) | per card: `work_id`, `name`, `lifecycle`, `phase`, `active_skill`, `updated`, `pause_reason`, `block_reason`, `block_artifact`, `tasks.length`, `source_mode` |
| `model.tool` | `ToolInfo` (f-002 DM-2) | the **Level-0 CLI info panel** (FR7) | `aid_version`, `installed_at`, `tools_installed`, `manifest_present` |
| `model.repo.kb_state` | `KbStateRef` \| null (f-002 DM-3) | the **KB summary card** (FR15-card) | `summary_approved`, `last_summary_date`, `doc_count`; `null` → "no KB yet" state |
| `model.repo.project_name` | string (f-002 DM-3) | the page `<h1>` / top-bar brand (FR9 — one project) | the single project this page scopes to |
| `model.read` | `ReadMeta` (f-002 DM-7) | freshness badge + `parse_warnings` "data note" | reused verbatim from feature-003 Telemetry — not re-implemented |

**DM-1. Why no new model.** Every field the cards, KB card, and Level-0 panel need was deliberately
populated by feature-002 as a hook for *this* feature: feature-002 DM-2 states the Level-0 card UI "is
feature-006"; feature-002 DM-3 captures `kb_state` as "only what FR16/FR3 cards need to exist," with the
rich KB card deferred to feature-007. So the model contract is closed — this feature is purely a new
**projection** of existing data. No `schema_version` bump (feature-003 DM-1) is required, because no
wire field changes.

**DM-2. The only client-side state.** A single in-memory view-state record (never persisted to `.aid/`,
NFR2):

```
ViewState
├─ route:   { view: "main" | "pipeline" | "kb", work_id?: string }   # derived from location.hash (FC-2)
├─ model:   the last-good /api/model body (shared with feature-003's loop)
└─ ui:      { theme, poll_interval }   # already owned by feature-003 (localStorage), reused as-is
```

`route.work_id` is the **stable `work_id`** (f-002 DM-4: `work-NNN-{slug}`, "the stable key (FR12)") —
the navigation key from a card to its pipeline view. No numeric index is ever used as a key (works are
sorted by `work_id`, but indices shift as folders are added/removed; the `work_id` does not).

---

### Feature Flow

This view adds a **client-side router** over feature-003's existing poll loop. There is **no new
server round-trip and no new endpoint** — routing is pure front-end navigation over the model the
shared loop already polls. All steps are client-side; the server side is unchanged (feature-003 LC-S,
read-only, bound `127.0.0.1`).

```
BROWSER LOAD (feature-003 index.html boot — UNCHANGED)
  ... feature-003 boots: read poll interval, immediate first fetch('/api/model'), start poll loop ...

ROUTER (net-new, front-end only)
  FC-1  on boot AND on every poll render: parse location.hash -> ViewState.route
          ""  | "#/"               -> { view: "main" }            (default route = the main page, FR3)
          "#/work/<work_id>"        -> { view: "pipeline", work_id }
          "#/kb"                    -> { view: "kb" }              (feature-007's view; this feature owns only the seam)
  FC-2  render(model, route):
          view=="main"     -> render the main page (card grid + KB card + Level-0 panel)   [UI-1..UI-5]
          view=="pipeline" -> feature-003's single-pipeline view, scoped to the works[] entry whose
                              work_id == route.work_id (find-by-key; works is a list, not a map — never
                              index by position, since folder add/remove shifts indices)
          view=="kb"       -> feature-007's KB dashboard view (feature-007 owns its internals)
  FC-3  unknown / stale work_id (folder removed since last poll, FR12):
          show a small "that pipeline is no longer in this repo" notice + a "back to main" link;
          do NOT blank the page (mirrors feature-003 "never goes blank on a transient miss")

NAVIGATION (no server call — hash change only)
  click a work card        -> location.hash = "#/work/" + work_id   (FC-1 re-renders to pipeline view)
  click the KB card        -> location.hash = "#/kb"                 (feature-007 view; SEAM-1)
  click brand / "back"     -> location.hash = "#/"                   (back to main page)
  browser back/forward     -> hashchange event -> FC-1 re-render     (history "just works"; FR3 drill is reversible)

POLL (feature-003's loop — SHARED, UNCHANGED)
  every tick: fetch('/api/model') -> update ViewState.model -> re-render the CURRENT route (FC-2)
  so the main page's cards refresh live (FR4/NFR3) exactly like the pipeline view does
```

- **The main page is the default route (FR3 "entry point / primary navigation").** With no hash, the
  app lands on the card grid. This is the natural top of the navigation tree: main → (work pipeline |
  KB dashboard) → back. Routing is **hash-based** (`location.hash` + `hashchange`) deliberately: it
  needs **no server-side route table change** (feature-003 LC-S serves only `/` + `/api/model`; a
  `pushState` path router would 404 on reload because the server has no catch-all). Hash routing keeps
  feature-003's closed two-route server intact (its bind/no-write/no-LLM invariants untouched) while
  giving real back/forward/bookmarkable navigation. **DD-1 below** records this decision.
- **Live cards (FR4, NFR3, AC-`FR3`).** The card grid re-renders on every poll tick from the shared
  loop — a work that transitions `Running → Blocked` on disk shows its card flip to the red attention
  state within one interval, with no page-specific polling. The freshness/stale/disconnected badge and
  the `parse_warnings` "data note" are feature-003's top-bar elements, visible on the main page too.
- **One project per page (FR9).** The page renders exactly `model.repo.project_name` and exactly
  `model.works[]` — a single `.aid/` scope (feature-002 reads one repo). There is **no cross-project
  tab strip and no cross-repo aggregation** (REQUIREMENTS §4, FR9). Multiple projects = multiple
  browser tabs, each its own served dashboard — the page never blends two repos.
- **Empty repo (no works yet) — FR18 guidance, not a blank screen.** When `model.works[]` is `[]`
  (feature-002 Feature Flow: "a repo with zero works returns a valid `RepoModel` with `works=[]`"), the
  grid is replaced by a **step-by-step "start your first pipeline" empty-state** (UI-5) — this is a
  user-intervention point (the tool cannot start a pipeline for the user), so FR18 applies: it shows the
  exact command and how to verify, not a one-line hint. The KB card and Level-0 panel still render
  (they do not depend on works existing).
- **No write / no agent (NFR2/NFR7).** Navigation mutates only `location.hash` and in-memory
  `ViewState`; nothing is written to `.aid/`. There is no Agent/LLM anywhere in the client. View-state
  that must survive reload (theme, interval) uses `localStorage` only — feature-003's existing pattern,
  not `.aid/` (UI-5).

---

### Layers & Components

All additions are **front-end only**, inside feature-003's `index.html` (feature-003 LC-F front-end +
LC-A assets). No server (LC-S), reader (LC-R / feature-002), CLI (feature-004), or remote (feature-005)
code is touched. Per `coding-standards.md` (small, single-purpose, deterministic, no hidden I/O) and
`module-map.md` (the dashboard front-end is the module feature-003 introduced; this extends it).

| Component | Half | Responsibility | MUST NOT |
|-----------|------|----------------|----------|
| **LC-MV Router** | front-end | parse `location.hash` → route (FC-1); dispatch render to main / pipeline / KB view (FC-2); handle back/forward + unknown `work_id` (FC-3) | add a server route; use `pushState` (server has no catch-all); use a work's list-index as a nav key |
| **LC-CG Card grid** | front-end | render `model.works[]` as a responsive grid of work-cards (UI-2), sorted as the wire delivers (`work_id` asc) | re-sort/re-derive lifecycle (renders f-002's `lifecycle` literal verbatim, UI-3); collapse parallel tasks into a count that hides state |
| **LC-WC Work-card** | front-end | one card per work: name, phase rail mini, lifecycle badge + FR11 attention emphasis (UI-3), `updated`, fallback/`source_mode` note; click → `#/work/<work_id>` | invent its own status vocabulary (maps f-002 enum literals to f-003's existing CSS classes, UI-3) |
| **LC-KB KB card** | front-end | summarize `model.repo.kb_state` (doc count, completeness, freshness/approved — UI-4); click → `#/kb` (SEAM-1); `null` kb_state → graceful "no KB" card | render feature-007's full inventory (that is feature-007 behind the seam) |
| **LC-L0 Level-0 panel** | front-end | render `model.tool` (version, install, tools) as the machine-level CLI card (UI-5 → FR7); `manifest_present:false` → "tool info unavailable" | error/throw on missing manifest (f-002 DM-2 already null-fills) |
| **LC-ES Empty-state** | front-end | when `works==[]`, render the FR18 step-by-step "how to start a pipeline" guidance (UI-5) | fake that a pipeline exists; hide the KB card / Level-0 panel |

- **Dependency direction.** LC-MV/LC-CG/LC-WC/LC-KB/LC-L0/LC-ES depend only on (a) the `/api/model`
  JSON shape (feature-003 DM-1/DM-2 → feature-002 types) and (b) feature-003's design-family CSS
  (LC-A). They depend on **nothing** in feature-004/005 and add **no** server/runtime surface — which
  is why the same `index.html` is still served byte-identically by both runtimes (feature-003 PT-1 is
  unaffected: this view changes only client render logic, and the `/api/model` bytes are unchanged).
- **No-write / no-LLM, inherited structurally.** Because this feature adds no server code, feature-003's
  hard invariants (bind-`127.0.0.1`, no-write, no-LLM self-check tests — feature-003 LC-S) continue to
  hold unchanged; there is no new surface for them to police. The client adds no network call beyond
  the existing same-origin `fetch('/api/model')` (feature-003 LC-F).
- **The feature-007 seam (SEAM-1).** This feature owns **only the navigation seam** to the KB
  dashboard, not its internals. The contract is: the KB card is an anchor/handler that sets
  `location.hash = "#/kb"`; the router (FC-1) recognizes `#/kb` and hands rendering to feature-007's
  view function for the `model.repo.kb_state` slice (and feature-007 may itself read more of
  `model.repo` / re-poll the same loop). Feature-007 plugs into the **already-defined route + the
  shared poll loop** — it adds no new endpoint either. The `kb_state` *summary* fields this card shows
  (UI-4) are exactly feature-002 DM-3's hook set; feature-007's *fuller* inventory (doc list,
  per-doc completeness, INDEX freshness — feature-007 AC) lives behind the seam and is out of scope
  here.

---

### UI Specs

The Level-1 main page, built on the `knowledge-summary/` design family (NFR8) and the feature-003 app
shell. FR8 visual-first: minimal text, single short words, color **and** shape, glance-readable.

#### UI-1. Design-family reuse (NFR8) — what this view borrows

| Reused asset (`canonical/templates/knowledge-summary/`) | Used for |
|---------------------------------------------------------|----------|
| `component-css.css:218` `.card` (+ `:226` hover lift), `.card .kicker` `:227`, `.card h3` `:228`, `.card .stat` `:229`, `.card .stat-sub` `:230`, `.card .meta` `:231` | work-cards, KB card, Level-0 card — clickable cards already lift on hover, reinforcing "drill in" affordance (FR3) |
| `component-css.css:209-216` `.grid` + `.grid.g2` (`minmax(280px,1fr)`) / `.grid.g3` (`minmax(240px,1fr)`) / `.grid.g4` (`minmax(200px,1fr)`) | the responsive work-card grid (`.g3`, auto-fit → reflow, UI-6) and the Knowledge & Tool row (`.g2`, UI-2) |
| `component-css.css:186-206` `.badge` + `.badge-ok/-warn/-err/-info/-purple/-primary/-accent/-dim` | lifecycle badges (UI-3), KB freshness chips (UI-4), Level-0 version chip |
| `design-tokens.md` palette `--ok/--warn/--err/--accent/--text-dim` (+ `*-bg` tints), light **and** dark | semantic status colors carried verbatim — same meaning as feature-003 UI-4 |
| feature-003 UI-1 app shell (`.top-bar`, `.brand` `component-css.css:91/104`, `.controls` `:122`, `#theme-toggle` `.btn-ghost` `:123`) + footer + freshness badge | the page reuses feature-003's exact header/footer; the main page just swaps the `<main>` body |
| `design-tokens.md` "Mobile breakpoint 768px (collapse grids to 1fr)" (`component-css.css:563`) | responsive collapse (UI-6, NFR6) |

System fonts only, CSS custom properties, no web fonts, no CDN at runtime — same "no external assets"
posture feature-003 UI-1 / `html-skeleton.html` already enforce (NFR8). The theme toggle is
feature-003's; both views share it.

#### UI-2. Page layout — the dashboard of dashboards (FR3, FR9)

```
┌─ .top-bar (feature-003 shell) ─ brand: <project_name> · freshness badge · interval · theme ─┐
├─ <main> ─────────────────────────────────────────────────────────────────────────────────┤
│  PIPELINES (h2)                                                                            │
│  .grid.g3  ┌─ work-card ─┐ ┌─ work-card ─┐ ┌─ work-card ─┐ ...  (one per model.works[])     │
│            │ name        │ │             │ │             │                                 │
│            │ phase rail  │ │  [Blocked]  │ │  [Done]     │                                 │
│            │ [lifecycle] │ │  red border │ │  green      │                                 │
│            └─────────────┘ └─────────────┘ └─────────────┘                                 │
│  KNOWLEDGE & TOOL (h2)                                                                      │
│  .grid.g2  ┌─ KB summary card (→ #/kb) ─┐  ┌─ Level-0 CLI info panel ─┐                      │
└────────────────────────────────────────────────────────────────────────────────────────────┘
```

- **One project per page (FR9):** the brand shows the single `project_name`; there is no project
  switcher. Attention-needing works sort/emphasize to the top of the grid (UI-3) so they "jump out"
  (FR11) without re-ordering the stable `work_id` key (the visual emphasis is a CSS treatment, not a
  data re-sort that would change the nav key).
- Two grouped sections: **Pipelines** (the work cards — FR3/FR16) and **Knowledge & Tool** (the KB card
  FR15 + the Level-0 panel FR7) so the page answers "what are my runs doing?" first, then "what's the
  KB / tool state?".

#### UI-3. Work-card — lifecycle state + FR11 attention (FR3, FR16, FR11, FR8)

Each card renders one `WorkModel`. It maps the **feature-002 `lifecycle` literal** to **exactly
feature-003 UI-4's two-color attention scheme** (color **and** shape — FR8/FR11) — this view does not
invent a parallel vocabulary; it reuses feature-003's badge mapping so the main page and the pipeline
view agree pixel-for-meaning:

| `lifecycle` literal (f-002 DM-6) | Badge class (`.badge-*`) | Color token | Shape / glyph | Word | Card emphasis (FR11) |
|----------------------------------|--------------------------|-------------|---------------|------|----------------------|
| `Running` | `.badge-accent` | `--accent` teal | ▶ filled | "Running" | normal card; a **repo-level** liveness dot may appear in the shared app shell (feature-003 Telemetry / heartbeat is repo-scoped + corroborating-only per KI-004 — NOT a per-work heartbeat attribution) |
| `Paused-Awaiting-Input` | `.badge-warn` | `--warn` amber | ❚❚ pause bars | "Input" | **amber left-border + pinned to top** (attention) |
| `Blocked` | `.badge-err` | `--err` red | ✕ / octagon | "Blocked" | **red left-border + pinned to top** (attention) |
| `Completed` | `.badge-ok` | `--ok` green | ✓ check | "Done" | normal, muted |
| `Canceled` | `.badge-dim` | `--text-dim` grey | ⊘ slash | "Canceled" | normal, muted |
| *(unrecognized literal — forward-compat)* | `.badge-dim` | `--text-dim` | ? | "Unknown" | neutral, never throws (mirrors f-003 DM-2 unknown-enum tolerance) |

**Two attention colors, matching feature-003 (DD-2).** FR16 collapses "input" and
"confirmation/approval" into the single `Paused-Awaiting-Input` state ("an approval is a kind of
input — not a separate state"), and feature-002 SM-2 derives both from pending Q&A. So the card shows
**amber Input** vs **red Blocked** — the same two-color attention scheme feature-003 UI-4 already
ships, not three. This is a deliberate inheritance, not a re-decision; feature-003 already flagged the
three-vs-two reading for confirmation (feature-003 UI-4 design note) and this card honors that resolved
two-color reading.

Card body (FR8 minimal-text, glance-readable):
- **Header:** `.kicker` = `work_id` (e.g. `work-001`), `<h3>` = `name` (slug).
- **Phase rail (mini):** small inline pills from `phase` (f-002 `Phase ∈ Interview | Specify | Plan |
  Detail | Execute | Deploy | Monitor`) — current phase filled `--primary`/`--accent`, prior `--ok`
  muted, later `--text-dim` — the same rail concept as feature-003 UI-2, condensed for the card. If
  `phase` is `null` (fallback path, f-002 DM-4), the rail is omitted and only the lifecycle badge
  shows.
- **Lifecycle badge:** per the table above.
- **Attention detail (FR11):** for `Blocked`, surface `block_reason` and the `block_artifact` path
  (e.g. `IMPEDIMENT-task-NNN.md`) read-only, so the operator sees *why/where* without opening files;
  for `Paused-Awaiting-Input`, surface `pause_reason`. (Both come straight from f-002 DM-4.)
- **`.meta` footer:** `updated` (relative, e.g. "3m ago"), `tasks.length` ("4 tasks"), and a small
  `source_mode` chip only when `≠ normalized` (a quiet "approx" note — f-002 DM-4's fallback
  provenance, so a fallback-derived card reads honestly rather than overstating certainty).
- **Whole card is the click target** → `location.hash = "#/work/<work_id>"` (FC-1). The `.card:hover`
  lift (`component-css.css:226`) signals it is clickable; cursor pointer; keyboard-focusable
  (the deferred full a11y pass is REQUIREMENTS §4 out-of-scope, but a plain focusable anchor costs
  nothing and is used).

#### UI-4. KB summary card (FR15-card) + the feature-007 seam (SEAM-1)

A single card in the **Knowledge & Tool** section, summarizing `model.repo.kb_state` (the f-002 DM-3
hook set — *summary only*, the rich inventory is feature-007):

| Card element | Source (`kb_state`) | Display |
|--------------|---------------------|---------|
| `.kicker` | — | "KNOWLEDGE BASE" |
| `.stat` | `doc_count` | the document count (e.g. "12") with `.stat-sub` "docs" |
| completeness/approval chip | `summary_approved` (bool) | `summary_approved:true` → `.badge-ok` "Approved"; `false` → `.badge-warn` "Draft" |
| freshness `.meta` | `last_summary_date` | "summary updated {date}" |
| affordance | — | whole card → `location.hash = "#/kb"` (SEAM-1); `.card:hover` lift signals drill-in |

- **`kb_state == null` (repo never ran `/aid-discover`, f-002 DM-3):** the card renders a graceful "No
  Knowledge Base yet" state with a one-line `.meta` ("run `/aid-discover` to build the KB") rather than
  empty stats or an error — and it is **not** clickable (no KB view to open). This is a light hint, not
  a full FR18 procedure, because building the KB is an optional capability, not a blocking
  user-intervention point on the dashboard's own happy path; the acute FR18 cases are the empty-works
  state (UI-5) and feature-004/005's runtime/ACL steps.
- **Seam contract (SEAM-1):** clicking sets `#/kb`; FC-1 routes to feature-007. This card shows only
  the f-002 DM-3 summary fields; feature-007 owns the dedicated KB dashboard (doc inventory, per-doc
  completeness/status, INDEX freshness — feature-007 AC). This feature does **not** implement
  feature-007's body — only the route and the summary card that opens it.

#### UI-5. Level-0 CLI info panel (FR7) + empty-state (FR18)

**Level-0 panel** — the machine-level AID CLI card (FR7; the only non-repo-scoped data,
REQUIREMENTS §3a/§4), rendering `model.tool` (f-002 DM-2). It uses the `.card.plugin` variant
(`component-css.css:235-242`, the existing definition-list card with `dt`/`dd`) so version/install
render as labeled rows:

| Row | Source (`model.tool`) | Notes |
|-----|-----------------------|-------|
| `.kicker` | — | "AID CLI (this machine)" |
| version chip | `aid_version` | `.badge-info` (e.g. `1.0.0`) |
| installed | `installed_at` | ISO date, `.meta` |
| tools | `tools_installed[]` | small chips (e.g. `claude-code`) |
| (degraded) | `manifest_present == false` | render "tool info unavailable" `.meta` — **never error** (f-002 DM-2 null-fills) |

This panel is **read locally** (the manifest is machine-level, read by feature-002 on the host the
server runs on) — it is the same value regardless of which repo's dashboard is open, per the Level-0
exception (REQUIREMENTS §4).

**Empty-state — no works yet (FR18 step-by-step).** When `model.works == []`, the Pipelines section
replaces the grid with a guided panel. FR18 requires a **step-by-step** procedure (what to do, the exact
command, how to verify) — not a one-line hint — because starting a pipeline is a user-intervention the
tool cannot perform:

```
┌─ .card (empty-state, centered) ─────────────────────────────────────────────┐
│  kicker: NO PIPELINES YET                                                    │
│  h3: This repo has no AID works in .aid/ yet.                                 │
│                                                                              │
│  To start your first pipeline:                                               │
│   1. In this repo, run:   /aid-interview                                     │
│        — begins a new work (creates .aid/work-NNN-<name>/ + its STATE.md).    │
│   2. Follow the interview prompts to capture requirements.                    │
│   3. Verify: a work-NNN-* folder now exists under .aid/, and this page        │
│      shows a card for it on the next refresh (within the poll interval).      │
│                                                                              │
│  meta: this page refreshes every Ns — the card appears automatically.         │
└──────────────────────────────────────────────────────────────────────────────┘
```

The KB card and Level-0 panel still render in the empty case (they do not depend on works). The
"verify" step ties back to the live poll (FR4): the user does not reload — the new work-card simply
appears within one interval, which the empty-state explicitly tells them.

#### UI-6. Responsive + cross-browser (NFR6, NFR5)

- **Breakpoints** reuse the design family's 768px collapse (`component-css.css:563`
  `.grid, .grid.g2, .grid.g3, .grid.g4 { grid-template-columns: 1fr; }`). **Desktop** (>1024px): the
  `.grid.g3` work grid shows multiple cards per row (`max-width: 1200px` centered per design tokens);
  **tablet** (768–1024px): auto-fit reflows to 2 columns; **mobile** (<768px): single column, cards
  stack, the card phase-rail becomes a horizontally-scrollable strip. The grid uses CSS `auto-fit`
  `minmax` (the design family's own rule) so reflow is automatic — no per-count JS.
- **Cross-browser (NFR5):** Chrome/Firefox/Edge/Safari — only broadly-supported primitives (CSS custom
  properties, `grid`/`flex`, `fetch`, `localStorage`, `setTimeout`, `location.hash`/`hashchange`), all
  baseline across the four targets. No bleeding-edge CSS, no polyfill, no transpile (same posture as
  feature-003 UI-6).
- **Per the global CLAUDE.md web-review gate**, the reviewer MUST render this page in Playwright (not
  inspect source) and visually validate: the card grid with each lifecycle state, the FR11 attention
  emphasis, click-to-drill navigation, the KB-card → `#/kb` seam, the Level-0 panel, and the FR18
  empty-state — across the responsive breakpoints. A source-only review of this web page is an
  automatic fail.

---

### Design decisions worth user attention

- **DD-1 — Hash routing, not path routing.** The drill-down/navigation (FR3) uses `location.hash`
  (`#/`, `#/work/<id>`, `#/kb`) rather than History-API path routing. Rationale: feature-003's server
  is a **closed two-route allowlist** (`/` + `/api/model`, no catch-all — feature-003 LC-S); a path
  router would 404 on reload/bookmark of `/work/<id>` because the server would not serve `index.html`
  for that path. Hash routing keeps feature-003's hard bind/no-write/no-LLM invariants and zero-build
  posture completely untouched while still giving real back/forward/bookmarkable navigation. **If** the
  user later wants clean URLs, that requires adding a catch-all static route to feature-003's server
  (a server change with its own invariant re-test) — deliberately deferred.
- **DD-2 — Two attention colors on cards, inherited from feature-003 (not a new decision).** Cards show
  **amber Input** / **red Blocked**, the same two-color FR11 scheme feature-003 UI-4 ships, because
  FR16 folds approval/confirmation into the single `Paused-Awaiting-Input` state. If the operator ever
  needs cards to *visually distinguish* "approval gate" vs "open question," that is a sub-distinction
  feature-001 does not type today (same caveat feature-003 already flagged) — noted here only so the
  two-color choice is a conscious inheritance, not an omission.

---

### Acceptance-criteria → spec map

| AC (this SPEC) | Requirement | Satisfied by |
|----------------|-------------|--------------|
| card per work + lifecycle + click-to-drill | FR3, FR16 | UI-2 grid + UI-3 work-card (lifecycle badge from `model.works[].lifecycle`); FC-1/FC-2 router; click → `#/work/<work_id>` |
| blocked/awaiting-input visually called out | FR11 | UI-3 attention emphasis (amber/red left-border + pin-to-top + color+shape badge), matching feature-003 UI-4 |
| KB summary card + Level-0 CLI panel; one project | FR15-card, FR7, FR9 | UI-4 KB card (→ SEAM-1 `#/kb`) + UI-5 Level-0 panel; single `project_name`, single `works[]`, no aggregation |
| (cross) live, ≤ interval | FR4, NFR3 | FC poll-driven re-render on the **shared** feature-003 loop; cards refresh each tick |
| (cross) visual-first / responsive / browsers / NFR8 | FR8, NFR5, NFR6, NFR8 | UI-1 design-family reuse; UI-3 color+shape; UI-6 768px collapse + baseline primitives + Playwright gate |
| (cross) read-only / no-LLM | NFR2, NFR7 | front-end-only, no server change; nav mutates only hash + in-memory state; `localStorage`-only client persistence |
| (cross) no-works guidance | FR18 | UI-5 step-by-step empty-state (command + verify), not a one-line hint |

---

### Known issues registered by this feature

This feature is a **front-end-only projection** of feature-002's existing model over feature-003's
existing app + `/api/model`. It introduces **no new schema, endpoint, server route, or contract**, and
the feature-007 seam (SEAM-1) is a defined hash-route handoff, not a coupling defect. It consumes the
already-tracked KI-003 (IMPEDIMENT path — surfaced read-only in UI-3's `block_artifact`) and KI-004
(repo-level heartbeat — surfaced as the advisory live dot in UI-3) without duplicating them. **No new
`known-issues.md` entry is warranted.** (If, during implementation, hash routing proves to need a
server catch-all for some reload case, that becomes a real KI at that time per DD-1; it is not a defect
now.)
