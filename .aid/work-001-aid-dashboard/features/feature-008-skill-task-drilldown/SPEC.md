# Skill / Task Drill-Down (Level-3 Forensic Detail)

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-10 | Feature identified from REQUIREMENTS.md §5 FR13, FR14, FR6 | /aid-interview |
| 2026-06-12 | **DEFERRED to its own separate later delivery** (user directive). Scope **UNCHANGED** — this feature is **not** part of the two-level dashboard re-architecture; it ships as an independent later delivery **after** the refactor. The SPEC below stands as-is; only its sequencing changes. | /aid-interview |
| 2026-06-12 | **Re-architecture reconciliation note added** (below) ahead of delivery-010 detailing. The SPEC body is **unchanged**; the note reconciles three of its premises to the post-re-arch base (the per-repo `/r/<id>/...` server, `home.html`'s router, the schema-3 floor) and records the **no-bump** schema decision for d010. Scope unchanged. | /aid-detail |
| 2026-06-13 | **NAV-1 added** (below, as reconciliation note **RC-4**): a user-requested **4-level clickable breadcrumb** (Main › Project › Pipeline › Task) that **folds into the existing d010 tasks** — it lives in the **same `home.html` drill-view router task-071 builds** (single home.html writer; no new home.html-writing task, no same-file race). It is router-driven, read-only, reuses the existing `.breadcrumb` top-bar styling, and requires **no schema change and no `<id>` in the model** (Main → `/`, Project → location-relative). Tasks 068 (DESIGN), 071 (IMPLEMENT), 073 (Playwright R5) extended in place. | /aid-detail |

> **Status: DEFERRED — scope unchanged.** Task drill-down (Level-3 forensic detail) is explicitly
> **excluded from the two-level refactor effort** and scheduled as its **own separate later
> delivery** (now **delivery-010**). Its existing A+ SPEC (below) is untouched. Its delivery-005 tasks
> (033/035/037, the drill-down half) carry forward to that later delivery; the KB half of the old
> delivery-005 (030–032/034/036) is superseded by feature-007's re-scope.

## Re-architecture Reconciliation (2026-06-12)

> _The A+ SPEC below was authored **before** the two-level re-architecture and assumes the delivered
> feature-003 base: a single **global** `/api/model`, feature-006's `index.html` + its hash router, and
> a `schema_version` **2→3** bump composing with feature-007's **1→2**. Three of those premises moved
> under the re-arch (feature-010 spine d008, feature-006 revision, feature-007 re-scope, feature-009
> schema floor). This note reconciles them; **the SPEC body is otherwise unchanged** (like the notes
> feature-006/007 carry). It is the authoritative reconciliation for **delivery-010** detailing —
> where the SPEC body and this note disagree, **this note wins.**_

**RC-1 — Routing: the drill rides the per-repo model, not a global one.** The SPEC's "extends
feature-006's route family" (`#/work/<id>/task/<task-id>` SEAM-2, DM-3, FC-1) is **correct in shape but
re-homed**. Post-re-arch (feature-006 R-1, d008 task-054): the per-repo app shell is **`home.html`**,
served by feature-010's multi-repo server at **`/r/<id>/home.html`**, and its client router + poll are
**location-relative** — it polls **`./api/model`** (which resolves to **`/r/<id>/api/model`** against
the served document), not a bare global `/api/model`. So:
- The `#/work/<work_id>/task/<task-id>` drill seam is a **deeper hash route in `home.html`'s router**
  (the same router that already owns `#/`, `#/work/<work_id>`); the per-repo `/r/<id>/` route prefix
  selects the repo + document, the hash selects the view within it — they compose (feature-006 R-1).
  The client never needs `<id>`; `/api/model` carries no `<id>` field (task-054 / task-065 pattern).
- The lazy forensic detail therefore arrives via **that repo's `/r/<id>/api/model`** — the drill view
  appends `?detail=<work_id>/<task_id>` to the **location-relative `./api/model`** poll (so the served
  request is `/r/<id>/api/model?detail=…`). The SPEC's DM-2/DM-3/FC-2 `?detail=` mechanism is
  unchanged; only the base URL is the per-repo relative form, not the global absolute one. There is no
  global `/api/model` to enrich and no second endpoint (DD-1 holds verbatim, now per-`<id>`).
- The server branch that reads `?detail=` (SPEC LC-SD) lives inside **feature-010's multi-repo server**
  (`server.{py,mjs}`, the d008 LC-MS rewrite), on the existing per-repo `/r/<id>/api/model` route — it
  adds **no new route/path/verb** to feature-010's closed allowlist (`/` + `/api/home` + per-`<id>`
  `/r/<id>/{home.html,kb.html,api/model}`), exactly as the SPEC's "no new endpoint" intent required of
  feature-003's old two-route allowlist. The construct-not-sanitize static-path discipline + the
  loopback-bind / no-write / no-LLM self-checks (d008 R9 / SEC-1..6) extend over the `?detail=` branch.

**RC-2 — Schema: the floor is `schema_version 3`, and d010 is NO-BUMP (stays at 3).** The SPEC's DM-2/
DD-2 "`schema_version` **2→3**, composing with feature-007's **1→2**" is **dead**: feature-009
(delivery-006, ac6d0f2) **already moved the floor to 3** (the per-task `short_name`/`delivery`/`lane`
fields), and feature-007's re-scope is **no-bump** (DM-A3 — it dropped the rich `KbModel`/`1→2` plan).
So there is no "1→2" to compose with, and "2→3" is no longer available — the floor when d010 builds is
**3**. The remaining question (PLAN **R14**) is whether the lazy `?detail=` wire genuinely changes the
**envelope shape** (→ a 3→4 cut) or is additive+omittable+lazy+tolerated (→ no-bump). **Decision:
NO-BUMP — d010 stays at `schema_version 3`.** Justification, applying the project's own reconciling
rule (DM-A3 / the `created` precedent ea40fe7 vs the feature-009 precedent ac6d0f2):
- The `details` map is **a new top-level envelope key that is PRESENT ONLY when `?detail=` is supplied —
  the key is OMITTED entirely otherwise** (SPEC DM-2: "absent (key omitted) when no param"). The
  always-polled pipeline/main/KB body is **byte-for-byte unchanged** (no `details` key at all).
- It is **consumer-tolerant**: a view that never sets `?detail=` never receives `details` and ignores
  it; an unknown/missing key degrades to the at-a-glance `TaskModel` view (the SPEC's "loading detail…"
  / FC-3 already handles `details[key]` absent). The drill view is the **only** consumer and ships
  **in lockstep** in the same delivery (the producing reader/server and the consuming front-end are one
  d010 cut) — exactly the co-revised-consumer condition DM-A3 names for the `created` shape.
- It is **not** a producer-format reconciliation and **not** a deliberate owned schema-revision act
  (the two conditions that made feature-009's bump correct). Nothing in the producer pipeline changes;
  no consumer is forced to re-interpret an existing field. This is **additive + omittable + already
  tolerated** — the **`created` shape, not the feature-009 shape → no bump** (DM-A3's reconciling rule).
- **Consequence for the SPEC body:** treat every "`schema_version 2→3`" / "composes with feature-007's
  1→2" / "front-end `EXPECTED` moves to 3" statement in DM-2 / DD-2 / the blast-radius table / "Known
  issues" as **superseded by this note** — the envelope **stays at 3**, the front-end `EXPECTED` stays
  **3**, and **no** stale-assets-banner churn occurs. What **does** still hold from DM-2: the `details`
  **key-order parity** rule (both runtimes emit `details` keys sorted ascending by `"work_id/task_id"`,
  byte-identical regardless of request order or runtime) and the **PT-1/PT-1-H fixture extension** with
  a findings/ledger/issues work + a `U+2028`/`U+2029` STATE.md — those are parity obligations, not a
  schema bump, and they are **retained** (PT-1-H grows; `schema_version` does not).
- _(Escape hatch, per R14: if detail-phase parity work finds a stricter gate that wants a bump anyway,
  it is a one-line lockstep change across both servers' envelope + the front-end `EXPECTED` + PT-1-H —
  but this note's position, grounded in the `created` precedent, is: **not required**.)_

**RC-3 — Dependency: d010 depends on d008 (the spine), NOT on d009.** feature-008 drills **within** a
per-repo `home.html`, reached through feature-010's `/r/<id>/...` routes; its lazy detail grows the
**per-`<id>` `/api/model`** surface that d008 (the spine) now serves, and the `#/work/<id>/task/<task-id>`
seam lives in the d008-renamed `home.html` (task-054). It consumes the **install-relocated reader**
(d008 task-046/047) — LC-TR is a sub-parser inside that reader. It does **not** depend on the KB tier
(d009): no KB state, no `kb.html`, no git-read. (Drill-down and the KB tier are independent after the
spine; the plan sequences d010 last by **user directive**, not by dependency — PLAN delivery-010
"Depends on".) Concretely, d010 task `Depends on:` edges reference **d008 task-050/051** (the LC-MS
servers, where LC-SD's `?detail=` branch lives), **d008 task-054** (the `home.html` the drill view +
SEAM-2 route live in), and the d008-relocated reader — **referenced, not duplicated.**

**RC-4 — NAV-1: a 4-level clickable breadcrumb (Main › Project › Pipeline › Task), router-driven, read-only, no schema/`<id>` change.** _(user-requested addition to d010, 2026-06-13.)_ The dashboard's
existing top bar already renders a breadcrumb-ish label (`home.html`: the `.brand` element
`<strong id="brand-name">…</strong> · Pipeline`, against the unused-but-present `.breadcrumb` CSS family
at `home.html:124–133` — `.breadcrumb` / `.sep` / `.current`, with the 768px / 390px responsive rules at
`:250` / `:259`). NAV-1 **extends that into the full clickable ancestor path** for the current route. It
**folds entirely into the SEAM-2 drill view task-071 already builds** — it is rendered/updated in the
**same `home.html` router** (the one that owns `#/`, `#/work/<id>` and the new `#/work/<id>/task/<id>`), in
the route-independent shell-head that already runs for every route (`home.html:1168–1176`, where
`brand-name` is set from `model.repo.project_name`). **No new `home.html`-writing task is created** (that
would race task-054's rename / task-071's body on the same file); NAV-1 is **one writer: task-071**.

**The 4-level navigation tree (the breadcrumb mirrors it exactly):**

| # | Level | Route / location | Breadcrumb label | Is it a link? | Nav target on click |
|---|-------|------------------|------------------|---------------|---------------------|
| 1 | **Main** | the CLI home, served at **`/`** (`dashboard/index.html`); lists projects | `AID` (the CLI-home brand) | **link** (ancestor) | **`/`** — an **absolute, same-origin** cross-page link to the CLI home. The model carries **no `<id>`**; the link is the literal `/`, never reconstructed from a repo id |
| 2 | **Project** | the per-repo dashboard, served at **`/r/<id>/home.html`** (list view, **no hash**); pipelines + KB card | `model.repo.project_name` | **link** (ancestor) | **`location.pathname`** — i.e. **the current page with the hash cleared** (back to the list view). It is the page you are already on, so **no `<id>` is needed** — `location.pathname` already resolves to `/r/<id>/home.html` |
| 3 | **Pipeline** | the per-work drill view, **`/r/<id>/home.html#/work/<work_id>`** (the existing hash-router view: phase pills + delivery list) | the work / pipeline name (`work.short_name` / `work.work_id`, already in `/api/model`) | **link** (ancestor) | **`#/work/<work_id>`** — an in-page **hash route** (the existing `#/work/<id>` the router already owns) |
| 4 | **Task** | the **NEW** d010 task drill view, **`/r/<id>/home.html#/work/<work_id>/task/<task-id>`** (SEAM-2, built by task-071) | the task id / title (`task.task_id` / `task.short_name`, already in `/api/model`) | **NOT a link — leaf** | — (current level) |

**Breadcrumb behavior (NAV-1):**

- **Ancestors link, leaf does not.** The breadcrumb renders the ancestor path for the **current** route;
  **every ancestor is a link, the current (leaf) level is plain `.current` text** (reusing the existing
  `.breadcrumb .current` style at `home.html:133`). Per route:
  - **main view** (`#/` or no hash) → `AID` only (Main is the page; Main is `.current`, no further levels).
  - **work view** (`#/work/<id>`) → `AID › <project> › <pipeline-current>` (Main + Project are links;
    Pipeline is the leaf).
  - **task view** (`#/work/<id>/task/<id>`, SEAM-2) → `AID › <project> › <pipeline> › <task-current>`
    (Main + Project + Pipeline are links; Task is the leaf).
- **Router-driven (the core requirement).** The breadcrumb is **recomputed on every render** from the
  parsed route + the polled `/api/model` body — it updates as the hash changes
  (list → `#/work/<id>` → `#/work/<id>/task/<id>` and back) so the operator can **climb the tree without
  the browser Back button** and the path always stays correct. It rides the existing `onHashChange`
  re-render (`home.html:1144–1149`) and the shell-head that runs for every route; **no new listener, no
  new poll, no new render entry-point.**
- **Nav targets (exact, no `<id>` carried in the model):** Main → **`/`** (absolute, same origin);
  Project → **`location.pathname`** (current page, hash cleared — the list view, no `<id>` reconstructed);
  Pipeline → **`#/work/<work_id>`** (hash route); Task = **leaf** (no link). The Project and Pipeline
  targets are **location-relative / hash-only** (consistent with RC-1: the client never needs `<id>`,
  `/api/model` carries no `<id>` field — task-054 / task-065 pattern); Main is the one **absolute** link,
  and it is the constant `/`, not derived from any id.
- **Read-only, no model/schema change (consistent with RC-2).** Every label comes from data **already in**
  `/api/model` — the project name (`model.repo.project_name`, already set at `home.html:1170`), the work
  name, the task id. **No new field, no `<id>` field, no `details`-key dependency** (the breadcrumb labels
  come from the always-polled lean body, not from the lazy `?detail=` map — so the path renders correctly
  on the very first tick of a drill, before `details[key]` arrives). **NO schema bump** — `schema_version`
  stays **3**, `EXPECTED` stays **3** (RC-2 holds; NAV-1 reads nothing new off the wire). It is read-only:
  it only sets `location.href` / `location.hash`, never writes `.aid/`, never fetches `.aid/` directly.
- **Visual reuse (NFR8).** NAV-1 **reuses the existing `.breadcrumb` top-bar family** (`home.html:124–133`)
  rather than inventing a component: ancestor links inherit the `.breadcrumb` color/size, separators use
  the existing `.breadcrumb .sep` (a `›`/`·`-style glyph, consistent across all levels), and the leaf uses
  `.breadcrumb .current`. The existing **768px** truncation/responsive behavior (`home.html:250`,
  ellipsis/`overflow:hidden`) and the **390px** `display:none` collapse (`home.html:259`) apply unchanged —
  the breadcrumb truncates gracefully on narrow viewports exactly as the current label does. The hardcoded
  `· Pipeline` suffix in the current `.brand` markup (`home.html:752`) is **replaced** by the router-driven
  path (the brand root `AID` stays; the `· Pipeline`/`· this machine`-style static suffix becomes the
  dynamic ancestor trail).
- **The CLI home (`/`, `index.html`) is Main (level 1) — needs no breadcrumb-back; likely NO change.** It
  **is** Main, so it has no ancestor to climb to; its existing `AID · this machine` brand
  (`index.html:475`) already serves as the level-1 root, and its project cards already link to
  `/r/<id>/home.html` (`index.html:807`) — i.e. it is already the `/` landing the Project pages' Main link
  targets. **No change to `index.html` is required by NAV-1** (it is the root of the tree, not a descendant
  of it). The only contract `index.html` must keep satisfying — which it already does — is being served at
  `/` (so the absolute Main link lands correctly).
- **Single writer / no new task.** Because the breadcrumb is rendered in `home.html`'s router and reuses
  the existing `.breadcrumb` styling, **all** of NAV-1 lands inside the existing d010 task set: **task-068**
  (DESIGN — specify the breadcrumb in the drill-view UI breakdown), **task-071** (IMPLEMENT — the single
  `home.html` drill-view writer adds the router-driven breadcrumb), **task-073** (Playwright R5 — visually
  validate the breadcrumb at each level + that each ancestor link navigates correctly). No new
  `home.html`-writing task is introduced, avoiding a same-file race with task-054 / task-071.

## Source

- REQUIREMENTS.md §5 FR13 (full drill-down — findings, ledger, raw STATE.md, logs)
- REQUIREMENTS.md §5 FR14 (parallel-execution detail)
- REQUIREMENTS.md §5 FR6 (maximal tracking detail)
- REQUIREMENTS.md §6 NFR2 (read-only)

## Description

The deepest drill tier. From a skill/task in the pipeline view, the operator can open **all** of its
detail: **findings**, the **review ledger / grades**, the **raw `STATE.md` content**, and **logs**.
Accommodates **parallel/concurrent tasks** so each simultaneously-active task's detail is reachable.
Read-only. This is the forensic depth beyond the at-a-glance progress view (feature-003).

## User Stories

- As an **operator diagnosing a run**, I want to drill into a task to see its findings, grades, raw
  state, and logs, so I can understand exactly what happened.
- As an **operator**, I want to inspect each of several parallel tasks individually, so concurrency
  doesn't hide detail.

## Priority

Should.

## Acceptance Criteria

- [ ] Given a skill/task, when I drill in, then I can view its findings, review ledger/grades, raw
      `STATE.md` content, and logs (FR13) — read-only (NFR2).
- [ ] Given parallel tasks, when I drill in, then each concurrent task's detail is individually
      reachable (FR14).

---

## Technical Specification

> Activated sections (per `canonical/templates/specs/spec-template.md`): **Data Model** (the per-task
> forensic sub-model this tier needs — `findings` from `## Quick Check Findings`, `ledger`/`grade` from
> `## Delivery Gates` + `delivery-NNN-issues.md`, the **raw STATE.md text** displayed read-only, and an
> honest `logs` model; the decision to serve this detail **lazily** via the existing `/api/model`
> envelope rather than enriching every poll, with the `schema_version` 2→3 bump + parity impact it
> entails, composing with feature-007's 1→2 bump), **Feature Flow** (drill from a task in the pipeline
> view → render detail from the already-polled model; how N parallel tasks each drill independently
> FR14; refresh on the shared loop), **Layers & Components** (the feature-002 reader extension that
> populates the forensic fields, the drill-down view, the read-only boundary, design-family reuse).
> Conditional: **UI Specs** (REQUIRED by FR13/FR14/FR6/FR18/NFR6/NFR8 — the drill-down panel: the
> severity-tagged findings list, the review-ledger/grade table, the **monospace escaped read-only raw
> STATE.md viewer**, the logs viewer, per-parallel-task drill, responsive, knowledge-summary visual
> family, and the FR18 step-by-step guidance when logs/forensics are unavailable). **Skipped:** Data-DB
> (no database — `schemas.md`), Migration (net-new front-end + additive reader fields; no on-disk
> change — this DISPLAYS state, writes nothing, NFR2), API Contracts → external (the only API is
> feature-003's internal `/api/model`; the lazy-detail decision is specified under Data Model, and the
> rejection of a second endpoint is justified there against feature-003's closed two-route allowlist),
> CLI (feature-004), Security / remote exposure (feature-005), State Machines (no lifecycle derivation
> here — feature-002 owns FR16; this tier renders already-derived state and literal forensic text).

This is the **deepest drill tier (Level-3 forensic detail)**. From any task chip in feature-003's
pipeline view, the operator opens **all** of that task's detail — its **findings**, its **review
ledger / grade**, the **raw `STATE.md` text**, and its **logs** — read-only (NFR2). It accommodates
**parallel/concurrent tasks** (FR14): each simultaneously-active task drills independently. Like
feature-006 and feature-007 it is **front-end + a read-only reader extension**: it reaches its content
through a hash route off feature-003's router (a `#/work/<id>/task/<task-id>` seam this feature
defines, extending feature-006's route family) and renders from the **same `/api/model` body the
shared feature-003 loop already polls** (feature-003 DM-1). At runtime it is deterministic client-side
code — **no agent/LLM** (NFR7) — and it **writes nothing to `.aid/`** (NFR2): the raw STATE.md is
*displayed*, never edited.

**The two real seam decisions (DD-1, DD-2 below).** (1) The forensic detail (findings, ledger, raw
STATE.md text) is **lazy** — it is the bulk of a per-poll payload if added to every `TaskModel`, so
NFR4 (low overhead) is honored by serving it **only on drill** through the existing `/api/model`
envelope, not by enriching the always-polled model. (2) Because the wire shape grows when detail is
present, this requires a **`schema_version` 2→3 bump** (composing with feature-007's 1→2 bump,
DD-2) and a corresponding **parity-fixture extension** (feature-003 PT-1). The alternative — a separate
per-task detail endpoint or a client-side `.aid/` read — is **rejected** (DD-1): it would put `.aid/`
reads outside feature-002's audited read-only/no-LLM reader, add a second server surface feature-003's
bind/no-write/no-LLM self-checks do not cover, and break the single-poll-loop model that feature-006
and feature-007 also share.

---

### Data Model

No relational schema (AID ships no database — `schemas.md`). This tier's data model is a **per-task
forensic sub-model** (`TaskDetail`) the **feature-002 reader** computes from sources that already live
in the work folder, plus the **raw `STATE.md` text** the work was already read from. All fields are
**read-derived**; nothing is persisted (NFR2). Every source below was verified on disk 2026-06-10.

#### DM-1. `TaskDetail` — the per-task forensic sub-model

`TaskDetail` is the forensic expansion of one `TaskModel` (feature-002 DM-5). It is keyed by the same
`task_id` and surfaced **lazily** (DD-1) — `model.works[].tasks[]` keep their existing
`TaskModel` fields for the at-a-glance view (feature-003 UI-3); the heavy forensic fields appear only
when a task is **drilled** (`detail_loaded` true). Shape:

```
TaskDetail  (the drilled expansion of a TaskModel, keyed by task_id)
├─ task_id:       string                 # == TaskModel.task_id (feature-002 DM-5)
├─ findings:      list<Finding>          # from work STATE.md ## Quick Check Findings ### task-NNN
├─ ledger:        TaskLedger             # from ## Delivery Gates + delivery-NNN-issues.md (the task's delivery)
├─ raw_state:     RawStateRef            # the literal STATE.md text + the byte span of this work's file
└─ logs:          LogAvailability        # HONEST: what logs exist for this task (see DM-4 — usually "none")
```

**`Finding`** — one bullet under `STATE.md ## Quick Check Findings → ### task-NNN → **Findings:**`
(verified shape 2026-06-10; the per-task block is written by `writeback-state.sh --findings` per
`state-review.md`, schema `coding-standards.md`-style severity tag + em-dash fields):

| Field | Type | Source (the `### task-NNN` block) | Notes |
|-------|------|-----------------------------------|-------|
| `severity` | enum `[CRITICAL] \| [HIGH]` | the leading bracketed tag of the bullet | this block records **only** `[CRITICAL]`/`[HIGH]` (the template note: "all [HIGH]/[CRITICAL] findings for that task"); a lower/unknown tag → `[MINOR]` neutral, never throws (NFR7, mirrors feature-002 DM-6) |
| `description` | string | the bullet text up to the first ` — ` | rendered verbatim |
| `location` | string \| null | the `{source-file:line}` segment | `null` if the bullet omits it |
| `disposition` | string \| null | the trailing `Fixed-on-spot` / `Deferred-to-gate` token | the template's two literals; any other trailing text surfaced verbatim |
| `reviewer_tier` | string | the block's `**Reviewer Tier:**` line | always `Small` for a quick check (template note); block-level, copied onto the block |

**`TaskLedger`** — the task's **grade context**, assembled from two real sources because **no grade is
recorded per task** (the `## Quick Check Findings` template note is explicit: "No grade is recorded
here — grading is per-delivery"). The grade lives at the **delivery** level, so the ledger joins the
task to its delivery:

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `delivery_id` | string \| null | the `## Tasks Status` row's delivery association (the task's `Notes`/wave → delivery; or the single delivery on the lite path) | `null` if the task is not yet associated to a delivery (pre-gate) — then `grade` is `null` and the panel says "not yet graded" |
| `grade` | string \| null | `## Delivery Gates → ### delivery-NNN → **Grade:**` | the **per-delivery** grade (e.g. `A+`), or `Pending`; rendered verbatim, never re-graded (NFR7) |
| `reviewer_tier` | string \| null | `### delivery-NNN → **Reviewer Tier:**` | `Small \| Medium \| Large` |
| `gate_timestamp` | string \| null | `### delivery-NNN → **Timestamp:**` | when the gate ran |
| `deferred_issues` | list<DeferredIssue> | `.aid/{work}/delivery-NNN-issues.md ## Deferred [HIGH] Issues` rows (`schemas.md §12`, 4-col `Source task \| Severity \| Description \| Status`) — **filtered to `Source task == this task_id`** | the task's own deferred-`[HIGH]` rows; empty list if the file is absent (no gate run yet) |

**`DeferredIssue`** — one row of `delivery-NNN-issues.md` (4 columns, verified `schemas.md §12` +
`canonical/templates/delivery-issues.md`):

| Field | Type | Source column | Notes |
|-------|------|---------------|-------|
| `source_task` | string | `Source task` | == `task_id` (the filter key) |
| `severity` | string | `Severity` | always `[HIGH]` in this file (`[CRITICAL]` is fixed-on-spot, never deferred — template note) |
| `description` | string | `Description` | one-line; verbatim |
| `status` | enum `Open \| Resolved \| Accepted` | `Status` | the row lifecycle (`schemas.md §12`); unknown literal → neutral chip, never throws |

> **Why ledger is a join, not a column (grounding).** The dashboard cannot show a "task grade" because
> AID does not produce one — grades are **per-delivery** (`## Delivery Gates`), and per-task forensics
> are the `## Quick Check Findings` block (no grade) + the task's deferred-`[HIGH]` rows in
> `delivery-NNN-issues.md`. The honest forensic story for a task is therefore: *its findings* (quick
> check), *its deferred issues* (rows where `Source task == task_id`), and *the grade of the delivery it
> belongs to*. The panel labels this exactly so (UI-2), never implying a task was independently graded.

**`RawStateRef`** — the **literal `STATE.md` text** of the task's work, displayed read-only (FR13 "raw
STATE.md content"; NFR2 "displayed, never edited"):

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `text` | string | the **verbatim bytes** of `.aid/{work}/STATE.md` the reader already read (feature-002 Feature Flow step 5a reads it once into memory) | the **whole** work STATE.md, shown as-is — the operator's escape hatch to see exactly what the pipeline wrote |
| `byte_len` | int | length of `text` | corroborates NFR4 payload budget; lets the front-end warn before rendering a very large file |
| `path` | string | `.aid/{work}/STATE.md` (relative) | shown as a caption ("source: …"); **read-only label**, not a link to edit |

> **Raw STATE.md is the work's, scoped per task by anchor (DD-3).** AID keeps **one `STATE.md` per
> work**, not per task (`work-state-template.md:9` — "Absorbs … per-task `task-NNN-STATE.md`"). There is
> no per-task STATE file to show. So FR13's "raw STATE.md content" for a task is the **work** STATE.md,
> and the viewer **deep-anchors** to that task's `### task-NNN` block under `## Quick Check Findings` and
> its `## Tasks Status` row (UI-3) so the operator lands on the relevant text without losing the
> whole-file escape hatch. The reader does **not** re-read the file for the drill — it reuses the bytes
> feature-002 already read for the work this pass (NFR4: zero extra disk I/O for `raw_state`).

**`LogAvailability`** — an **honest** model of what logs exist (see DM-4 for the on-disk reality):

| Field | Type | Source | Notes |
|-------|------|--------|-------|
| `task_logs` | enum `none` (always, today) | — | **AID persists no per-task / per-agent execution log** (DM-4). This is `none` for every task; the field exists so a future per-task log capability can populate it without a wire change beyond a value |
| `server_log_present` | bool | stat `.aid/.temp/dashboard.log` (feature-004 DM-1 `logfile`) | the **only** log on disk is the **dashboard server's own** stdout/stderr — a tool-operational log, **not** a pipeline/task log; surfaced as a repo-level diagnostic, clearly labeled "not a task log" (UI-4) |
| `heartbeat_present` | bool | stat `.aid/.heartbeat/` (feature-002 Telemetry; KI-004) | a **liveness** signal, **not** a log; repo-level + corroborating-only (KI-004), so it is shown as advisory "last seen", never as task output |

#### DM-2. Lazy delivery via `/api/model` + `schema_version` 2 → 3 (DD-1, DD-2)  **[SUPERSEDED by RC-2 — NO bump; d010 stays at `schema_version 3`]**

`TaskDetail` is **not** added to every `TaskModel` on every poll — that would multiply the payload by
the raw STATE.md bytes × every task on every 5s tick, violating NFR4. Instead, the **shared poll
carries detail only for the currently-drilled task(s)**, driven by a single query parameter the
front-end appends when a drill route is active:

```jsonc
GET /api/model                         // pipeline/main/KB views — TaskModel only, no TaskDetail (unchanged)
GET /api/model?detail=<work_id>/<task_id>[,<work_id>/<task_id>...]   // drill view — server attaches TaskDetail for those tasks (FR14: comma-list of composite keys)
```

This is **not a new endpoint** — it is the **same `/api/model` route** with an **optional, additive
query parameter** the server's existing handler reads; feature-003's closed two-route allowlist
(`/` + `/api/model`, feature-003 LC-S) is **unchanged** (no new path, no new verb — still GET-only,
still read-only). The response envelope grows a `details` map only when the parameter is present:

```jsonc
{
  "schema_version": 3,                  // stays 3 — NO bump (RC-2 supersedes the old "2->3"; details map is conditionally-present, base envelope byte-unchanged)
  "generated_by": "python",             // diagnostic only; excluded from PT-1 parity (feature-003 DM-1)
  "model": { /* serialized RepoModel — unchanged, TaskModel only */ },
  "details": {                          // PRESENT ONLY when ?detail=... is supplied; absent (key omitted) otherwise
    "work-001-x/task-003": { /* TaskDetail — DM-1 */ }   // keyed "work_id/task_id" (FR14: one entry per requested task)
    // KEY ORDER (parity, on top of feature-003 DM-3): both runtimes MUST emit `details` keys
    // sorted ascending by the "work_id/task_id" string, so the response is byte-identical regardless
    // of the request comma-list order or runtime — enforced by PT-1.
  }
}
```

Blast radius and why it is contained:

| Impact | Effect | Mitigation |
|--------|--------|------------|
| `schema_version` | `2` → `3` in feature-003's DM-1 envelope, both runtimes | one constant per server + the front-end's `EXPECTED`; feature-003's stale-assets banner already fails loud on mismatch (feature-003 Feature Flow 3b). **Composes with feature-007**: feature-007 bumps 1→2 for the rich `KbModel`; this feature bumps 2→3 for the `details` map. Whichever ships second consumes the prior number — they are sequential, not conflicting (DD-2) |
| feature-003 front-end | bumps `EXPECTED` to `3`; the pipeline/main/KB views **ignore** `details` entirely (additive, optional key) | a view that never sets `?detail=` never receives the key — zero behavior change for feature-003/006/007 |
| feature-002 reader | LC-R grows a **detail sub-parser** (LC-TR below) that runs **only when a `task_id` is requested** — it parses the findings/ledger blocks and returns the raw STATE.md bytes it already read | stays inside the audited read-only/no-LLM reader (NFR2/NFR7 self-checks unchanged in kind); the always-on read path is **untouched** (NFR4) |
| parity (PT-1) | the byte-identical-across-runtimes guarantee now covers `details` | **extend PT-1's fixture** with a work that has a `## Quick Check Findings` block, a `## Delivery Gates` block, a `delivery-NNN-issues.md`, and a STATE.md containing `U+2028`/`U+2029` (feature-003 DM-3 escaping) — and assert both runtimes emit byte-identical `details` for a `?detail=` request (DD-2) |

> **Why a query param, not the always-polled model, and not a second endpoint (DD-1).** Three options
> were weighed. (a) **Enrich every `TaskModel` with `TaskDetail` on every poll** — rejected: the raw
> STATE.md text alone can be tens of KB, multiplied by every task on every 5s tick — a direct NFR4
> violation, sending forensic bytes nobody is looking at. (b) **A new `/api/task/<id>` endpoint** —
> rejected: it adds a second dynamic server route, expanding the surface feature-003's bind/no-write/no
> -LLM self-checks must cover (feature-003 LC-S is a closed two-route allowlist; feature-006 DD-1
> deliberately kept it closed for the same reason), and moves the read off the shared single-poll loop.
> (c) **The chosen option:** the **same `/api/model` route with an additive `?detail=` query param** —
> the server's existing handler branches on the param, calls feature-002's detail sub-parser only for
> the requested `task_id`(s), and attaches `details`. It keeps **one route, one poll loop, one reader,
> read-only, GET-only** — every feature-003 invariant intact — and serves the heavy bytes **only when
> drilled**. This is the minimal contract evolution consistent with feature-006/007.

#### DM-3. The only client-side state

This tier introduces **no new persisted client state**. The drill route lives in feature-006's
`ViewState.route` family (feature-006 DM-2), extended with a `task_id`:

```
route: { view: "main" | "pipeline" | "kb" | "task", work_id?: string, task_id?: string }
```

When `view == "task"`, the front-end's poll appends `?detail=<work_id>/<task_id>` (FR14: the comma-list
of all currently-open task drills, each a `work_id/task_id` composite — the `#/work/<id>/task/<task-id>`
route carries both halves, so the front-end always has the `work_id` to disambiguate a non-unique
`task-NNN` across parallel works) so the shared loop carries that task's `TaskDetail`. View-state that
survives reload (theme, interval) is feature-003's `localStorage`, reused as-is. Nothing is written to
`.aid/` (NFR2).

#### DM-4. HONEST log inventory — what logs actually exist (FR13 "logs")

FR13 lists "logs" among the drill-down detail. An honest on-disk audit (2026-06-10) is required so the
UI does not promise logs that do not exist:

| Candidate "log" | Exists on disk? | What it actually is | How this tier treats it |
|-----------------|-----------------|---------------------|--------------------------|
| **Per-task / per-agent execution log** | **NO** — verified: no `*.log` anywhere under `.aid/`; the work folder holds only `STATE.md`, `REQUIREMENTS.md`, `known-issues.md`. AID **does not capture** sub-agent stdout/transcripts to a persisted file | — | `LogAvailability.task_logs = none` always; the log panel shows the FR18 "no task logs are captured" guidance (UI-4) rather than a fake empty viewer |
| **Dashboard server log** | Conditionally + **platform-dependent** — `.aid/.temp/dashboard.log`, the dashboard **server child's** stdout/stderr (feature-004 DM-1 `logfile`; created by `aid dashboard start`, removed by `stop`). **Linux/macOS only** (Bash `setsid ... >"$log" 2>&1`); **on Windows the log is NOT captured** — the PS launcher spawns the server detached via ShellExecute (no `-Redirect*`, to avoid the handle-inheritance hang), so no `dashboard.log` is written (see known-issues.md). | a **tool-operational** log (server boot/errors), **not** a pipeline or task log | surfaced as a repo-level "dashboard server log" diagnostic, **explicitly labeled "not a task log"** (UI-4); `server_log_present` reflects the stat and is **expected-false on Windows** — show the "log not captured on this platform" state, not a fake-empty viewer |
| **Sub-agent heartbeat** | Conditionally — `.aid/.heartbeat/<agent>-<unix-ts>.txt` (verified absent now; normal) | a **liveness** signal (single pipe-delimited line), repo-level + corroborating-only (KI-004), **not** a log | shown as advisory "last seen" only; never presented as task output (KI-004) |
| **Reviewer ledger** | Transient — `.aid/.temp/review-pending/<scope>.md` (7-col table, `reviewer-ledger-schema.md`) | the **in-flight** review ledger, **deleted at skill DONE** (`reviewer-ledger-schema.md` "deleted at skill DONE") | **NOT** a forensic source for a completed task — it is gone by the time the operator drills a finished task. The **persistent** forensics are `## Quick Check Findings` + `## Delivery Gates` + `delivery-NNN-issues.md` (DM-1). The ledger is mentioned only to explain why it is *not* the drill source |

> **The honest "logs" answer (DD-4).** AID has **no per-task execution log today**. FR13's "logs" is
> therefore satisfied by (a) clearly stating no task logs are captured + FR18 guidance on how to get
> diagnostic output (UI-4), and (b) surfacing the *only* real log — the **dashboard server's own**
> `.aid/.temp/dashboard.log` — as a clearly-labeled tool diagnostic, never mislabeled as task output.
> Inventing a log viewer over files that do not exist would be a fabricated guarantee (the
> ask-user-over-auto-proof discipline: annotate what we cannot prove, never fake it). Registered as
> **KI-008**.

---

### Feature Flow

This tier adds **no new server round-trip** beyond the shared poll: drilling a task sets the hash
route, and the **same `/api/model` poll** now carries `?detail=<work_id>/<task_id>` so the next tick's
body includes that task's `TaskDetail`. The only net-new *read* work is in feature-002's detail
sub-parser (LC-TR), which runs **only** when a composite `work_id/task_id` is requested.

```
SERVER (feature-002 reader, per poll — read-only, no-LLM, UNCHANGED posture)
  read_repo(aid_root [, detail_task_ids]):
    ... LEVEL-0..2 + tasks (feature-002 Feature Flow) -> RepoModel (TaskModel only) ...
    DETAIL-EXTEND (net-new, ONLY when detail_task_ids non-empty — LC-TR):
      for each requested "work_id/task_id":
        DR-1  locate the work; reuse its ALREADY-READ STATE.md bytes (no re-read)        -> raw_state (DM-1)
        DR-2  parse ## Quick Check Findings ### task-NNN  -> findings[]                    (Finding, DM-1)
        DR-3  resolve the task's delivery; parse ## Delivery Gates ### delivery-NNN        -> ledger grade/tier/ts
        DR-4  read .aid/{work}/delivery-NNN-issues.md; filter rows Source task == task_id  -> ledger.deferred_issues
        DR-5  stat .aid/.temp/dashboard.log + .aid/.heartbeat/                             -> logs (LogAvailability, DM-4)
        assemble TaskDetail; attach under details["work_id/task_id"]
    ... serialize (feature-003 DM-1/DM-3), schema_version = 3 ...

  GET /api/model              -> details key OMITTED       (pipeline/main/KB views; unchanged, NFR4)
  GET /api/model?detail=ids   -> details map present       (drill view; the heavy bytes ride here)

CLIENT (feature-006 router + shared poll loop — plumbing extended, not replaced)
  FC-1  hash "#/work/<id>/task/<task-id>" -> feature-006 router dispatches render to THIS view (SEAM-2, below)
  FC-2  on entering a task route: add the composite "<work_id>/<task_id>" (both halves from the hash route) to the live ?detail= set; poll re-issues with it
  FC-3  render(model, route, details):
          details[key] absent (first tick after drill) -> show TaskModel at-a-glance + a "loading detail…" affordance
          details[key] present -> render findings + ledger + raw STATE.md viewer + logs panel (UI-1..UI-5)
  FC-4  every poll tick re-renders the CURRENT route -> the drill view refreshes live (FR4/NFR3): a
          new finding written mid-run appears within one interval, off the SAME loop
  FC-5  PARALLEL DRILL (FR14): N task routes can be open (tabs/expansions); the ?detail= set carries
          all open "<work_id>/<task_id>" composite keys (comma-list); each renders its own independent TaskDetail
  NAV   "back" -> location.hash = "#/work/<id>" (the pipeline view) -> drop that "<work_id>/<task_id>" key from ?detail= (drill is reversible)
```

- **Detail rides the shared loop, no new endpoint (NFR4, DD-1).** When the operator is on a task
  route, each tick's `fetch('/api/model?detail=…')` carries the drilled task(s)' `TaskDetail`; when
  they leave, the param drops and the payload shrinks back to the lean `TaskModel`-only body. There is
  **no task-specific fetch, no second endpoint, no extra disk traffic** beyond the detail sub-parser's
  reads — and `raw_state` reuses bytes already read this pass (DR-1).
- **Parallel tasks each drill independently (FR14).** Concurrency is first-class: `model.works[].tasks[]`
  already carries every concurrent task's own `status`/`wave` (feature-002 DM-5), and `?detail=` is a
  **comma-list** so several open drills each get their own `details[key]` entry. The view never collapses
  parallel tasks into one — N drilled tasks render N independent forensic panels (UI-5).
- **Live forensics (FR4/NFR3).** Because the detail sub-parser re-parses the findings/ledger and re-reads
  the STATE.md bytes each pass, a `[HIGH]` finding written by the reviewer mid-run, or a delivery grade
  posted at the gate, appears in the open drill within one interval — the same ≤-interval lag
  feature-003 NFR3 holds for pipeline state.
- **First-tick "loading" (not a blank).** The tick that *enters* a drill may precede the first
  `?detail=`-bearing response by one round-trip; the view shows the task's at-a-glance `TaskModel` plus
  a "loading detail…" affordance, then fills in on the next tick — never blanks (mirrors feature-003
  "never goes blank on a transient miss").
- **Read-only / no-LLM / displayed-never-edited (NFR2/NFR7).** Every forensic field comes from the
  feature-002 reader's read/stat path (LC-TR adds only reads of files already in the work folder + a
  reuse of the STATE.md bytes already read). The **raw STATE.md is rendered into a read-only viewer**
  (escaped text, no editable control, no write affordance — UI-3); the client only renders. There is
  **no write to `.aid/`** and **no agent/LLM** anywhere.
- **Torn-read tolerance (inherited).** A mid-write STATE.md / issues file yields `parse_warnings` +
  best-effort fields on that one poll; the next poll self-corrects (feature-002 Feature Flow). The drill
  view surfaces `parse_warnings` via feature-003 Telemetry's existing "data note" affordance.

---

### Layers & Components

All additions are **front-end (one new view) + one reader sub-component** in feature-002's reader, plus
the server-handler branch that reads `?detail=`. No new server route, no new endpoint, no CLI
(feature-004), no remote (feature-005). Per `coding-standards.md` (small, single-purpose, deterministic,
no hidden I/O) and `module-map.md` (the reader is feature-002's module; the front-end is feature-003's;
the server handler is feature-003's — this extends all three additively).

| Component | Half | Responsibility | MUST NOT |
|-----------|------|----------------|----------|
| **LC-TR Detail sub-parser** | server (feature-002 reader) | populate `TaskDetail` (DM-1) **only for requested `task_id`s**: parse `## Quick Check Findings ### task-NNN` → `findings[]`; resolve delivery + parse `## Delivery Gates ### delivery-NNN` + `delivery-NNN-issues.md` filtered to the task → `ledger`; return the already-read STATE.md bytes → `raw_state`; stat the log/heartbeat paths → `logs` | write/append/lock any file; re-read STATE.md when the work's bytes are already in memory; run on the always-on path (only on `?detail=`); call any agent/LLM to "grade"/"summarize" a task; throw on a missing block (null-fill + `parse_warning`) |
| **LC-SD Server detail branch** | server (feature-003 LC-S, ×2 runtimes) | parse `?detail=` from the `/api/model` query; pass the `task_id` list to the reader; attach `details` to the envelope; serialize deterministically (feature-003 DM-3) | add a new route/path/verb (stays the same GET `/api/model`); bind non-loopback; expose any write; diverge from the other runtime (held by PT-1) |
| **LC-DV Drill view** | front-end | render `TaskDetail` as the forensic panel: findings list, ledger/grade table, raw STATE.md viewer, logs panel, FR18 guidance; manage the `?detail=` set on enter/leave | fetch `.aid/` files directly; add a network call beyond the shared `fetch('/api/model?detail=…)`; re-derive grades/findings (renders reader output literally); render the raw STATE.md in an editable control |
| **LC-RV Raw-state viewer** | front-end | render `raw_state.text` in a **monospace, escaped, read-only** block, deep-anchored to the task's `### task-NNN` block (UI-3) | un-escape / execute / allow edit of the text; rewrite or re-flow it (shown verbatim) |

- **Dependency direction.** LC-DV/LC-RV depend only on (a) the `/api/model` envelope's `details` map
  (DM-2) and (b) feature-003's design-family CSS (feature-003 LC-A) + feature-006's router (the
  `#/work/<id>/task/<task-id>` seam, SEAM-2). LC-TR depends only on feature-002's reader internals + the
  work-folder files. LC-SD is a branch inside feature-003's existing handler. Nothing here depends on
  feature-004/005.
- **Read-only / no-LLM, inherited structurally.** LC-TR sits **inside** feature-002's reader, whose
  read-only boundary is already a self-check test ("the reader module contains no write primitive" —
  feature-002 LC-R); adding more *reads* (work-folder files already in scope) does not introduce a write
  surface, so that test continues to hold and now also covers LC-TR. LC-SD adds **no new route** to
  feature-003's closed allowlist, so feature-003's bind-`127.0.0.1` / no-write / no-LLM self-checks
  (feature-003 LC-S) are unchanged in kind. No agent/LLM anywhere (NFR7): findings/ledger/raw text are
  deterministic string parses + verbatim passthrough, not inference.
- **The feature-006 router seam, extended (SEAM-2).** feature-006's router (feature-006 FC-1) recognizes
  `#/`, `#/work/<id>`, `#/kb`. This feature **defines and consumes** the deeper
  `#/work/<id>/task/<task-id>` route in that same hash-router family (no `pushState`, no server route —
  feature-006 DD-1's rationale holds: the server is a closed two-route allowlist, so a path router would
  404 on reload). It is reached **from** a task chip in the pipeline view (feature-003 UI-3): the chip's
  click sets `location.hash = "#/work/<id>/task/<task-id>"`. This keeps the drill **reversible** (back →
  the pipeline view) and bookmarkable, with feature-003's invariants untouched.

---

### UI Specs

The Level-3 forensic drill-down, built on the `knowledge-summary/` design family (NFR8) and the
feature-003 app shell (top bar, theme toggle, footer, freshness badge) reused via feature-006. FR8
visual-first for the **signals** (severity color+shape, grade chip); but FR6/FR13 demand **maximal
detail**, so this tier deliberately shows **more text** than the at-a-glance views — the raw STATE.md
viewer is intentionally verbose. Per the global CLAUDE.md web-review gate, the reviewer MUST render this
page in Playwright (not inspect source) and visually validate the findings list (across severities),
the ledger/grade table, the **read-only escaped raw STATE.md viewer**, the logs panel + FR18 guidance,
the drill arrival from a task chip, the parallel-drill case (FR14), the back nav, and the responsive
breakpoints. A source-only review of this web page is an automatic fail.

#### UI-1. Design-family reuse (NFR8) + panel layout

Reuses the **same** assets feature-006/007 enumerate from `canonical/templates/knowledge-summary/`:
`.card` (+ hover), `.kicker`/`h3`/`.stat`/`.meta`, `.grid.g2/.g3`, the full `.badge-*` family
(`.badge-err/-warn/-ok/-info/-dim`), the `design-tokens.md` palette (light + dark), and feature-003's
app shell. The drill view swaps only the `<main>` body; header/footer/theme/freshness are feature-003's,
shared. System fonts, CSS custom properties, no web fonts, no CDN at runtime (NFR8) — same family as
`knowledge-summary.html`. Layout (an **expandable panel** reachable as its own route, so it works as a
full page on mobile and an in-place expansion on desktop):

```
┌─ .top-bar (feature-003 shell, via feature-006) ─ brand · ◄ back to pipeline · freshness · theme ─┐
├─ <main> ─────────────────────────────────────────────────────────────────────────────────────────┤
│  TASK · <task_id>   [status badge]  ·  <type> · wave <wave> · <elapsed>   (the TaskModel header)   │
│  .grid.g2  ┌─ FINDINGS (UI-2) ───────────────┐ ┌─ REVIEW LEDGER / GRADE (UI-2) ─┐                  │
│            │ [CRITICAL]/[HIGH] severity list │ │ delivery grade chip + tier + ts │                  │
│            │ desc · file:line · disposition  │ │ deferred-[HIGH] issues table    │                  │
│            └─────────────────────────────────┘ └─────────────────────────────────┘                  │
│  LOGS (UI-4)  ► honest "no task logs captured" + FR18 guidance · server-log diagnostic (labeled)    │
│  RAW STATE.md (UI-3)  [source: .aid/<work>/STATE.md · read-only]  ▼ collapsed by default            │
│    <pre> monospace, escaped, scrollable, anchored to ### task-NNN — DISPLAYED, never editable       │
└──────────────────────────────────────────────────────────────────────────────────────────────────┘
```

#### UI-2. Findings list + review ledger / grade (FR13 findings + ledger/grades, FR6)

- **Findings** (`TaskDetail.findings[]`) — a severity-tagged list, each row: a **color+shape severity
  chip** (FR8 — `[CRITICAL]` → `.badge-err` + ✕ octagon; `[HIGH]` → `.badge-warn` + ⚠ triangle; unknown
  → `.badge-dim` neutral, never throws), the `description`, the `location` (`file:line`, monospace, in
  `.meta`) when present, and the `disposition` chip (`Fixed-on-spot` → `.badge-ok` ✓; `Deferred-to-gate`
  → `.badge-info` →gate). Empty list → "No quick-check findings recorded for this task." (a clean task is
  the common case — not an error).
- **Review ledger / grade** (`TaskDetail.ledger`) — a small panel, **honestly labeled** per DM-1's
  "ledger is a join":
  - **Grade chip** — `ledger.grade` of the task's **delivery** (e.g. `A+` → `.badge-ok`; `Pending` →
    `.badge-dim`), captioned **"delivery grade (delivery-NNN)"** — never "task grade" (AID grades per
    delivery, not per task; DM-1). `delivery_id == null` → "Not yet graded (no delivery gate run)".
  - **Reviewer tier** (`Small/Medium/Large`) + **gate timestamp** in `.meta`.
  - **Deferred-`[HIGH]` issues table** — `ledger.deferred_issues[]` (the task's own rows from
    `delivery-NNN-issues.md`) as a compact 3-col table (`Severity · Description · Status`), each `Status`
    a chip (`Open` → `.badge-warn`, `Resolved` → `.badge-ok`, `Accepted` → `.badge-info`). Empty → "No
    deferred issues for this task."

#### UI-3. Raw STATE.md viewer — read-only, escaped (FR13 raw STATE.md, NFR2)

The literal `raw_state.text` rendered in a **`<pre>` monospace, HTML-escaped, scrollable, read-only**
block — the operator's forensic escape hatch to see exactly what the pipeline wrote. Honoring NFR2
("displayed, never edited") **structurally**: it is a non-editable `<pre>` (no `contenteditable`, no
`<textarea>`, no form, no write affordance), captioned `source: .aid/<work>/STATE.md · read-only`.
Because AID keeps **one STATE.md per work** (DD-3, not per task), the viewer:
- **Deep-anchors** to this task's relevant text on open — scrolls to / highlights the `## Tasks Status`
  row for `task_id` and the `### task-NNN` block under `## Quick Check Findings` — so the operator lands
  on the task's text without losing the whole-file view.
- Is **collapsed by default** (it is large; `byte_len` drives a "show N KB" affordance) and expands on
  demand, so the heavy text is not forced into the initial paint (works with the lazy `?detail=` load).
- **Escapes all content** (`<`, `>`, `&`, and the `U+2028/U+2029` line separators feature-003 DM-3 calls
  out) so STATE.md markup/HTML cannot inject into the page — a read-only viewer, not a renderer.

#### UI-4. Logs panel — HONEST availability + FR18 guidance (FR13 logs, FR18)

The logs panel reflects DM-4's honest inventory — it must **not** fake a log viewer over files that do
not exist:

| `LogAvailability` state | Panel content |
|--------------------------|---------------|
| `task_logs == none` (always, today) | **"No per-task logs are captured."** + the FR18 step-by-step guidance below. This is the normal, honest state — not an error. |
| `server_log_present == true` | A clearly-labeled **"Dashboard server log (tool diagnostic — not a task log)"** affordance noting `.aid/.temp/dashboard.log` exists (the dashboard's own stdout/stderr from `aid dashboard start`, feature-004 DM-1). It is surfaced as a server-troubleshooting aid, **never** as this task's output. |
| `heartbeat_present == true` | An advisory **"last seen"** line from `.aid/.heartbeat/` (repo-level, corroborating-only per KI-004) — a liveness hint, explicitly **not** a log. |

**FR18 step-by-step guidance (the "logs" user-intervention point).** Because AID captures no per-task
execution log, FR18 requires a real procedure for an operator who wants task-level diagnostics — not a
one-line shrug:

```
┌─ .card (logs guidance) ───────────────────────────────────────────────────────────────────┐
│  kicker: NO TASK LOGS CAPTURED                                                              │
│  This task's forensic record is its findings, its review ledger, and the raw STATE.md       │
│  above — AID does not persist a separate per-task execution log.                             │
│                                                                                              │
│  To capture diagnostic output for a run:                                                     │
│   1. The dashboard server's own log is at  .aid/.temp/dashboard.log  (created by             │
│      `aid dashboard start`; it records the SERVER's boot/errors, not task execution).        │
│   2. For pipeline/task troubleshooting, re-run the relevant skill (e.g. `/aid-execute`)      │
│      and watch its live terminal output; AID writes task forensics to this work's            │
│      STATE.md (## Quick Check Findings, ## Delivery Gates) — shown on this page.              │
│   3. Verify: after a re-run, this panel's Findings/Ledger sections update on the next        │
│      refresh (within the poll interval) as the reviewer writes them.                         │
│  meta: this page refreshes every Ns — new findings appear automatically.                     │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
```

If the work is **Blocked** with an IMPEDIMENT (feature-002 `block_artifact`,
`.aid/{work}/IMPEDIMENT-task-NNN.md` per KI-002/KI-003), the panel additionally surfaces a read-only
link/label to that artifact path (the impediment's `## Options` require a human decision — an FR18
user-intervention point), pointing the operator at the file to read and decide on. The dashboard never
runs commands itself (read-only, NFR2) — it tells the operator exactly what to type and how to confirm.

#### UI-5. Parallel-task drill (FR14)

Concurrency is first-class: from the pipeline view (feature-003 UI-3 wave-grouped chips), the operator
can drill **several** concurrent tasks. Each open drill is its own route entry in the `?detail=`
comma-list (DM-3) and renders an **independent** forensic panel — on desktop as side-by-side expandable
panels (`.grid.g2`), on mobile as a stack, each with its own findings/ledger/raw-state/logs. The view
never merges two tasks' forensics; N drilled tasks = N panels, matching FR14's "several
simultaneously-active tasks … not a single linear current task". A drilled task that **disappears**
between polls (its row removed, FR12) shows a small "this task is no longer in the work's state" notice
+ back link, never a blank (mirrors feature-006 FC-3).

#### UI-6. Responsive + cross-browser (NFR6, NFR5)

- **Breakpoints** reuse the design family's 768px collapse (`component-css.css:563`
  `.grid, .grid.g2, .grid.g3 { grid-template-columns: 1fr; }`). **Desktop** (>1024px): findings + ledger
  side-by-side (`.grid.g2`), the raw-state `<pre>` full-width below, parallel drills side-by-side.
  **Tablet** (768–1024px): the g2 panels stay 2-up; the raw-state viewer scrolls horizontally within its
  `<pre>`. **Mobile** (<768px): everything stacks to one column; the raw-state `<pre>` is
  horizontally-scrollable (monospace must not wrap-corrupt), collapsed by default so it does not dominate
  the small viewport.
- **Cross-browser (NFR5):** Chrome/Firefox/Edge/Safari — only baseline primitives (CSS custom
  properties, `grid`/`flex`, `fetch`, `localStorage`, `location.hash`/`hashchange`, `<pre>`), no
  polyfill, no transpile, same posture as feature-003/006/007 UI-6.

---

### Design decisions worth user attention

- **DD-1 — Lazy detail via `?detail=` on the existing `/api/model`, not an enriched model and not a
  second endpoint.** The forensic detail (esp. the raw STATE.md text, tens of KB) is served **only when
  a task is drilled**, via an additive query param on feature-003's existing GET `/api/model` route —
  keeping all `.aid/` reads inside feature-002's audited read-only/no-LLM reader, the server at one
  closed two-route allowlist (feature-003 LC-S, feature-006 DD-1), and the whole stack on one poll loop.
  Enriching every `TaskModel` on every 5s poll was rejected (NFR4 violation — sends forensic bytes nobody
  is viewing); a separate `/api/task/<id>` endpoint was rejected (new server surface the bind/no-write/no
  -LLM self-checks would have to re-cover).
- **DD-2 — `schema_version` 2 → 3, composing with feature-007's 1 → 2.** Two Should-tier features each
  grow the wire shape: feature-007 (rich `KbModel`, 1→2) and this feature (the `details` map, 2→3).
  They are **sequential, not conflicting** — whichever ships second takes the next integer and the
  front-end's `EXPECTED` moves with it; feature-003's stale-assets banner fails loud on any mismatch.
  The cost is a one-line constant per runtime + the front-end `EXPECTED`, plus extending feature-003's
  PT-1 fixture with a findings/ledger/issues work and a `U+2028/U+2029` STATE.md so `details` is proven
  byte-identical across runtimes. **If the planning phase sequences 007 and 008 into the same delivery**,
  they can share a single 1→3 bump; if separate, each takes its own step — either way the front-end
  `EXPECTED` and PT-1 fixture move in lockstep (worth user attention as the genuine cross-feature
  coordination, touching feature-002 reader + feature-003 envelope/PT-1).
- **DD-3 — "Raw STATE.md for a task" is the work's STATE.md, anchored to the task.** AID keeps one
  `STATE.md` per work (no per-task STATE file exists — `work-state-template.md:9`). The drill shows the
  **work** STATE.md verbatim, deep-anchored to the task's `### task-NNN` / `## Tasks Status` row, so FR13
  is satisfied with the real artifact rather than a fabricated per-task file.
- **DD-4 — "Logs" is honest: AID captures no per-task execution log.** Verified on disk: there is no
  per-task/per-agent log anywhere under `.aid/`. The only log is the **dashboard server's own**
  `.aid/.temp/dashboard.log` (a tool diagnostic, feature-004 DM-1), surfaced clearly-labeled-as-such; the
  reviewer ledger (`.aid/.temp/review-pending/`) is **transient and deleted at skill DONE**, so it is not
  a forensic source for a finished task (the persistent forensics are `## Quick Check Findings` +
  `## Delivery Gates` + `delivery-NNN-issues.md`). Rather than fake a log viewer, the panel states the
  honest reality + FR18 guidance (KI-008). Worth user attention: if true per-task execution logging is
  desired, that is a **producer-side** capability change (feature-001 territory), out of scope for this
  read-only view.

---

### Acceptance-criteria → spec map

| AC (this SPEC) | Requirement | Satisfied by |
|----------------|-------------|--------------|
| drill a task → findings, ledger/grades, raw STATE.md, logs — read-only | FR13, NFR2 | DM-1 `TaskDetail` (findings/ledger/raw_state/logs); UI-2 findings + ledger, UI-3 read-only escaped raw STATE.md viewer, UI-4 honest logs panel; reached via SEAM-2 route off feature-006's router |
| parallel tasks each individually reachable | FR14 | `?detail=` comma-list (DM-2/DM-3); FC-5 parallel drill; UI-5 N independent forensic panels; feature-002 DM-5 already carries per-task `status`/`wave` |
| maximal tracking detail | FR6 | findings + deferred-issue rows + delivery grade + the full verbatim STATE.md (UI-2/UI-3) |
| read-only / displayed-never-edited | NFR2 | front-end view + reader-side reads only (LC-TR inside the audited reader); raw STATE.md in a non-editable escaped `<pre>` (UI-3); no write, no new server route |
| no-LLM | NFR7 | deterministic string parses + verbatim passthrough in LC-TR; grades/findings rendered literally, never re-derived |
| low overhead (lazy detail) | NFR4 | DD-1 lazy `?detail=` — heavy bytes only on drill; `raw_state` reuses already-read STATE.md bytes (DR-1); always-on poll body unchanged |
| matches summary style; responsive; cross-browser | NFR8, NFR6, NFR5 | UI-1 design-family reuse; UI-6 768px collapse + baseline primitives + Playwright gate |
| (cross) live ≤ interval | FR4, NFR3 | FC-4 re-render on the shared feature-003 poll loop; LC-TR re-parses each pass |
| step-by-step guidance when logs/forensics need user action | FR18 | UI-4 "no task logs captured" procedure (command + verify) + the IMPEDIMENT-artifact pointer for a Blocked work |

---

### Known issues registered by this feature

This feature is a **read-only projection** of per-task forensic state: a reader sub-parser (inside
feature-002's audited read-only reader) + a server-handler branch (inside feature-003's closed route) +
a front-end drill view on feature-006's router. The `schema_version` bump (DD-2) is a planned, contained
contract evolution (front-end `EXPECTED` + PT-1 fixture grow in lockstep, composing with feature-007's
bump), not a defect. It registers **one** genuine known issue:

- **KI-008** — **AID captures no per-task / per-agent execution log.** FR13 lists "logs" among drill-down
  detail, but a disk audit (2026-06-10) confirms no `*.log` exists under `.aid/` for pipeline/task
  execution; the only log is the dashboard **server's own** `.aid/.temp/dashboard.log` (a tool
  diagnostic, feature-004 DM-1), and the reviewer ledger (`.aid/.temp/review-pending/<scope>.md`) is
  transient — deleted at skill DONE (`reviewer-ledger-schema.md`). This tier therefore surfaces the
  **persistent** forensics (`## Quick Check Findings`, `## Delivery Gates`, `delivery-NNN-issues.md` —
  DM-1) plus an honest "no task logs captured" state + FR18 guidance (UI-4), and clearly labels the
  server log as a tool diagnostic, never as task output. True per-task execution logging would be a
  **producer-side** capability (feature-001 territory), out of scope for this read-only view. Advisory;
  revisit if a per-task log capture is added to the pipeline.

(KI-001/KI-002 are feature-001's; KI-003/KI-004 are feature-002's; KI-005/KI-006 are feature-005's;
KI-007 is feature-007's — all consumed, not duplicated. The `schema_version` 2→3 bump is recorded as a
cross-feature impact in DD-2, coordinated with feature-002 + feature-003 + feature-007, and is not a
standalone debt entry.)
