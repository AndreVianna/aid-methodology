# feature-008 UI Breakdown — Level-3 task drill-down (UI-1..UI-6) + NAV-1 4-level breadcrumb

**Type:** DESIGN output (task-068). Consumed **verbatim** by **task-071** (the single `home.html`
drill-view writer — LC-DV/LC-RV + the NAV-1 breadcrumb) and the **task-073** Playwright R5 visual gate.

**Source of truth for the render seam:** the **delivered d008 `home.html`** — the tracked
`/home/andre.vianna/projects/AID/.aid/dashboard/home.html` (the task-054 rename of the old per-repo
`index.html`, served by feature-010's multi-repo server at `/r/<id>/home.html`). Line refs below are
spot-verified against that file (task-027 discipline). NOT the pre-re-arch feature-003/008 SPEC layout.

**Source of truth for the Main/level-1 page:** `/home/andre.vianna/projects/AID/dashboard/index.html`
(the CLI home, served at `/`).

**Source of truth for wire fields:** `dashboard/server/server.py` serializers + `dashboard/reader/`
(feature-002 types). The breadcrumb reads only **already-serialized** lean-body fields (verified §2);
the forensic `details` map is produced by **task-070** (the reader/server detail producer, task-071's
peer dependency) per SPEC DM-1.

> **Scope:** design only — this artifact contains **no production code**. It pins UI-1..UI-6 and the
> NAV-1 breadcrumb against the real d008 base, makes every layout/affordance decision task-071 needs,
> and applies the settled reconciliations: **RC-1** (location-relative per-repo poll), **RC-2**
> (NO schema bump — `schema_version`/`EXPECTED` stay **3**), **RC-4** (router-driven breadcrumb,
> folds into task-071 — no separate breadcrumb writer). It introduces **no** schema/`EXPECTED` change
> and **no** new server route. The Playwright visual validation is **task-073** (not this task).

---

## 0. Component → {reused d008 asset, model field, AC} index

| Component (SPEC) | Reused asset in d008 `home.html` (line-verified) | Serialized field(s) read | task-068 AC |
|---|---|---|---|
| §1 App shell (top bar / theme / footer / freshness / data-note) | `.top-bar`,`.brand`,`#brand-name`,`.controls`,`#freshness-badge`,`#data-note-chip`,`<footer>` — feature-003 shell via d008, **reused, not duplicated** (`home.html:752–754` header) | `model.repo.project_name` (`:1170`); `model.read.*` | AC1 |
| §1 Panel layout (drill `<main>` body) | `<main>` body swapped; `.grid.g2` (findings ∥ ledger), `.card`,`.kicker`,`h3`,`.stat`,`.meta` | `details["<work>/<task>"]` (lazy, task-070) | AC1 |
| **§2 NAV-1 breadcrumb** | **`.breadcrumb` / `.breadcrumb .sep` / `.breadcrumb .current`** (`home.html:123–134`); the `· Pipeline` brand suffix (`home.html:754`) **replaced** by the dynamic trail | `model.repo.project_name`, `work.title`/`work.name`/`work_id`, `task.task_id` — **lean body only, no `details`** | AC2 |
| §3 SEAM-2 route | the existing hash router: `parseRoute()` (`home.html:1111`), `onHashChange` (`home.html:1145`), `#/work/<id>` arm (`home.html:1115–1124`), `findWorkById` (`home.html:1134`) | route parse only (no `<id>` from model) | AC1 |
| §4 Findings list (UI-2) | `.card`,`.badge-err/-warn/-dim/-ok/-info`,`.meta`,`.kicker` | `details[k].findings[]` | AC3 |
| §4 Ledger / grade (UI-2) | `.card`,`.badge-*`,`.stat`,`.meta`, 3-col `<table>` | `details[k].ledger.*` | AC3 |
| §5 Raw STATE.md viewer (UI-3) | a read-only `<pre>` + `.kicker`/`.meta` caption + `.btn-ghost` (`home.html:135`) expander | `details[k].raw_state.{text,byte_len,path}` | AC4 |
| §6 Logs panel (UI-4) | `.card`,`.callout`/`.empty-state`,`.meta`,`.badge-info` | `details[k].logs.{task_logs,server_log_present,heartbeat_present}` + work `block_artifact` | AC5 |
| §7 Parallel drill (UI-5) | `.grid.g2` desktop / 768px stack | `?detail=` comma-list → N `details[k]` | AC6 |
| §8 Responsive (UI-6) | `@media (max-width:768px)` `1fr` collapse (`home.html:252`); `@media (max-width:420px)` `.breadcrumb{display:none}` (`home.html:258`) | — (layout) | AC6 |

> **No CSS divergence to reconcile.** Unlike feature-006 (§0.1 there added `.pipelines-grid`/`.card.plugin`),
> every primitive this tier needs — `.card`(+hover), the full `.badge-*` family, `.kicker`/`.stat`/`.meta`,
> `.grid.g2`, `.breadcrumb`/`.sep`/`.current`, the 768px collapse, the `:root` light+dark tokens, the app
> shell — **already ships in d008 `home.html`**. The only net-new client code is (a) the SEAM-2 route arm,
> (b) the LC-DV/LC-RV drill-view render, and (c) the router-driven breadcrumb. No new palette (NFR8).

---

## 1. The SEAM-2 route — `#/work/<work_id>/task/<task-id>` (RC-1, AC1)

The drill is a **deeper hash route in `home.html`'s existing router**, not a new page and not a new
server route. The served document is `/r/<id>/home.html` (feature-010's multi-repo server); the per-`<id>`
**path** selects repo + document, the **hash** selects the view within it — they compose (feature-006 R-1).
The client **never needs `<id>`**: `/api/model` carries no `<id>` field, and the poll is location-relative.

### 1.1 Where it slots into the existing router (line-verified)

`parseRoute(hash)` (`home.html:1111–1130`) today matches `^/work/(.+)$` → `{view:'work', workId}`
(`:1115–1124`), `/kb` → `{view:'kb'}`, else `{view:'main'}`. task-071 adds **one arm, matched BEFORE the
`/work/<id>` arm** (more-specific-first), composing the composite key the SPEC DM-3 route carries:

```
route grammar (additive — the three existing arms are unchanged):
  #/work/<work_id>/task/<task-id>   -> { view:'task', workId, taskId }   [NEW — matched first]
  #/work/<work_id>                  -> { view:'work', workId }            (home.html:1115)
  #/kb                              -> { view:'kb' }                      (home.html:1126)
  #/  | ""  | unrecognized          -> { view:'main' }                    (home.html:1129)
```

Both halves are URL-decoded exactly as the existing `/work/<id>` arm decodes `workId` (`home.html:1119–1121`,
the `try{decodeURIComponent}` guard) — the `task-NNN` slug needs the same treatment for robustness. The
new arm dispatches inside `render(model, route)` (`home.html:1162`) beside the existing
`if (route.view === 'work')` / `else if (route.view === 'kb')` branches (`home.html:1179–1188`) with a new
`else if (route.view === 'task')` arm that calls the LC-DV render (§4–§7).

### 1.2 Entering from a task chip (reversible)

The pipeline (work) view renders wave-grouped **task chips** (`makeTaskChip`-family, `home.html:~2400–2427`:
`.chip-task-id`/`.chip-type`/`.chip-short-name`). task-071 makes each chip **navigable** — on click it sets:

```
location.hash = "#/work/" + encodeURIComponent(work.work_id) + "/task/" + encodeURIComponent(task.task_id);
```

(mirroring the existing work-card link at `home.html:1401`,
`card.href = '#/work/' + encodeURIComponent(work.work_id)`). Setting `location.hash` fires the existing
`onHashChange` (`home.html:1145–1149`) → `render(lastGoodModel, parseRoute(location.hash))` — **no fetch,
no new listener**. The transition is **reversible**: a "◄ back to pipeline" affordance (and the breadcrumb
Pipeline link, §2) sets `location.hash = "#/work/" + encodeURIComponent(work_id)`, dropping back to the
`view:'work'` render, and **drops that `<work>/<task>` key from the live `?detail=` set** (§3.2).

### 1.3 Lazy detail on the location-relative poll (RC-1, NFR4, AC7)

When `route.view === 'task'`, the front-end appends the open drills' composite keys to its poll. The base
URL is **location-relative `./api/model`** (resolves to `/r/<id>/api/model` against the served document —
the d008/task-065 pattern), NOT a bare global `/api/model`:

```
GET ./api/model                                          // main / work / kb views — lean TaskModel body, no `details`
GET ./api/model?detail=<work_id>/<task_id>[,<w>/<t>...]  // task view(s) — server attaches `details` for those tasks
```

- **Same route, additive query param** — no new path/verb added to feature-010's closed allowlist
  (`/` + `/api/home` + per-`<id>` `/r/<id>/{home.html,kb.html,api/model}`). The server `?detail=` branch
  is **task-070**'s (LC-SD inside the multi-repo server); this front-end is its only consumer.
- **`?detail=` comma-list** (FR14): one composite `<work_id>/<task_id>` per open drill (§7).
- **First-tick "loading detail…" — never blank (AC7).** The tick that *enters* a drill may precede the
  first `?detail=`-bearing response by one round-trip. On `details[key]` **absent**, render the task's
  **at-a-glance `TaskModel`** (id/type/status/wave from the already-polled `work.tasks[]`) **plus a
  "loading detail…" affordance**, then fill in findings/ledger/raw-state/logs on the next tick when
  `details[key]` is present (FC-3). The view never blanks on a transient miss (mirrors the existing
  stale-work notice posture, `renderStaleWorkNotice` `home.html:1746`).
- **Live forensics (FR4/NFR3).** Every poll re-renders the current route, so a `[HIGH]` finding or a
  delivery grade written mid-run appears in the open drill within one interval — off the same loop.

---

## 2. NAV-1 — the 4-level breadcrumb (Main › Project › Pipeline › Task) (RC-4, AC2)

NAV-1 is a **router-driven extension of the existing `.breadcrumb` top-bar family** — **NOT a new
component** and **NOT a separate writer task** (it folds entirely into task-071's single `home.html` body).
It replaces the hardcoded `· Pipeline` brand suffix with the full clickable ancestor path for the current
route.

### 2.1 The existing assets it extends (line-verified)

- **CSS family already present** (`home.html:123–134`): `.breadcrumb { flex:1; color:var(--text-dim);
  font-size:0.87rem; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }`,
  `.breadcrumb .sep { margin:0 0.45em; opacity:0.6; }`, `.breadcrumb .current { color:var(--text);
  font-weight:500; }`. **Reused verbatim** — ancestor links inherit `.breadcrumb` color/size, separators
  use `.breadcrumb .sep`, the leaf uses `.breadcrumb .current`. (Today the `.breadcrumb` class is defined
  but the brand markup uses a static `.brand` label — NAV-1 activates the family.)
- **Brand markup to replace** (`home.html:754`): `<strong id="brand-name">AID Dashboard</strong>
  <span class="dot">·</span>Pipeline`. The brand root + `#brand-name` stay (it is set from
  `model.repo.project_name` at `home.html:1170`); the static `<span class="dot">·</span>Pipeline` **suffix
  becomes the router-driven trail**.
- **Render hook** (`home.html:1162–1176`): the **route-independent shell head** that runs for **every**
  route inside `render(model, route)` — it already sets `document.title` and `#brand-name` from
  `model.repo.project_name` (`:1168–1171`) and calls `renderParseWarnings`. NAV-1's `renderBreadcrumb(model,
  route)` is called **here**, beside the `#brand-name` set, so it is recomputed on every render and rides the
  existing `onHashChange` re-render (`home.html:1145–1149`). **No new listener, no new poll, no new render
  entry-point.**

### 2.2 The 4-level tree → per-level nav targets (exact, no `<id>` carried)

| # | Level | Label source (lean body, no `details`) | Link? | Nav target on click |
|---|-------|----------------------------------------|-------|---------------------|
| 1 | **Main** | constant **`AID`** (the CLI-home brand) | **link** (ancestor) | **`href="/"`** — absolute, same-origin, the literal `/`. **Never reconstructed from a repo id** (the model carries none). This is the one absolute link. |
| 2 | **Project** | `model.repo.project_name` (`home.html:1170`) | **link** (ancestor) | **`location.pathname`** — the current page with the **hash cleared** (= the list view). It is the page you are already on, so **no `<id>` is needed** — `location.pathname` already resolves to `/r/<id>/home.html`. |
| 3 | **Pipeline** | the work name (resolved §2.3) | **link** (ancestor) | **`#/work/<work_id>`** — the existing in-page hash route. |
| 4 | **Task** | the task id `task.task_id` (resolved §2.3) | **NOT a link — leaf** `.current` | — (current level) |

Per route the rendered path is:

- **main view** (`#/` or no hash, `view:'main'`) → `AID` only — Main is the page, rendered as **`.current`**
  (leaf), no further levels, no separators.
- **work view** (`#/work/<id>`, `view:'work'`) → `AID › <project> › <pipeline>` — Main + Project are links,
  Pipeline is the **`.current`** leaf.
- **task view** (`#/work/<id>/task/<id>`, SEAM-2, `view:'task'`) → `AID › <project> › <pipeline> › <task>` —
  Main + Project + Pipeline are links, Task is the **`.current`** leaf.

Separator between levels is the existing `.breadcrumb .sep` glyph (a consistent `›`/`·`-style mark across
all levels, one definition).

### 2.3 Label resolution — lean body only, renders on the first drill tick

Every label comes from data **already in the always-polled lean `/api/model` body** — **not** from the lazy
`?detail=` map — so the full path renders correctly on the **very first tick of a drill, before
`details[key]` arrives** (the breadcrumb has **no `details`-key dependency**):

- **Project** = `model.repo.project_name` (verified serialized at `server.py:407`; already consumed at
  `home.html:1170`). Fallback to `AID Dashboard` (the existing `#brand-name` fallback) if absent.
- **Pipeline** = the work's display name, resolved by the **existing work-header precedence**
  (`home.html:1808–1822`): prefer `work.title`; when absent, the labelled de-slug of `work.work_id`
  (`replace(/^work-\d+-/,'')` → spaces → Title Case), never the raw `work_id` presented as a name.
  > **Field correction (load-bearing).** The SPEC RC-4 table wording says the Pipeline label is
  > `work.short_name / work.work_id`, but the work serializer (`server.py:455–474`) carries **`title`** and
  > **`name`**, **not** `short_name` (`short_name` is a *task* field, `server.py:423`). task-071 MUST use
  > the existing work-title precedence (`title` → de-slug(`work_id`)), reusing `home.html:1808–1822`, NOT a
  > non-existent `work.short_name`. This is still "data already in `/api/model`" — no new field — so RC-4's
  > contract holds; only the field name in the prose is corrected here.
  The work object is found with the existing `findWorkById(model.works, route.workId)` (`home.html:1134`).
- **Task** = `task.task_id` (verified serialized at `server.py:416`); when the chip-style display number is
  wanted, the existing `parseTaskNumber` (`home.html:~2405`) may render `#NNN`, but the leaf label is the
  literal `task.task_id` per RC-4. No `task.short_name` dependency for the leaf (it is the at-a-glance id;
  `short_name` may be appended as a title attribute, not required).

### 2.4 Behavior, reuse, and the no-change contracts

- **Router-driven (the core requirement).** Recomputed on **every render** from `parseRoute(location.hash)`
  + the polled `model` — it updates as the hash changes (list → `#/work/<id>` → `#/work/<id>/task/<id>` and
  back) so the operator can **climb the tree without the browser Back button**, and the path always stays
  correct. Rides the existing `onHashChange` (`home.html:1145`) + the per-route shell head (`home.html:1168`).
- **Read-only, no model/schema change (RC-2).** It only sets `location.href` / `location.hash`; it never
  writes `.aid/`, never fetches `.aid/` directly. **No new field, no `<id>` field, no `details`-key
  dependency, NO `schema_version`/`EXPECTED` bump** — `schema_version` stays **3**, `EXPECTED` stays **3**
  (NAV-1 reads nothing new off the wire). No stale-assets-banner churn.
- **Visual reuse (NFR8).** Reuses `.breadcrumb`/`.sep`/`.current` (`home.html:123–134`) — no new component,
  no new palette. The existing **768px** truncation (`home.html:250`: `.breadcrumb { font-size:0.78rem;
  min-width:0; }` + the family's `overflow:hidden; text-overflow:ellipsis`) and the **390px-class collapse**
  (`home.html:258`, `@media (max-width:420px) { .breadcrumb { display:none; } }`) **apply unchanged** — the
  trail truncates with an ellipsis on tablet and collapses entirely on the narrowest viewport, exactly as
  the current label does.
- **`index.html` needs NO change — it IS Main / level-1.** Verified: its brand is `<strong>AID</strong>
  <span class="dot">·</span>this machine` (`dashboard/index.html:474–476`), it is served at **`/`** (the
  Main link's target), and its project cards already link `card.href = '/r/' + repo.id + '/home.html'`
  (`dashboard/index.html:807`). It is the **root** of the tree — it has no ancestor to climb to, so it
  needs no breadcrumb-back. The only contract it must keep (which it already satisfies) is being served at
  `/`. **task-071 does not touch `index.html`.**
- **Single writer / no new task.** All of NAV-1 lands in **task-071** (the single `home.html` drill-view
  writer). This DESIGN does **NOT** spec a separate breadcrumb writer/task — that would race task-054's
  rename / task-071's body on the same file. task-073 (Playwright R5) visually validates the breadcrumb at
  each level + that each ancestor link navigates correctly.

---

## 3. Lazy `?detail=` set management (RC-1, AC7) — the client plumbing

### 3.1 The only client-side route state (SPEC DM-3)

No new persisted state. The route descriptor gains `taskId`:
`route: { view:'main'|'work'|'kb'|'task', workId?, taskId? }` (§1.1). Theme/interval stay in feature-003's
`localStorage`, reused as-is. The **open-drill set** is derived from the live route(s) (§7), not persisted.

### 3.2 Enter / leave (reversible)

- **Enter** (`view:'task'`): add `"<work_id>/<task_id>"` (both halves from the hash) to the live `?detail=`
  set; the next poll re-issues `./api/model?detail=…` carrying that task's `TaskDetail`.
- **Leave** (back to `#/work/<id>` or `#/`): **drop** that composite key from the set; the payload shrinks
  back to the lean body. The drill is fully reversible (§1.2).

---

## 4. UI-2 — findings list + delivery-grade ledger (FR13, FR6, AC3)

Rendered **literally** from `details[k]` (task-070's reader output) — **no** client-side re-derivation of
grades/findings (NFR7). Desktop layout: findings ∥ ledger in `.grid.g2` (collapses to stacked at 768px, §8).

### 4.1 Findings list (`details[k].findings[]`)

Each finding row, a `.card`-internal line:

| Element | Source field | Render |
|---------|--------------|--------|
| Severity chip (color **and** shape, FR8) | `severity` | `[CRITICAL]` → `.badge-err` + ✕ (octagon); `[HIGH]` → `.badge-warn` + ⚠ (triangle); **unknown/other** → `.badge-dim` neutral, **never throws** |
| Description | `description` | verbatim text |
| Location | `location` | `file:line` in monospace `.meta`, **only when present** (`null` → omit) |
| Disposition chip | `disposition` | `Fixed-on-spot` → `.badge-ok` ✓; `Deferred-to-gate` → `.badge-info` →gate; other → verbatim neutral |

- **Empty state:** `findings == []` → **"No quick-check findings recorded for this task."** A clean task is
  the common case — this is a calm empty state, **not** an error chip.

### 4.2 Review ledger / grade (`details[k].ledger`) — honestly labeled per DM-1

AID records **no per-task grade** — grades are **per delivery** (DM-1 "ledger is a join"). The panel labels
this exactly:

- **Grade chip** — `ledger.grade` of the task's **delivery**, captioned **"delivery grade (delivery-NNN)"**
  using `ledger.delivery_id` — **never "task grade"**. `A+`/passing → `.badge-ok`; `Pending` → `.badge-dim`;
  rendered verbatim, never re-graded.
- **`ledger.delivery_id == null`** → **"Not yet graded (no delivery gate run)"** (pre-gate state) — no grade
  chip rendered.
- **Reviewer tier** (`ledger.reviewer_tier`, `Small/Medium/Large`) + **gate timestamp**
  (`ledger.gate_timestamp`) in `.meta`.
- **Deferred-`[HIGH]` issues table** — `ledger.deferred_issues[]` (the task's own rows from
  `delivery-NNN-issues.md`, already filtered `Source task == task_id` by the reader) as a compact 3-col
  `<table>`: **`Severity · Description · Status`**. Each `Status` is a chip: `Open` → `.badge-warn`,
  `Resolved` → `.badge-ok`, `Accepted` → `.badge-info`; unknown literal → neutral chip, never throws.
  - **Empty state:** `deferred_issues == []` → **"No deferred issues for this task."**

---

## 5. UI-3 — raw STATE.md viewer (FR13, NFR2, R15, AC4)

Renders `details[k].raw_state.text` — the literal `STATE.md` bytes of the task's **work** (AID keeps **one
STATE.md per work**, DD-3; there is no per-task STATE file) — as the operator's forensic escape hatch.

- **Read-only, structurally (NFR2).** A non-editable **`<pre>`** — **no** `contenteditable`, **no**
  `<textarea>`, **no** form, **no** write affordance of any kind. Captioned `source: .aid/<work>/STATE.md ·
  read-only` (the caption is a **label, not an edit link**), using `raw_state.path`.
- **Monospace + scrollable.** `<pre>` monospace; horizontally scrollable within its box (monospace must
  **not** wrap-corrupt — the bytes are shown as-is, never re-flowed).
- **Escaped — no injection (R15, AC4).** Escape `<` → `&lt;`, `>` → `&gt;`, `&` → `&amp;`, **and** the line
  separators `U+2028` / `U+2029` (to NCRs `&#8232;`/`&#8233;`) so STATE.md markup/HTML **cannot inject** into
  the page. The served arbitrary `.aid/` content is **rendered, never executed** — the construct-not-sanitize
  static-path discipline (d008 R9) covers the production side; the front-end escapes on render.
- **Deep-anchored (DD-3).** On open, scroll to / highlight the task's relevant text — the `## Tasks Status`
  row for `task_id` and the `### task-NNN` block under `## Quick Check Findings` — so the operator lands on
  the task's text without losing the whole-file view. (Anchor by client-side text search within the escaped
  `<pre>`; no server anchor needed.)
- **Collapsed by default + `byte_len` affordance.** The viewer is **collapsed by default** (it is large;
  works with the lazy load so the heavy bytes are not in the initial paint) behind a `.btn-ghost`-style
  expander whose label is driven by `raw_state.byte_len`: **"show raw STATE.md (N KB)"** (compute KB from
  `byte_len`). Expands on demand.

---

## 6. UI-4 — honest logs panel (FR13, FR18, KI-008, AC5)

Reflects DM-4's honest on-disk inventory. It **must NOT fake a log viewer over files that do not exist**
(KI-008). Three states, driven by `details[k].logs`:

| `logs` state | Panel content |
|--------------|---------------|
| `task_logs == none` (**always**, today) | **"No per-task logs are captured."** + the **FR18 step-by-step guidance** (below). The normal, honest state — **not** an error, **not** a fake-empty viewer. |
| `server_log_present == true` | A clearly-labeled **"Dashboard server log (tool diagnostic — not a task log)"** affordance noting `.aid/.temp/dashboard.log` exists (the dashboard server's own stdout/stderr from `aid dashboard start`, feature-004). Surfaced as a server-troubleshooting aid, **never** as this task's output. (Expected **false on Windows** — show the honest "not captured on this platform" state, not a fake viewer.) |
| `heartbeat_present == true` | An advisory **"last seen"** line from `.aid/.heartbeat/` (repo-level, corroborating-only, KI-004) — a **liveness** hint, explicitly **not** a log. |

**FR18 guidance card** (`task_logs == none`, the always-on state) — a `.card` with `kicker: NO TASK LOGS
CAPTURED`:
1. The dashboard server's own log is at `.aid/.temp/dashboard.log` (created by `aid dashboard start`; it
   records the **server's** boot/errors, not task execution).
2. For pipeline/task troubleshooting, re-run the relevant skill (e.g. `/aid-execute`) and watch its live
   terminal output; AID writes task forensics to this work's `STATE.md` (`## Quick Check Findings`,
   `## Delivery Gates`) — shown on **this** page.
3. Verify: after a re-run, this panel's Findings/Ledger sections update on the next refresh (within the
   poll interval) as the reviewer writes them.
- `meta`: "this page refreshes every Ns — new findings appear automatically."

**Blocked-work IMPEDIMENT pointer (FR18).** If the work is **Blocked** with an IMPEDIMENT (the work's
`block_artifact`, serialized at `server.py` `_ser_work` `block_artifact`; `.aid/{work}/IMPEDIMENT-task-NNN.md`
per KI-002/KI-003), the panel additionally surfaces a **read-only label** to that artifact path — pointing
the operator at the file to read and decide on. The dashboard **never runs commands itself** (read-only,
NFR2): it tells the operator exactly what to type / which file to open and how to confirm, never executes.

---

## 7. UI-5 — parallel-task drill (FR14, AC6)

Concurrency is first-class. From the wave-grouped task chips (`home.html:~2400`), the operator can drill
**several** concurrent tasks. Each open drill is its own composite key in the `?detail=` comma-list (§3.2)
and renders an **independent** forensic panel:

- **Desktop:** side-by-side `.grid.g2` panels (each its own findings/ledger/raw-state/logs).
- **Mobile (<768px):** stacked (§8).
- **Never merged.** The view **never** collapses two tasks' forensics into one — N drilled tasks = N panels,
  matching FR14's "several simultaneously-active tasks … not a single linear current task".
- **Disappeared-task notice (never blank).** A drilled task whose row is removed between polls (FR12) shows a
  small **"this task is no longer in the work's state"** notice + a back link, **never a blank** (mirrors
  `renderStaleWorkNotice`, `home.html:1746`, and feature-006 FC-3).

---

## 8. UI-6 — responsive + cross-browser (NFR6, NFR5, AC6)

- **Breakpoints reuse the d008 family.** **Desktop (>1024px):** findings ∥ ledger side-by-side (`.grid.g2`),
  the raw-state `<pre>` full-width below, parallel drills side-by-side. **Tablet (768–1024px):** g2 panels
  stay 2-up; the raw-state `<pre>` scrolls horizontally within its box. **Mobile (<768px):** the existing
  `@media (max-width:768px)` rule (`home.html:252`: `.grid, .grid.g2, .grid.g3, .grid.g4, .grid.g-lane,
  .pipelines-grid { grid-template-columns: 1fr; }`) stacks everything to one column; the raw-state `<pre>`
  is horizontally-scrollable (monospace must not wrap-corrupt), collapsed by default so it does not dominate
  the small viewport. The breadcrumb truncates at 768px (`home.html:250`) and collapses at the 420px class
  (`home.html:258`), unchanged (§2.4).
- **Cross-browser (NFR5):** Chrome/Firefox/Edge/Safari — **baseline primitives only**: CSS custom
  properties, `grid`/`flex`, `fetch`, `localStorage`, `location.hash`/`hashchange`, `<pre>`. No polyfill, no
  transpile — same posture as feature-003/006/007 UI-6.

---

## 9. No schema decision is made here (RC-2)

The **no-bump** call is settled in the SPEC's RC-2 note; this artifact **applies** it. The front-end task-071
reads `details` **additively** at the same `schema_version 3` envelope; the front-end `EXPECTED` **stays 3**;
**no** `schema_version`/`EXPECTED` change is introduced; **no** stale-assets-banner churn. The `details` map
is present only on a `?detail=` request and the lean body is byte-unchanged otherwise (RC-2 / the `created`
precedent). The key-order parity (`details` sorted ascending by `"work_id/task_id"`) and the PT-1-H fixture
extension are **task-070**'s producer obligations, not this front-end's.

---

## 10. AC → component map (task-068 ACs)

| task-068 AC | Satisfied by |
|---|---|
| Grounds UI-1..UI-6 in the **real** d008 `home.html` + router; selectors/line-refs spot-verified | §0 index + every §-level line ref (`home.html:123–134`,`:252`,`:258`,`:754`,`:1111`,`:1115`,`:1134`,`:1145`,`:1162–1176`,`:1401`,`:1808–1822`,`:~2400`; `index.html:474–476`,`:807`; `server.py:407`,`:416`,`:423`,`:455–474`) |
| SEAM-2 `#/work/<id>/task/<id>` as a deeper hash route, reachable from a chip, reversible, client needs no `<id>` (location-relative) | §1.1–§1.3 |
| **NAV-1 4-level breadcrumb** — router-driven extension of `.breadcrumb`, ancestors-as-links/leaf-as-`.current`, exact targets (Main→`/`, Project→`location.pathname`, Pipeline→`#/work/<id>`, Task=leaf), labels from existing `/api/model` only, folds into task-071, `index.html` unchanged | §2 (whole section) |
| UI-2 severity-tagged findings (color+shape, empty) + **delivery-grade-not-task-grade** ledger (`delivery_id==null` state, deferred-`[HIGH]` table + empty) | §4 |
| UI-3 raw STATE.md viewer — read-only/monospace/escaped/scrollable/collapsed-by-default `<pre>`, deep-anchored, escapes `<`/`>`/`&`/`U+2028`/`U+2029` (R15), no write affordance | §5 |
| UI-4 honest logs panel (3 DM-4 states + FR18 guidance + Blocked IMPEDIMENT pointer), never fakes a viewer (KI-008) | §6 |
| UI-5 independent parallel-drill panels (no merge; disappeared-task notice) + UI-6 768px collapse + baseline-primitive cross-browser | §7, §8 |
| First-tick "loading detail…" (never blank) + location-relative `./api/model` + `?detail=` poll; no `schema_version`/`EXPECTED` change (RC-2 no-bump) | §1.3, §3, §9 |
| DESIGN artifact only — no production code; Playwright R5 visual gate is task-073 | this file (no code); §2.4 / scope note |
