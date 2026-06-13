# Requirements

- **Name:** AID Live Dashboard
- **Description:** A local, read-only, live HTML dashboard that visualizes AID pipeline state and progress across works, deliveries, and tasks.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-10 | Initial interview started | /aid-interview |
| 2026-06-10 | KB hydration — reasoned no-op (brownfield KB accurate; dashboard tech/arch deferred to OQ2/spec; feature-inventory post-decomposition) | /aid-interview |
| 2026-06-10 | Added FR14 parallel-execution display; folded concurrency into AC2 | /aid-interview |
| 2026-06-10 | Interview complete — approved | /aid-interview |
| 2026-06-10 | Added FR15 (KB-state display at Level 1) during feature decomposition | /aid-interview |
| 2026-06-10 | Reframed Level 1 as project main page (FR3 cards/drill-down); FR15 → independent KB dashboard card; added FR16 pipeline lifecycle state | /aid-interview |
| 2026-06-10 | Finalized FR16 state set: Running / Paused-awaiting-input / Blocked / Completed / Canceled (dropped Idle; merged approval into input) | /aid-interview |
| 2026-06-10 | Added FR17 (authorized behavior-preserving pipeline state-management refactor; subsumes OQ4) + C4 (behavior preservation); front-loaded research/design/refactor feature | /aid-interview |
| 2026-06-10 | Cross-reference fixes: corrected false bare-`aid` claim (OQ3), bounded C4 verification surface, NFR3 traceability, C3 tailnet-vs-ACL gap, URL-deferral wording, status footers → Complete | /aid-interview |
| 2026-06-10 | Cross-ref Q&A resolved: OQ3 → new `aid` subcommand; FR17/C4 → fully-open redesign (behavior-preservation only invariant); C3 → host/user-scoped ACLs + research Tailscale alternatives | /aid-interview |
| 2026-06-10 | OQ2 resolved (during /aid-specify feature-003): Option C hybrid (static front-end + thin stdlib localhost server running read_repo); dual-runtime Python+Node, user-selectable `aid serve python\|node`; parity test required | /aid-specify |
| 2026-06-10 | Added FR18 (cross-cutting): any user-intervention action must be explained to the end user step by step (commands + verification) — esp. feature-005 ACL grant, feature-004 missing-runtime/--remote | /aid-specify |
| 2026-06-11 | feature-009 producer-loop closure: added FR19–FR26 (producer emission per skill, single phase source, lane-from-PLAN decision B, consumer reconciliation, dogfood render, graceful degradation, work-001 data migration) + C5 (dogfood-rendered producers; reader stays no-LLM/read-only) | /aid-interview |
| 2026-06-12 | **Two-level dashboard re-architecture** (user-approved): added FR27–FR36 (CLI home + machine repo registry + multi-repo server routing; per-repo `home.html`/`kb.html` split; CLI-panel relocation; KB-summary relocation to `.aid/dashboard/kb.html`; 5-state KB card; reader KB-status + cross-runtime default-branch git read; discover→summarize auto-trigger chain; KB-freshness baseline/`outdated`; producer-skill changes for summarize/discover/housekeep/`bin/aid`), NFR9–NFR11 (multi-root read-only scoping; stale-registry tolerance; co-located per-repo dashboard artifacts), C6–C7 (multi-root read-only scoping + no path traversal; producer-skill edits are dogfood-rendered & behavior-preserving), OQ5 (`--remote` exposure scope — CLI home vs single repo) and OQ6 (`aid add`/`aid remove` verb-naming collision — those verbs already install/uninstall host-tools; registry-verb shape open) — both open for /aid-specify | /aid-interview |
| 2026-06-13 | **Upgrade migration** (user-directed, feature-011): added FR37–FR40 (per-repo upgrade migration — detect ≥0.7.X vs pre-0.7, validate/repair or synthesize `settings.yml`, add `home.html`, relocate legacy summary→`kb.html`, register; command model `aid update self`=machine-scan-all w/ All/Yes/No/Cancel vs `aid update [<tool>]`=current-repo-only; trigger=npm postinstall + cross-manager version-sentinel lazy first-run since pypi wheels have no postinstall; `home.html` single vendored source `dashboard/home.html`), NFR12 (migration safety — idempotent/additive/WARN-not-fail/no-delete), C8 (lands in hand-maintained `bin/aid`+PS twin, ASCII+parity+vendor gates not render-drift, never destroys user data). Resolves KI-010 (home.html provisioning). User: not a blocker (adoption negligible) but this version carries the migration. | /aid-interview |
| 2026-06-12 | **Cross-reference-gate fixes + two OQ decisions** (user-approved): **OQ5 RESOLVED** — `aid dashboard --remote` exposes the **CLI home (all registered repos)**; tailnet-private/never-public (NFR1/C1) + host/user-ACL (C3) hold, repo-list-to-grantees is an accepted trade-off. **OQ6 RESOLVED** — registry maintenance is a **side-effect of the existing `aid add` / `aid remove`** (no new verb; register on first tool added, unregister on last removed; host-tool install/uninstall behavior unchanged). Registry relocated to **`$AID_HOME/registry.yml`** (the CLI install's own registry, not the per-repo `.aid/settings.yml`; `~/.aid/` IS `AID_HOME`). FR34 reframed as a **deliberate new closing behavior** of `aid-discover` (produces `kb.html`), **not** a C4 behavior-preserving change (C7 amended). FR30/C6 reframed as a **contract-level change** to feature-003's delivered closed two-route server (preserve bind/no-write/no-LLM; extend PT-1 to the multi-repo shape). FR3 edited in place (Level-0 relocates per FR33). FR7 explicitly owned by feature-010 (renders on the CLI home). FR35 notes the new `.aid/settings.yml` KB-baseline key (`/aid-config` schema addition). | /aid-interview |

## 1. Objective

Build a **local-only, dynamic HTML dashboard** that visualizes the state and live progress
of AID runs. The dashboard renders AID workspace state (works, skills/phases, deliveries,
tasks, reviews) and updates in real time as runs progress. It is research-heavy: layout,
multi-run aggregation, cross-repo and VM scenarios, live-update mechanism, exposure tooling,
and security must all be investigated before/alongside implementation.

> _Status: Complete — approved._

## 2. Problem Statement

Today there is **no tracking, visibility, or global view** of the state of an AID pipeline.
While piloting a run the operator cannot easily see, at a glance:
- the overall **state of the pipeline** and how far along it is,
- **what to do next**,
- **failures** / where something went wrong.

This forces the operator to manually inspect scattered state files to reconstruct "where am I
and what's happening." The dashboard provides a single live visual view that answers those
questions directly.

> _Status: Complete._

## 3. Users & Stakeholders

- **Primary user:** the operator **piloting the AID pipeline** — watching their own run(s)
  progress on their machine.
- **Secondary user (handoff):** because a work/pipeline folder is **persisted in the repo**,
  a *different* user can pick up a pipeline where the first stopped. This implies any
  dashboard data/state that is **specific to one pipeline must live with that pipeline's work
  folder** (so it travels with the repo and supports handoff), while machine- and repo-level
  state lives at a higher scope.
- **Interaction model:** **read-only observation only.** The dashboard never triggers, pauses,
  approves, or otherwise mutates a run — it only reflects state. (Consistent with the
  read-only posture of `/aid-ask`.)

> _Status: Complete (approved; any open research deferred to /aid-specify)._

## 3a. Monitoring Levels (data hierarchy)

Four nested levels of monitoring, each a candidate scope/view:

Each level's displayed information is sourced from where that level's state actually lives —
the data source colocates with the scope it describes:

| Level | Name | Scope | Data source (where the shown info lives) |
|-------|------|-------|------------------------------------------|
| 0 | **AID (tool)** | The CLI installed on the machine | the **global CLI tool** (machine-level install — e.g. version, install location) |
| 1 | **Repo / Project** | The folder where AID was installed | the project's **`.aid/` folder** — including **KB state** (`.aid/knowledge/` docs, `README.md` completeness, `STATE.md` summary status) per FR15 |
| 2 | **Work / Pipeline** | Each work performed on that repo | the **work folder** (inside `.aid/`; portable, handoff-able) |
| 3 | **Skill / Task** | Live, during execution of a skill | **wherever that skill/task's STATE is kept** — ⚠️ **OPEN ITEM: exact location to be reviewed** (today skill/task run-state is spread across e.g. work `STATE.md` `## Tasks Status` / `## Quick Check Findings`, `.aid/.temp/*STATE*.md`, `MONITOR-STATE.md` — needs to be pinned down) |

> _Status: Complete — approved. Levels + data sources defined; level-3 state location is owned by
> FR17/feature-001 (resolved there)._

## 4. Scope

### Architecture principle (clarified at intake)

**One independent dashboard per repo/project.** AID is installed per project, each with its own
`.aid/` folder. Each repo therefore **exposes its own browser view**, fully independent of any
other repo — there is **no cross-repo rollup / aggregation** dashboard. "Different repos" means
*N separate dashboards*, not one combined view.

A repo (and thus its dashboard) may be running:
- on the user's **local laptop/desktop**, or
- on a **VM**, or
- on a **remote machine**.

In every case the repo's own dashboard must be **reachable via browser by the end user**, wherever
the repo physically runs.

**Level 0 exception:** a small amount of info is **common to all repos on a machine** — namely the
**AID CLI tool installed at machine level** (e.g. version, install location). Each repo's dashboard
surfaces this level-0 info (read locally from the machine it runs on); it is the only
non-repo-scoped data, and it is *displayed within* each per-repo dashboard rather than in a
separate global view.

### In Scope

Open research areas raised at intake (each likely a feature):
1. Dashboard **layout / visual design**.
2. Display **multiple runs (works/pipelines) within the same repo**.
3. **Per-repo independence** — each repo serves its own dashboard; no cross-repo aggregation.
4. **Live update** — reflect run progress in real time.
5. **What information** to display (per monitoring level 0–3).
6. Reaching a dashboard when the repo lives **on a VM / remote machine** (exposure & reachability).
7. **Tooling to expose/serve** the HTML.
8. **Security considerations.**
9. **Level-0 machine-level AID CLI info** surfaced within each dashboard.
10. **Pipeline state-management review & normalization** (FR17) — authorized behavior-preserving
    refactor of how/where the pipeline stores state, to give the dashboard a clean source.
11. Implementation of all the above once the research is decided.
12. _(and more — to be elaborated.)_

### Out of Scope

- A **single combined/aggregated view across multiple repos** — explicitly *not* the model;
  each repo is independent (one project per page; browser tabs for more).
- Any **write/control actions** on runs (read-only observation only).
- **Accessibility** features (keyboard nav, color-blind-safe palette, etc.) — **deferred for
  now** (not now, may revisit later).
- **Export / share** (snapshot PNG/HTML to send to others) — **deferred for now.**
- **Cross-platform serving niceties** (auto-open browser, auto-pick free port, **auto-surface**
  the reachable URL) — **deferred for now.** (Note: *remote reachability itself* is in scope and
  MVP via feature-005; only the convenience of auto-surfacing the URL is deferred — manual URL
  discovery suffices.)

## 5. Functional Requirements

> _Status: Complete — approved; FR1–FR17 decomposed into 8 features._

- **FR1 — Per-repo dashboard.** Each repo serves its own independent browser-viewable HTML
  dashboard scoped to that repo's `.aid/`; no cross-repo aggregation.
- **FR2 — Four-level view.** Surface the four monitoring levels (0 tool, 1 project, 2 work,
  3 skill/task), each sourced from its own data location (see § 3a).
- **FR3 — Project main page (Level-1 overview).** The Level-1 view is the project's **main page**
  — a "dashboard of dashboards." It shows a **card for every pipeline/work** in the repo, each
  card displaying that pipeline's **current lifecycle state** (see FR16). The page also hosts a
  **KB card** (FR15). _(The Level-0 CLI info no longer renders here — it **relocates** to the CLI
  home per FR33; this supersedes the original "the page also hosts the Level-0 CLI info (FR7)"
  clause.)_ **Clicking a card opens that item's own
  detail view** (a pipeline card → the pipeline progress/detail view; the KB card → the KB
  dashboard). This is the dashboard's entry point and primary navigation surface.
- **FR4 — Live update by polling.** The dashboard refreshes from the on-disk AID state on a
  **polling** interval to reflect run progress in near-real-time. (Push-based updates are a
  possible future evolution, not required for v1.)
- **FR5 — Configurable refresh interval.** Default polling interval **5 seconds**; the user can
  change it from the dashboard.
- **FR6 — Maximal tracking detail.** Display as much run-tracking information as practical —
  current skill/task and status, progress across waves/tasks, review grades/results, and more
  (exact field set to be defined in research/spec).
- **FR7 — Level-0 CLI info.** Show machine-level AID CLI info (e.g. version, install location)
  read from the global CLI tool.
- **FR8 — Visual-first design.** Use as much **visual representation** as possible, following
  dashboard best practices: minimum text; only single, short, clearly-visible words; consistent
  and intuitive use of **color and shape**; information organized to facilitate fast
  understanding at a glance.
- **FR9 — One project per page (browser tabs for multiple).** Each dashboard page shows
  **exactly one project**, fully independent. There is **no in-app cross-project tab strip**;
  to view multiple projects the user simply opens **multiple browser tabs**, each pointing at
  that project's own independently-served dashboard. (Two projects are never blended on one
  screen — consistent with § 3a/§ 4.) _OQ1 resolved._
- **FR10 — CLI start/stop.** The dashboard is **started and stopped via a CLI**. _Open: whether
  to extend the **existing `aid` CLI** or introduce a **separate CLI** — to be discussed (see
  § 8)._
- **FR11 — Failure & attention signals.** The dashboard **actively calls out** states that need
  the operator's attention — **errors/failures** and **blocked-waiting-for-user** (input or
  confirmation) — not just passively showing them (visual emphasis: badge/color/shape per FR8).
- **FR12 — Per-work-folder history & retention.** History is **scoped to the work folders that
  persist in the repo**: if a work/pipeline folder exists in the project's `.aid/`, that
  pipeline's information **is available in the dashboard** (current and completed alike). There
  is **no separate/global history store** — retention is governed entirely by which work folders
  remain in the repo.
- **FR13 — Full drill-down.** The user can drill into a skill/task to see **all** of its detail:
  **findings**, the **review ledger / grades**, the **raw STATE.md content**, and **logs**.
- **FR14 — Parallel execution display.** Some pipeline stages run **multiple tasks in parallel**
  (e.g. parallel agents during `/aid-discover`, or concurrent task waves during `/aid-execute`).
  The dashboard's level-3 view must **accommodate concurrency** — representing several
  simultaneously-active tasks and their individual states at once, not assuming a single linear
  "current task."
- **FR15 — KB dashboard (Level-1 card).** The Knowledge Base is rich enough to be **its own
  dashboard**. On the project main page (FR3) it appears as a **KB card** summarizing KB state
  (doc inventory + completeness from `knowledge/README.md`; freshness — INDEX up-to-date,
  `knowledge-summary.html` current & approved per `knowledge/STATE.md`; last update). **Clicking
  the card opens a dedicated, independent KB dashboard** with the fuller detail. Read-only.
- **FR16 — Pipeline lifecycle state.** Each pipeline/work has a **derived lifecycle state**
  shown on its card (FR3) and used by attention signals (FR11). The state set is:
  - **Running** — a skill, a task, or multiple tasks is actively executing
  - **Paused — awaiting input** — blocked on any user input, including questions **and
    confirmations/approvals** (an approval is a kind of input — not a separate state)
  - **Blocked — error / impediment** — failed gate, IMPEDIMENT, etc.
  - **Completed**
  - **Canceled**

  (There is no "Idle / Not-started" state — starting a work via `/aid-interview` moves it
  immediately to **Running**.) The state is **derived read-only** from on-disk work state;
  computing it reliably depends on the state-model work in FR17 (which resolves OQ4).
- **FR17 — Pipeline state-management review & normalization (behavior-preserving).** This work is
  **authorized to review in full how the AID pipeline stores and manages pipeline state**, and to
  **refactor it** to provide a clean, reliable, dashboard-friendly single source of truth. In
  scope for the refactor: **where state files are stored, what information is captured and when,
  file names, skill behavior, and agent definitions** — everything is on the table. **Hard
  guardrail: any such refactor MUST preserve the pipeline's existing behavior** (see C4). This is
  a **front-loaded research + design + refactor** effort (the first feature/phase of the work) and
  it **subsumes and resolves OQ4**. The dashboard's reader (FR1/FR2/FR16) consumes the normalized
  state this defines.
- **FR18 — Step-by-step guidance for any user-intervention action (cross-cutting).** Whenever the
  dashboard or its CLI reaches a point that **requires the end user to do something** the tool cannot
  do for them — install a runtime, install/enable the remote-exposure mechanism, **add the tailnet
  ACL grant** (feature-005), fix a missing dependency, resolve a port conflict, etc. — it must
  **explain the required action to the end user step by step**: what to do, the exact command(s) to
  run or setting(s) to change, and how to verify success. A terse one-line hint is not sufficient for
  actions with multiple steps. (Consistent with "annotate what we cannot prove and tell the user how
  to resolve it" — never fake a guarantee, never leave the user guessing.) Applies to every feature
  with a user-intervention point; most acute for feature-005 (ACL grant) and feature-004 (missing
  runtime / `--remote` unavailable).

### Feature-009 — Producer-loop closure (dashboard renders REAL pipeline data)

> _Context: features 001–008 built the reader (feature-002) and front-end (feature-003)
> **consumer-first**, against an **invented PT-1 fixture**. Pointed at the real work-001 repo
> they break — "phase unknown", "Delivery #0", a stray `> _Status:_` blockquote in the
> description, and the work title falling back to the `work_id` — because the producing pipeline
> skills never emitted the display fields the reader reads, and the lane format was invented in
> the fixture rather than derived from real producer output. Feature-009 closes that loop: the
> pipeline skills become the canonical PRODUCERS of every field the dashboard consumes, the
> reader/front-end are reconciled to those canonical formats, and work-001's pre-existing state is
> migrated. The display fields below were always implied by FR3/FR6/FR12/FR16; FR19–FR26 make
> their **production, format, and end-to-end correctness** explicit and testable._

- **FR19 — Producer emission: work identity (Name + Description).** `/aid-interview` must WRITE,
  into `REQUIREMENTS.md`, a **typed, parseable header block** carrying a human-readable work
  **Name** and a **one-sentence Description**. The Description is **derived from the Objective at
  author time** — the skill generates it and the user confirms (it is not free-form authored
  separately, and not the same text as the Objective body). The dashboard's work-overview header
  reads Name/Description from this block; it must never fall back to rendering the raw `work_id` as
  a title, nor leak section markup (e.g. a `> _Status:_` blockquote) into the displayed
  description. _(Resolved decision: description-derived-from-objective — not an open question.)_
- **FR20 — Producer emission: task short-name.** `/aid-detail` must WRITE a **one-sentence task
  short-name / description** into each `tasks/task-NNN.md` in a typed, parseable location the
  reader can read, so each task card shows a **real, human task name** rather than only its
  `task-NNN` id. Both `/aid-detail` (seed) and `/aid-execute` (any update) must preserve it.
- **FR21 — Single phase source (Pipeline Status) — confirm + cover bootstrap.** The typed
  `## Pipeline Status` block (lifecycle / phase) emitted by the phase skills via
  `writeback-state.sh --pipeline` (feature-001) is the **single source of truth** for a work's
  phase and FR16 lifecycle state. No new producer is introduced; this FR requires **verifying**
  the reader derives phase/lifecycle solely from that block (no secondary/inferred phase source),
  and that the **bootstrap / migration case** — a work whose `## Pipeline Status` block predates
  feature-001 or is absent — is explicitly handled (migrated per FR23, degraded per FR25).
- **FR22 — Lane source = PLAN.md Execution Graph (decision B).** The dashboard's
  **Delivery > Lane > Task** lanes are derived **by the reader** from `PLAN.md`'s
  `## Execution Graph` (which defines the **waves per delivery**), correlated to tasks — **not**
  from an invented `delivery-NNN-wave-M` column. Deliveries group by the **real**
  `## Tasks Status` **Wave column = `delivery-NNN`** (the delivery), and the **lanes within a
  delivery** come from that delivery's wave structure in the Execution Graph. The STATE Tasks
  Status Wave column **stays** the real `delivery-NNN` value (no invented wave column is added to
  STATE). _(Resolved decision: lane = B / PLAN Execution Graph — not an open question.)_
- **FR23 — Consumer reconciliation (reader + front-end to real canonical formats).** Feature-002's
  reader and feature-003's front-end must be **reconciled to the canonical producer formats** in
  FR19–FR22 (they currently match the invented fixture). The **PT-1 fixture must be regenerated
  from / validated against REAL producer output** (captured from actual skill emission, e.g. the
  migrated work-001 data), so the fixture **cannot silently drift** from what producers emit. A
  test must assert producer-emitted format ⇄ reader-consumed format equivalence (a
  producer↔consumer round-trip / contract test), so a future producer-format change fails fast.
- **FR24 — Dogfood render (producers usable on THIS repo without a CLI release).** The producer
  changes live in `canonical/skills/` (hand-maintained source) and MUST be rendered into this
  repo's dogfood copy at `.claude/skills/` via the **FULL `run_generator.py`**, so `/aid-*` on
  **this** repo uses the new producers immediately — without waiting for an `aid` CLI release. The
  **render-drift and deterministic-emission gates must stay green** (all install trees
  byte-identical; emission manifests current).
- **FR25 — Graceful degradation for partial / legacy works.** For any work that still lacks a
  producer field (legacy or partially-migrated), the dashboard must degrade **cleanly and
  legibly** — e.g. an em-dash `—` placeholder or an explicit "not yet recorded" — and must **never
  render garbage** such as `Delivery #0`, `phase unknown`, a leaked `> _Status:_` blockquote, or
  the raw `work_id` as a title. Missing-field handling is uniform across the work-overview header,
  delivery/lane grouping, and task cards.

#### Feature-009 data migration (work-001 bootstrap)

- **FR26 — Migrate work-001 to the canonical schema.** work-001 is the **bootstrap case** — its
  `STATE.md`, `REQUIREMENTS.md`, and task files predate the producers this feature adds and must be
  **migrated to the canonical schema**, filling the genuinely-absent information: the FR19
  Name/Description header block, the typed `## Pipeline Status` block / Phase (FR21), and the FR20
  task short-names. (`settings.yml` `project.name` is repo-scoped and already set to `AID`; migration
  only ensures it is a clean display value — the reader-side inline-comment-stripping is an FR23
  reconciliation item, not a missing field.) After migration
  the dashboard pointed at the real work-001 repo renders end-to-end with **no degraded/garbage
  fields** (closing the gap that motivated feature-009).

### Two-level dashboard re-architecture (FR27–FR36)

> _Context: features 001–009 built a dashboard that models **one repo** and mixes machine-scope
> (Level-0 CLI info) and repo-scope on a single page. But the AID CLI is **global** and spans
> **many** repos. This re-architecture splits the dashboard into **two levels** — a machine/CLI
> **home** that lists all registered repos, and a **per-repo** view — fed by a **machine-level repo
> registry** and a **multi-repo-aware server**. It supersedes the §4 "one independent dashboard per
> repo, no global view" framing for the machine tier ONLY: there is now a machine-level CLI home
> that enumerates repos, but it is still **navigation, not aggregation** — each repo's pipeline data
> remains independent and is never blended (FR9 holds). The §3a Level-0 / Level-1 split is preserved
> but **relocated**: Level-0 (machine/CLI) moves UP to the CLI home; Level-1 (project) stays
> per-repo. FR27–FR36 are additive and do not disturb the records of already-delivered features
> (006 is revised, 007 is re-scoped — see Features Status), only their go-forward shape._

- **FR27 — Two-level dashboard (CLI home + per-repo).** The dashboard is split into **two levels**:
  - **Level A — CLI home** at `<CLI install>/dashboard/index.html` (the existing shared-app
    location): shows **machine/CLI info** (version, installed tools — the Level-0 panel relocated
    from the per-repo page, FR33) plus the **list of registered repos** (FR28) as repo-cards.
  - **Level B — per-repo** at `<repo>/.aid/dashboard/`: **`home.html`** = the live per-repo pipeline
    view (the current project main page, FR3, **minus** the relocated CLI panel) and **`kb.html`** =
    the KB summary view (FR31).
  - **Navigation:** CLI `index.html` repo-card → that repo's `home.html` → work-cards → per-work
    pipeline view → (later, feature-008) task drill-down; the KB card on `home.html` → that repo's
    `kb.html`. The CLI home is **navigation, not cross-repo aggregation** (FR9 preserved — one
    project's pipeline data is never blended with another's).
- **FR28 — Machine-level repo registry.** A machine-scoped registry file
  **`$AID_HOME/registry.yml`** (default **`~/.aid/registry.yml`**) holds **only the list of
  registered repo base folders** (paths). This is the **CLI install's own registry of the repos it
  manages** — it is *not* a per-repo project artifact. Note: **`~/.aid/` is `AID_HOME`, the installed
  CLI tree** (`bin/`, `lib/`, `VERSION`), not a project `.aid/` folder; the registry is a new file
  *inside that install tree*, distinct from any repo's `.aid/settings.yml`. A full uninstall
  (`aid remove self`, which `rm -rf`s `$AID_HOME`) therefore **removes the registry too** — which is
  **acceptable**: the registry is rebuilt by re-adding repos (each `aid add` re-registers, FR29). Per-repo
  display metadata (name, description, version) is **not** duplicated here — it is read from each repo's
  own `.aid/settings.yml` at render time. The registry is maintained by the CLI (FR29). It is
  **paths-only** by design so a repo rename/version bump never requires touching the registry.
- **FR29 — Registry maintained as a side-effect of `aid add` / `aid remove`.** Registering a repo base
  folder into `$AID_HOME/registry.yml`, and unregistering it, are CLI actions. Registration is
  folder-level: it does not move, copy, or mutate repo contents; these are the **only** writers of the
  registry.
  - **RESOLVED (OQ6, user decision 2026-06-12):** the registry is maintained as a **side-effect of the
    existing `aid add` / `aid remove`** — **no new verb** and **no change** to their host-tool
    install/uninstall behavior. This is **additive, not an overload**: a repo is **registered on its
    FIRST tool added** (`aid add <tool>` when the repo had none) and **unregistered on its LAST tool
    removed** (`aid remove <tool>` when none remain). `aid add`/`aid remove` keep doing exactly what
    they do today (install/uninstall AID host-tools — claude-code, codex, cursor, …) and now **also**
    keep `$AID_HOME/registry.yml` in sync. The default behavior of `aid add`/`aid remove` is therefore
    **preserved** (C4/C7); the registry write is a new, behavior-additive consequence of those same
    commands.
- **FR30 — Multi-repo server routing (a contract-level change to feature-003's delivered server).**
  The **one server per CLI install** becomes **multi-repo aware**. ⚠️ This is **not** a mere routing
  extension: feature-003 already **delivered** a **CLOSED two-route allowlist** server (`/` + `/api/model`,
  a single `--root` repo). FR30 **replaces that closed allowlist with a NEW explicit closed allowlist**:
  `/` (CLI `index.html`) plus, **for each registered repo** resolved via the registry (FR28), that repo's
  **`home.html`**, **`kb.html`**, and that repo's **`/api/model`** (feature-002 `read_repo` run against
  that repo's root). It is a **contract-level rewrite** of an already-delivered, invariant-tested component,
  so it **must preserve feature-003's hard invariants**: **loopback bind / local-only** (C1/C2), **no-write**
  (NFR2), **no-LLM** (NFR7). Static serving is **scoped to registered repos' `.aid/dashboard/` only**, fixed
  filenames, **no path traversal** (C6); every request is resolved against the registry and any path outside
  a registered repo's `.aid/dashboard/` is refused. The read-only contract (NFR2) now spans **N registered
  roots**, and feature-003's **PT-1 cross-runtime parity + no-write self-checks must be extended to this
  multi-repo shape** (the blast radius on feature-003's delivered server is explicit, not additive — see C6).
- **FR31 — KB summary relocation to `<repo>/.aid/dashboard/kb.html`.** `aid-summarize` writes its
  generated KB summary to **`<repo>/.aid/dashboard/kb.html`** (relocated from
  `.aid/knowledge/knowledge-summary.html`) — keeping the KB **source** folder
  (`.aid/knowledge/`) clean and **co-locating** the per-repo dashboard artifacts (`home.html`,
  `kb.html`) under `.aid/dashboard/`. The server serves it (FR30); the KB card (FR32) opens it. The
  summary's visual family (NFR8) is unchanged — only its output path moves.
- **FR32 — KB card 5-state status (reader-derived).** The KB card on the per-repo `home.html` shows
  a **derived 5-state status** (read-only, computed by feature-002's reader):
  - **pending** — no KB yet (`.aid/knowledge/` absent/empty).
  - **generating** — discovery is building the KB (`aid-discover` in progress per
    `.aid/knowledge/STATE.md`).
  - **preparing** — KB approved, summary being generated (`aid-summarize` in progress / `kb.html`
    not yet produced or approved).
  - **approved** — KB **and** `kb.html` ready, current, and approved.
  - **outdated** — the repo's default branch has advanced past the KB baseline (FR35).

  Only **approved** and **outdated** are **clickable** (outdated opens the stale `kb.html` plus a
  refresh prompt). Status signals: discovery/summarize state in `.aid/knowledge/STATE.md`,
  `kb.html` presence + approval, and the git baseline comparison (FR35).
- **FR33 — CLI (Level-0) panel relocation.** The "AID CLI (this machine)" panel (version, install
  location, installed tools — FR7) **moves from the per-repo page UP to the CLI home** (FR27 Level
  A); it is **machine-scoped**, common to all repos. The per-repo `home.html` then shows **only
  project-scoped** info (works/pipelines + the KB card), no CLI panel. (This supersedes FR3's
  "the page also hosts the Level-0 CLI info" clause and §4's "each repo's dashboard surfaces this
  level-0 info" framing — Level-0 is now surfaced once, on the CLI home.) **"Installed tools"
  clarification (feature-010):** AID installs once per machine but its host-tools are installed
  **per repo** (each repo's `.aid/.aid-manifest.json`), so there is no single machine-global
  installed-tools value. The machine panel therefore renders the CLI's manageable-tool **catalog**
  (the host-tools `aid add` can install); each repo's **installed** tools are surfaced on that repo's
  card (and its own `home.html`). Both together realize FR7/FR33 "installed tools".
- **FR34 — Discovery → summarize auto-trigger chain.** After `aid-discover` completes **its own** KB
  approval, it **auto-triggers `aid-summarize`** as its closing step. `aid-summarize` then runs
  **its own** (second) human visual approval — its existing V1 gate — producing `kb.html` (FR31).
  This is an **auto-trigger, not a single combined gate**: discovery is "done" at KB approval and
  the summary completes asynchronously, so the KB card (FR32) sits at **preparing** until the
  summary is approved. This guarantees the KB is always viewable once discovery completes.
  - **This is a deliberate, intended NEW behavior of `aid-discover`, not a behavior-preserving change.**
    Today `aid-discover` ends at HALT after KB approval and produces **no** summary; by design it now
    produces `kb.html` as its **closing step** — a new observable output/decision. C4 governs the FR17
    state refactor's behavior preservation; FR34 intentionally **adds** to `aid-discover`'s closing
    behavior and makes **no** "behavior-preserving in the C4 sense" claim. (It still leaves both existing
    approval gates intact — discovery's KB approval and summarize's V1 — it composes them, but the added
    auto-invocation + `kb.html` output is the intended new behavior.)
- **FR35 — KB freshness baseline / `outdated` detection.** At KB generation/update,
  `aid-discover` (and `aid-housekeep` on refresh, FR36) **record the repo's default branch + its tip
  commit date** into `<repo>/.aid/settings.yml` (a "KB reflects `<branch>` as of `<date>`" baseline).
  The **reader** reads the **current** default-branch tip date and compares: current newer than the
  baseline ⇒ **outdated**. To do so the reader gains a **cheap, read-only, cross-runtime
  (Python + Node) git read** of the default branch's latest-commit date that **degrades gracefully**
  — not a git repo / no `main`|`master` / detached HEAD / git absent ⇒ **skip the check, stay
  `approved`** (never error). The git read runs **per registered repo**. `aid-housekeep` (FR36)
  resolves an `outdated` state and re-stamps the baseline.
  - **Settings-schema note (producer-side schema addition).** This baseline is a **new key in the
    per-repo `.aid/settings.yml` schema**, which **`/aid-config` owns**. So the `aid-config`
    template/skill gains a **KB-baseline key** (e.g. `kb_baseline: {branch, tip_date}`), **written** by
    `aid-discover`/`aid-housekeep` (FR36) and **read** by the dashboard reader. This is a small,
    additive producer-side schema addition — no existing key changes — so it needs **no new open
    question**; it is captured here as a `/aid-specify` note (who validates the key, whether `/aid-config`
    surfaces it).
- **FR36 — Producer-skill changes (summarize / discover / housekeep / `bin/aid`).** The
  re-architecture requires the following **producer** edits, authored in `canonical/` and rendered
  via the FULL `run_generator.py` (C7), consistent with feature-009's dogfood model:
  - **`aid-summarize`** — write the KB summary to `<repo>/.aid/dashboard/kb.html` (FR31) instead of
    `.aid/knowledge/knowledge-summary.html`.
  - **`aid-discover`** — auto-trigger `aid-summarize` at its close (FR34) **and** record the
    default-branch baseline in `.aid/settings.yml` (FR35).
  - **`aid-housekeep`** — on a KB-DELTA refresh, regenerate the summary, **resolve `outdated`**, and
    **re-stamp** the default-branch baseline (FR35).
  - **`bin/aid`** (+ its PowerShell twin) — make `aid add`/`aid remove` **also** maintain
    `$AID_HOME/registry.yml` as a side-effect (FR29, OQ6 RESOLVED — register on first tool added,
    unregister on last tool removed; the host-tool install/uninstall behavior is unchanged) and the
    multi-repo server routing (FR30). Also adds a new key to the per-repo `.aid/settings.yml` schema —
    the KB-freshness baseline (FR35); see FR35's schema-ownership note.

### Upgrade migration (FR37–FR40)

> _Context: the two-level re-architecture (FR27–FR36) changed the per-repo layout — the dashboard
> page is now `<repo>/.aid/dashboard/home.html`, the KB summary moved to `.aid/dashboard/kb.html`,
> and a repo must be registered in `$AID_HOME/registry.yml` to appear on the CLI home. Repos created
> by older AID versions do **not** comply: they have no `.aid/dashboard/home.html` (it is neither
> vendored, generated, nor scaffolded — KI-010), may still hold a legacy
> `.aid/knowledge/knowledge-summary.html`, may have a missing/invalid `.aid/settings.yml`, and are not
> in the registry — so their per-repo dashboard cannot be served. FR37–FR40 add an **upgrade
> migration** that brings existing AID repos into compliance as part of the CLI upgrade. This is a
> migration problem, not a new-install problem: a fresh `aid add` already lays down a compliant repo
> once `home.html` is vendored (FR40); the migration is for repos that predate the new layout._

- **FR37 — Per-repo upgrade migration.** The CLI gains an **idempotent, read-mostly migration** that
  brings a single AID repo up to the current layout. It runs against a repo's base folder and performs,
  in order, only the steps that are not already satisfied (a no-op on an already-compliant repo):
  - **Detect / qualify.** A folder is a migratable AID repo iff it has a base-folder `.aid/` **and**
    either **(a)** a `.aid/settings.yml` (a repo from **≥ 0.7.X**) **or** **(b)** a `.aid/knowledge/`
    folder containing a discovery/knowledge state file (`DISCOVERY_STATE.md` / `DISCOVERY-STATE.md` /
    the modern `STATE.md` — a **pre-0.7** repo). A bare `.aid/` with neither marker (e.g. a stray
    `.aid/.temp`) is **not** a migration candidate.
  - **settings.yml — validate/repair or synthesize.** Era (a): validate `.aid/settings.yml` against the
    current schema (`/aid-config`-owned: `project.{name,description,type}`, `tools.installed`,
    `review.minimum_grade`, `execution.max_parallel_tasks`, `traceability.heartbeat_interval`;
    preserving any present `kb_baseline`/per-skill overrides) and **repair** it to the current shape if
    malformed/incomplete. Era (b): **synthesize** `.aid/settings.yml` from the template defaults, with
    `project.name` = repo folder basename and `tools.installed` derived from `.aid/.aid-manifest.json`
    (`project.description` empty/placeholder; `project.type` = `brownfield`; review/execution/
    traceability = template defaults). The synthesized/repaired file must parse cleanly for all current
    readers (`read-setting.sh`, the dashboard server/reader).
  - **Add `home.html`.** Place the current `.aid/dashboard/home.html` (the per-repo SPA shell — a
    static, repo-agnostic file copied from the single vendored source, FR40) if absent.
  - **Relocate legacy KB summary.** Move `.aid/knowledge/knowledge-summary.html` →
    `.aid/dashboard/kb.html` reusing the existing FR31 no-clobber idiom
    (`mkdir -p .aid/dashboard && mv -n`, guarded by `[ -f OLD ] && [ ! -f NEW ]`).
  - **Register.** Register the repo's base folder in `$AID_HOME/registry.yml` (reusing the existing
    idempotent, atomic `registry_register`).
- **FR38 — Migration command model (reach differs; logic is shared).** The migration is reached two
  ways, both via the **existing `aid update`** command (no new verb):
  - **`aid update self`** updates the CLI itself **then scans the machine** for AID repos (FR37 detect)
    and migrates **each discovered repo**, prompting per repo with **All / Yes / No / Cancel** (All =
    apply to this and all remaining without re-asking; Yes = this repo only; No = skip; Cancel = abort
    the whole scan). A repo the user answers **No** is **not registered** and the CLI tells the user to
    run **`aid update`** inside that folder to migrate it later.
  - **`aid update [<tool>…]`** ensures the CLI is current (self-update if a newer version exists), then
    migrates **only the current repo** (cwd / `--target`) — **no machine scan** — attaching the FR37
    migration to the existing per-repo update success path (beside the current `registry_register`
    side-effect). The same FR37 logic services both reaches; the only difference is scope (machine-wide
    scan vs current repo).
- **FR39 — Migration is part of the upgrade (trigger).** The migration is a **required part of the CLI
  upgrade** — the upgrade is not "complete" until the affected repos are migrated. Because the package
  managers cannot run a true install-time hook uniformly (npm can add a `postinstall`; pip/pipx wheels
  have no standard post-install hook, PEP 517), the trigger is realized as:
  - a **version sentinel** — the installed CLI version (`$AID_HOME/VERSION`) compared against a
    persisted "last-migrated" marker — checked on `aid` invocation: when the installed version has
    advanced past the last-migrated marker, the machine scan (FR38 `aid update self` behavior) runs
    **once** and the marker is updated. This is the **universal guarantee** (covers pypi,
    `--ignore-scripts`, and curl bootstrap), since pypi wheels have no install-time hook; and
  - an **npm `postinstall`** as the **eager** path on `npm i -g`.
  - In a **non-interactive** context (no TTY / CI / postinstall) the scan must **not** silently mutate
    repos: it annotates the candidate list and defers to the next interactive `aid update self` (or an
    explicit opt-in), per NFR12.
  - _(The exact sentinel-marker location and the opt-in flag/env-var name are /aid-specify decisions.)_
- **FR40 — `home.html` single vendored source.** `home.html` becomes a **vendored, repo-agnostic static
  shell** with a **single source of truth** (`dashboard/home.html`, alongside the CLI-home
  `dashboard/index.html`): it is added to both vendor manifests (`packages/npm/scripts/vendor.js`,
  `packages/pypi/scripts/vendor.py`) and installed to `$AID_HOME/dashboard/home.html`; the migration
  (FR37) and a fresh `aid add` copy it into each repo's `.aid/dashboard/home.html`. There is **no second
  committed source** that could drift (the repo's own `.aid/dashboard/home.html` is a copy of the
  vendored source). Repos stay **self-contained** — each holds its own `home.html` physically (NFR11),
  and no per-repo display info is duplicated outside its `.aid/` (FR28).

## 6. Non-Functional Requirements

> _Status: Complete (approved; any open research deferred to /aid-specify)._

- **NFR1 — Local-only / never public.** The dashboard is served locally and must never be
  reachable on the public internet (see C1). Reachability when the repo runs on a VM/remote
  machine is handled by an explicit, access-restricted private exposure mechanism (see C3),
  never by making it public.
- **NFR2 — Read-only.** No action ever mutates AID run state from the dashboard.
- **NFR3 — Freshness.** With default settings the displayed state should lag reality by no more
  than the polling interval (default ~5s).
- **NFR4 — Low overhead.** Polling/refresh must not meaningfully interfere with the AID runs it
  observes (it only reads state files).
- **NFR5 — Cross-platform & cross-browser.** Must work on **Windows, macOS, and Linux**, and
  render correctly in as many major browsers as possible — **Chrome, Firefox, Edge, Safari**.
- **NFR6 — Responsive layout.** The layout must adapt to **mobile, tablet, and desktop**
  viewports.
- **NFR7 — No agents / no LLM at runtime (hard).** The dashboard is an **automated information
  tool, not a skill**. While *operating*, it must **not depend on or invoke any agent / LLM** —
  it is deterministic code that reads state files and renders. This is to avoid wasting tokens.
  (This constrains the dashboard's *runtime behavior*; it does not restrict how this work itself
  is built.)
- **NFR8 — Visual style consistency.** Follow the **same style / theme / color scheme as the
  existing `.aid/knowledge/knowledge-summary.html`**, so the dashboard feels like part of the
  same AID visual family.
- **NFR9 — Multi-root read-only scoping.** With the multi-repo server (FR30), the read-only posture
  (NFR2) must hold across **all N registered repo roots simultaneously** — the server reads each
  registered repo's `.aid/` and never writes to any of them. Static file serving is **scoped to
  registered repos' `.aid/dashboard/` directories with fixed filenames only**; an unregistered path,
  a path outside a registered repo's `.aid/dashboard/`, or any path-traversal attempt is refused
  (see C6).
- **NFR10 — Stale-registry tolerance.** A registered repo that has been **moved or deleted** must
  render as **"unavailable"** on the CLI home (with an offer to prune it from the registry) and must
  **never cause the server, the CLI home, or any other repo's view to error**. A stale entry is a
  display state, not a failure. The cross-runtime git read (FR35) degrades the same way (FR35
  graceful-degradation rules apply per registered repo independently).
- **NFR11 — Co-located per-repo dashboard artifacts.** Per-repo dashboard output (`home.html`,
  `kb.html`) lives under **`<repo>/.aid/dashboard/`**, keeping the KB **source** folder
  (`.aid/knowledge/`) free of generated presentation artifacts. Anything specific to one repo travels
  with that repo's `.aid/` folder (consistent with §3 handoff portability); machine-level state
  (the registry, FR28) lives at the higher `~/.aid/` scope.
- **NFR12 — Migration safety (idempotent, additive, degrade-don't-block).** The upgrade migration
  (FR37–FR39) must be **safe to run repeatedly**: a no-op on an already-compliant repo, and it only
  **adds** files (`home.html`), **moves** the legacy summary (no-clobber `mv -n`, never deletes user
  data), and **repairs/creates** `settings.yml` while **preserving** any present
  `kb_baseline`/per-skill-override content. It uses crash-safe writes (temp-file + `mv -f`) and a
  **WARN-not-fail** posture (a single repo's migration failure never aborts the scan or the CLI op,
  mirroring registry NFR10). Repo **detection is read-only**; mutation happens only after consent
  (FR38) and never in a non-interactive context without an explicit opt-in (FR39). There is a **single
  source** for `home.html` (FR40) so no two copies can drift, and no per-repo metadata is duplicated
  outside the repo (FR28/NFR11).

## 7. Constraints

> _Status: Complete (approved; any open research deferred to /aid-specify)._

- **C1 — Never public (hard constraint).** The dashboard must **never** be exposed on the
  public internet under any circumstance.
- **C2 — Local case is private by default.** When running locally, privacy is inherent
  (bound to localhost / not routable externally).
- **C3 — Remote/VM exposure must be access-restricted (host/user-scoped).** When a repo must be
  reached from another machine, access must be **restricted to only the people authorized to access
  that specific VM / host** — **not** merely "anyone on the tunnel/tailnet." Direction set
  2026-06-10: if **Tailscale** is used it **must** be locked to **host/user ACLs/grants** (plain
  `tailscale serve` exposes the whole tailnet and is unacceptable); and the research must also
  **evaluate online alternatives to Tailscale** (other private/zero-trust/authenticated mechanisms),
  with the exact mechanism finalized in /aid-specify.
- **C4 — Behavior preservation (hard).** The FR17 pipeline state-management refactor may change
  *how and where* state is stored/named and *what* is captured, and may adjust skill/agent
  definitions to do so — but it must **preserve the existing observable behavior of the
  pipeline**. No change to what the pipeline *does* (its phases, gates, outputs, decisions); only
  to how its state is represented and surfaced.
  - **Fully-open redesign (user decision, 2026-06-10):** the refactor is **not** bounded to the
    current state design — **everything is on the table**, including re-opening the FR2 STATE.md
    consolidation and the `## Housekeep Status` layout if a better state model warrants it. The
    only invariant is **observable behavior preservation**, not the preservation of any current
    *file format/structure*. FR17 changes the state *representation*; C4 preserves the *behavior*.
  - **Catalogue, don't freeze:** the existing state design (FR2 consolidation, `## Housekeep
    Status` relocation, `.aid/.temp/*STATE*.md`, heartbeat, `MONITOR-STATE.md` — see
    `knowledge/pipeline-contracts.md`) must be **fully inventoried** by the research so the
    redesign knows exactly what it is changing — but it is reference context, not a fixed baseline.
  - **Verification surface:** any canonical edit (skill/agent/template/script bodies) must re-run
    the **FULL `run_generator.py`** so all five install trees stay byte-identical (render-drift),
    and **render-drift + full `tests/run-all.sh` + the Windows installer suite** must all stay
    green. Observable pipeline behavior (phases, gates, outputs, decisions) is unchanged.
- **C5 — Producer changes are dogfood-rendered (not awaiting a CLI release); reader stays
  no-LLM / read-only (hard).** The feature-009 producer edits to the pipeline skills are authored
  in `canonical/skills/` and **rendered into this repo's `.claude/skills/` via the FULL
  `run_generator.py`** (FR24), so they take effect for `/aid-*` on this repo **immediately**,
  with no dependency on shipping an `aid` CLI release. Two invariants hold: (1) the producer edits
  are **behavior-preserving** in the C4 sense — they only **add** the canonical display fields to
  what the skills already emit, never altering phases, gates, outputs, or decisions; and (2) the
  dashboard **reader/front-end remain no-LLM and strictly read-only** (NFR2/NFR7) — reconciliation
  (FR23) changes only how the reader **parses** state, never that it writes or invokes an
  agent/LLM at runtime.
- **C6 — Multi-root read-only scoping + no path traversal; preserve feature-003's delivered server
  invariants (hard).** FR30 is a **contract-level change** to feature-003's already-delivered CLOSED
  two-route allowlist server (`/` + `/api/model`, single `--root`) — **not** an additive routing tweak.
  It **replaces** that closed allowlist with a **NEW explicit closed allowlist**: `/` (CLI `index.html`)
  plus, **per registered repo**, that repo's `home.html`, `kb.html`, and `/api/model`. The multi-repo
  server must **preserve feature-003's hard invariants** — **loopback bind / local-only** (C1/C2),
  **no-write** (NFR2), **no-LLM** (NFR7) — and serve static files **only** from registered repos'
  `.aid/dashboard/` directories, **only** the fixed filenames the dashboard produces, resolving every
  request against the registry (FR28). It must **structurally refuse** any path that escapes a registered
  repo's `.aid/dashboard/` (no `..`, no symlink escape, no absolute-path injection, no serving of arbitrary
  `.aid/` content). The never-public (C1/C2) and read-only (NFR2/NFR9) constraints continue to hold across
  **all** registered roots. **Blast radius (explicit):** feature-003's **PT-1 cross-runtime parity** and its
  **no-write / bind / no-LLM self-checks** must be **extended to the multi-repo shape** (N roots, the new
  per-repo route set, the new closed allowlist), since this reopens the same invariants feature-006's DD-1
  leaned on. (Tightens NFR2 for the N-root case; preserves C1's local-only binding.)
- **C7 — Re-architecture producer edits are dogfood-rendered; reader stays no-LLM / read-only
  (hard).** The FR36 producer-skill changes (`aid-summarize`, `aid-discover`, `aid-housekeep`,
  `bin/aid`) are authored in `canonical/` and **rendered into this repo's `.claude/skills/` (and all
  install trees) via the FULL `run_generator.py`** — exactly the C5 dogfood model — so they take effect
  for `/aid-*` on this repo immediately, with no dependency on an `aid` CLI release, and **render-drift +
  deterministic-emission gates stay green**. **Behavior scope (not blanket-preserving):** most of these
  edits are **behavior-additive** to the existing skills — relocating the summary output path, recording/
  resolving the KB baseline, and making `aid add`/`aid remove` **also** maintain the registry (a
  side-effect that leaves their host-tool install/uninstall behavior unchanged) — they do not alter any
  existing phase, gate, output, or decision of the affected skills. **The one deliberate exception is
  FR34:** the discover→summarize auto-trigger is an **intended new closing behavior** of `aid-discover`
  (it now produces `kb.html`), **not** a C4 behavior-preserving change (see FR34). It composes the two
  existing approval gates (discovery KB approval + summarize V1) rather than replacing either, but the
  added auto-invocation + new output is by design. The dashboard **reader stays no-LLM / read-only**
  (NFR2/NFR7): the new git read (FR35) and KB-status derivation (FR32) are read-only and contain no
  agent/LLM invocation.
- **C8 — Migration ships in `bin/aid` with PowerShell parity; never destroys user data (hard).** The
  upgrade migration (FR37–FR40) lands in the **hand-maintained** `bin/aid` (+ its `bin/aid.ps1` twin)
  and the install/package layer — **not** in `canonical/`→render artifacts. Every `bin/aid` edit is
  therefore gated by **ASCII-only** (`tests/canonical/test-ascii-only.sh`), **Bash↔PowerShell parity**
  (`tests/canonical/test-aid-cli-parity.sh`), and **vendored-copy refresh** (`vendor.js`/`vendor.py`) —
  NOT render-drift. The migration **must never delete or overwrite** user content: it only adds
  `home.html`, moves the legacy summary with `mv -n` (no-clobber), and repairs/creates `settings.yml`
  preserving existing values (NFR12). It honors the project's "annotate + offer, let the user confirm"
  posture — it does not auto-mutate a repo a heuristic merely *guesses* is AID without the FR37 marker,
  and it asks before writing (FR38). `home.html` has exactly one committed source (`dashboard/home.html`,
  FR40) to prevent drift, consistent with C7's no-duplication intent for repo info.

## 8. Assumptions & Dependencies

**Open research / discussion items (flagged at intake):**
- **OQ1 — RESOLVED.** Per-repo independence stands: **one project per page**, no in-app
  cross-project tab strip. Multiple projects are viewed via **native browser tabs**, each
  pointing at one project's independently-served dashboard. The "no cross-repo aggregation"
  decision (§ 3a/§ 4) is unchanged and reinforced.
- **OQ2 — RESOLVED (2026-06-10): Option C (hybrid), dual-runtime.** A pure static `file://` HTML
  page cannot poll live `.aid/` state (browsers block `file://` fetch), so live polling (FR4)
  requires a runtime process. Decision: a **dependency-free static HTML/CSS/JS front-end** (reusing
  the `knowledge-summary.html` design family, NFR8) that polls a single `/api/model` endpoint on a
  **thin, stdlib-only local server** bound to `127.0.0.1` (C1/C2), which runs feature-002's
  `read_repo()`. **Both runtimes are supported and user-selectable at launch**
  (`aid dashboard start node` / `aid dashboard start python`) — the `/api/model` JSON contract and
  the front-end are identical across runtimes. Zero third-party deps (Python 3.11+ stdlib / Node built-ins). **Implication:** the thin
  server + feature-002 reader are implemented **twice** (Python + Node), with a **parity test**
  guaranteeing identical model JSON from both. **Runtime is chosen on the start command** (see OQ3):
  `aid dashboard start node` / `aid dashboard start python`.
- **OQ3 — RESOLVED (2026-06-10): `aid dashboard` subcommand with `start`/`stop` verbs.** Exact
  command shape:
  - **`aid dashboard start node|python [--remote]`** — start; the positional selects the runtime
    (OQ2); the **`--remote` flag** (orthogonal to runtime) additionally brings up feature-005's
    host/user-ACL-scoped Tailscale exposure over the localhost port. Without `--remote` the server
    is local-only (binds `127.0.0.1`, C1). On a host without the exposure mechanism, `--remote`
    fails clearly — it never binds public.
  - **`aid dashboard stop`** — tears down the server **and** any active remote exposure.

  Runtime and exposure are **orthogonal axes** (any runtime composes with local or remote). Bare
  `aid` is already an implemented command (`bin/aid` `_cmd_dashboard()`), so it must not be
  repurposed (C4); a separate CLI was not chosen. Launcher stays Bash (`bin/aid`) + PowerShell twin
  (`bin/aid.ps1`), spawning the chosen runtime's server as a tracked child process.
- **OQ4 — PROMOTED to FR17.** Where is per-skill/task run-state persisted? Today fragmented
  (work `STATE.md` tables, `.aid/.temp/*STATE*.md`, `MONITOR-STATE.md`, heartbeat). This is no
  longer just an open question — **FR17 authorizes a full behavior-preserving review and
  normalization** of pipeline state management to resolve it at the source. Owned by the
  front-loaded state-architecture feature.
- **OQ5 — RESOLVED (user decision 2026-06-12): `--remote` exposes the CLI home (all registered repos).**
  `aid dashboard --remote` exposes the **machine-level CLI home** — a grantee sees the **full
  registered-repo list** and can open **any** registered repo's dashboard (`home.html`/`kb.html`/
  `/api/model`) through the multi-repo server (FR30). It remains **tailnet-private and never public**
  (NFR1/C1) and **host/user-ACL-scoped** (C3) — only the granted tailnet identities reach it; the
  exposure mechanism is unchanged. **Accepted trade-off:** exposing the repo list (paths/names) to those
  *granted* tailnet identities is acceptable; a granted user is already a trusted operator of that host.
  This is a feature-010 serving-scope decision (not a registry or per-repo decision) and did not block
  the refactor's earlier slices. _Owned by feature-010; cross-references feature-005 (C3)._
- **OQ6 — RESOLVED (user decision 2026-06-12): registry maintenance is a side-effect of `aid add` /
  `aid remove` — no new verb.** There is **no naming collision** because there is **no new verb**:
  `aid add` / `aid remove` keep their existing host-tool install/uninstall behavior **unchanged** and
  now **additionally** keep `$AID_HOME/registry.yml` in sync — a repo is **registered on its first tool
  added** and **unregistered on its last tool removed** (FR29). This is **additive, not an overload**:
  no existing behavior changes (C4/C7 preserved), so the literal `aid add` / `aid remove` in feature-010's
  user stories is now **correct** (a side-effect, not a repurposed verb). _Owned by feature-010._

## 9. Acceptance Criteria

> _Status: Complete — approved. MVP acceptance defined; full-scope AC elaborated per-feature during spec._

**MVP acceptance (the first usable win):** For the repo it is launched in, the dashboard shows:
- **AC1** — The **stages of the project pipeline** (works on either the **full** or **lite**
  path) with a clear indication of **where the pipeline currently is** in the process.
- **AC2** — **Which skill/task is currently executing** and **in what state** — including
  **multiple tasks running in parallel** (e.g. `/aid-discover` agents, `/aid-execute` waves)
  shown concurrently, not as a single linear task.
- **AC3** — A clear indication when the process is **paused / blocked**, distinguishing:
  - waiting for **user input**,
  - waiting for a **confirmation / decision**,
  - halted because of an **error / failure**.
- **AC4** — The view **updates live** (polling, default 5s) so the above reflects progress in
  near-real-time.
- **AC5** — Served **locally** and viewable in a browser; never public.

**Scope note — MVP ≠ the whole work.** The MVP (AC1–AC5) is **only the first deliverable** of
this work. This work's full scope includes **many more features** beyond the MVP (multiple &
historical works in one repo, level-0 CLI info, secure VM/remote exposure with authorized-user
restriction, full level-3 detail and richest tracking set, multi-platform/responsive polish,
etc.). The complete **feature roadmap and delivery sequencing are decided during the planning
phase (`/aid-plan`)** — not locked in this requirements document. Requirements here describe the
**full vision**; the MVP simply marks what ships first.

## 10. Priority

> _Status: Complete — approved. **Indicative only:** the authoritative roadmap and delivery
> sequencing are decided during `/aid-plan`. The list below is a first-cut hint, not a commitment;
> only the MVP (P0) is firmly "ships first."_

- **P0 (MVP — first deliverable):** Single-repo, local, live pipeline-progress view per
  AC1–AC5 (the operator's "where am I / what's next / what failed" view).
- **P1 (candidate):** Multiple & historical works in the same repo; level-0 machine CLI info.
- **P2 (candidate):** Secure VM/remote exposure with authorized-user-only restriction (C3
  research); serving-tool selection.
- **P3 (candidate):** Maximal level-3 tracking detail; layout/visual-design refinement;
  possible push-based (non-polling) live updates.

_(P1–P3 groupings are tentative; planning may re-order, split, or add features.)_
