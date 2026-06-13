# task-068: feature-008 drill-view UI specs (UI-1..UI-6) — findings/ledger/raw-STATE/logs panel + parallel drill, grounded on the d008 home.html + router

**Type:** DESIGN

**Source:** feature-008-skill-task-drilldown → delivery-010

**Depends on:** task-054

**Scope:**
- Produce the drill-view UI breakdown (a `design/feature-008-ui-breakdown.md`, mirroring task-027/task-052)
  that pins feature-008's UI-1..UI-6 against the **delivered, re-arch'd** base: the per-repo `home.html`
  (the d008 task-054 rename of the old `index.html`), its hash router, and the `knowledge-summary/`
  design family feature-006/007 reuse. This is the DESIGN seam the front-end implement task (task-071)
  builds against; it makes the concrete layout/affordance decisions, it does **not** write production code.
- **Ground every reference in the real d008 `home.html`** (the renamed file): the app shell (top bar,
  theme toggle, footer, freshness badge) it reuses, the `.card`/`.kicker`/`.stat`/`.meta`/`.grid.g2|g3`/
  `.badge-err|-warn|-ok|-info|-dim` primitives (UI-1), and the `#/work/<work_id>` route the drill seam
  extends. Spot-verify the line refs (the task-027 discipline) — do not invent selectors.
- **SEAM-2 drill route (per RC-1):** specify the `#/work/<work_id>/task/<task-id>` route as a **deeper
  hash route in `home.html`'s existing router** (composes under the served `/r/<id>/home.html` document;
  the per-`<id>` prefix selects repo+document, the hash selects the view). Specify how a **task chip**
  in the pipeline view (feature-003 UI-3, now in `home.html`) sets `location.hash` to enter the drill,
  and how **back** returns to `#/work/<work_id>` and drops that key from the `?detail=` set (reversible).
- **NAV-1 4-level breadcrumb (SPEC RC-4):** specify the **clickable Main › Project › Pipeline › Task**
  breadcrumb as an **extension of the existing `.breadcrumb` top-bar family** (`home.html:124–133`
  `.breadcrumb`/`.sep`/`.current`; the hardcoded `· Pipeline` brand suffix at `home.html:752` becomes the
  dynamic trail) — **not** a new component. Pin: it is **router-driven** (recomputed in the same shell-head
  that runs for every route, `home.html:1168–1176`; updates on `#/` → `#/work/<id>` → `#/work/<id>/task/<id>`
  and back via the existing `onHashChange`), **every ancestor is a link and the leaf is plain `.current`
  text**, and the **per-level nav targets**: Main → **absolute `/`** (the CLI-home page; label `AID`),
  Project → **`location.pathname`** (current page, hash cleared = list view; label `model.repo.project_name`),
  Pipeline → **`#/work/<work_id>`** (hash route; label work/pipeline name), Task = **leaf, no link** (label
  task id/title). Per route the path shows: main → `AID`; work → `AID › <project> › <pipeline>`;
  task → `AID › <project> › <pipeline> › <task>`. Specify that labels come **only from data already in
  `/api/model`** (`project_name`, work name, task id) — **no new field, no `<id>` in the model, no
  `details`-key dependency** (renders on the first drill tick before `details[key]` arrives), **no
  `schema_version`/`EXPECTED` change** (RC-2/RC-4) — and the existing **768px** truncation + **390px**
  collapse rules apply unchanged. Confirm **`index.html` needs no change** (it IS Main/level-1: its
  `AID · this machine` brand is the root, its cards already link `/r/<id>/home.html`, and it is already
  served at `/` — the Main link's target). This folds into task-071 (single `home.html` writer) — the
  DESIGN must **not** spec a separate breadcrumb writer/task.
- **UI-2 findings + ledger/grade panel:** the severity-tagged findings list (`[CRITICAL]`→`.badge-err`✕,
  `[HIGH]`→`.badge-warn`⚠, unknown→`.badge-dim` neutral; `description`·`location`·`disposition` chip;
  empty→"No quick-check findings recorded for this task."), and the **honestly-labeled** ledger: the
  **delivery** grade chip captioned "delivery grade (delivery-NNN)" — never "task grade" (AID grades per
  delivery, DM-1) — `delivery_id==null`→"Not yet graded (no delivery gate run)", reviewer tier + gate
  timestamp in `.meta`, and the deferred-`[HIGH]` issues 3-col table (`Severity·Description·Status`,
  Status chips) with the empty state.
- **UI-3 raw STATE.md viewer (RC-1 served path + R15):** a **monospace, HTML-escaped, scrollable,
  read-only `<pre>`** (no `contenteditable`/`<textarea>`/form/write affordance), captioned
  `source: .aid/<work>/STATE.md · read-only`; **deep-anchored** to the task's `### task-NNN` block /
  `## Tasks Status` row (DD-3, one STATE.md per work); **collapsed by default** with a `byte_len`-driven
  "show N KB" affordance; escapes `<`/`>`/`&` **and** `U+2028`/`U+2029` so STATE.md markup cannot inject
  (R15 — the no-injection contract; the served raw content flows only through the spine's
  construct-not-sanitize static path, d008 R9).
- **UI-4 honest logs panel + FR18 guidance:** the DM-4 honest-inventory states (`task_logs==none` always
  → "No per-task logs are captured." + the FR18 step-by-step guidance; `server_log_present` → the
  clearly-labeled "Dashboard server log (tool diagnostic — not a task log)" affordance;
  `heartbeat_present` → advisory "last seen", explicitly not a log) + the Blocked-work IMPEDIMENT-artifact
  pointer (read-only label to `.aid/{work}/IMPEDIMENT-task-NNN.md`). The panel **must not** fake a viewer
  over files that do not exist (KI-008).
- **UI-5 parallel-task drill (FR14):** N concurrent task drills each render an **independent** forensic
  panel (desktop `.grid.g2` side-by-side, mobile stacked); the view never merges two tasks' forensics; a
  drilled task that disappears between polls shows a "no longer in the work's state" notice + back link,
  never a blank.
- **UI-6 responsive + cross-browser:** the design family's 768px collapse (findings+ledger side-by-side
  → stacked; raw-state `<pre>` horizontally-scrollable, never wrap-corrupt); baseline primitives only
  (CSS custom props, grid/flex, fetch, localStorage, `location.hash`/`hashchange`, `<pre>`) — same
  posture as feature-003/006/007 UI-6.
- **Lazy-load affordance (NFR4, RC-1):** specify the first-tick "loading detail…" state (the tick that
  enters a drill may precede the first `?detail=`-bearing response by one round-trip → show the
  at-a-glance `TaskModel` + a loading affordance, then fill in — never blank), and that the `?detail=`
  set is appended to the **location-relative `./api/model`** poll (resolves to `/r/<id>/api/model`).
- **No schema decision is made here** — the no-bump call is settled in the SPEC's RC-2 note; this task
  applies it (no `EXPECTED`/`schema_version` change in the front-end it specs).

**Acceptance Criteria:**
- [ ] A `design/feature-008-ui-breakdown.md` is produced that grounds UI-1..UI-6 in the **real** d008
      `home.html` (the task-054 rename) + its router + the `knowledge-summary/` family; the cited
      selectors/line-refs are spot-verified (no invented assets).
- [ ] The `#/work/<work_id>/task/<task-id>` SEAM-2 route is specified as a deeper hash route in
      `home.html`'s existing router (composes under `/r/<id>/home.html`), reachable from a task chip and
      reversible via back (drops the key from `?detail=`); the client needs no `<id>` (location-relative).
- [ ] The **NAV-1 4-level breadcrumb** (Main › Project › Pipeline › Task) is specified as a **router-driven
      extension of the existing `.breadcrumb` top-bar family** (reused, not reinvented), with **ancestors as
      links / leaf as `.current`** and the exact per-level nav targets (Main → absolute `/`, Project →
      `location.pathname`/hash-cleared, Pipeline → `#/work/<work_id>`, Task = leaf); labels come **only from
      existing `/api/model` data** (no new field, no `<id>`, no `details` dependency, no schema/`EXPECTED`
      bump); it **folds into task-071** (no separate breadcrumb writer) and **`index.html` needs no change**
      (it is Main/level-1, served at `/`).
- [ ] UI-2 specifies the severity-tagged findings list (color+shape chips, empty state) and the
      **delivery-grade-not-task-grade** ledger (captioned per DM-1; `delivery_id==null` state; deferred-
      `[HIGH]` table with empty state).
- [ ] UI-3 specifies the raw STATE.md viewer as a **read-only, monospace, escaped, scrollable, collapsed-
      by-default `<pre>`**, deep-anchored to `### task-NNN`, escaping `<`/`>`/`&`/`U+2028`/`U+2029` (R15
      no-injection); no editable control or write affordance.
- [ ] UI-4 specifies the honest logs panel (the three DM-4 states + FR18 guidance + the Blocked IMPEDIMENT
      pointer) and never fakes a viewer over absent files (KI-008).
- [ ] UI-5 specifies independent parallel-drill panels (no merge; disappeared-task notice) and UI-6 the
      768px responsive collapse + baseline-primitive cross-browser posture.
- [ ] The first-tick "loading detail…" (never-blank) affordance and the location-relative `./api/model`
      + `?detail=` poll are specified; no `schema_version`/`EXPECTED` change is introduced (RC-2 no-bump).
- [ ] All §6 quality gates pass; this is a DESIGN artifact only (no production code); the Playwright R5
      visual gate is task-073.
