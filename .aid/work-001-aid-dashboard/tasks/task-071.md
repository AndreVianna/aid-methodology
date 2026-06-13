# task-071: Front-end drill view (LC-DV/LC-RV) in home.html — findings/ledger/escaped read-only raw STATE.md/honest logs + parallel drill on SEAM-2

**Type:** IMPLEMENT

**Source:** feature-008-skill-task-drilldown → delivery-010

**Depends on:** task-068, task-070, task-054

**Scope:**
- Add the **LC-DV drill view + LC-RV raw-state viewer** to the per-repo `<repo>/.aid/dashboard/home.html`
  (the d008 task-054 rename, served at `/r/<id>/home.html`), per the task-068 UI breakdown. This is the
  **single front-end writer** in d010 (no same-file race; d008 task-054 owns the rename, this owns the
  drill-view body). Renders reader output **literally** — no client-side re-derivation of grades/findings
  (NFR7), no direct `.aid/` fetch.
- **SEAM-2 route (RC-1):** add the `#/work/<work_id>/task/<task-id>` route as a **deeper hash route in
  `home.html`'s existing router** (the one that owns `#/`, `#/work/<work_id>`); a **task chip** in the
  pipeline view sets `location.hash = "#/work/<work_id>/task/<task-id>"` to enter; **back** returns to
  `#/work/<work_id>` and drops that key from the `?detail=` set (reversible). The client needs no `<id>`.
- **NAV-1 4-level breadcrumb (SPEC RC-4) — router-driven, in THIS single `home.html` writer:** implement
  the **clickable Main › Project › Pipeline › Task** breadcrumb by **extending the existing `.breadcrumb`
  top-bar family** (`home.html:124–133`; replace the hardcoded `· Pipeline` brand suffix at `home.html:752`
  with the dynamic trail) — render/update it in the **route-independent shell-head that already runs for
  every render** (`home.html:1168–1176`, beside the existing `brand-name` set), so it is **router-driven**:
  recomputed from the parsed route + the polled model on every render and on the existing `onHashChange`
  (`home.html:1144–1149`) — **no new listener, no new poll, no new render entry-point**. Per route emit:
  main → `AID` (leaf); work (`#/work/<id>`) → `AID › <project> › <pipeline>` (leaf = pipeline); task
  (`#/work/<id>/task/<id>`, SEAM-2) → `AID › <project> › <pipeline> › <task>` (leaf = task). **Every
  ancestor is a link, the leaf is plain `.breadcrumb .current` text.** Exact nav targets: **Main →
  `href="/"`** (absolute, same origin — the CLI home; do **not** reconstruct it from `<id>`); **Project →
  `location.pathname`** (the current page with the hash cleared = the list view — no `<id>` needed, it is
  the page you are on); **Pipeline → `#/work/<work_id>`** (the existing hash route). Labels come **only from
  the always-polled lean body** — `model.repo.project_name` (already at `home.html:1170`), the work name,
  the task id — so the path renders correctly on the **first drill tick before `details[key]` arrives**
  (no `details`-key dependency). Reuse the existing `.breadcrumb .sep` separator (consistent glyph across
  all levels) and the existing **768px** truncation + **390px** `display:none` rules (`home.html:250`/`:259`)
  unchanged. **No new field, no `<id>` in the model, NO `schema_version`/`EXPECTED` bump** (RC-2/RC-4 hold).
  Read-only: only sets `location.href`/`location.hash`, never writes/fetches `.aid/`. **`index.html` is
  unchanged** (it is Main/level-1, served at `/`).
- **Lazy detail on the location-relative poll (RC-1, NFR4):** when a task route is active, append the
  open drills' composite keys to the **location-relative `./api/model`** poll as
  `?detail=<work_id>/<task_id>[,...]` (resolves to `/r/<id>/api/model?detail=…` against the served
  document — the d008/task-054 pattern). On entering a drill the first tick may precede the first
  `?detail=`-bearing response by one round-trip → render the at-a-glance `TaskModel` + a "loading detail…"
  affordance, then fill in on `details[key]` present; **never blank**. Leaving drops the key (payload
  shrinks back). Every poll re-renders the current route, so a finding/grade written mid-run appears
  within one interval (FR4/NFR3). **No** network call beyond the shared `./api/model`.
- **UI-2 findings + ledger (literal render):** the severity-tagged findings list (`[CRITICAL]`→`.badge-err`
  ✕, `[HIGH]`→`.badge-warn`⚠, unknown→`.badge-dim`; `description`·`location` in `.meta`·`disposition` chip
  `Fixed-on-spot`→`.badge-ok`✓ / `Deferred-to-gate`→`.badge-info`; empty→"No quick-check findings recorded
  for this task."), and the **honestly-labeled** ledger: the **delivery** grade chip captioned "delivery
  grade (delivery-NNN)" — never "task grade"; `delivery_id==null`→"Not yet graded (no delivery gate run)";
  reviewer tier + gate ts in `.meta`; the deferred-`[HIGH]` 3-col table (`Severity·Description·Status`,
  Status chips `Open`→`.badge-warn`/`Resolved`→`.badge-ok`/`Accepted`→`.badge-info`; empty→"No deferred
  issues for this task.").
- **LC-RV raw STATE.md viewer (UI-3, R15 — read-only + escaped):** render `raw_state.text` in a
  **monospace, HTML-escaped, scrollable, read-only `<pre>`** — no `contenteditable`/`<textarea>`/form/
  write affordance; captioned `source: .aid/<work>/STATE.md · read-only`. **Escape** `<`/`>`/`&` **and**
  `U+2028`/`U+2029` so STATE.md markup/HTML cannot inject (R15 no-injection — the served arbitrary
  `.aid/` content is rendered, never executed). **Deep-anchor** to the task's `### task-NNN` block /
  `## Tasks Status` row on open (DD-3); **collapsed by default** with a `byte_len`-driven "show N KB"
  affordance so the heavy bytes are not in the initial paint (works with the lazy `?detail=` load).
- **UI-4 honest logs panel (KI-008):** render the DM-4 states — `task_logs==none` (always) → "No per-task
  logs are captured." + the FR18 step-by-step guidance card; `server_log_present` → the clearly-labeled
  "Dashboard server log (tool diagnostic — not a task log)" affordance; `heartbeat_present` → advisory
  "last seen". For a **Blocked** work, additionally surface a read-only label to
  `.aid/{work}/IMPEDIMENT-task-NNN.md` (an FR18 user-intervention pointer). **Never** fake a viewer over
  absent files; the dashboard tells the operator what to type, never runs it (NFR2).
- **UI-5 parallel drill (FR14):** N open task drills each render an **independent** forensic panel
  (desktop `.grid.g2` side-by-side, mobile stacked) from their own `details[key]`; the view never merges
  two tasks' forensics; a drilled task that disappears between polls shows a "this task is no longer in
  the work's state" notice + back link, never a blank.
- **UI-1/UI-6 design family + responsive (NFR8/NFR6/NFR5):** built on the `knowledge-summary/` family
  (`.card`, `.badge-*`, `.kicker`/`.stat`/`.meta`, light+dark tokens) reusing feature-003's app shell via
  `home.html`; the 768px collapse (findings+ledger side-by-side → stacked; raw `<pre>` horizontally-
  scrollable, never wrap-corrupt); baseline primitives only.
- **NO `schema_version`/`EXPECTED` bump (RC-2):** the front-end reads `details` additively at the same
  envelope; `EXPECTED` stays **3**. Front-end stays read-only/no-LLM (renders reader output literally,
  no `.aid/` fetch, same-origin only).

**Acceptance Criteria:**
- [ ] The `#/work/<work_id>/task/<task-id>` SEAM-2 route renders the drill view in `home.html`, reached
      from a task chip and reversible via back (drops the key from `?detail=`); the client uses no `<id>`.
- [ ] The **NAV-1 4-level breadcrumb** is implemented in this single `home.html` writer as a **router-driven
      extension of the existing `.breadcrumb` family**: it recomputes per route (main → `AID`; work → `AID ›
      <project> › <pipeline>`; task → `AID › <project> › <pipeline> › <task>`) on every render + `onHashChange`,
      with **ancestors as links / leaf as `.current`** and the exact targets (**Main → `/`**, **Project →
      `location.pathname`**, **Pipeline → `#/work/<work_id>`**, Task = leaf). Labels read **only** existing
      `/api/model` data (`project_name`/work name/task id) — no new field, no `<id>`, no `details` dependency
      (renders on the first drill tick), **no `schema_version`/`EXPECTED` bump**; `index.html` is untouched.
- [ ] The poll appends `?detail=<work_id>/<task_id>[,...]` to the **location-relative `./api/model`**
      (resolves to `/r/<id>/api/model?detail=…`); the first tick shows at-a-glance + "loading detail…"
      then fills in (**never blank**); leaving drops the key; no network call beyond `./api/model`.
- [ ] UI-2 renders findings (color+shape chips, empty state) and the **delivery-grade-not-task-grade**
      ledger (captioned per DM-1; `delivery_id==null` state; deferred-`[HIGH]` table + empty state) —
      **literally** from reader output, no client re-derivation (NFR7).
- [ ] LC-RV renders `raw_state.text` in a **read-only, monospace, escaped, scrollable, collapsed-by-
      default `<pre>`** (no editable control), deep-anchored to `### task-NNN`, escaping
      `<`/`>`/`&`/`U+2028`/`U+2029` (R15 no-injection); the `byte_len` "show N KB" affordance is present.
- [ ] UI-4 renders the honest logs panel (the three DM-4 states + FR18 guidance + the Blocked IMPEDIMENT
      pointer); no viewer is faked over absent files (KI-008).
- [ ] UI-5 renders N parallel drills as independent panels (no merge; disappeared-task notice, never
      blank); UI-1/UI-6 use the `knowledge-summary/` family + light/dark + the 768px responsive collapse.
- [ ] No `schema_version`/`EXPECTED` bump (RC-2); static self-checks: `home.html` writes nothing to
      `.aid/`, no agent/LLM import, same-origin fetch only, no client-side grade/finding re-derivation.
- [ ] All §6 quality gates pass; rendered behavior is Playwright-validated by task-073 — this task adds the
      front-end change only.
